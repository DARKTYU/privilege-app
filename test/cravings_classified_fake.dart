import 'dart:async';
import 'package:privilege/services/cravings_repository.dart';
import 'package:privilege/services/classified_checks_repository.dart';

class FakeCravings implements CravingsDataSource {
  @override
  String? accountId = 'user-a';
  final Map<String, List<Craving>> records = {};
  String? error;
  Completer<void>? gate;
  int writes = 0, nextId = 0;
  List<Craving> get current => records.putIfAbsent(accountId!, () => []);
  void check() {
    if (error != null) throw StateError(error!);
  }

  @override
  Future<List<Craving>> loadMonth(String start, String end) async {
    check();
    return current
        .where((item) =>
            item.date.compareTo(start) >= 0 && item.date.compareTo(end) < 0)
        .toList();
  }

  Future<void> wait() async {
    writes++;
    if (gate != null) await gate!.future;
    check();
  }

  @override
  Future<Craving> add(String date, String notes) async {
    final user = accountId!;
    await wait();
    final list = records.putIfAbsent(user, () => []);
    if (list
            .where((m) => m.date.substring(0, 7) == date.substring(0, 7))
            .length >=
        2) {
      throw StateError('cheat meal limit');
    }
    final result = Craving(id: '${++nextId}', date: date, notes: notes);
    list.add(result);
    return result;
  }

  @override
  Future<Craving> edit(String id, String date, String notes,
      {required String originalDate}) async {
    final user = accountId!;
    await wait();
    final list = records[user]!;
    if (date != originalDate &&
        list
                .where((m) =>
                    m.id != id &&
                    m.date.substring(0, 7) == date.substring(0, 7))
                .length >=
            2) {
      throw StateError('cheat meal limit');
    }
    final result = Craving(id: id, date: date, notes: notes);
    list[list.indexWhere((m) => m.id == id)] = result;
    return result;
  }

  @override
  Future<void> delete(String id) async {
    final user = accountId!;
    await wait();
    records[user]!.removeWhere((m) => m.id == id);
  }
}

class FakeClassifiedChecks implements ClassifiedChecksDataSource {
  @override
  String? accountId = 'user-a';
  final Map<String, Set<String>> records = {};
  String? error;
  Completer<void>? gate;
  Set<String> get current => records.putIfAbsent(accountId!, () => {});
  @override
  Future<Set<String>> load() async {
    if (error != null) throw StateError(error!);
    return Set.of(current);
  }

  @override
  Future<void> setChecked(String key, bool checked) async {
    final user = accountId!;
    if (gate != null) await gate!.future;
    if (error != null) throw StateError(error!);
    final list = records.putIfAbsent(user, () => {});
    if (checked) {
      list.add(key);
    } else {
      list.remove(key);
    }
  }
}
