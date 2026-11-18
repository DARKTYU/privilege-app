import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_models.dart';
import '../models/community_post.dart';
import 'session_recovery.dart';

class CommunityException implements Exception {
  const CommunityException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CommunityRepository {
  CommunityRepository(this.client);
  final SupabaseClient client;
  static const pageSize = 20;
  static const commentPageSize = 30;
  static const imageMaxBytes = 8 * 1024 * 1024;
  static const imageBucket = 'community-posts';

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) {
      throw const CommunityException('Please sign in again.');
    }
    return id;
  }

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await SessionRecovery.forClient(client).request(action);
    } on PostgrestException catch (error) {
      throw CommunityException(error.message);
    } on StorageException catch (error) {
      throw CommunityException(error.message);
    } on http.ClientException {
      throw const CommunityException(
          'Could not connect. Check your internet connection.');
    } on SocketException {
      throw const CommunityException(
          'Could not connect. Check your internet connection.');
    } on TimeoutException {
      throw const CommunityException(
          'The request timed out. Please try again.');
    }
  }

  Future<List<CommunityPost>> feed({CommunityPost? before}) async {
    final rows = await _request(() => client.rpc('community_feed', params: {
          'p_before_group': before?.friendGroup,
          'p_before_time': before?.createdAt.toUtc().toIso8601String(),
          'p_before_id': before?.id,
          'p_limit': pageSize,
        }));
    return (rows as List)
        .map((row) =>
            CommunityPost.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> post(String body, String visibility, {XFile? image}) async {
    if (body.trim().isEmpty) {
      throw const CommunityException(
          'Write something before sharing your post.');
    }
    if (body.length > 5000) {
      throw const CommunityException('Posts must be 5000 characters or fewer.');
    }
    if (image != null) {
      final length = await image.length();
      if (length == 0 || length > imageMaxBytes) {
        throw const CommunityException('Choose an image smaller than 8 MB.');
      }
      final type = _mimeType(image);
      if (type != 'image/jpeg' && type != 'image/png' && type != 'image/webp') {
        throw const CommunityException('Choose a JPG, PNG, or WebP image.');
      }
    }

    final userId = _userId;
    final postId = _generateUuid();
    final imagePath = image == null
        ? null
        : '$userId/$postId/image.${_extension(_mimeType(image))}';
    if (image != null) {
      await _request(() async {
        await client.storage.from(imageBucket).uploadBinary(
              imagePath!,
              await image.readAsBytes(),
              fileOptions: FileOptions(
                contentType: _mimeType(image),
                upsert: false,
              ),
            );
      });
    }
    try {
      await _request(() => client.from('community_posts').insert({
            'id': postId,
            'body': body.trim(),
            'visibility': visibility,
            if (imagePath != null) 'image_path': imagePath,
          }));
    } catch (error) {
      if (imagePath != null) {
        try {
          await _request(
              () => client.storage.from(imageBucket).remove([imagePath]));
        } on StorageException catch (cleanupError) {
          throw CommunityException(
              '$error (The uploaded image could not be cleaned up: ${cleanupError.message})');
        }
      }
      rethrow;
    }
  }

  String _mimeType(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType == 'image/jpeg' ||
        mimeType == 'image/png' ||
        mimeType == 'image/webp') {
      return mimeType!;
    }
    final name = image.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    return mimeType ?? '';
  }

  String _extension(String mimeType) => switch (mimeType) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => 'jpg',
      };

  String _generateUuid() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> deletePost(CommunityPost post) async {
    if (post.authorId != _userId) {
      throw const CommunityException('You can only delete your own post.');
    }
    if (post.imagePath != null) {
      await _request(
          () => client.storage.from(imageBucket).remove([post.imagePath!]));
    }
    await _request(() => client
        .from('community_posts')
        .delete()
        .eq('id', post.id)
        .eq('author_id', _userId));
  }

  Future<String> signedImageUrl(String path) => _request(
      () => client.storage.from(imageBucket).createSignedUrl(path, 600));

  Future<void> setLiked(CommunityPost post) async {
    final userId = _userId;
    if (post.likedByMe) {
      await _request(() => client
          .from('community_likes')
          .delete()
          .eq('post_id', post.id)
          .eq('user_id', userId));
    } else {
      await _request(
          () => client.from('community_likes').insert({'post_id': post.id}));
    }
  }

  Future<List<CommunityComment>> comments(
    String postId, {
    CommunityComment? before,
  }) async {
    final rows =
        await _request(() => client.rpc('community_comments_page', params: {
              'p_post_id': postId,
              'p_before_created_at':
                  before?.createdAt.toUtc().toIso8601String(),
              'p_before_id': before?.id,
              'p_limit': commentPageSize,
            }));
    final data = (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    if (data.isEmpty) return [];
    final likes = await _request(() => client
        .from('community_comment_likes')
        .select('comment_id')
        .eq('user_id', _userId)
        .inFilter('comment_id', data.map((row) => row['id']).toList()));
    final liked = likes.map((row) => row['comment_id']).toSet();
    return data.map((row) {
      row['liked_by_me'] = liked.contains(row['id']);
      return CommunityComment.fromJson(row);
    }).toList();
  }

  Future<void> setCommentLiked(String id, bool liked) async {
    await _request(() => client.rpc('community_set_comment_like',
        params: {'p_comment_id': id, 'p_liked': liked}));
  }

  Future<CommunityPost?> postById(String id) async {
    final row = await _request(() => client
        .from('community_posts')
        .select('id,author_id,body,visibility,image_path,created_at')
        .eq('id', id)
        .maybeSingle());
    if (row == null) return null;
    final identity = await _request(() => client
        .from('community_profiles')
        .select('username,full_name,avatar_url')
        .eq('id', row['author_id'])
        .maybeSingle());
    if (identity == null) return null;
    final likes = await _request(() => client
        .from('community_likes')
        .select('id')
        .eq('post_id', id)
        .eq('user_id', _userId));
    return CommunityPost.fromJson({
      ...row,
      ...identity,
      'friend_group': 0,
      'like_count': 0,
      'comment_count': 0,
      'liked_by_me': likes.isNotEmpty,
    });
  }

  Future<void> comment(String postId, String body) async {
    final value = body.trim();
    if (value.isEmpty || value.length > 2000) {
      throw const CommunityException('Comments must be 1–2000 characters.');
    }
    await _request(() => client
        .from('community_comments')
        .insert({'post_id': postId, 'body': value}));
  }

  Future<List<CommunityPerson>> searchUsers(String query) async {
    final rows = await _request(() => client.rpc('community_search_users',
        params: {'p_query': query.trim(), 'p_limit': 30, 'p_offset': 0}));
    return (rows as List)
        .map((row) =>
            CommunityPerson.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<CommunityPerson>> friends() async {
    final rows = await _request(() => client.rpc('community_friends'));
    return (rows as List).map((row) {
      final json = Map<String, dynamic>.from(row as Map);
      json['relationship'] = 'friends';
      return CommunityPerson.fromJson(json);
    }).toList();
  }

  Future<List<CommunityPerson>> friendRequests() async {
    final rows = await _request(() => client.rpc('community_friend_requests'));
    return (rows as List)
        .map((row) =>
            CommunityPerson.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> sendFriendRequest(String userId) async {
    await _request(
        () => client.from('friendships').insert({'addressee_id': userId}));
  }

  Future<void> respondToFriendRequest(
      String friendshipId, String action) async {
    await _request(() => client.rpc('respond_to_friendship',
        params: {'p_id': friendshipId, 'p_action': action}));
  }

  Future<void> setFollowing(String userId, bool following) async {
    if (following) {
      await _request(() => client
          .from('community_follows')
          .delete()
          .eq('followed_id', userId)
          .eq('follower_id', _userId));
    } else {
      await _request(() =>
          client.from('community_follows').insert({'followed_id': userId}));
    }
  }

  Future<void> blockUser(String userId) async {
    await _request(
        () => client.from('community_blocks').insert({'blocked_id': userId}));
  }

  Future<void> reportPost(String postId, String reason) async {
    await _request(() => client
        .from('community_reports')
        .insert({'post_id': postId, 'reason': reason}));
  }

  Future<CommunityPublicProfile?> publicProfile(String userId) async {
    final row = await _request(() => client.rpc('community_public_profile',
        params: {'p_user_id': userId}).maybeSingle());
    if (row == null) return null;
    return CommunityPublicProfile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<CommunityNotification>> notifications() async {
    final rows = await _request(() =>
        client.rpc('community_notifications_page_v2', params: {'p_limit': 50}));
    return (rows as List)
        .map((row) => CommunityNotification.fromJson(
            Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<int> unreadCount() async {
    final count = await _request(() => client.rpc('community_unread_count'));
    if (count is! num) {
      throw const CommunityException('Could not load notification count.');
    }
    return count.toInt();
  }

  Future<void> markNotificationRead(String id) async {
    await _request(() => client
        .from('community_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('recipient_id', _userId));
  }

  Future<void> markAllNotificationsRead() async {
    await _request(() => client
        .from('community_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('recipient_id', _userId)
        .isFilter('read_at', null));
  }

  Future<Map<String, bool>> notificationSettings() async {
    final row = await _request(() => client
        .from('community_notification_settings')
        .select(
            'likes_enabled,comments_enabled,friend_posts_enabled,friend_requests_enabled')
        .eq('user_id', _userId)
        .maybeSingle());
    return {
      for (final key in [
        'likes_enabled',
        'comments_enabled',
        'friend_posts_enabled',
        'friend_requests_enabled'
      ])
        key: row == null ? true : row[key] as bool,
    };
  }

  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    await _request(
        () => client.rpc('community_set_notification_settings', params: {
              'p_likes': settings['likes_enabled'],
              'p_comments': settings['comments_enabled'],
              'p_friend_posts': settings['friend_posts_enabled'],
              'p_friend_requests': settings['friend_requests_enabled'],
            }));
  }
}
