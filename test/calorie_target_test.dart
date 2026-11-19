import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/calorie_target.dart';

void main() {
  final today = DateTime(2026, 11, 19);
  CalorieTarget calculate({
    double? weight = 80,
    double? height = 180,
    DateTime? birth,
    TargetSex? sex = TargetSex.male,
    TargetActivity? activity = TargetActivity.moderate,
    NutritionGoal? goal = NutritionGoal.maintain,
    int? legacyTarget,
    String? legacyGoal,
  }) =>
      CalorieTarget.calculate(
        today: today,
        weightKg: weight,
        heightCm: height,
        birthDate: birth ?? DateTime(1996, 11, 19),
        sex: sex,
        activity: activity,
        goal: goal,
        legacyTarget: legacyTarget,
        legacyTrainingGoal: legacyGoal,
      );

  test('male and female reference values', () {
    final male = calculate();
    expect(male.bmr, 1780);
    expect(male.target, 2760);
    expect(male.isEstimate, false);
    final female = calculate(
        weight: 60,
        height: 165,
        birth: DateTime(2001, 11, 19),
        sex: TargetSex.female,
        activity: TargetActivity.light);
    expect(female.bmr, 1345);
    expect(female.target, 1850);
    expect(
        calculate(
                weight: 60,
                height: 165,
                birth: DateTime(2001, 11, 19),
                sex: TargetSex.female,
                activity: TargetActivity.light,
                goal: NutritionGoal.lose)
            .target,
        1570);
  });

  test('goal mapping covers every existing value', () {
    expect(nutritionGoalFromTraining('Metabolic Fat Loss & Calorie Deficit'),
        NutritionGoal.lose);
    expect(nutritionGoalFromTraining('Lean Muscle Mass Hypertrophy'),
        NutritionGoal.gain);
    expect(nutritionGoalFromTraining('Natural Championship Qualification'),
        NutritionGoal.maintain);
    expect(nutritionGoalFromTraining('Sports & Strength Split Merger'),
        NutritionGoal.maintain);
    expect(nutritionGoalFromTraining('lose'), NutritionGoal.lose);
    expect(nutritionGoalFromTraining('maintain'), NutritionGoal.maintain);
    expect(nutritionGoalFromTraining('gain'), NutritionGoal.gain);
    expect(nutritionGoalFromTraining('other'), NutritionGoal.maintain);
  });

  test('training goal takes precedence over the older goal field', () {
    final loss = calculate(
        legacyGoal: 'Metabolic Fat Loss & Calorie Deficit',
        goal: NutritionGoal.maintain);
    expect(loss.goal, NutritionGoal.lose);
    expect(loss.target, 2350);
    expect(loss.macros!.protein, 160);
    expect(calculate(legacyGoal: '', goal: NutritionGoal.gain).goal,
        NutritionGoal.gain);
    expect(calculate(legacyGoal: 'unknown', goal: NutritionGoal.gain).target,
        3030);
    expect(calculate(legacyGoal: '', goal: null).goal, NutritionGoal.maintain);
    expect(
        calculate(
                legacyGoal: 'Natural Championship Qualification',
                goal: NutritionGoal.gain)
            .goal,
        NutritionGoal.maintain);
  });

  test('age uses local date and under 18 stays at maintenance', () {
    final young =
        calculate(birth: DateTime(2009, 11, 20), goal: NutritionGoal.lose);
    expect(young.age, 16);
    expect(young.target, ((young.maintenance! / 10).round() * 10));
    final gain =
        calculate(birth: DateTime(2009, 11, 20), goal: NutritionGoal.gain);
    expect(gain.target, young.target);
    expect(
        calculate(birth: DateTime(2008, 11, 19), goal: NutritionGoal.lose).age,
        18);
  });

  test('deficit floors for each sex', () {
    for (final entry in {
      TargetSex.male: 1500,
      TargetSex.female: 1200,
      TargetSex.unspecified: 1350,
    }.entries) {
      final result = calculate(
          weight: 30,
          height: 120,
          birth: DateTime(1950, 1, 1),
          sex: entry.key,
          activity: TargetActivity.sedentary,
          goal: NutritionGoal.lose);
      expect(result.target, entry.value);
    }
  });

  test('female deficit below the floor is raised to 1200', () {
    final result = calculate(
        weight: 45,
        height: 150,
        birth: DateTime(1986, 11, 19),
        sex: TargetSex.female,
        activity: TargetActivity.sedentary,
        goal: NutritionGoal.lose);
    expect(result.age, 40);
    expect(result.bmr, 1027);
    expect(result.maintenance, 1232);
    expect(result.target, 1200);
    expect(result.isEstimate, false);
  });

  test('unspecified sex is distinct from missing', () {
    expect(calculate(sex: TargetSex.unspecified).bmr, 1697);
    expect(calculate(sex: TargetSex.unspecified).isEstimate, false);
    expect(calculate(sex: null).isEstimate, true);
  });

  test('missing or invalid data produces a legacy estimate', () {
    final legacy =
        calculate(sex: null, legacyGoal: 'Natural Championship Qualification');
    expect(legacy.isEstimate, true);
    expect(legacy.bmr, 1800);
    expect(legacy.target, 2790);
    expect(
        calculate(sex: null, legacyGoal: 'Metabolic Fat Loss & Calorie Deficit')
            .target,
        2370);
    expect(
        calculate(sex: null, legacyGoal: '', goal: NutritionGoal.gain).target,
        3070);
    final missing = calculate(weight: null, legacyTarget: 2143);
    expect(missing.target, 2143);
    expect(missing.bmr, isNull);
    expect(missing.macros!.protein, 161);
    expect(calculate(weight: 29, legacyTarget: 2000).target, 2000);
    expect(calculate(height: 231, legacyTarget: 2000).target, 2000);
    expect(calculate(weight: double.nan).target, isNull);
    expect(calculate(birth: DateTime(2014, 1, 1)).isEstimate, true);
    expect(calculate(birth: DateTime(1925, 1, 1)).isEstimate, true);
    expect(calculate(activity: null).isEstimate, true);
    expect(calculate(goal: null).isEstimate, true);
  });

  test('legacy estimate applies floors and under-18 maintenance', () {
    for (final entry in {
      TargetSex.male: 1500,
      TargetSex.unspecified: 1350,
    }.entries) {
      final result = calculate(
          weight: 30,
          height: 120,
          activity: null,
          sex: entry.key,
          goal: NutritionGoal.lose);
      expect(result.target, entry.value);
    }
    final young = calculate(
        birth: DateTime(2010, 1, 1), sex: null, goal: NutritionGoal.lose);
    expect(young.target, 2790);
  });

  test('legacy female deficit above the floor is not floored', () {
    final result = calculate(
        weight: 30,
        height: 120,
        activity: null,
        sex: TargetSex.female,
        goal: NutritionGoal.lose);
    expect(result.isEstimate, true);
    expect(result.bmr, 925);
    expect(result.maintenance, 1434);
    expect(result.target, 1220);
  });

  test('macros use protein weight, fat 25 percent and nonnegative carbs', () {
    final maintain = calculate();
    expect(maintain.macros!.protein, 144);
    expect(maintain.macros!.fat, 77);
    expect(maintain.macros!.carbs, 374);
    final lose = calculate(goal: NutritionGoal.lose);
    expect(lose.macros!.protein, 160);
    final highWeight = calculate(
        weight: 300,
        height: 120,
        birth: DateTime(1927, 1, 1),
        sex: TargetSex.female,
        activity: TargetActivity.sedentary,
        goal: NutritionGoal.lose);
    expect(highWeight.macros!.carbs, greaterThanOrEqualTo(0));
  });
}
