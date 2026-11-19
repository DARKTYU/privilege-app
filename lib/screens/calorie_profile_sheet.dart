import 'package:flutter/material.dart';

import '../logic/calorie_target.dart';
import '../state.dart';
import 'calories_food_summary.dart';

Future<void> showCalorieProfileSheet(BuildContext context, AppState state) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CalorieProfileSheet(state: state),
    );

class CalorieProfileSheet extends StatefulWidget {
  const CalorieProfileSheet({super.key, required this.state});
  final AppState state;

  @override
  State<CalorieProfileSheet> createState() => _CalorieProfileSheetState();
}

class _CalorieProfileSheetState extends State<CalorieProfileSheet> {
  late final TextEditingController weight = TextEditingController(
      text: widget.state.profile.hasWeight
          ? widget.state.profile.weightKg.toString()
          : '');
  late final TextEditingController height = TextEditingController(
      text: widget.state.profile.hasHeight
          ? widget.state.profile.heightCm.toString()
          : '');
  late DateTime? birthDate = widget.state.profile.birthDate;
  late TargetSex? sex = widget.state.profile.sex;
  late TargetActivity? activity = widget.state.profile.activity;
  bool saving = false;
  String? error;

  CalorieTarget get preview => CalorieTarget.calculate(
        today: DateTime.now(),
        weightKg: double.tryParse(weight.text.trim()),
        heightCm: double.tryParse(height.text.trim()),
        birthDate: birthDate,
        sex: sex,
        activity: activity,
        goal: resolveNutritionGoal(widget.state.profile.targetGoal,
            widget.state.profile.nutritionGoal),
        legacyTrainingGoal: widget.state.profile.targetGoal,
        legacyTarget: widget.state.profile.hasSavedTarget
            ? widget.state.profile.dailyCalorieTarget
            : null,
      );

  @override
  void dispose() {
    weight.dispose();
    height.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 101);
    final date = await showDatePicker(
      context: context,
      initialDate: birthDate != null &&
              !birthDate!.isAfter(now) &&
              !birthDate!.isBefore(first)
          ? birthDate!
          : DateTime(now.year - 26, now.month, now.day),
      firstDate: first,
      lastDate: now,
    );
    if (date != null && mounted) setState(() => birthDate = date);
  }

  Future<void> save() async {
    if (preview.isEstimate ||
        birthDate == null ||
        sex == null ||
        activity == null) {
      setState(() => error =
          'Enter a valid birth date (age 13–100), sex, activity, weight (30–300 kg), and height (120–230 cm).');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.state.saveTargetProfile(
        weightKg: double.parse(weight.text.trim()),
        heightCm: double.parse(height.text.trim()),
        birthDate: birthDate!,
        sex: sex!,
        activity: activity!,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = 'Could not save your profile: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = CaloriesPalette(Theme.of(context));
    final result = preview;
    final date = birthDate;
    const descriptions = {
      TargetActivity.sedentary: (
        'Sedentary',
        'Mostly sitting, little exercise.'
      ),
      TargetActivity.light: ('Light', 'Light exercise 1–3 days per week.'),
      TargetActivity.moderate: ('Moderate', 'Exercise 3–5 days per week.'),
      TargetActivity.veryActive: (
        'Very active',
        'Hard exercise 6–7 days per week.'
      ),
      TargetActivity.athlete: (
        'Athlete',
        'Very demanding daily training or physical work.'
      ),
    };
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
                  Text('Complete your profile',
                      style: TextStyle(
                          color: p.text,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: TextField(
                      key: const ValueKey('target-weight'),
                      controller: weight,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Weight (kg)'),
                      onChanged: (_) => setState(() {}),
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                      key: const ValueKey('target-height'),
                      controller: height,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Height (cm)'),
                      onChanged: (_) => setState(() {}),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: saving ? null : pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(date == null
                        ? 'Choose birth date'
                        : 'Birth date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                  ),
                  const SizedBox(height: 8),
                  Text('Sex for the estimate', style: TextStyle(color: p.text)),
                  Wrap(spacing: 8, children: [
                    for (final item in [
                      (TargetSex.male, 'Male'),
                      (TargetSex.female, 'Female'),
                      (TargetSex.unspecified, 'Prefer not to say'),
                    ])
                      ChoiceChip(
                        label: Text(item.$2),
                        selected: sex == item.$1,
                        selectedColor: p.accent.withAlpha(55),
                        onSelected: saving
                            ? null
                            : (_) => setState(() => sex = item.$1),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Text('Activity level',
                      style: TextStyle(
                          color: p.text, fontWeight: FontWeight.bold)),
                  RadioGroup<TargetActivity>(
                    groupValue: activity,
                    onChanged: (value) {
                      if (!saving) setState(() => activity = value);
                    },
                    child: Column(children: [
                      for (final item in descriptions.entries)
                        RadioListTile<TargetActivity>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.value.$1),
                          subtitle: Text(item.value.$2),
                          value: item.key,
                          activeColor: p.accent,
                          enabled: !saving,
                        ),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: p.inner,
                        border: Border.all(color: p.border),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Your daily target: ${result.target == null ? 'unavailable' : '${result.target} kcal'}${result.isEstimate ? ' • Estimated' : ''}',
                              style: TextStyle(
                                  color: p.accentText,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              'BMR: ${result.bmr ?? 'unavailable'} • Maintenance: ${result.maintenance ?? 'unavailable'}',
                              style: TextStyle(color: p.muted)),
                          Text(
                              result.isEstimate
                                  ? 'Complete all fields for a personal estimate.'
                                  : 'Goal adjustment: ${result.target! - result.maintenance! >= 0 ? '+' : ''}${result.target! - result.maintenance!} kcal'
                                      '${result.age! < 18 ? ' (maintenance for under 18)' : ''}',
                              style: TextStyle(color: p.muted)),
                          const SizedBox(height: 4),
                          Text('Estimates are not medical advice.',
                              style: TextStyle(color: p.muted)),
                        ]),
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
                    child: Text(saving ? 'Saving...' : 'Save profile'),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
