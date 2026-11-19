import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/logic/food_nutrition.dart';
import 'package:privilege/services/activity_repository.dart';
import 'package:privilege/services/food_database.dart';
import 'package:privilege/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  final rows = <Map<String, dynamic>>[];
  const userId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  final mock = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    http.Response json(Object? data, [int status = 200]) =>
        http.Response(jsonEncode(data), status,
            request: request, headers: {'content-type': 'application/json'});
    if (path.endsWith('/token')) {
      return json({
        'access_token': 'token',
        'refresh_token': 'refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': userId,
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z'
        }
      });
    }
    if (path.endsWith('/activity_today')) return json('2026-01-02');
    if (path.endsWith('/set_activity_timezone')) return json(null);
    if (path.endsWith('/store_points_balance')) return json(10);
    if (path.endsWith('/workout_logs')) return json([]);
    if (path.endsWith('/streaks')) return json(null);
    if (path.endsWith('/meal_logs')) {
      if (request.method == 'POST') {
        rows.add({
          ...jsonDecode(request.body) as Map<String, dynamic>,
          'id': 'meal-${rows.length}',
          'created_at': '2026-01-02T12:00:00Z',
        });
        return json(null, 201);
      }
      if (request.method == 'PATCH') {
        if (rows.isEmpty) return json([]);
        rows.first.addAll(jsonDecode(request.body) as Map<String, dynamic>);
        return json([
          {'id': rows.first['id']}
        ]);
      }
      if (request.method == 'DELETE') {
        rows.clear();
        return json(null);
      }
      return json(rows);
    }
    return json({'message': 'Unexpected request: $path'}, 500);
  });

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_timezone'), (call) async => 'UTC');
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      httpClient: mock,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
    await Supabase.instance.client.auth
        .signInWithPassword(email: 'test@example.com', password: 'password');
  });
  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_timezone'), null);
    await Supabase.instance.dispose();
  });
  setUp(() {
    rows.clear();
    requests.clear();
  });

  test('real repository maps food fields in inserts, reads and atomic updates',
      () async {
    final database = FoodDatabase();
    await database.load();
    final food = database.foods.first;
    final portion = calculateFoodPortion(food.per100g, 200);
    final repo = ActivityRepository();
    final meal = MealItem(
      id: '',
      name: food.nameEn,
      time: 'now',
      calories: portion.kcal,
      proteinGrams: portion.proteinG.round(),
      carbsGrams: portion.carbsG.round(),
      fatGrams: portion.fatG.round(),
      fiberGrams: portion.fiberG.round(),
      icon: 'food',
      consumed: true,
      category: MealCategory.lunch,
      foodId: food.id,
      grams: 200,
      servingLabel: 'Bowl',
      sugarG: portion.sugarG,
      sodiumMg: portion.sodiumMg,
      source: 'food_db',
    );
    await repo.addMeal(meal);
    final insert = jsonDecode(requests
        .firstWhere(
            (r) => r.method == 'POST' && r.url.path.endsWith('/meal_logs'))
        .body) as Map;
    expect(insert['food_id'], food.id);
    expect(insert['grams'], 200);
    expect(insert['serving_label'], 'Bowl');
    expect(insert['sugar_g'], 4.8);
    expect(insert['sodium_mg'], 770);
    expect(insert['source'], 'food_db');
    final loaded = (await repo.loadToday()).meals.single;
    expect(loaded.foodId, food.id);
    expect(loaded.grams, 200);
    expect(loaded.servingLabel, 'Bowl');
    expect(loaded.sugarG, 4.8);
    expect(loaded.sodiumMg, 770);
    expect(loaded.source, 'food_db');
    final selection = requests.lastWhere(
        (r) => r.method == 'GET' && r.url.path.endsWith('/meal_logs'));
    for (final column in [
      'food_id',
      'grams',
      'serving_label',
      'sugar_g',
      'sodium_mg',
      'source'
    ]) {
      expect(selection.url.queryParameters['select'], contains(column));
    }
    await repo.updateFoodPortion(loaded.copyWith(
        grams: 100,
        calories: 172,
        proteinGrams: 5,
        carbsGrams: 29,
        fatGrams: 4,
        fiberGrams: 3,
        sugarG: 2.4,
        sodiumMg: 385,
        clearServingLabel: true));
    final update = requests.lastWhere((r) => r.method == 'PATCH');
    final payload = jsonDecode(update.body) as Map;
    expect(payload['grams'], 100);
    expect(payload['calories'], 172);
    expect(payload['protein_g'], 5);
    expect(payload['serving_label'], isNull);
    expect(update.url.queryParameters['user_id'], 'eq.$userId');
    expect(update.url.queryParameters['food_id'], 'eq.${food.id}');
    expect((await repo.loadToday()).meals.single.calories, 172);
    await repo.removeMeal(loaded.id);
    expect(rows, isEmpty);
    await expectLater(repo.updateFoodPortion(loaded), throwsStateError);
  });

  test('manual rows remain compatible with missing new fields', () async {
    rows.add({
      'id': 'old',
      'name': 'Manual',
      'calories': 100,
      'protein_g': 1,
      'carbs_g': 2,
      'fat_g': 3,
      'fiber_g': 4,
      'category': 'snack',
      'icon': 'x',
      'consumed': true,
      'created_at': '2026-01-02T12:00:00Z',
    });
    final repo = ActivityRepository();
    final manual = (await repo.loadToday()).meals.single;
    expect(manual.source, 'manual');
    expect(manual.foodId, isNull);
    expect(manual.grams, isNull);
    expect(manual.sugarG, isNull);
    expect(manual.copyWith(calories: 90).source, 'manual');
    await repo.setMealCalories('old', 90);
    expect((await repo.loadToday()).meals.single.calories, 90);
    await repo.addMeal(manual.copyWith(id: ''));
    final inserted = jsonDecode(requests
        .lastWhere(
            (r) => r.method == 'POST' && r.url.path.endsWith('/meal_logs'))
        .body) as Map;
    expect(inserted['source'], 'manual');
    expect(inserted['food_id'], isNull);
    expect(inserted['grams'], isNull);
  });

  test('AppState logs and edits through its existing activity path', () async {
    final database = FoodDatabase();
    await database.load();
    final food = database.foods.first;
    final repo = _FakeActivityRepository();
    final state = AppState(activityRepository: repo, foodDatabase: database)
      ..loggedIn = true;
    addTearDown(state.dispose);
    await state.loadActivity();
    await state.logFood(
        food, calculateFoodPortion(food.per100g, 200), MealCategory.lunch,
        servingLabel: 'Bowl');
    expect(repo.insertCount, 1);
    expect(state.meals.single.foodId, food.id);
    expect(state.meals.single.source, 'food_db');
    expect(state.meals.single.calories, 344);
    expect(state.meals.single.proteinGrams, 11);
    expect(state.meals.single.carbsGrams, 57);
    expect(state.meals.single.fatGrams, 8);
    expect(state.meals.single.fiberGrams, 6);
    expect(state.meals.single.sugarG, 4.8);
    expect(state.meals.single.sodiumMg, 770);
    expect(state.meals.single.servingLabel, 'Bowl');
    final before = state.meals.single;
    expect(before.copyWith(consumed: false).foodId, food.id);
    await state.updateFoodPortion(before, 150.04);
    final changed = state.meals.single;
    expect(changed.grams, 150);
    expect(changed.calories, 258);
    expect(changed.proteinGrams, 8);
    expect(changed.carbsGrams, 43);
    expect(changed.fatGrams, 6);
    expect(changed.fiberGrams, 5);
    expect(changed.sugarG, 3.6);
    expect(changed.sodiumMg, 577.5);
    expect(changed.servingLabel, isNull);
    expect(repo.updateCount, 1);
    await expectLater(state.updateFoodPortion(changed, 0), throwsRangeError);
    expect(repo.updateCount, 1);
    expect(before.calories, 344);
  });

  test('missing or manual food cannot be edited', () async {
    final repo = _FakeActivityRepository();
    final state = AppState(activityRepository: repo)..loggedIn = true;
    addTearDown(state.dispose);
    await state.loadActivity();
    const missing = MealItem(
      id: 'missing',
      name: 'Old food',
      time: 'now',
      calories: 1,
      proteinGrams: 1,
      carbsGrams: 1,
      fatGrams: 1,
      fiberGrams: 1,
      icon: '',
      consumed: true,
      category: MealCategory.snack,
      foodId: 'not_in_bundle',
      grams: 100,
      source: 'food_db',
    );
    await expectLater(
        state.updateFoodPortion(missing, 200),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('no longer available'))));
    await expectLater(
        state.updateFoodPortion(
            const MealItem(
                id: 'manual',
                name: 'Manual',
                time: '',
                calories: 1,
                proteinGrams: 1,
                carbsGrams: 1,
                fatGrams: 1,
                fiberGrams: 1,
                icon: '',
                consumed: true,
                category: MealCategory.snack),
            100),
        throwsStateError);
    expect(repo.updateCount, 0);
    expect(state.meals, isEmpty);
  });

  test('failed portion save does not alter the snapshot', () async {
    final database = FoodDatabase();
    await database.load();
    final food = database.foods.first;
    final repo = _FakeActivityRepository();
    final state = AppState(activityRepository: repo, foodDatabase: database)
      ..loggedIn = true;
    addTearDown(state.dispose);
    await state.loadActivity();
    await state.logFood(
        food, calculateFoodPortion(food.per100g, 100), MealCategory.snack);
    repo.failUpdate = true;
    await expectLater(
        state.updateFoodPortion(state.meals.single, 200), throwsStateError);
    expect(state.meals.single.grams, 100);
    expect(repo.meals.single.calories, 172);
  });
}

class _FakeActivityRepository extends ActivityRepository {
  final List<MealItem> meals = [];
  int insertCount = 0, updateCount = 0;
  bool failUpdate = false;
  @override
  Future<ActivitySnapshot> loadToday() async => ActivitySnapshot(
      meals: List.of(meals),
      workouts: const [],
      streak: 1,
      longestStreak: 1,
      lastActivityDate: null,
      storePoints: 10);
  @override
  Future<void> addMeal(MealItem meal) async {
    insertCount++;
    meals.add(meal.copyWith(id: 'saved'));
  }

  @override
  Future<void> updateFoodPortion(MealItem meal) async {
    updateCount++;
    if (failUpdate) throw StateError('Update failed');
    meals[meals.indexWhere((item) => item.id == meal.id)] = meal;
  }
}
