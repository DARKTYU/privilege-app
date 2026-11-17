import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privilege/services/progression_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
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
      if (path.endsWith('/rewards')) {
        expect(request.url.queryParameters['is_active'], 'eq.true');
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
    expect(store.rewards.single.owned, isTrue);
    await repo.redeem('reward-id', 'request-id');
    final redemption = requests
        .singleWhere((r) => r.url.path.endsWith('/redeem_digital_reward'));
    expect(jsonDecode(redemption.body),
        {'p_reward_id': 'reward-id', 'p_request_id': 'request-id'});
    expect(requests.any((r) => r.url.path.endsWith('/user_rewards')), isFalse);
    await client.dispose();
  });
}
