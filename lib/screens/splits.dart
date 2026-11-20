import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../logic/workout_estimate.dart';
import '../services/planner_repository.dart';
import '../state.dart';
import '../ui.dart';
import 'calorie_profile_sheet.dart';
import 'workout_logger_sheet.dart';

const _sportActivities = <String, WorkoutActivity>{
  'basketball': WorkoutActivity.basketball,
  'football': WorkoutActivity.football,
  'tennis': WorkoutActivity.tennis,
  'boxing': WorkoutActivity.martialArts,
  'swimming': WorkoutActivity.swimming,
  'sprints': WorkoutActivity.circuit,
};

class SplitsScreen extends StatefulWidget {
  const SplitsScreen(
      {super.key, this.state, this.onManageSplits, this.active = true});
  final AppState? state;
  final VoidCallback? onManageSplits;
  final bool active;

  @override
  State<SplitsScreen> createState() => _SplitsScreenState();
}

class _SplitsScreenState extends State<SplitsScreen>
    with WidgetsBindingObserver {
  late final AppState state = widget.state ?? appState;
  final splitMinutes = TextEditingController(text: '60');
  final sportMinutes = TextEditingController(text: '60');
  SplitOption split = defaultWorkoutSplits.first;
  SplitOption sport = defaultSports.first;
  PlannerSplit? savedSplit;
  List<PlannerSplit> savedSplits = [];
  WorkoutIntensity splitIntensity = WorkoutIntensity.moderate;
  WorkoutIntensity sportIntensity = WorkoutIntensity.moderate;
  String? account;
  String? loadError;
  bool loading = false;
  bool planning = false;
  int loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    account = state.plannerAccountId;
    state.addListener(_accountChanged);
    if (widget.active) _loadSplits();
  }

  @override
  void didUpdateWidget(covariant SplitsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _loadSplits();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (widget.active && lifecycleState == AppLifecycleState.resumed) {
      _loadSplits();
    }
  }

  void _accountChanged() {
    if (account == state.plannerAccountId) return;
    account = state.plannerAccountId;
    loadGeneration++;
    setState(() {
      savedSplits = [];
      savedSplit = null;
      split = defaultWorkoutSplits.first;
      splitMinutes.text = '${split.durationMin}';
      loadError = null;
      loading = false;
    });
    if (widget.active) _loadSplits();
  }

  Future<void> _loadSplits() async {
    final user = state.plannerAccountId;
    final generation = ++loadGeneration;
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      if (user == null) throw StateError('Please log in again.');
      final rows = await state.loadPlannerSplits();
      if (!mounted ||
          generation != loadGeneration ||
          user != state.plannerAccountId) {
        return;
      }
      setState(() {
        savedSplits = rows.where((item) => item.kind == 'workout').toList();
        if (savedSplit != null) {
          final updated = savedSplits
              .where((item) => item.id == savedSplit!.id)
              .firstOrNull;
          if (updated == null) {
            savedSplit = null;
            split = defaultWorkoutSplits.first;
            splitMinutes.text = '${split.durationMin}';
          } else {
            savedSplit = updated;
          }
        }
      });
    } catch (error) {
      if (mounted &&
          generation == loadGeneration &&
          user == state.plannerAccountId) {
        setState(() => loadError = error.toString());
      }
    } finally {
      if (mounted &&
          generation == loadGeneration &&
          user == state.plannerAccountId) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    state.removeListener(_accountChanged);
    splitMinutes.dispose();
    sportMinutes.dispose();
    super.dispose();
  }

  String get splitName => savedSplit?.name ?? split.name;
  int? get splitDuration => int.tryParse(splitMinutes.text);
  int? get sportDuration => int.tryParse(sportMinutes.text);
  bool validMinutes(int? value) => value != null && value >= 1 && value <= 600;
  void _message(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  double? get weight {
    final profile = state.profile;
    return profile.hasWeight &&
            profile.weightKg.isFinite &&
            profile.weightKg > 0
        ? profile.weightKg
        : null;
  }

  Future<void> _plan() async {
    if (planning) return;
    final a = splitDuration;
    final b = sportDuration;
    final name = '$splitName + ${sport.name}';
    final sourceSplitId = savedSplit?.id;
    if (!validMinutes(a) || !validMinutes(b) || a! + b! > 600) {
      _message(
          'Enter valid durations with a combined total of 1 to 600 minutes.');
      return;
    }
    if (name.runes.length > 100) {
      _message('The combined name must be 100 characters or fewer.');
      return;
    }
    setState(() => planning = true);
    final user = state.plannerAccountId;
    try {
      if (user == null) throw StateError('Please log in again.');
      final today = parsePlannerDate(await state.plannerLocalToday());
      if (!mounted || user != state.plannerAccountId) return;
      final result = await showDialog<(DateTime, int)>(
          context: context, builder: (_) => _PlanDateDialog(today: today));
      if (result == null || !mounted || user != state.plannerAccountId) return;
      final date = plannerDate(result.$1);
      final existing = await state.loadPlannerDay(date);
      if (!mounted || user != state.plannerAccountId) return;
      if (existing != null) {
        final replace = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Replace existing plan?'),
            content: Text('$date already has "${existing.name}". Replace it?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Replace')),
            ],
          ),
        );
        if (replace != true || !mounted || user != state.plannerAccountId) {
          return;
        }
      }
      await state.savePlannerDay(PlannerDay(
          date: date,
          name: name,
          kind: 'workout',
          sourceSplitId: sourceSplitId,
          duration: a + b,
          effort: result.$2));
      if (mounted && user == state.plannerAccountId) {
        _message('Planned successfully.');
      }
    } catch (error) {
      if (mounted && user == state.plannerAccountId) {
        _message('Could not plan: $error');
      }
    } finally {
      if (mounted) setState(() => planning = false);
    }
  }

  Future<void> _log(WorkoutActivity? activity, int? minutes,
      WorkoutIntensity intensity) async {
    if (activity == null || !validMinutes(minutes)) return;
    await showWorkoutLogger(context, state,
        initialActivity: activity,
        initialDuration: minutes,
        initialIntensity: intensity);
  }

  Widget _segment(
          String label,
          TextEditingController controller,
          WorkoutIntensity intensity,
          ValueChanged<WorkoutIntensity> onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          key: ValueKey('$label-minutes'),
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
              labelText: '$label minutes', helperText: '1 to 600 minutes'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          for (final item in WorkoutIntensity.values)
            ChoiceChip(
              label: Text(item.name[0].toUpperCase() + item.name.substring(1)),
              selected: item == intensity,
              onSelected: (_) => setState(() => onChanged(item)),
            )
        ]),
      ]);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final a = splitDuration;
        final b = sportDuration;
        final activity = _sportActivities[sport.id];
        final strengthKcal = estimateWorkoutCalories(
            WorkoutActivity.strength, splitIntensity, weight, a);
        final sportKcal = activity == null
            ? null
            : estimateWorkoutCalories(activity, sportIntensity, weight, b);
        return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              ScreenHeader('Splits & Sports Merge',
                  'Combine gym splits with daily sports.', actions: [
                TextButton(
                    onPressed: widget.onManageSplits,
                    child: const Text('Manage splits'))
              ]),
              if (loading) const LinearProgressIndicator(),
              if (loadError != null) ...[
                Text('Could not load splits: $loadError'),
                TextButton(onPressed: _loadSplits, child: const Text('Retry')),
              ],
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey('split-${savedSplit?.id ?? split.id}'),
                      initialValue: savedSplit == null
                          ? 'built:${split.id}'
                          : 'saved:${savedSplit!.id}',
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Workout split'),
                      items: [
                        for (final item in defaultWorkoutSplits)
                          DropdownMenuItem(
                              value: 'built:${item.id}',
                              child: Text(item.name,
                                  overflow: TextOverflow.ellipsis)),
                        for (final item in savedSplits)
                          DropdownMenuItem(
                              value: 'saved:${item.id}',
                              child: Text('${item.name} (My split)',
                                  overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (value) => setState(() {
                        if (value!.startsWith('saved:')) {
                          savedSplit = savedSplits.firstWhere(
                              (item) => 'saved:${item.id}' == value);
                          splitMinutes.text = '${savedSplit!.duration}';
                        } else {
                          savedSplit = null;
                          split = defaultWorkoutSplits.firstWhere(
                              (item) => 'built:${item.id}' == value);
                          splitMinutes.text = '${split.durationMin}';
                        }
                      }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: sport.id,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Sport'),
                      items: [
                        for (final item in defaultSports)
                          DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name,
                                  overflow: TextOverflow.ellipsis))
                      ],
                      onChanged: (value) => setState(() {
                        sport = defaultSports
                            .firstWhere((item) => item.id == value);
                        sportMinutes.text = '${sport.durationMin}';
                      }),
                    ),
                    const SizedBox(height: 16),
                    _segment('Split', splitMinutes, splitIntensity,
                        (value) => splitIntensity = value),
                    const SizedBox(height: 16),
                    _segment('Sport', sportMinutes, sportIntensity,
                        (value) => sportIntensity = value),
                  ])),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        'Combined duration: ${validMinutes(a) && validMinutes(b) ? '${a! + b!} minutes' : 'Unavailable'}'),
                    Text(
                        '$splitName: ${validMinutes(a) ? '$a min' : 'Invalid duration'}'),
                    Text(
                        '${sport.name}: ${validMinutes(b) ? '$b min' : 'Invalid duration'}'),
                    if (sport.id == 'sprints')
                      const Text(
                          'Track sprint intervals use the HIIT or circuit estimate.'),
                    const SizedBox(height: 8),
                    if (weight == null) ...[
                      const Text(
                          'Calorie estimate unavailable - add your weight'),
                      TextButton(
                          onPressed: () =>
                              showCalorieProfileSheet(context, state),
                          child: const Text('Complete your profile')),
                    ] else if (activity == null) ...[
                      const Text(
                          'Calorie estimate unavailable for this sport.'),
                    ] else ...[
                      Text(
                          'Estimated calories burned: ${strengthKcal != null && sportKcal != null ? '${strengthKcal + sportKcal} kcal' : 'Unavailable'}'),
                      Text(
                          '$splitName: ${strengthKcal == null ? 'Unavailable' : '$strengthKcal kcal'}'),
                      Text(
                          '${sport.name}: ${sportKcal == null ? 'Unavailable' : '$sportKcal kcal'}'),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                        'Estimate based on activity type, duration, intensity and your weight.'),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      OutlinedButton(
                          onPressed: planning ? null : _plan,
                          child: const Text('Plan on a date')),
                      OutlinedButton(
                          onPressed: validMinutes(a)
                              ? () => _log(
                                  WorkoutActivity.strength, a, splitIntensity)
                              : null,
                          child: const Text('Log workout')),
                      OutlinedButton(
                          onPressed: activity != null && validMinutes(b)
                              ? () => _log(activity, b, sportIntensity)
                              : null,
                          child: const Text('Log sport')),
                    ])
                  ])),
            ]);
      });
}

class _PlanDateDialog extends StatefulWidget {
  const _PlanDateDialog({required this.today});
  final DateTime today;
  @override
  State<_PlanDateDialog> createState() => _PlanDateDialogState();
}

class _PlanDateDialogState extends State<_PlanDateDialog> {
  late DateTime date = widget.today;
  final effort = TextEditingController(text: '70');
  String? error;

  @override
  void dispose() {
    effort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Plan on a date'),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100, 12, 31),
              );
              if (picked != null && mounted) setState(() => date = picked);
            },
            child: Text(
                'Date: ${MaterialLocalizations.of(context).formatMediumDate(date)}'),
          ),
          TextField(
            controller: effort,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                labelText: 'Planner effort (%)',
                helperText: '0 to 100',
                errorText: error),
          )
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                final value = int.tryParse(effort.text);
                if (value == null || value < 0 || value > 100) {
                  setState(() => error = 'Enter effort from 0 to 100%.');
                  return;
                }
                Navigator.pop(context, (date, value));
              },
              child: const Text('Continue'))
        ],
      );
}
