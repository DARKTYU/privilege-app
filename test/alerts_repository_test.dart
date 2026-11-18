import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privilege/services/community_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('v2 alerts, settings and comment likes use the correct Supabase APIs',
      () async {
    final requests = <http.Request>[];
    final mock = MockClient((request) async {
      requests.add(request);
      http.Response json(Object? value) => http.Response(jsonEncode(value), 200,
          request: request, headers: {'content-type': 'application/json'});
      final path = request.url.path;
      if (path.endsWith('/token')) {
        return json({
          'access_token': 'token',
          'refresh_token': 'refresh',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            'aud': 'authenticated',
            'created_at': '2026-01-01T00:00:00Z',
          }
        });
      }
      if (path.endsWith('/community_notifications_page_v2')) {
        return json([
          {
            'id': 'alert',
            'notification_type': 'post_comment',
            'post_id': 'post',
            'friendship_id': null,
            'read_at': null,
            'created_at': '2026-01-01T00:00:00Z',
            'actor_id': 'actor',
            'username': 'runner',
            'full_name': null,
            'avatar_url': null,
            'comment_body': 'Great!',
          }
        ]);
      }
      if (path.endsWith('/community_notification_settings')) return json(null);
      if (path.endsWith('/community_comments_page')) {
        return json([
          {
            'id': 'comment',
            'post_id': 'post',
            'author_id': 'actor',
            'username': 'runner',
            'full_name': null,
            'avatar_url': null,
            'body': 'Great!',
            'created_at': '2026-01-01T00:00:00Z',
          }
        ]);
      }
      if (path.endsWith('/community_comment_likes')) {
        expect(request.url.queryParameters['user_id'],
            'eq.aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
        return json([
          {'comment_id': 'comment'}
        ]);
      }
      if (path.endsWith('/community_set_comment_like') ||
          path.endsWith('/community_set_notification_settings')) {
        return json(null);
      }
      return http.Response('Unexpected request: $path', 500);
    });
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        httpClient: mock,
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    await client.auth
        .signInWithPassword(email: 'a@example.com', password: 'password');
    final repo = CommunityRepository(client);
    expect((await repo.notifications()).single.message,
        '@runner commented: Great!');
    final settings = await repo.notificationSettings();
    expect(settings.values.every((value) => value), isTrue);
    settings['likes_enabled'] = false;
    await repo.saveNotificationSettings(settings);
    expect((await repo.comments('post')).single.likedByMe, isTrue);
    await repo.setCommentLiked('comment', false);
    expect(
        jsonDecode(requests
            .singleWhere(
                (r) => r.url.path.endsWith('/community_set_comment_like'))
            .body),
        {'p_comment_id': 'comment', 'p_liked': false});
    expect(
        jsonDecode(requests
            .singleWhere((r) =>
                r.url.path.endsWith('/community_set_notification_settings'))
            .body),
        {
          'p_likes': false,
          'p_comments': true,
          'p_friend_posts': true,
          'p_friend_requests': true
        });
    await client.dispose();
  });
}
