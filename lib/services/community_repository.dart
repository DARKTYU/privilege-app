import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_post.dart';

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

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
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

  Future<void> post(String body, String visibility) async {
    await _request(() => client.from('community_posts').insert({
          'body': body,
          'visibility': visibility,
        }));
  }

  Future<void> setLiked(CommunityPost post) async {
    if (post.likedByMe) {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw const CommunityException('Please sign in again.');
      }
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
}
