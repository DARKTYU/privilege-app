import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/models/supabase_rows.dart';

void main() {
  test('store points ledger preserves owner, value, reason, and local day', () {
    final entry = StorePointsLedgerRow.fromJson({
      'id': 'entry-id',
      'user_id': 'user-id',
      'points': 10,
      'reason': 'Daily activity points',
      'activity_date': '2026-11-16',
      'entry_type': 'activity',
      'created_at': '2026-11-16T00:15:00Z',
    });

    expect(entry.points, 10);
    expect(entry.toJson()['activity_date'], '2026-11-16');
    final restored = StorePointsLedgerRow.fromJson(entry.toJson());
    expect(restored.userId, 'user-id');
    expect(restored.reason, 'Daily activity points');
    expect(restored.createdAt, entry.createdAt);
  });
}
