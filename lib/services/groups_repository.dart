import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_recovery.dart';

class GroupException implements Exception {
  const GroupException(this.message);
  final String message;
  @override
  String toString() => message;
}

String groupError(Object error) {
  final text = error is PostgrestException ? error.message : error.toString();
  final lower = text.toLowerCase();
  if (lower.contains('banned')) {
    return 'You are banned from this group. Only the group owner or a moderator can unban you.';
  }
  if (lower.contains('group is full')) return 'This group is full.';
  if (lower.contains('only moderators can post')) {
    return 'Only moderators can post in this group.';
  }
  if (lower.contains('posting limit')) {
    return 'Posting limit reached. Please try again later.';
  }
  if (lower.contains('three groups')) return 'You can create up to 3 groups.';
  if (lower.contains('group is unavailable')) {
    return 'This group is unavailable or requires an invitation.';
  }
  return text;
}

class Group {
  Group.fromJson(Map<String, dynamic> row)
      : id = row['id'] as String,
        ownerId = row['owner_id'] as String,
        name = row['name'] as String,
        description = row['description'] as String,
        category = row['category'] as String,
        visibility = row['visibility'] as String,
        joinMode = row['join_mode'] as String,
        limit = (row['member_limit'] as num).toInt(),
        rules = row['rules'] as String,
        avatar = row['avatar_url'] as String?,
        posting = row['who_can_post'] as String,
        images = row['images_allowed'] as bool,
        chat = row['chat_enabled'] as bool;
  final String id, ownerId, name, description, category, visibility, joinMode;
  final int limit;
  final String rules, posting;
  final String? avatar;
  final bool images, chat;
}

class GroupsRepository {
  GroupsRepository(this.client);
  final SupabaseClient client;
  String get userId =>
      client.auth.currentUser?.id ??
      (throw const GroupException('Please sign in again.'));

  Future<T> request<T>(Future<T> Function() action) async {
    try {
      return await SessionRecovery.forClient(client).request(action);
    } on PostgrestException catch (error) {
      throw GroupException(groupError(error));
    } on StorageException catch (error) {
      throw GroupException(error.message);
    } on SocketException {
      throw const GroupException(
          'Could not connect. Check your internet connection.');
    } on http.ClientException {
      throw const GroupException(
          'Could not connect. Check your internet connection.');
    } on TimeoutException {
      throw const GroupException('The request timed out. Please try again.');
    }
  }

  Future<List<Group>> groups() async {
    final rows =
        await request(() => client.from('groups').select().order('name'));
    return rows.map((row) => Group.fromJson(row)).toList();
  }

  Future<Group?> group(String id) async {
    final row = await request(
        () => client.from('groups').select().eq('id', id).maybeSingle());
    return row == null ? null : Group.fromJson(row);
  }

  Future<List<Map<String, dynamic>>> members(String id) async =>
      await request(() => client
          .from('group_members')
          .select()
          .eq('group_id', id)
          .order('created_at'));

  Future<List<Map<String, dynamic>>> bannedMembers(String id) async {
    final rows = await rpc('group_banned_members', {'p_group': id});
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> myMemberships() async =>
      await request(() => client
          .from('group_members')
          .select()
          .eq('user_id', userId)
          .inFilter('status', ['active', 'pending']));

  Future<List<Map<String, dynamic>>> invitations() async => await request(() =>
      client.from('group_invites').select('group_id').eq('user_id', userId));

  Future<List<Map<String, dynamic>>> posts(String id) async =>
      await request(() => client
          .from('group_posts')
          .select()
          .eq('group_id', id)
          .order('created_at', ascending: false));

  Future<List<Map<String, dynamic>>> comments(String id) async =>
      await request(() => client
          .from('group_comments')
          .select()
          .eq('post_id', id)
          .order('created_at'));

  Future<List<Map<String, dynamic>>> likes(String id) async => await request(
      () => client.from('group_post_likes').select().eq('post_id', id));

  Future<Map<String, dynamic>?> profile(String id) async =>
      await request(() => client
          .from('community_profiles')
          .select('id,username,full_name,avatar_url')
          .eq('id', id)
          .maybeSingle());

  Future<int> count(String id) async {
    final value = await request(
        () => client.rpc('group_member_count', params: {'p_group': id}));
    return (value as num).toInt();
  }

  Future<dynamic> rpc(String name, Map<String, dynamic> params) =>
      request(() => client.rpc(name, params: params));

  Future<String> imageUrl(String path) => request(() =>
      client.storage.from('group-post-images').createSignedUrl(path, 600));

  Future<void> createPost(String groupId, String body, XFile? image) async {
    String? path;
    if (image != null) {
      final name = image.name.toLowerCase();
      final mime = image.mimeType;
      final type = mime == 'image/jpeg' || mime == 'image/png' || mime == 'image/webp'
          ? mime
          : name.endsWith('.png')
              ? 'image/png'
              : name.endsWith('.webp')
                  ? 'image/webp'
                  : name.endsWith('.jpg') || name.endsWith('.jpeg')
                      ? 'image/jpeg'
                      : null;
      if (type == null) {
        throw const GroupException(
            'Choose a JPG, PNG or WebP image smaller than 8 MB.');
      }
      final Uint8List bytes;
      try {
        bytes = await image.readAsBytes();
      } catch (error, stack) {
        debugPrint('Could not read group image: $error\n$stack');
        throw const GroupException('Could not read the image. Please choose it again.');
      }
      if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
        throw const GroupException(
            'Choose a JPG, PNG or WebP image smaller than 8 MB.');
      }
      final suffix = type == 'image/png'
          ? 'png'
          : type == 'image/webp'
              ? 'webp'
              : 'jpg';
      final random = Random.secure();
      final filename = List.generate(16, (_) => random.nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
      path = '$groupId/$userId/$filename.$suffix';
      try {
        await request(() => client.storage.from('group-post-images')
            .uploadBinary(path!, bytes, fileOptions: FileOptions(contentType: type)));
      } on GroupException catch (error, stack) {
        debugPrint('Group image upload failed: $error\n$stack');
        throw const GroupException('Could not upload the image. Please try again.');
      }
    }
    try {
      await rpc('group_create_post',
          {'p_group': groupId, 'p_body': body, 'p_image_path': path});
    } catch (error) {
      if (path != null) {
        try {
          await request(
              () => client.storage.from('group-post-images').remove([path!]));
        } catch (cleanupError) {
          throw GroupException(
              '${groupError(error)} Image cleanup failed: ${groupError(cleanupError)}');
        }
      }
      rethrow;
    }
  }

  Future<String?> notificationTarget(String id) async =>
      await rpc('group_notification_target', {'p_notification': id}) as String?;
}
