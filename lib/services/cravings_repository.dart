import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n_strings.dart';

import 'planner_repository.dart';
import 'session_recovery.dart';

class Craving {
  const Craving({required this.id, required this.date, required this.notes});
  final String id, date, notes;

  factory Craving.fromRow(Map<String, dynamic> row) => Craving(
      id: row['id'] as String,
      date: row['planned_date'] as String,
      notes: row['notes'] as String);
}

abstract interface class CravingsDataSource {
  String? get accountId;
  Future<List<Craving>> loadMonth(String start, String end);
  Future<Craving> add(String date, String notes);
  Future<Craving> edit(String id, String date, String notes,
      {required String originalDate});
  Future<void> delete(String id);
}

class CravingsRepository implements CravingsDataSource {
  SupabaseClient get _client => Supabase.instance.client;
  SessionRecovery get _session => SessionRecovery.forClient(_client);
  @override
  String? get accountId => _client.auth.currentUser?.id;
  String get _user =>
      accountId ?? (throw AuthException(savedLanguageStrings().sessionExpired));

  @override
  Future<List<Craving>> loadMonth(String start, String end) async {
    parsePlannerDate(start);
    parsePlannerDate(end);
    final user = _user;
    final result = <Craving>[];
    for (var offset = 0;; offset += 1000) {
      final rows = await _session.request(() => _client
          .from('cheat_meals')
          .select('id,planned_date,notes')
          .eq('user_id', user)
          .gte('planned_date', start)
          .lt('planned_date', end)
          .order('planned_date', ascending: true)
          .order('id', ascending: true)
          .range(offset, offset + 999));
      result.addAll(rows.map(Craving.fromRow));
      if (rows.length < 1000) break;
    }
    return result;
  }

  @override
  Future<Craving> add(String date, String notes) async {
    final user = _user;
    final row = await _session.request(() => _client
        .from('cheat_meals')
        .insert({'user_id': user, 'planned_date': date, 'notes': notes.trim()})
        .select('id,planned_date,notes')
        .single());
    return Craving.fromRow(row);
  }

  @override
  Future<Craving> edit(String id, String date, String notes,
      {required String originalDate}) async {
    final user = _user;
    final row = await _session.request(() => _client
        .from('cheat_meals')
        .update({
          'notes': notes.trim(),
          if (date != originalDate) 'planned_date': date
        })
        .eq('user_id', user)
        .eq('id', id)
        .select('id,planned_date,notes')
        .single());
    return Craving.fromRow(row);
  }

  @override
  Future<void> delete(String id) async {
    final user = _user;
    final rows = await _session.request(() => _client
        .from('cheat_meals')
        .delete()
        .eq('user_id', user)
        .eq('id', id)
        .select('id'));
    if (rows.isEmpty) {
      throw StateError(savedLanguageStrings().errorCravingMissing);
    }
  }
}
