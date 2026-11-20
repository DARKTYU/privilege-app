import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import '../data.dart';
import '../l10n_strings.dart';
import '../logic/localized_dates.dart';
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

class _WesternArabicMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _WesternArabicMaterialDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    DateFormat western(DateFormat format) => format..useNativeDigits = false;
    return SynchronousFuture(MaterialLocalizationAr(
      fullYearFormat: western(DateFormat.y('ar')),
      compactDateFormat: western(DateFormat.yMd('ar')),
      shortDateFormat: western(DateFormat.yMMMd('ar')),
      mediumDateFormat: western(DateFormat.MMMEd('ar')),
      longDateFormat: western(DateFormat.yMMMMEEEEd('ar')),
      yearMonthFormat: western(DateFormat.yMMMM('ar')),
      shortMonthDayFormat: western(DateFormat.MMMd('ar')),
      decimalFormat: NumberFormat.decimalPattern('en'),
      twoDigitZeroPaddedFormat: NumberFormat('00', 'en'),
    ));
  }

  @override
  bool shouldReload(_WesternArabicMaterialDelegate old) => false;
}

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
      if (user == null) {
        setState(() => loadError = strings(context).mergeSignIn);
        return;
      }
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
        setState(() => loadError = friendlyError(error, localizations: strings(context)));
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
  String _displayStoredName(String name) {
    final l = strings(context);
    switch (name) {
      case 'Push':
        return l.plannerPush;
      case 'Pull':
        return l.plannerPull;
      case 'Legs':
        return l.plannerLegs;
      case 'Rest':
        return l.plannerRest;
      case 'Rest day':
        return l.plannerRestDay;
    }
    for (final option in [...defaultWorkoutSplits, ...defaultSports]) {
      if (option.name == name) return _builtInName(option);
    }
    return name;
  }

  String _builtInName(SplitOption option) {
    final l = strings(context);
    switch (option.id) {
      case 'push':
        return l.splitPushDay;
      case 'pull':
        return l.splitPullDay;
      case 'legs':
        return l.splitLegDay;
      case 'upper':
        return l.splitUpper;
      case 'calisthenics':
        return l.splitCalisthenics;
      case 'olympic':
        return l.splitOlympic;
      case 'basketball':
        return l.sportBasketball;
      case 'football':
        return l.sportFootball;
      case 'tennis':
        return l.sportTennis;
      case 'boxing':
        return l.sportBoxing;
      case 'swimming':
        return l.sportSwimming;
      case 'sprints':
        return l.sportSprints;
      default:
        return option.name;
    }
  }

  String _intensityLabel(WorkoutIntensity intensity) {
    final l = strings(context);
    switch (intensity) {
      case WorkoutIntensity.light:
        return l.intensityLight;
      case WorkoutIntensity.moderate:
        return l.intensityModerate;
      case WorkoutIntensity.vigorous:
        return l.intensityVigorous;
    }
  }

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
      _message(strings(context).mergeInvalidTotal);
      return;
    }
    if (name.runes.length > 100) {
      _message(strings(context).mergeNameTooLong);
      return;
    }
    setState(() => planning = true);
    final user = state.plannerAccountId;
    try {
      if (user == null) {
        _message(strings(context).mergeSignIn);
        return;
      }
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
            title: Text(strings(context).mergeReplaceTitle),
            content: Text(strings(context).mergeReplaceDetails(
                westernDigits(MaterialLocalizations.of(context)
                    .formatMediumDate(parsePlannerDate(date))),
                _displayStoredName(existing.name))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(strings(context).plannerCancel)),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(strings(context).mergeReplace)),
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
        _message(strings(context).mergeSuccess);
      }
    } catch (error) {
      if (mounted && user == state.plannerAccountId) {
        _message(strings(context).mergePlanError(friendlyError(error, localizations: strings(context))));
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
          String key,
          TextEditingController controller,
          WorkoutIntensity intensity,
          ValueChanged<WorkoutIntensity> onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          key: ValueKey(key),
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
              labelText: strings(context).mergeMinutesLabel(label),
              helperText: strings(context).plannerDurationHint),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          for (final item in WorkoutIntensity.values)
            ChoiceChip(
              label: Text(_intensityLabel(item)),
              selected: item == intensity,
              onSelected: (_) => setState(() => onChanged(item)),
            )
        ]),
      ]);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final l = strings(context);
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
              ScreenHeader(l.mergeTitle, l.mergeSubtitle, actions: [
                TextButton(
                    onPressed: widget.onManageSplits,
                    child: Text(l.mergeManage))
              ]),
              if (loading) const LinearProgressIndicator(),
              if (loadError != null) ...[
                Text(l.mergeLoadError(loadError!)),
                TextButton(onPressed: _loadSplits, child: Text(l.plannerRetry)),
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
                          InputDecoration(labelText: l.mergeWorkoutSplit),
                      items: [
                        for (final item in defaultWorkoutSplits)
                          DropdownMenuItem(
                              value: 'built:${item.id}',
                              child: Text(_builtInName(item),
                                  overflow: TextOverflow.ellipsis)),
                        for (final item in savedSplits)
                          DropdownMenuItem(
                              value: 'saved:${item.id}',
                              child: Text(
                                  l.mergeSavedName(
                                      _displayStoredName(item.name)),
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
                      decoration: InputDecoration(labelText: l.mergeSport),
                      items: [
                        for (final item in defaultSports)
                          DropdownMenuItem(
                              value: item.id,
                              child: Text(_builtInName(item),
                                  overflow: TextOverflow.ellipsis))
                      ],
                      onChanged: (value) => setState(() {
                        sport = defaultSports
                            .firstWhere((item) => item.id == value);
                        sportMinutes.text = '${sport.durationMin}';
                      }),
                    ),
                    const SizedBox(height: 16),
                    _segment(l.mergeSplit, 'Split-minutes', splitMinutes,
                        splitIntensity, (value) => splitIntensity = value),
                    const SizedBox(height: 16),
                    _segment(l.mergeSport, 'Sport-minutes', sportMinutes,
                        sportIntensity, (value) => sportIntensity = value),
                  ])),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(l.mergeCombinedDuration(
                        validMinutes(a) && validMinutes(b)
                            ? l.mergeMinutes(a! + b!)
                            : l.mergeUnavailable)),
                    Text(l.mergeNamedValue(
                        savedSplit == null
                            ? _builtInName(split)
                            : _displayStoredName(savedSplit!.name),
                        validMinutes(a)
                            ? l.mergeShortMinutes(a!)
                            : l.mergeInvalidDuration)),
                    Text(l.mergeNamedValue(
                        _builtInName(sport),
                        validMinutes(b)
                            ? l.mergeShortMinutes(b!)
                            : l.mergeInvalidDuration)),
                    if (sport.id == 'sprints') Text(l.mergeSprintEstimate),
                    const SizedBox(height: 8),
                    if (weight == null) ...[
                      Text(l.mergeAddWeight),
                      TextButton(
                          onPressed: () =>
                              showCalorieProfileSheet(context, state),
                          child: Text(l.mergeCompleteProfile)),
                    ] else if (activity == null) ...[
                      Text(l.mergeSportUnavailable),
                    ] else ...[
                      Text(l.mergeEstimatedCalories(
                          strengthKcal != null && sportKcal != null
                              ? l.mergeCalories(
                                  strengthKcal + sportKcal, (strengthKcal + sportKcal).toString())
                              : l.mergeUnavailable)),
                      Text(l.mergeNamedValue(
                          savedSplit == null
                              ? _builtInName(split)
                              : _displayStoredName(savedSplit!.name),
                          strengthKcal == null
                              ? l.mergeUnavailable
                              : l.mergeCalories(strengthKcal, strengthKcal.toString()))),
                      Text(l.mergeNamedValue(
                          _builtInName(sport),
                          sportKcal == null
                              ? l.mergeUnavailable
                              : l.mergeCalories(sportKcal, sportKcal.toString()))),
                    ],
                    const SizedBox(height: 8),
                    Text(l.mergeEstimateNote),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      OutlinedButton(
                          onPressed: planning ? null : _plan,
                          child: Text(l.mergePlanDate)),
                      OutlinedButton(
                          onPressed: validMinutes(a)
                              ? () => _log(
                                  WorkoutActivity.strength, a, splitIntensity)
                              : null,
                          child: Text(l.mergeLogWorkout)),
                      OutlinedButton(
                          onPressed: activity != null && validMinutes(b)
                              ? () => _log(activity, b, sportIntensity)
                              : null,
                          child: Text(l.mergeLogSport)),
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
        title: Text(strings(context).mergePlanDate),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100, 12, 31),
                builder: (context, child) => Localizations.override(
                  context: context,
                  delegates: const [_WesternArabicMaterialDelegate()],
                  child: child!,
                ),
              );
              if (picked != null && mounted) setState(() => date = picked);
            },
            child: Text(strings(context).mergeDate(westernDigits(
                MaterialLocalizations.of(context).formatMediumDate(date)))),
          ),
          TextField(
            controller: effort,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                labelText: strings(context).mergePlannerEffort,
                helperText: strings(context).plannerEffortHint,
                errorText: error),
          )
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings(context).plannerCancel)),
          TextButton(
              onPressed: () {
                final value = int.tryParse(effort.text);
                if (value == null || value < 0 || value > 100) {
                  setState(() => error = strings(context).plannerInvalidEffort);
                  return;
                }
                Navigator.pop(context, (date, value));
              },
              child: Text(strings(context).mergeContinue))
        ],
      );
}
