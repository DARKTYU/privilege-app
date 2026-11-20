import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privilege/services/coach_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  Object response = {'reply': 'Hello', 'remaining': 12, 'reset_at': null};
  var status = 200;
  final mock = MockClient((request) async {
    requests.add(request);
    final Object data = request.url.path.endsWith('/token')
        ? {
            'access_token': 'token',
            'refresh_token': 'refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
              'aud': 'authenticated',
              'created_at': '2026-01-01T00:00:00Z'
            }
          }
        : response;
    return http.Response(
        jsonEncode(data), request.url.path.endsWith('/token') ? 200 : status,
        request: request, headers: {'content-type': 'application/json'});
  });
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-key',
        httpClient: mock,
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false));
    await Supabase.instance.client.auth
        .signInWithPassword(email: 'test@example.com', password: 'password');
  });
  setUp(() {
    requests.clear();
    response = {'reply': 'Hello', 'remaining': 12, 'reset_at': null};
    status = 200;
  });
  tearDownAll(() async => Supabase.instance.dispose());

  test('invokes coach with signed-in token and exact request body', () async {
    final client = SupabaseCoachClient();
    final reply = await client.send({'message': 'Hello', 'consent': false});
    expect(reply.text, 'Hello');
    expect(reply.remaining, 12);
    expect(requests.single.url.path, '/functions/v1/coach');
    expect(requests.single.headers['authorization'], 'Bearer token');
    expect(jsonDecode(requests.single.body),
        {'message': 'Hello', 'consent': false});
  });

  test('maps function HTTP errors and reset time', () async {
    response = {'error': 'quota_exceeded', 'reset_at': '2026-11-21T00:00:00Z'};
    status = 429;
    await expectLater(
        SupabaseCoachClient().send({'message': 'Hi', 'consent': false}),
        throwsA(isA<CoachException>()
            .having((e) => e.code, 'code', 'quota_exceeded')
            .having((e) => e.resetAt, 'resetAt', DateTime.utc(2026, 11, 21))));
  });

  test('rejects malformed success instead of inventing a reply', () async {
    response = {'reply': '', 'remaining': null, 'reset_at': null};
    await expectLater(
        SupabaseCoachClient().send({'message': 'Hi', 'consent': false}),
        throwsA(isA<CoachException>()
            .having((e) => e.code, 'code', 'unavailable')));
  });
}
