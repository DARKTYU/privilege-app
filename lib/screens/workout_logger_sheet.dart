import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n_strings.dart';
import '../l10n/app_localizations.dart';
import '../logic/fitness_logic.dart';
import '../logic/workout_estimate.dart';
import '../state.dart';
import '../ui.dart';
import 'calorie_profile_sheet.dart';
import 'calories_food_summary.dart';

String localizedWorkoutActivityName(AppLocalizations l, WorkoutActivity item) =>
    switch (item) {
      WorkoutActivity.strength => l.workoutStrength,
      WorkoutActivity.walking => l.workoutWalking,
      WorkoutActivity.running => l.workoutRunning,
      WorkoutActivity.cycling => l.workoutCycling,
      WorkoutActivity.swimming => l.workoutSwimming,
      WorkoutActivity.football => l.workoutFootball,
      WorkoutActivity.basketball => l.workoutBasketball,
      WorkoutActivity.tennis => l.workoutTennis,
      WorkoutActivity.circuit => l.workoutCircuit,
      WorkoutActivity.martialArts => l.workoutMartialArts,
      WorkoutActivity.yoga => l.workoutYoga,
      WorkoutActivity.jumpRope => l.workoutJumpRope,
      WorkoutActivity.other => l.workoutOther,
    };

Future<void> showWorkoutLogger(BuildContext context, AppState state,
        {int? initialDuration,
        WorkoutActivity initialActivity = WorkoutActivity.strength,
        WorkoutIntensity initialIntensity = WorkoutIntensity.moderate}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => WorkoutLoggerSheet(
        state: state,
        initialDuration: initialDuration,
        initialActivity: initialActivity,
        initialIntensity: initialIntensity,
      ),
    );

class WorkoutLoggerSheet extends StatefulWidget {
  const WorkoutLoggerSheet(
      {super.key,
      required this.state,
      this.initialDuration,
      this.initialActivity = WorkoutActivity.strength,
      this.initialIntensity = WorkoutIntensity.moderate});
  final AppState state;
  final int? initialDuration;
  final WorkoutActivity initialActivity;
  final WorkoutIntensity initialIntensity;

  @override
  State<WorkoutLoggerSheet> createState() => _WorkoutLoggerSheetState();
}

class _WorkoutLoggerSheetState extends State<WorkoutLoggerSheet> {
  late final TextEditingController duration;
  final calories = TextEditingController();
  late WorkoutActivity activity;
  late WorkoutIntensity intensity;
  bool manual = false;
  bool saving = false;
  String? error;

  double? get weight {
    final profile = widget.state.profile;
    return profile.hasWeight &&
            profile.weightKg.isFinite &&
            profile.weightKg > 0
        ? profile.weightKg
        : null;
  }

  int? get estimate => estimateWorkoutCalories(
      activity, intensity, weight, int.tryParse(duration.text.trim()));

  @override
  void initState() {
    super.initState();
    duration = TextEditingController(text: '${widget.initialDuration ?? 30}');
    activity = widget.initialActivity;
    intensity = widget.initialIntensity;
    widget.state.addListener(_profileChanged);
    _refreshEstimate();
  }

  void _profileChanged() {
    if (!mounted) return;
    setState(_refreshEstimate);
  }

  void _refreshEstimate() {
    if (!manual) calories.text = estimate?.toString() ?? '';
  }

  void _changeEstimate(VoidCallback change) {
    setState(() {
      change();
      _refreshEstimate();
      error = null;
    });
  }

