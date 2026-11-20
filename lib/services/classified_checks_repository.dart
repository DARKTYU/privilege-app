import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_recovery.dart';

abstract interface class ClassifiedChecksDataSource {
  String? get accountId;
  Future<Set<String>> load();
  Future<void> setChecked(String key, bool checked);
}

class ClassifiedChecksRepository implements ClassifiedChecksDataSource {
  SupabaseClient get _client => Supabase.instance.client;
  SessionRecovery get _session => SessionRecovery.forClient(_client);
  @override
  String? get accountId => _client.auth.currentUser?.id;
  String get _user =>
      accountId ?? (throw const AuthException('Please log in again.'));

  @override
  Future<Set<String>> load() async {
    final user = _user;
    final result = <String>{};
    for (var offset = 0;; offset += 1000) {
      final rows = await _session.request(() => _client
          .from('classified_checks')
          .select('item_key')
          .eq('user_id', user)
          .order('item_key', ascending: true)
          .range(offset, offset + 999));
      result.addAll(rows.map((row) => row['item_key'] as String));
      if (rows.length < 1000) break;
    }
    return result;
  }

  @override
  Future<void> setChecked(String key, bool checked) async {
    final user = _user;
    if (checked) {
      await _session.request(() => _client
          .from('classified_checks')
          .insert({'user_id': user, 'item_key': key}));
    } else {
      await _session.request(() => _client
          .from('classified_checks')
          .delete()
          .eq('user_id', user)
          .eq('item_key', key));
    }
  }
}
