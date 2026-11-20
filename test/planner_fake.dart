import 'dart:async';

import 'package:privilege/services/planner_repository.dart';

class FakePlanner implements PlannerDataSource {
  @override
  String? accountId = 'user';
  String date = '2026-11-20';
  final List<PlannerSplit> splits = [];
  final List<PlannerDay> days = [];
  final Set<String> workouts = {};
  String? failure;
  int createCalls = 0;
  Completer<void>? createGate;
  Completer<void>? saveGate;
  int saveCalls = 0;
  int _id = 0;

  void _check() {
    if (failure != null) throw StateError(failure!);
  }

  @override
  Future<String> today() async {
    _check();
    return date;
  }

  @override
  Future<List<PlannerSplit>> loadSplits() async {
    _check();
    return List.of(splits);
  }

  @override
  Future<PlannerDay?> loadDay(String date) async {
    _check();
    return days.where((day) => day.date == date).firstOrNull;
  }

  @override
  Future<PlannerSnapshot> load(String start, String end) async {
    _check();
    return PlannerSnapshot(
        today: date,
        splits: List.of(splits),
        days: days
            .where((d) =>
                d.date.compareTo(start) >= 0 && d.date.compareTo(end) <= 0)
            .toList(),
        workoutDates: workouts
            .where((d) => d.compareTo(start) >= 0 && d.compareTo(end) <= 0)
            .toSet());
  }

  @override
  Future<List<PlannerSplit>> createSplits(List<PlannerSplit> items) async {
    _check();
    createCalls++;
    if (createGate != null) await createGate!.future;
    final created = [
      for (final item in items)
        PlannerSplit(
            id: '${++_id}',
            name: item.name,
            kind: item.kind,
            duration: item.duration,
            effort: item.effort)
    ];
    splits.addAll(created);
    return created;
  }

  @override
  Future<PlannerSplit> updateSplit(PlannerSplit item) async {
    _check();
    final index = splits.indexWhere((s) => s.id == item.id);
    if (index < 0) throw StateError('Missing split');
    splits[index] = item;
    return item;
  }

  @override
  Future<void> deleteSplit(String id) async {
    _check();
    splits.removeWhere((s) => s.id == id);
  }

  @override
  Future<PlannerDay> saveDay(PlannerDay day) async {
    _check();
    saveCalls++;
    if (saveGate != null) await saveGate!.future;
    _check();
    days.removeWhere((d) => d.date == day.date);
    days.add(day);
    return day;
  }

  @override
  Future<void> deleteDay(String date) async {
    _check();
    days.removeWhere((d) => d.date == date);
  }
}
