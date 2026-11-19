import 'dart:math' as math;

enum TargetSex { male, female, unspecified }

enum TargetActivity {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  veryActive(1.725),
  athlete(1.9);

  const TargetActivity(this.multiplier);
  final double multiplier;
}

enum NutritionGoal { lose, maintain, gain }

NutritionGoal? _recognizedTrainingGoal(String value) {
  switch (value.trim().toLowerCase()) {
    case 'lose':
    case 'metabolic fat loss & calorie deficit':
      return NutritionGoal.lose;
    case 'gain':
    case 'lean muscle mass hypertrophy':
      return NutritionGoal.gain;
    case 'maintain':
    case 'natural championship qualification':
    case 'sports & strength split merger':
      return NutritionGoal.maintain;
    default:
      return null;
  }
}

NutritionGoal nutritionGoalFromTraining(String value) =>
    resolveNutritionGoal(value, null);

NutritionGoal resolveNutritionGoal(String trainingGoal, NutritionGoal? goal) =>
    _recognizedTrainingGoal(trainingGoal) ?? goal ?? NutritionGoal.maintain;

class MacroGoals {
  const MacroGoals(this.protein, this.carbs, this.fat);
  final int protein, carbs, fat;
}

class CalorieTarget {
  const CalorieTarget._({
    required this.bmr,
    required this.maintenance,
    required this.target,
    required this.macros,
    required this.isEstimate,
    required this.age,
    required this.goal,
  });

  final int? bmr, maintenance, target;
  final MacroGoals? macros;
  final bool isEstimate;
  final int? age;
  final NutritionGoal goal;

  static CalorieTarget calculate({
    required DateTime today,
    double? weightKg,
    double? heightCm,
    DateTime? birthDate,
    TargetSex? sex,
    TargetActivity? activity,
    NutritionGoal? goal,
    String? legacyTrainingGoal,
    int? legacyTarget,
  }) {
    final weight = weightKg != null &&
            weightKg.isFinite &&
            weightKg >= 30 &&
            weightKg <= 300
        ? weightKg
        : null;
    final height = heightCm != null &&
            heightCm.isFinite &&
            heightCm >= 120 &&
            heightCm <= 230
        ? heightCm
        : null;
    final date = DateTime(today.year, today.month, today.day);
    final birth = birthDate == null
        ? null
        : DateTime(birthDate.year, birthDate.month, birthDate.day);
    var age = birth == null ? null : date.year - birth.year;
    if (age != null &&
        (date.month < birth!.month ||
            (date.month == birth.month && date.day < birth.day))) {
      age--;
    }
    if (age != null && (age < 13 || age > 100)) age = null;
    final effectiveGoal = resolveNutritionGoal(legacyTrainingGoal ?? '', goal);
    final estimate = weight == null ||
        height == null ||
        age == null ||
        sex == null ||
        activity == null ||
        (goal == null &&
            _recognizedTrainingGoal(legacyTrainingGoal ?? '') == null);

    int? bmr;
    int? maintenance;
    int? target;
    if (weight == null || height == null) {
      target = legacyTarget != null && legacyTarget > 0 ? legacyTarget : null;
    } else if (estimate) {
      final rawBmr = 10 * weight + 6.25 * height - 5 * 26 + 5;
      bmr = rawBmr.round();
      final rawMaintenance = rawBmr * 1.55;
      maintenance = rawMaintenance.round();
      target = _adjustTarget(rawMaintenance, effectiveGoal, age, sex);
    } else {
      final coefficient = switch (sex) {
        TargetSex.male => 5,
        TargetSex.female => -161,
        TargetSex.unspecified => -78,
      };
      final rawBmr = 10 * weight + 6.25 * height - 5 * age + coefficient;
      bmr = rawBmr.round();
      final rawMaintenance = rawBmr * activity.multiplier;
      maintenance = rawMaintenance.round();
      target = _adjustTarget(rawMaintenance, effectiveGoal, age, sex);
    }

    final macros = target == null
        ? null
        : calculateMacros(target, weight, effectiveGoal, age);
    return CalorieTarget._(
      bmr: bmr,
      maintenance: maintenance,
      target: target,
      macros: macros,
      isEstimate: estimate,
      age: age,
      goal: effectiveGoal,
    );
  }

  static int _adjustTarget(
      double maintenance, NutritionGoal goal, int? age, TargetSex? sex) {
    var adjusted = maintenance;
    if (age == null || age >= 18) {
      if (goal == NutritionGoal.lose) {
        final floor = switch (sex) {
          TargetSex.male => 1500,
          TargetSex.female => 1200,
          TargetSex.unspecified || null => 1350,
        };
        adjusted = math.max(maintenance * .85, floor.toDouble());
      } else if (goal == NutritionGoal.gain) {
        adjusted = maintenance * 1.1;
      }
    }
    return (adjusted / 10).round() * 10;
  }

  static MacroGoals calculateMacros(
      int target, double? weight, NutritionGoal goal, int? age) {
    if (weight == null || !weight.isFinite || weight < 30 || weight > 300) {
      return MacroGoals((target * .3 / 4).round(), (target * .4 / 4).round(),
          (target * .3 / 9).round());
    }
    final protein = weight *
        (goal == NutritionGoal.lose && (age == null || age >= 18) ? 2.0 : 1.8);
    final fat = target * .25 / 9;
    final carbs = math.max(0.0, (target - protein * 4 - fat * 9) / 4);
    return MacroGoals(protein.round(), carbs.round(), fat.round());
  }
}
