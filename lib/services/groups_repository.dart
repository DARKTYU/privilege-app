import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n_strings.dart';
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
    return savedLanguageStrings().groupsBannedError;
  }
  if (lower.contains('group is full')) return savedLanguageStrings().groupsFullError;
  if (lower.contains('only moderators can post')) {
    return savedLanguageStrings().groupsModeratorsOnlyError;
  }
  if (lower.contains('posting limit')) {
    return savedLanguageStrings().groupsPostingLimitError;
  }
  if (lower.contains('three groups')) return savedLanguageStrings().groupsCreationLimitError;
  if (lower.contains('group is unavailable')) {
    return savedLanguageStrings().groupsUnavailableError;
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
        avatarPath = row['avatar_path'] as String?,
        posting = row['who_can_post'] as String,
        images = row['images_allowed'] as bool,
        chat = row['chat_enabled'] as bool;
  final String id, ownerId, name, description, category, visibility, joinMode;
  final int limit;
  final String rules, posting;
  final String? avatar;
  final String? avatarPath;
  final bool images, chat;
}

class GroupAvatarImage {
  const GroupAvatarImage(this.bytes, this.extension, this.contentType);
  final Uint8List bytes;
  final String extension;
  final String contentType;
}

class GroupsRepository {
  GroupsRepository(this.client);
  final SupabaseClient client;
  static final Expando<Map<String, (String, DateTime)>> _avatarCache =
      Expando();
  Map<String, (String, DateTime)> get _avatarUrls =>
      _avatarCache[client] ??= {};
  String get userId =>
      client.auth.currentUser?.id ??
      (throw GroupException(savedLanguageStrings().communityErrorSignIn));

