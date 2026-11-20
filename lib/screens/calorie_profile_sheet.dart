import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import '../l10n_strings.dart';
import '../logic/calorie_target.dart';
import '../state.dart';
import 'calories_food_summary.dart';

class _ArabicWesternDates extends LocalizationsDelegate<MaterialLocalizations> {
  const _ArabicWesternDates();
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
  bool shouldReload(_ArabicWesternDates old) => false;
}

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
      builder: (context, child) => Localizations.override(
        context: context,
        delegates: const [_ArabicWesternDates()],
        child: child!,
      ),
    );
    if (date != null && mounted) setState(() => birthDate = date);
  }

  Future<void> save() async {
    if (preview.isEstimate ||
        birthDate == null ||
        sex == null ||
        activity == null) {
      setState(() => error = strings(context).profileInvalid);
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
      if (mounted) {
        setState(() => error = strings(context).profileSaveError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = CaloriesPalette(Theme.of(context));
    final l = strings(context);
    final result = preview;
    final date = birthDate;
    final descriptions = {
      TargetActivity.sedentary: (
        l.profileSedentary,
        l.profileSedentaryDescription
      ),
      TargetActivity.light: (l.intensityLight, l.profileLightDescription),
      TargetActivity.moderate: (
        l.intensityModerate,
        l.profileModerateDescription
      ),
      TargetActivity.veryActive: (
        l.profileVeryActive,
        l.profileVeryActiveDescription
      ),
      TargetActivity.athlete: (l.profileAthlete, l.profileAthleteDescription),
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
                  Text(l.mergeCompleteProfile,
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
                      decoration: InputDecoration(labelText: l.profileWeight),
                      onChanged: (_) => setState(() {}),
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                      key: const ValueKey('target-height'),
                      controller: height,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l.profileHeight),
                      onChanged: (_) => setState(() {}),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: saving ? null : pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(date == null
                        ? l.profileChooseBirth
                        : l.profileBirth(
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}')),
                  ),
                  const SizedBox(height: 8),
                  Text(l.profileSex, style: TextStyle(color: p.text)),
                  Wrap(spacing: 8, children: [
                    for (final item in [
                      (TargetSex.male, l.profileMale),
                      (TargetSex.female, l.profileFemale),
                      (TargetSex.unspecified, l.profileUnspecified),
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
                  Text(l.profileActivity,
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
                              l.profileTarget(
                                  result.target == null
                                      ? l.mergeUnavailable.toLowerCase()
                                      : l.mergeCalories(
                                          result.target.toString()),
                                  result.isEstimate ? l.foodEstimated : ''),
                              style: TextStyle(
                                  color: p.accentText,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              l.profileBmr(
                                  result.bmr?.toString() ??
                                      l.mergeUnavailable.toLowerCase(),
                                  result.maintenance?.toString() ??
                                      l.mergeUnavailable.toLowerCase()),
                              style: TextStyle(color: p.muted)),
                          Text(
                              result.isEstimate
                                  ? l.profileCompleteFields
                                  : l.profileAdjustment(
                                      '${result.target! - result.maintenance! >= 0 ? '+' : ''}${result.target! - result.maintenance!}',
                                      result.age! < 18 ? l.profileMinor : ''),
                              style: TextStyle(color: p.muted)),
                          const SizedBox(height: 4),
                          Text(l.profileDisclaimer,
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
                    child: Text(saving ? l.workoutSaving : l.profileSave),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