  @override
  void dispose() {
    widget.state.removeListener(_profileChanged);
    duration.dispose();
    calories.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    final minutes = int.tryParse(duration.text.trim());
    final amount = int.tryParse(calories.text.trim());
    if (minutes == null || minutes < 1 || minutes > 600) {
      setState(() => error = strings(context).workoutInvalidDuration);
      return;
    }
    if (amount == null || amount < 0 || amount > 5000) {
      setState(() => error = strings(context).workoutInvalidCalories);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.state.addBurn(BurnItem(
        id: '',
        title: '${activity.label} - $minutes min',
        time: 'Just now',
        calories: amount,
        type: activity.type,
        durationMin: minutes,
        icon: activity.icon,
      ));
      if (!mounted) return;
      notifyCaloriesLog(CaloriesResultKind.workout, amount);
      final message = widget.state.activityError == null
          ? strings(context).workoutSaved
          : strings(context).workoutRefreshError;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) {
        setState(() => error = strings(context).workoutSaveError(
            friendlyError(e, localizations: strings(context))));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = CaloriesPalette(Theme.of(context));
    final l = strings(context);
    String intensityName(WorkoutIntensity item) => switch (item) {
          WorkoutIntensity.light => l.intensityLight,
          WorkoutIntensity.moderate => l.intensityModerate,
          WorkoutIntensity.vigorous => l.intensityVigorous,
        };
    final currentEstimate = estimate;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: .9,
        child: Material(
          color: p.card,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.mergeLogWorkout,
                    style: TextStyle(
                        color: p.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(l.activity,
                    style:
                        TextStyle(color: p.text, fontWeight: FontWeight.bold)),
                Wrap(spacing: 8, children: [
                  for (final item in WorkoutActivity.values)
                    ChoiceChip(
                      label: Text(l.workoutActivityLabel(
                          item.icon, localizedWorkoutActivityName(l, item))),
                      selected: activity == item,
                      selectedColor: p.accent.withAlpha(55),
                      onSelected: saving
                          ? null
                          : (_) => _changeEstimate(() => activity = item),
                    ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('workout-duration'),
                  controller: duration,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                      labelText: l.plannerDuration,
                      helperText: l.plannerDurationHint),
                  onChanged: (_) => _changeEstimate(() {}),
                ),
                Wrap(spacing: 8, children: [
                  for (final minutes in [15, 30, 45, 60, 90])
                    ChoiceChip(
                      label: Text(l.mergeShortMinutes(minutes)),
                      selected: int.tryParse(duration.text) == minutes,
                      selectedColor: p.accent.withAlpha(55),
                      onSelected: saving
                          ? null
                          : (_) =>
                              _changeEstimate(() => duration.text = '$minutes'),
                    ),
                ]),
                const SizedBox(height: 12),
                Text(l.workoutIntensity,
                    style:
                        TextStyle(color: p.text, fontWeight: FontWeight.bold)),
                Wrap(spacing: 8, children: [
                  for (final item in WorkoutIntensity.values)
                    ChoiceChip(
                      label: Text(intensityName(item)),
                      selected: intensity == item,
                      selectedColor: p.accent.withAlpha(55),
                      onSelected: saving
                          ? null
                          : (_) => _changeEstimate(() => intensity = item),
                    ),
                ]),
                const SizedBox(height: 12),
                Text(
                    currentEstimate == null
                        ? l.workoutEstimateUnavailable
                        : l.workoutEstimate(currentEstimate),
                    style: TextStyle(
                        color: p.accentText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(l.workoutFormula, style: TextStyle(color: p.muted)),
                Text(l.workoutEstimateNote, style: TextStyle(color: p.muted)),
                if (weight == null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: saving
                          ? null
                          : () =>
                              showCalorieProfileSheet(context, widget.state),
                      child: Text(l.mergeCompleteProfile),
                    ),
                  ),
                if (activity == WorkoutActivity.other)
                  Text(l.workoutManualOther, style: TextStyle(color: p.muted)),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('workout-calories'),
                  controller: calories,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                      labelText: l.workoutCaloriesEditable,
                      helperText: l.workoutCaloriesHint),
                  onChanged: (_) => setState(() {
                    manual = true;
                    error = null;
                  }),
                ),
                if (manual && currentEstimate != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: saving
                          ? null
                          : () => _changeEstimate(() => manual = false),
                      child: Text(l.workoutUseEstimate),
                    ),
                  ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: TextStyle(color: kSmallTextAccent)),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: p.accent, foregroundColor: p.onAccent),
                  onPressed: saving ? null : save,
                  child: Text(saving ? l.workoutSaving : l.workoutSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