  Future<T> request<T>(Future<T> Function() action) async {
    try {
      return await SessionRecovery.forClient(client).request(action);
    } on PostgrestException catch (error) {
      throw GroupException(groupError(error));
    } on StorageException catch (error) {
      throw GroupException(error.message);
    } on SocketException {
      throw GroupException(savedLanguageStrings().communityErrorConnection);
    } on http.ClientException {
      throw GroupException(savedLanguageStrings().communityErrorConnection);
    } on TimeoutException {
      throw GroupException(savedLanguageStrings().communityErrorTimeout);
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

  Future<String> signedAvatarUrl(String path) async {
    final key = '$userId:$path';
    final cached = _avatarUrls[key];
    if (cached != null && DateTime.now().isBefore(cached.$2)) return cached.$1;
    final url = await request(
        () => client.storage.from('group-avatars').createSignedUrl(path, 600));
    _avatarUrls[key] = (url, DateTime.now().add(const Duration(minutes: 8)));
    return url;
  }

  Future<GroupAvatarImage> prepareAvatar(XFile image) async {
    final name = image.name.toLowerCase();
    final extension = name.split('.').last;
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
    if (contentType == null || !name.contains('.')) {
      throw GroupException(savedLanguageStrings().groupsPhotoTypeError);
    }
    final Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
    } catch (error, stack) {
      debugPrint('Could not read group photo: $error\n$stack');
      throw GroupException(savedLanguageStrings().groupsPhotoReadError);
    }
    if (bytes.isEmpty) {
      throw GroupException(savedLanguageStrings().groupsPhotoEmptyError);
    }
    final matchesType = switch (contentType) {
      'image/jpeg' => bytes.length >= 3 &&
          bytes[0] == 0xff &&
          bytes[1] == 0xd8 &&
          bytes[2] == 0xff,
      'image/png' => bytes.length >= 8 &&
          listEquals(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]),
      'image/webp' => bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP',
      _ => false,
    };
    if (!matchesType) {
      throw GroupException(savedLanguageStrings().groupsPhotoMismatchError);
    }
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final ui.ImageDescriptor descriptor;
      try {
        descriptor = await ui.ImageDescriptor.encoded(buffer);
      } finally {
        buffer.dispose();
      }
      final width = descriptor.width;
      final height = descriptor.height;
      descriptor.dispose();
      if (width > 1024 || height > 1024) {
        final scale = 1024 / max(width, height);
        final codec = await ui.instantiateImageCodec(bytes,
            targetWidth: max(1, (width * scale).round()),
            targetHeight: max(1, (height * scale).round()));
        final frame = await codec.getNextFrame();
        final data =
            await frame.image.toByteData(format: ui.ImageByteFormat.png);
        frame.image.dispose();
        codec.dispose();
        if (data == null) throw StateError('Image encoding failed');
        final resized =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        if (resized.length > 2 * 1024 * 1024) {
          throw GroupException(savedLanguageStrings().groupsPhotoSizeError);
        }
        return GroupAvatarImage(resized, 'png', 'image/png');
      }
    } on GroupException {
      rethrow;
    } catch (error, stack) {
      debugPrint('Could not decode group photo: $error\n$stack');
      throw GroupException(savedLanguageStrings().groupsPhotoInvalidError);
    }
    if (bytes.length > 2 * 1024 * 1024) {
      throw GroupException(savedLanguageStrings().groupsPhotoSizeError);
    }
    return GroupAvatarImage(bytes, extension, contentType);
  }

  Future<void> setAvatar(
      String groupId, GroupAvatarImage? image, String? oldPath) async {
    String? newPath;
    if (image != null) {
      final random = Random.secure();
      final filename = List.generate(16, (_) => random.nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      newPath = '$groupId/$filename.${image.extension}';
      await request(() => client.storage.from('group-avatars').uploadBinary(
          newPath!, image.bytes,
          fileOptions: FileOptions(contentType: image.contentType)));
    }
    await rpc('group_set_avatar', {'p_group': groupId, 'p_path': newPath});
    if (oldPath != null && oldPath != newPath) {
      try {
        await request(
            () => client.storage.from('group-avatars').remove([oldPath]));
      } catch (error, stack) {
        debugPrint('Could not clean up old group photo: $error\n$stack');
      }
      _avatarUrls.remove('$userId:$oldPath');
    }
  }

  Future<void> createPost(String groupId, String body, XFile? image) async {
    String? path;
    if (image != null) {
      final name = image.name.toLowerCase();
      final mime = image.mimeType;
      final type =
          mime == 'image/jpeg' || mime == 'image/png' || mime == 'image/webp'
              ? mime
              : name.endsWith('.png')
                  ? 'image/png'
                  : name.endsWith('.webp')
                      ? 'image/webp'
                      : name.endsWith('.jpg') || name.endsWith('.jpeg')
                          ? 'image/jpeg'
                          : null;
      if (type == null) {
        throw GroupException(savedLanguageStrings().groupImageTypeSizeError);
      }
      final Uint8List bytes;
      try {
        bytes = await image.readAsBytes();
      } catch (error, stack) {
        debugPrint('Could not read group image: $error\n$stack');
        throw GroupException(savedLanguageStrings().groupImageReadError);
      }
      if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
        throw GroupException(savedLanguageStrings().groupImageTypeSizeError);
      }
      final suffix = type == 'image/png'
          ? 'png'
          : type == 'image/webp'
              ? 'webp'
              : 'jpg';
      final random = Random.secure();
      final filename = List.generate(16, (_) => random.nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      path = '$groupId/$userId/$filename.$suffix';
      try {
        await request(() => client.storage
            .from('group-post-images')
            .uploadBinary(path!, bytes,
                fileOptions: FileOptions(contentType: type)));
      } on GroupException catch (error, stack) {
        debugPrint('Group image upload failed: $error\n$stack');
        throw GroupException(savedLanguageStrings().groupImageUploadError);
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
          throw GroupException(friendlyError(cleanupError));
        }
      }
      rethrow;
    }
  }

  Future<String?> notificationTarget(String id) async =>
      await rpc('group_notification_target', {'p_notification': id}) as String?;
}
