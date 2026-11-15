import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/logic/user_profile.dart';

// Port of src/utils/fitnessLogic.test.ts
void main() {
  test('calculateCalorieBalance computes deficit and balances', () {
    final r = calculateCalorieBalance(2855, 1206, bmr: 1800);
    expect(r.totalBurned, 3006);
    expect(r.netDifference, -151);
    expect(r.isSurplus, false);
  });

  test('adjustCalories dynamically increments and decrements calories', () {
    final afterMeal = adjustCalories(2000, 500, isMeal: true, amount: 450);
    expect(afterMeal.consumed, 2450);
    expect(afterMeal.burned, 500);

    final afterBurn = adjustCalories(2450, 500, isMeal: false, amount: 300);
    expect(afterBurn.burned, 800);

    final afterRemoval =
        adjustCalories(2450, 800, isMeal: true, amount: 450, isRemoval: true);
    expect(afterRemoval.consumed, 2000);
  });

  test('canAccessFeature validates Free, Pro, and Elite subscription perks',
      () {
    expect(canAccessFeature(SubscriptionTier.free, Feature.basic), true);
    expect(
        canAccessFeature(SubscriptionTier.free, Feature.aiVoicePhoto), false);
    expect(canAccessFeature(SubscriptionTier.pro, Feature.aiVoicePhoto), true);
    expect(canAccessFeature(SubscriptionTier.pro, Feature.contestPrep), false);
    expect(canAccessFeature(SubscriptionTier.elite, Feature.contestPrep), true);
  });

  test(
      'calculateQualificationScore returns Silver Beast or better for the benchmark athlete',
      () {
    final score = calculateQualificationScore(const QualificationMetrics(
      naturalVerified: true,
      bodyFatPercent: 11,
      muscleMassKg: 42,
      mandatoryPosingRoutine: false,
    ));
    expect(score.eligible, true);
    expect(score.scorePercent >= 85, true);
    expect(score.statusNotes.contains('100% Natural Status Verified'), true);
  });

  test('calculateEstimatedBmr and recommended calories adjust based on goal',
      () {
    final bmr = calculateEstimatedBmr(78, 182, age: 26);
    expect(bmr > 1600 && bmr < 2000, true);
    final cut = calculateRecommendedCalories(
        78, 182, 'Natural Championship Qualification');
    final bulk =
        calculateRecommendedCalories(78, 182, 'Lean Muscle Mass Hypertrophy');
    expect(cut < bulk, true);
  });

  test('mergeWorkoutWithSport combines calories and recovery targets', () {
    final merged =
        mergeWorkoutWithSport('Push Day', 450, 60, 'Basketball', 550, 60);
    expect(merged.totalCalories, 1000);
    expect(merged.totalDurationMin, 120);
    expect(merged.recoveryHoursRecommended >= 24, true);
    expect(merged.hydrationMlNeeded > 1000, true);
  });

  test('isDayAllowedForCheat flags cheat days correctly', () {
    const allowed = [8, 20];
    expect(isDayAllowedForCheat(8, allowed), true);
    expect(isDayAllowedForCheat(20, allowed), true);
    expect(isDayAllowedForCheat(9, allowed), false);
  });

  test('getPrivilegeBotFallback returns informative answers', () {
    final reply =
        getPrivilegeBotFallback('how do I merge push day and basketball?');
    expect(reply.contains('merge') || reply.contains('workout'), true);
  });

  test('calculateMacroTotals sums consumed meals and workouts correctly', () {
    const meals = [
      MealItem(
          id: 'm1',
          name: 'Oats & Eggs',
          time: '08:00',
          calories: 500,
          proteinGrams: 40,
          carbsGrams: 50,
          fatGrams: 10,
          fiberGrams: 6,
          icon: '🥞',
          consumed: true,
          category: MealCategory.breakfast),
      MealItem(
          id: 'm2',
          name: 'Unchecked Dinner',
          time: '19:00',
          calories: 700,
          proteinGrams: 50,
          carbsGrams: 60,
          fatGrams: 20,
          fiberGrams: 8,
          icon: '🥩',
          consumed: false,
          category: MealCategory.dinner),
    ];
    const burns = [
      BurnItem(
          id: 'b1',
          title: 'Bench Press',
          time: '10:00',
          calories: 400,
          type: BurnType.strength,
          durationMin: 50,
          icon: '🏋️'),
      BurnItem(
          id: 'b2',
          title: 'Basketball Run',
          time: '15:00',
          calories: 350,
          type: BurnType.cardio,
          durationMin: 40,
          icon: '🏀'),
    ];

    final totals = calculateMacroTotals(meals, burns,
        calorieTarget: 2400, burnTarget: 1200);
    expect(totals.totalMealCalories, 500);
    expect(totals.proteinGrams, 40);
    expect(totals.proteinCalories, 160);
    expect(totals.totalBurnedCalories, 750);
    expect(totals.strengthBurnCalories, 400);
    expect(totals.cardioBurnCalories, 350);
    expect(totals.activeMealCount, 1);

    final radial = calculateRadialSegments(totals);
    expect(radial.segments.length, 7);
    final colors = radial.segments.map((s) => s.color).toList();
    for (final c in const [
      0xFFF43F5E,
      0xFF3B82F6,
      0xFFF97316,
      0xFF10B981,
      0xFFF59E0B,
      0xFF06B6D4,
      0xFF8B5CF6
    ]) {
      expect(colors.contains(Color(c)), true, reason: 'missing colour $c');
    }
    for (final seg in radial.segments) {
      expect(seg.arcLength > 0, true);
      expect(seg.label.isNotEmpty, true);
    }

    const themeProtein = Color(0xFFAA3377);
    final themedRadial =
        calculateRadialSegments(totals, proteinColor: themeProtein);
    expect(themedRadial.segments.first.color, themeProtein);
  });
}
