import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_recovery.dart';

String plannerDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime parsePlannerDate(String value) {
  final parts = value.split('-').map(int.parse).toList();
  if (parts.length != 3) throw FormatException('Invalid planner date: $value');
  final date = DateTime.utc(parts[0], parts[1], parts[2]);
  if (plannerDate(date) != value) {
    throw FormatException('Invalid planner date: $value');
  }
  return date;
}

class PlannerSplit {
  const PlannerSplit(
      {required this.id,
      required this.name,
      required this.kind,
      this.duration,
      this.effort});
  final String id, name, kind;
  final int? duration, effort;

  factory PlannerSplit.fromRow(Map<String, dynamic> row) => PlannerSplit(
        id: row['id'] as String,
        name: row['name'] as String,
        kind: row['kind'] as String,
        duration: (row['default_duration_minutes'] as num?)?.toInt(),
        effort: (row['default_effort_percent'] as num?)?.toInt(),
      );

  Map<String, dynamic> toRow() => {
        'name': name.trim(),
        'kind': kind,
        'default_duration_minutes': duration,
        'default_effort_percent': effort,
      };
}

class PlannerDay {
  const PlannerDay(
      {required this.date,
      required this.name,
      required this.kind,
      this.sourceSplitId,
      this.duration,
      this.effort});
  final String date, name, kind;
  final String? sourceSplitId;
  final int? duration, effort;

  factory PlannerDay.fromRow(Map<String, dynamic> row) => PlannerDay(
        date: row['planned_date'] as String,
        name: row['name'] as String,
        kind: row['kind'] as String,
        sourceSplitId: row['source_split_id'] as String?,
        duration: (row['duration_minutes'] as num?)?.toInt(),
        effort: (row['effort_percent'] as num?)?.toInt(),
      );

  Map<String, dynamic> toRow() => {
        'planned_date': date,
        'name': name.trim(),
        'kind': kind,
        'source_split_id': sourceSplitId,
        'duration_minutes': duration,
        'effort_percent': effort,
      };
}

class PlannerSnapshot {
  const PlannerSnapshot(
      {required this.today,
      required this.splits,
      required this.days,
      required this.workoutDates});
  final String today;
  final List<PlannerSplit> splits;
  final List<PlannerDay> days;
  final Set<String> workoutDates;
}

abstract class PlannerDataSource {
  String? get accountId;
  Future<String> today();
  Future<PlannerSnapshot> load(String start, String end);
  Future<List<PlannerSplit>> createSplits(List<PlannerSplit> splits);
  Future<PlannerSplit> updateSplit(PlannerSplit split);
  Future<void> deleteSplit(String id);
  Future<PlannerDay> saveDay(PlannerDay day);
  Future<void> deleteDay(String date);
}

class PlannerRepository implements PlannerDataSource {
  SupabaseClient get _client => Supabase.instance.client;
  SessionRecovery get _session => SessionRecovery.forClient(_client);
  @override
  String? get accountId => _client.auth.currentUser?.id;
  String get _userId =>
      accountId ?? (throw const AuthException('Please log in again.'));

  @override
  Future<String> today() async {
    final value = await _session.request(() => _client.rpc('activity_today'));
    if (value is! String) {
      throw const FormatException('Could not determine today’s activity date.');
    }
    parsePlannerDate(value);
    return value;
  }

  @override
  Future<PlannerSnapshot> load(String start, String end) async {
    final user = _userId;
    final current = await today();
    final splits = <PlannerSplit>[];
    for (var offset = 0;; offset += 1000) {
      final rows = await _session.request(() => _client
          .from('planner_splits')
          .select()
          .eq('user_id', user)
          .order('created_at')
          .order('id')
          .range(offset, offset + 999));
      splits.addAll(rows.map(PlannerSplit.fromRow));
      if (rows.length < 1000) break;
    }
    final days = await _session.request(() => _client
        .from('planner_days')
        .select()
        .eq('user_id', user)
        .gte('planned_date', start)
        .lte('planned_date', end));
    final workoutDates = <String>{};
    for (var offset = 0;; offset += 1000) {
      final workouts = await _session.request(() => _client
          .from('workout_logs')
          .select('id,activity_date')
          .eq('user_id', user)
          .gte('activity_date', start)
          .lte('activity_date', end)
          .order('activity_date')
          .order('id')
          .range(offset, offset + 999));
      workoutDates
          .addAll(workouts.map((row) => row['activity_date'] as String));
      if (workouts.length < 1000) break;
    }
    return PlannerSnapshot(
      today: current,
      splits: splits,
      days: [for (final row in days) PlannerDay.fromRow(row)],
      workoutDates: workoutDates,
    );
  }

  @override
  Future<List<PlannerSplit>> createSplits(List<PlannerSplit> splits) async {
    final user = _userId;
    final rows =
        await _session.request(() => _client.from('planner_splits').insert([
              for (final split in splits) {...split.toRow(), 'user_id': user}
            ]).select());
    return [for (final row in rows) PlannerSplit.fromRow(row)];
  }

  @override
  Future<PlannerSplit> updateSplit(PlannerSplit split) async {
    final row = await _session.request(() => _client
        .from('planner_splits')
        .update(split.toRow())
        .eq('id', split.id)
        .eq('user_id', _userId)
        .select()
        .single());
    return PlannerSplit.fromRow(row);
  }

  @override
  Future<void> deleteSplit(String id) async {
    final rows = await _session.request(() => _client
        .from('planner_splits')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId)
        .select('id'));
    if (rows.isEmpty) {
      throw StateError('The split was not found or was already deleted.');
    }
  }

  @override
  Future<PlannerDay> saveDay(PlannerDay day) async {
    final row = await _session.request(() => _client
        .from('planner_days')
        .upsert({...day.toRow(), 'user_id': _userId},
            onConflict: 'user_id,planned_date')
        .select()
        .single());
    return PlannerDay.fromRow(row);
  }

  @override
  Future<void> deleteDay(String date) async {
    final rows = await _session.request(() => _client
        .from('planner_days')
        .delete()
        .eq('user_id', _userId)
        .eq('planned_date', date)
        .select('id'));
    if (rows.isEmpty) {
      throw StateError('The planned day was not found or was already removed.');
    }
  }
}
