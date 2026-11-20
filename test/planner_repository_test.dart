import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privilege/services/planner_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  const user = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  final client = MockClient((request) async {
    requests.add(request);
    http.Response json(Object? value, [int status = 200]) =>
        http.Response(jsonEncode(value), status,
            request: request, headers: {'content-type': 'application/json'});
    final path = request.url.path;
    if (path.endsWith('/token')) {
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
    if (path.endsWith('/rpc/activity_today')) return json('2026-11-20');
    if (path.endsWith('/planner_splits')) {
      if (request.method == 'GET') {
        return json([]);
      }
      if (request.method == 'POST') {
        return json([
          for (final row in jsonDecode(request.body) as List)
            {...row as Map<String, dynamic>, 'id': 'split-1'}
        ], 201);
      }
    }
    if (path.endsWith('/planner_days')) {
      if (request.method == 'GET') {
        return json([]);
      }
      if (request.method == 'POST') return json(jsonDecode(request.body), 201);
    }
    if (path.endsWith('/workout_logs')) {
      return json([
        {'id': 'a', 'activity_date': '2026-11-20'},
        {'id': 'b', 'activity_date': '2026-11-20'},
      ]);
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

  test('repository scopes weekly reads and saves independent snapshots',
      () async {
    final repository = PlannerRepository();
    final snapshot = await repository.load('2026-11-15', '2026-11-21');
    expect(snapshot.today, '2026-11-20');
    expect(snapshot.workoutDates, {'2026-11-20'});
    for (final table in ['planner_splits', 'planner_days', 'workout_logs']) {
      final request = requests.singleWhere(
          (r) => r.url.path.endsWith('/$table') && r.method == 'GET');
      expect(request.url.queryParameters['user_id'], 'eq.$user');
      if (table != 'planner_splits') {
        final date = table == 'workout_logs' ? 'activity_date' : 'planned_date';
        expect(request.url.queryParametersAll[date],
            containsAll(['gte.2026-11-15', 'lte.2026-11-21']));
      }
    }
    final created = await repository.createSplits([
      const PlannerSplit(
          id: '', name: 'Push', kind: 'workout', duration: 60, effort: 70),
    ]);
    expect(created.single.name, 'Push');
    final posted = jsonDecode(requests.last.body) as List;
    expect(posted.single['user_id'], user);
    final saved = await repository.saveDay(const PlannerDay(
        date: '2026-11-20',
        sourceSplitId: 'split-1',
        name: 'Push',
        kind: 'workout',
        duration: 60,
        effort: 70));
    expect(saved.date, '2026-11-20');
    expect(saved.sourceSplitId, 'split-1');
    final body = jsonDecode(requests.last.body) as Map;
    expect(body['user_id'], user);
    expect(body['planned_date'], '2026-11-20');
    expect(body.containsKey('workout_log_id'), isFalse);
    expect(requests.last.url.queryParameters['on_conflict'],
        'user_id,planned_date');
    expect(
        requests
            .where((r) => r.url.path.endsWith('/workout_logs'))
            .every((r) => r.method == 'GET'),
        isTrue);
  });
}
