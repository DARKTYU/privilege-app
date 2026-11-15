import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logic/fitness_logic.dart';

class ActivitySnapshot {
  const ActivitySnapshot({
    required this.meals,
    required this.workouts,
    required this.streak,
    required this.longestStreak,
    required this.lastActivityDate,
    required this.storePoints,
  });

  final List<MealItem> meals;
  final List<BurnItem> workouts;
  final int streak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int storePoints;
}

class ActivityRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Please log in again.');
    return id;
  }

  Future<ActivitySnapshot> loadToday() async {
    final userId = _userId;
    final timezone = await FlutterTimezone.getLocalTimezone();
    await _client.rpc(
      'set_activity_timezone',
      params: {'p_timezone': timezone.identifier},
    );
    final today = await _today();

    final mealRows = await _client
        .from('meal_logs')
        .select(
            'id,user_id,logged_date,meal_type,name,calories,protein_g,carbs_g,fat_g,fiber_g,category,icon,consumed,created_at,updated_at')
        .eq('user_id', userId)
        .eq('logged_date', today)
        .order('created_at', ascending: false);
    final workoutRows = await _client
        .from('workout_logs')
        .select(
            'id,user_id,activity_date,sets,reps,duration_minutes,notes,name,calories_burned,category,icon,created_at,updated_at')
        .eq('user_id', userId)
        .eq('activity_date', today)
        .order('created_at', ascending: false);
    final streakRow = await _client
        .from('streaks')
        .select('current_streak,longest_streak,last_activity_date')
        .eq('user_id', userId)
        .maybeSingle();
    final pointsBalance = await _client.rpc('store_points_balance');
    if (pointsBalance is! num) {
      throw const FormatException('Could not load the store-points balance.');
    }

    final streak = streakRow;
    final lastActivity = streak?['last_activity_date'] as String?;
    final lastDate = lastActivity == null ? null : _calendarDate(lastActivity);
    final todayDate = _calendarDate(today);
    final isCurrent = lastDate != null &&
        !lastDate.isBefore(todayDate.subtract(const Duration(days: 1)));

    return ActivitySnapshot(
      meals: (mealRows as List<dynamic>)
          .map((row) => _mealFromRow(Map<String, dynamic>.from(row as Map)))
          .toList(),
      workouts: (workoutRows as List<dynamic>)
          .map((row) => _workoutFromRow(Map<String, dynamic>.from(row as Map)))
          .toList(),
      streak: isCurrent ? (streak?['current_streak'] as num?)?.toInt() ?? 0 : 0,
      longestStreak: (streak?['longest_streak'] as num?)?.toInt() ?? 0,
      lastActivityDate: lastDate,
      storePoints: pointsBalance.toInt(),
    );
  }

  Future<void> addMeal(MealItem meal) async {
    final userId = _userId;
    final today = await _today();
    final category = meal.category.name;
    final mealType = category == 'shake' ? 'snack' : category;
    await _client.from('meal_logs').insert({
      'user_id': userId,
      'logged_date': today,
      'meal_type': mealType,
      'name': meal.name.trim(),
      'calories': meal.calories,
      'protein_g': meal.proteinGrams,
      'carbs_g': meal.carbsGrams,
      'fat_g': meal.fatGrams,
      'fiber_g': meal.fiberGrams,
      'category': category,
      'icon': meal.icon,
      'consumed': meal.consumed,
    });
  }

  Future<void> addWorkout(BurnItem workout) async {
    final userId = _userId;
    final today = await _today();
    await _client.from('workout_logs').insert({
      'user_id': userId,
      'activity_date': today,
      'name': workout.title.trim(),
      'calories_burned': workout.calories,
      'category': workout.type.name,
      'duration_minutes': workout.durationMin,
      'notes': '',
      'icon': workout.icon,
    });
  }

  Future<void> setMealConsumed(String id, bool consumed) async {
    await _client
        .from('meal_logs')
        .update({'consumed': consumed})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> setMealCalories(String id, int calories) async {
    await _client
        .from('meal_logs')
        .update({'calories': calories})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> setWorkoutCalories(String id, int calories) async {
    await _client
        .from('workout_logs')
        .update({'calories_burned': calories})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> removeMeal(String id) async {
    await _client
        .from('meal_logs')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> removeWorkout(String id) async {
    await _client
        .from('workout_logs')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<String> _today() async {
    final result = await _client.rpc('activity_today');
    if (result is! String || result.isEmpty) {
      throw const FormatException('Could not determine today’s activity date.');
    }
    return result;
  }

  DateTime _calendarDate(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime.utc(parts[0], parts[1], parts[2]);
  }

  MealItem _mealFromRow(Map<String, dynamic> row) {
    final date = DateTime.parse(row['created_at'] as String).toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour < 12 ? 'AM' : 'PM';
    final category = MealCategory.values.firstWhere(
      (value) => value.name == row['category'],
      orElse: () => MealCategory.snack,
    );
    return MealItem(
      id: row['id'] as String,
      name: row['name'] as String,
      time: '$hour:$minute $suffix',
      calories: (row['calories'] as num).round(),
      proteinGrams: (row['protein_g'] as num).round(),
      carbsGrams: (row['carbs_g'] as num).round(),
      fatGrams: (row['fat_g'] as num).round(),
      fiberGrams: (row['fiber_g'] as num).round(),
      icon: row['icon'] as String,
      consumed: row['consumed'] as bool,
      category: category,
    );
  }

  BurnItem _workoutFromRow(Map<String, dynamic> row) {
    final date = DateTime.parse(row['created_at'] as String).toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour < 12 ? 'AM' : 'PM';
    final type = BurnType.values.firstWhere(
      (value) => value.name == row['category'],
      orElse: () => BurnType.strength,
    );
    final duration = (row['duration_minutes'] as num?)?.toInt() ?? 1;
    return BurnItem(
      id: row['id'] as String,
      title: row['name'] as String,
      time: '$hour:$minute $suffix • ${duration}m',
      calories: (row['calories_burned'] as num).toInt(),
      type: type,
      durationMin: duration,
      icon: row['icon'] as String,
    );
  }
}
