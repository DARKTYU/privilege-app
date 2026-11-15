import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/models/supabase_rows.dart';

void main() {
  test('profile row round-trips nullable fields, dates and numeric values', () {
    final row = ProfileRow.fromJson({
      'id': 'user-id',
      'username': 'user_test',
      'full_name': null,
      'avatar_url': null,
      'birth_date': '2000-02-29',
      'gender': null,
      'height_cm': 175,
      'weight_kg': 75.5,
      'goal': 'maintain',
      'activity_level': null,
      'daily_calorie_target': 2000,
      'level_id': null,
      'training_goal': null,
      'bio': '',
      'onboarding_completed': false,
      'created_at': '2026-01-01T10:00:00Z',
      'updated_at': '2026-01-02T10:00:00Z',
    });
    expect(row.heightCm, 175.0);
    expect(row.weightKg, 75.5);
    expect(row.toJson()['birth_date'], '2000-02-29');
    expect(row.toJson()['full_name'], isNull);
    expect(ProfileRow.fromJson(row.toJson()).username, row.username);
  });

  test('subscription plan preserves feature flags and prices', () {
    final row = SubscriptionPlanRow.fromJson({
      'id': 'plan-id',
      'name': 'Silver',
      'price_usd': 9.99,
      'feature_flags': {'ai_chat': true},
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    });
    expect(row.priceUsd, 9.99);
    expect(row.toJson()['feature_flags'], {'ai_chat': true});
  });

  test('meal log preserves its calendar date and nutrition values', () {
    final row = MealLogRow.fromJson({
      'id': 'meal-id',
      'user_id': 'user-id',
      'logged_date': '2024-02-29',
      'meal_type': 'snack',
      'name': 'Meal',
      'calories': 125.5,
      'protein_g': 10,
      'carbs_g': 12.5,
      'fat_g': 3,
      'fiber_g': 2.5,
      'category': 'shake',
      'icon': '🥤',
      'consumed': true,
      'created_at': '2024-03-01T00:30:00Z',
      'updated_at': '2024-03-01T00:30:00Z',
    });

    expect(row.toJson()['logged_date'], '2024-02-29');
    expect(row.toJson()['calories'], 125.5);
    final restored = MealLogRow.fromJson(row.toJson());
    expect(restored.userId, 'user-id');
    expect(restored.carbsG, 12.5);
    expect(restored.mealType, 'snack');
    expect(restored.category, 'shake');
    expect(restored.fiberG, 2.5);
    expect(restored.icon, '🥤');
    expect(restored.consumed, isTrue);
  });

  test('workout log round-trips nullable exercise and calendar date', () {
    final row = WorkoutLogRow.fromJson({
      'id': 'workout-id',
      'user_id': 'user-id',
      'exercise_id': null,
      'activity_date': '2024-12-31',
      'sets': null,
      'reps': null,
      'duration_minutes': 30,
      'notes': 'Completed workout',
      'name': 'Workout',
      'calories_burned': 240,
      'category': 'strength',
      'icon': '🏋️',
      'created_at': '2025-01-01T01:00:00Z',
      'updated_at': '2025-01-01T01:00:00Z',
    });

    expect(row.toJson()['activity_date'], '2024-12-31');
    final restored = WorkoutLogRow.fromJson(row.toJson());
    expect(restored.userId, 'user-id');
    expect(restored.exerciseId, isNull);
    expect(restored.durationMinutes, 30);
    expect(restored.notes, 'Completed workout');
    expect(restored.caloriesBurned, 240);
    expect(restored.category, 'strength');
    expect(restored.icon, '🏋️');
  });

  test('streak preserves nullable last activity and count values', () {
    final row = StreakRow.fromJson({
      'id': 'streak-id',
      'user_id': 'user-id',
      'current_streak': 0,
      'longest_streak': 5,
      'last_activity_date': null,
      'created_at': '2025-01-01T00:00:00Z',
      'updated_at': '2025-01-01T00:00:00Z',
    });

    final restored = StreakRow.fromJson(row.toJson());
    expect(restored.lastActivityDate, isNull);
    expect(restored.currentStreak, 0);
    expect(restored.longestStreak, 5);
  });
}
