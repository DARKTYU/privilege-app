import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/data.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/logic/food_nutrition.dart';
import 'package:privilege/logic/recipe_nutrition.dart';
import 'package:privilege/screens/academy.dart';
import 'package:privilege/screens/recipes.dart';
import 'package:privilege/services/food_database.dart';
import 'package:privilege/services/storage_image.dart';
import 'package:privilege/state.dart';
import 'package:privilege/supabase_config.dart';
import 'package:privilege/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calories_test_database.dart';

Widget _app(Widget child) =>
    MaterialApp(theme: buildTheme(), home: Scaffold(body: child));

void main() {
  setUpAll(() async => FoodDatabase().load());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('bundled recipes sum the existing portion results and log them',
      (tester) async {
    final db = FoodDatabase();
    MealItem? logged;
    await tester.pumpWidget(_app(RecipesScreen(
      accountId: () => 'a',
      database: CaloriesTestDatabase(db),
      saveMeal: (meal) async => logged = meal,
    )));
    await tester.pumpAndSettle();
    for (final recipe in recipes) {
      final result = calculateRecipeNutrition(recipe, db.foods)!;
      final portions = recipe.ingredients
          .map((i) => calculateFoodPortion(
              db.foods.singleWhere((f) => f.id == i.foodId).per100g, i.grams))
          .toList();
      expect(result.portion.kcal, portions.fold<int>(0, (a, b) => a + b.kcal));
      expect(result.portion.proteinG,
          closeTo(portions.fold<double>(0, (a, b) => a + b.proteinG), 0.001));
      expect(result.portion.carbsG,
          closeTo(portions.fold<double>(0, (a, b) => a + b.carbsG), 0.001));
      expect(result.portion.fatG,
          closeTo(portions.fold<double>(0, (a, b) => a + b.fatG), 0.001));
      expect(result.portion.fiberG,
          closeTo(portions.fold<double>(0, (a, b) => a + b.fiberG), 0.001));
      expect(result.portion.sugarG,
          closeTo(portions.fold<double>(0, (a, b) => a + b.sugarG), 0.001));
      expect(result.portion.sodiumMg,
          closeTo(portions.fold<double>(0, (a, b) => a + b.sodiumMg), 0.001));
    }
    expect(find.text('Estimated from ingredients'), findsWidgets);
    for (final recipe in recipes) {
      final expected = calculateRecipeNutrition(recipe, db.foods)!.portion;
      final card = find
          .ancestor(of: find.text(recipe.name), matching: find.byType(Panel))
          .first;
      final log = find.descendant(of: card, matching: find.text('Log'));
      await tester.ensureVisible(log);
      await tester.tap(log);
      await tester.pumpAndSettle();
      expect(logged!.name, recipe.name);
      expect(logged!.source, 'manual');
      expect(logged!.calories, expected.kcal);
      expect(logged!.proteinGrams, expected.proteinG.round());
      expect(logged!.carbsGrams, expected.carbsG.round());
      expect(logged!.fatGrams, expected.fatG.round());
      expect(logged!.fiberGrams, expected.fiberG.round());
      expect(logged!.sugarG, expected.sugarG);
      expect(logged!.sodiumMg, expected.sodiumMg);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('missing ingredient disables logging', (tester) async {
    const missing = Recipe(
      id: 'missing',
      name: 'Missing food',
      prepTime: '1 min',
      difficulty: 'Easy',
      description: '',
      ingredients: [RecipeIngredient('does-not-exist', 100)],
      emoji: '',
      category: MealCategory.lunch,
    );
    await tester.pumpWidget(_app(RecipesScreen(
        accountId: () => 'a',
        database: CaloriesTestDatabase(FoodDatabase()),
        recipeList: const [missing])));
    await tester.pumpAndSettle();
    expect(find.text('Nutrition not available'), findsOneWidget);
    expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull);
  });

  testWidgets('favorites persist and are isolated by account', (tester) async {
    Widget screen(String user) => _app(RecipesScreen(
        accountId: () => user, database: CaloriesTestDatabase(FoodDatabase())));
    await tester.pumpWidget(screen('a'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add favorite').first);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen('b'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove favorite'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen('a'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove favorite'), findsOneWidget);
  });

  testWidgets('favorites clear immediately when the signed-in user changes',
      (tester) async {
    var account = 'a';
    await tester.pumpWidget(_app(RecipesScreen(
      accountId: () => account,
      database: CaloriesTestDatabase(FoodDatabase()),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add favorite').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove favorite'), findsOneWidget);
    account = 'b';
    appState.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove favorite'), findsNothing);
    account = 'a';
    appState.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove favorite'), findsOneWidget);
  });

  test('only Supabase storage object URLs can load as remote images', () {
    expect(
        storageImage(
            '${SupabaseConfig.url}/storage/v1/object/sign/posts/x?token=abc'),
        isNotNull);
    expect(
        storageImage(
            '${SupabaseConfig.url}/storage/v1/object/public/avatars/x'),
        isNotNull);
    expect(storageImage('https://example.com/image.png'), isNull);
    expect(storageImage('${SupabaseConfig.url}/rest/v1/profiles'), isNull);
    expect(
        storageImage(
            'http://${Uri.parse(SupabaseConfig.url).host}/storage/v1/object/public/x'),
        isNull);
  });

  testWidgets('academy details show advice disclaimer', (tester) async {
    await tester.pumpWidget(_app(const AcademyScreen()));
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'General information, not professional advice. Check with a qualified coach or doctor.'),
        findsOneWidget);
  });
}
