import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/fitness_logic.dart';
import '../logic/workout_estimate.dart';
import '../state.dart';
import 'calorie_profile_sheet.dart';
import 'calories_food_summary.dart';

Future<void> showWorkoutLogger(BuildContext context, AppState state) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => WorkoutLoggerSheet(state: state),
    );

class WorkoutLoggerSheet extends StatefulWidget {
  const WorkoutLoggerSheet({super.key, required this.state});
  final AppState state;

  @override
  State<WorkoutLoggerSheet> createState() => _WorkoutLoggerSheetState();
}

class _WorkoutLoggerSheetState extends State<WorkoutLoggerSheet> {
  final duration = TextEditingController(text: '30');
  final calories = TextEditingController();
  WorkoutActivity activity = WorkoutActivity.strength;
  WorkoutIntensity intensity = WorkoutIntensity.moderate;
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
      setState(() => error = 'Enter a duration between 1 and 600 minutes.');
      return;
    }
    if (amount == null || amount < 0 || amount > 5000) {
      setState(() => error = 'Enter calories between 0 and 5000.');
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
      final message = widget.state.activityError == null
          ? 'Workout logged.'
          : 'Saved, but the activity list could not be refreshed. Please retry.';
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) setState(() => error = 'Could not save workout: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = CaloriesPalette(Theme.of(context));
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
                Text('Log workout',
                    style: TextStyle(
                        color: p.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text('Activity',
                    style:
                        TextStyle(color: p.text, fontWeight: FontWeight.bold)),
                Wrap(spacing: 8, children: [
                  for (final item in WorkoutActivity.values)
                    ChoiceChip(
                      label: Text('${item.icon} ${item.label}'),
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
                  decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      helperText: '1 to 600 minutes'),
                  onChanged: (_) => _changeEstimate(() {}),
                ),
                Wrap(spacing: 8, children: [
                  for (final minutes in [15, 30, 45, 60, 90])
                    ChoiceChip(
                      label: Text('$minutes min'),
                      selected: int.tryParse(duration.text) == minutes,
                      selectedColor: p.accent.withAlpha(55),
                      onSelected: saving
                          ? null
                          : (_) =>
                              _changeEstimate(() => duration.text = '$minutes'),
                    ),
                ]),
                const SizedBox(height: 12),
                Text('Intensity',
                    style:
                        TextStyle(color: p.text, fontWeight: FontWeight.bold)),
                Wrap(spacing: 8, children: [
                  for (final item in WorkoutIntensity.values)
                    ChoiceChip(
                      label: Text(
                          '${item.name[0].toUpperCase()}${item.name.substring(1)}'),
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
                        ? 'Estimate unavailable — enter calories manually.'
                        : '≈ $currentEstimate kcal burned',
                    style: TextStyle(
                        color: p.accentText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text('MET x weight x hours', style: TextStyle(color: p.muted)),
                Text('Calorie burn is an estimate.',
                    style: TextStyle(color: p.muted)),
                if (weight == null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: saving
                          ? null
                          : () =>
                              showCalorieProfileSheet(context, widget.state),
                      child: const Text('Complete your profile'),
                    ),
                  ),
                if (activity == WorkoutActivity.other)
                  Text('Other activities require manual calories.',
                      style: TextStyle(color: p.muted)),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('workout-calories'),
                  controller: calories,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Calories burned (editable)',
                      helperText: '0 to 5000 kcal'),
                  onChanged: (_) => setState(() {
                    manual = true;
                    error = null;
                  }),
                ),
                if (manual && currentEstimate != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: saving
                          ? null
                          : () => _changeEstimate(() => manual = false),
                      child: const Text('Use estimate'),
                    ),
                  ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: p.accent, foregroundColor: p.onAccent),
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Saving...' : 'Save workout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
