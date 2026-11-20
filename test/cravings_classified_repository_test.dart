import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privilege/services/cravings_repository.dart';
import 'package:privilege/services/classified_checks_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  const user = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  final client = MockClient((request) async {
    requests.add(request);
    http.Response json(Object? data, [int status = 200]) =>
        http.Response(jsonEncode(data), status,
            request: request, headers: {'content-type': 'application/json'});
    if (request.url.path.endsWith('/token')) {
      return json({
        'access_token': 'token',
        'refresh_token': 'refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': user,
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z'
        }
      });
    }
    if (request.url.path.endsWith('/cheat_meals')) {
      if (request.method == 'GET') {
        return json([
          {'id': 'id', 'planned_date': '2026-11-20', 'notes': 'Pizza'}
        ]);
      }
      if (request.method == 'DELETE') {
        return json([
          {'id': 'id'}
        ]);
      }
      return json({'id': 'id', 'planned_date': '2026-12-01',
        ...jsonDecode(request.body) as Map<String, dynamic>});
    }
    if (request.url.path.endsWith('/classified_checks')) {
      if (request.method == 'GET') {
        return json([
          {'item_key': 'foundation_goal'}
        ]);
      }
      return json(null);
    }
    return json({'message': 'Unexpected request'}, 500);
  });
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-key',
        httpClient: client,
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false));
    await Supabase.instance.client.auth
        .signInWithPassword(email: 'test@example.com', password: 'password');
  });
  tearDownAll(() async => Supabase.instance.dispose());
  setUp(requests.clear);
  test('monthly reads and mutations target only the signed-in user', () async {
    final repo = CravingsRepository();
    expect((await repo.loadMonth('2026-11-01', '2026-12-01')).single.notes,
        'Pizza');
    final get = requests.last;
    expect(get.url.queryParameters['user_id'], 'eq.$user');
    expect(get.url.queryParametersAll['planned_date'],
        ['gte.2026-11-01', 'lt.2026-12-01']);
    await repo.add('2026-11-21', ' Cake ');
    expect(jsonDecode(requests.last.body)['user_id'], user);
    expect(jsonDecode(requests.last.body)['notes'], 'Cake');
    await repo.edit('id', '2026-12-01', 'Pie', originalDate: '2026-11-20');
    expect(requests.last.url.queryParameters['user_id'], 'eq.$user');
    expect(jsonDecode(requests.last.body)['planned_date'], '2026-12-01');
    await repo.edit('id', '2026-12-01', 'New', originalDate: '2026-12-01');
    expect(jsonDecode(requests.last.body).containsKey('planned_date'), isFalse);
    await repo.delete('id');
    expect(requests.last.url.queryParameters['user_id'], 'eq.$user');
  });
  test('checklist uses stable keys and owner-scoped select and delete',
      () async {
    final repo = ClassifiedChecksRepository();
    expect(await repo.load(), {'foundation_goal'});
    expect(requests.last.url.queryParameters['user_id'], 'eq.$user');
    await repo.setChecked('novice_routine', true);
    expect(jsonDecode(requests.last.body)['item_key'], 'novice_routine');
    expect(jsonDecode(requests.last.body)['user_id'], user);
    await repo.setChecked('novice_routine', false);
    expect(requests.last.url.queryParameters['user_id'], 'eq.$user');
    expect(requests.last.url.queryParameters['item_key'], 'eq.novice_routine');
  });
}
