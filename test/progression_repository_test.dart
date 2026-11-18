import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privilege/services/progression_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('membership chooses highest current active plan or Free', () async {
    var subscriptions = <Map<String, dynamic>>[];
    final mock = MockClient((request) async {
      http.Response jsonResponse(Object value) =>
          http.Response(jsonEncode(value), 200,
              request: request, headers: {'content-type': 'application/json'});
      if (request.url.path.endsWith('/token')) {
        return jsonResponse({
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
      if (request.url.path.endsWith('/user_subscriptions')) {
        expect(request.url.queryParameters['user_id'],
            'eq.aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
        expect(request.url.queryParameters['status'], 'eq.active');
        return jsonResponse(subscriptions);
      }
      return http.Response('Unexpected request', 500);
    });
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        httpClient: mock,
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    await client.auth
        .signInWithPassword(email: 'a@example.com', password: 'password');
    final repo = ProgressionRepository(client: client);
    expect(await repo.subscriptionTier(), 'Free');
    subscriptions = [
      {
        'started_at': '2020-01-01T00:00:00Z',
        'expires_at': null,
        'subscription_plans': {'name': 'Silver'}
      },
      {
        'started_at': '2020-01-01T00:00:00Z',
        'expires_at': '2021-01-01T00:00:00Z',
        'subscription_plans': {'name': 'Gold'}
      },
      {
        'started_at': '2099-01-01T00:00:00Z',
        'expires_at': null,
        'subscription_plans': {'name': 'Gold'}
      },
    ];
    expect(await repo.subscriptionTier(), 'Silver');
    subscriptions.add({
      'started_at': '2020-01-01T00:00:00Z',
      'expires_at': null,
      'subscription_plans': {'name': 'Gold'}
    });
    expect(await repo.subscriptionTier(), 'Gold');
    await client.dispose();
  });

  test('store reads active rewards and uses redemptions, not legacy rewards',
      () async {
    final requests = <http.Request>[];
    final mock = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      http.Response jsonResponse(Object value) =>
          http.Response(jsonEncode(value), 200,
              request: request, headers: {'content-type': 'application/json'});
      if (path.endsWith('/token')) {
        return jsonResponse({
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
      if (path.endsWith('/store_points_balance')) return jsonResponse(100);
      if (path.endsWith('/my_freeze_token_balance')) return jsonResponse(1);
      if (path.endsWith('/user_subscriptions')) {
        expect(request.url.queryParameters['status'], 'eq.active');
        return jsonResponse([
          {
            'started_at': '2020-01-01T00:00:00Z',
            'expires_at': null,
            'subscription_plans': {'name': 'Silver'}
          },
          {
            'started_at': '2020-01-01T00:00:00Z',
            'expires_at': '2021-01-01T00:00:00Z',
            'subscription_plans': {'name': 'Gold'}
          },
          {
            'started_at': '2099-01-01T00:00:00Z',
            'expires_at': null,
            'subscription_plans': {'name': 'Gold'}
          },
        ]);
      }
      if (path.endsWith('/rewards')) {
        expect(request.url.queryParameters['is_active'], 'eq.true');
        expect(request.url.queryParameters['order'],
            'cost_points.asc.nullslast,id.asc.nullslast');
        return jsonResponse([
          {
            'id': 'reward-id',
            'name': 'Frame',
            'description': 'Digital frame',
            'reward_kind': 'frame',
            'cost_points': 20,
            'stock': 3,
            'required_tier': 'Free',
          }
        ]);
      }
      if (path.endsWith('/reward_redemptions')) {
        return jsonResponse([
          {'reward_id': 'reward-id'}
        ]);
      }
      if (path.endsWith('/redeem_digital_reward')) {
        return jsonResponse('redemption-id');
      }
      return http.Response('Unexpected request', 500);
    });
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: mock,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await client.auth
        .signInWithPassword(email: 'a@example.com', password: 'password');
    final repo = ProgressionRepository(client: client);
    final store = await repo.store();
    expect(store.balance, 100);
    expect(store.tokens, 1);
    expect(store.tier, 'Silver');
    expect(store.rewards.single.owned, isTrue);
    await repo.redeem('reward-id', 'request-id');
    final redemption = requests
        .singleWhere((r) => r.url.path.endsWith('/redeem_digital_reward'));
    expect(jsonDecode(redemption.body),
        {'p_reward_id': 'reward-id', 'p_request_id': 'request-id'});
    expect(requests.any((r) => r.url.path.endsWith('/user_rewards')), isFalse);
    await client.dispose();
  });

  test('levels are ordered ascending and Bronze progresses to Silver',
      () async {
    final mock = MockClient((request) async {
      http.Response jsonResponse(Object value) =>
          http.Response(jsonEncode(value), 200,
              request: request, headers: {'content-type': 'application/json'});
      final path = request.url.path;
      if (path.endsWith('/token')) {
        return jsonResponse({
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
      if (path.endsWith('/profiles')) {
        return jsonResponse({'level_id': 'bronze'});
      }
      if (path.endsWith('/levels')) {
        expect(request.url.queryParameters['order'], 'min_xp.asc.nullslast');
        return jsonResponse([
          {'id': 'bronze', 'name': 'Bronze', 'min_xp': 0},
          {'id': 'silver', 'name': 'Silver', 'min_xp': 500},
          {'id': 'gold', 'name': 'Gold', 'min_xp': 1500},
          {'id': 'platinum', 'name': 'Platinum', 'min_xp': 3000},
          {'id': 'diamond', 'name': 'Diamond', 'min_xp': 6000},
          {'id': 'elite', 'name': 'Elite', 'min_xp': 10000},
          {'id': 'champion', 'name': 'Champion', 'min_xp': 20000},
        ]);
      }
      if (path.endsWith('/xp_points')) {
        return jsonResponse([
          {'id': 'xp-id', 'points': 45}
        ]);
      }
      return http.Response('Unexpected request', 500);
    });
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: mock,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await client.auth
        .signInWithPassword(email: 'a@example.com', password: 'password');
    final level = (await ProgressionRepository(client: client).level())!;
    expect(level.name, 'Bronze');
    expect(level.nextName, 'Silver');
    expect(level.nextMinimum! - level.xp, 455);
    expect(level.fraction, closeTo(0.09, 0.00001));
    await client.dispose();
  });
}
