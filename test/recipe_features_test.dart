import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/data.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/logic/calorie_target.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/logic/food_nutrition.dart';
import 'package:privilege/logic/recipe_nutrition.dart';
import 'package:privilege/logic/recipe_fit.dart';
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

class _PhotoBundle extends CachingAssetBundle {
  _PhotoBundle(this.photoPath);
  final String photoPath;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        photoPath: [
          {'asset': photoPath}
        ]
      })!;
    }
    if (key == photoPath) return rootBundle.load('assets/images/logo.png');
    return rootBundle.load(key);
  }
}

void main() {
  setUpAll(() async => FoodDatabase().load());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('recipe screen has no hardcoded UI strings or Arabic', () {
    final source = File('lib/screens/recipes.dart').readAsStringSync();
    final labels = RegExp(
        r"""(?:Text\(\s*(?:const\s*)?|(?:PrimaryButton|fieldDecoration|_recipePill)\(\s*|(?:tooltip|labelText|hintText|helperText|semanticLabel)\s*:\s*)['"]""");
    expect(labels.allMatches(source), isEmpty);
    expect(source, isNot(contains(RegExp(r'[\u0600-\u06ff]'))));
  });

  for (final language in ['en', 'ar']) {
    testWidgets('recipes localize and log unchanged data at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = FoodDatabase();
      final recipe = recipes.first;
      MealItem? logged;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: Scaffold(
            body: RecipesScreen(
          accountId: () => 'a',
          database: CaloriesTestDatabase(db),
          recipeList: [recipe],
          saveMeal: (meal) async => logged = meal,
        )),
      ));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(RecipesScreen));
      final l = AppLocalizations.of(context)!;
      final name = language == 'ar' ? recipe.nameAr : recipe.name;
      expect(find.text(name), findsOneWidget);
      expect(find.text(language == 'ar' ? recipe.name : recipe.nameAr),
          findsNothing);
      expect(
          find.text(
              l.recipeSummary('20', l.recipeDifficultyEasyMedium, l.foodLunch)),
          findsOneWidget);
      await tester.ensureVisible(find.byTooltip(l.recipeAddFavorite));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l.recipeAddFavorite));
      await tester.pumpAndSettle();
      expect(find.byTooltip(l.recipeRemoveFavorite), findsOneWidget);
      await tester.ensureVisible(find.text(l.recipeLog));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.recipeLog));
      await tester.pumpAndSettle();
      expect(logged!.name, recipe.name);
      expect(logged!.category, recipe.category);
      expect(logged!.servingLabel, 'Recipe');
      expect(find.text(l.recipeLogged(name, logged!.calories.toString())),
          findsOneWidget);
      await tester.ensureVisible(find.text(name));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      expect(find.text(l.recipeDetails), findsOneWidget);
      expect(find.text(name), findsOneWidget);
      final ingredient =
          calculateRecipeNutrition(recipe, db.foods)!.ingredients.first;
      final ingredientName =
          language == 'ar' ? ingredient.$1.nameAr : ingredient.$1.nameEn;
      final ingredientText = l.recipeIngredientAmount(ingredientName, '150');
      await tester.scrollUntilVisible(find.text(ingredientText), 150);
      await tester.pumpAndSettle();
      expect(find.text(ingredientText), findsOneWidget);
      await tester.scrollUntilVisible(find.text(l.recipeHowToCook), 200);
      await tester.pumpAndSettle();
      expect(find.text(l.recipeStep('1', recipe.steps.first)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

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
      await tester.pumpWidget(_app(RecipesScreen(
        key: ValueKey(recipe.id),
        accountId: () => 'a',
        database: CaloriesTestDatabase(db),
        recipeList: [recipe],
        saveMeal: (meal) async => logged = meal,
      )));
      await tester.pumpAndSettle();
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
      expect(logged!.servingLabel, 'Recipe');
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

  test('catalog meets ingredient, nutrition and coverage requirements', () {
    final foods = FoodDatabase().foods;
    expect(recipes.length, 10);
    expect(recipes.map((r) => r.id).toSet().length, 10);
    expect(
        recipes.map((r) => r.category).toSet(),
        containsAll([
          MealCategory.breakfast,
          MealCategory.lunch,
          MealCategory.dinner,
          MealCategory.snack
        ]));
    for (final recipe in recipes) {
      expect(recipe.nameAr, isNotEmpty);
      expect(recipe.steps.length, inInclusiveRange(3, 5));
      for (final ingredient in recipe.ingredients) {
        expect(
            foods.where((food) => food.id == ingredient.foodId), hasLength(1));
      }
    }
    final portions = recipes
        .map((r) => calculateRecipeNutrition(r, foods)!.portion)
        .toList();
    expect(portions.where((p) => p.proteinG >= 30).length,
        greaterThanOrEqualTo(3));
    expect(portions.where((p) => p.kcal < 400).length, greaterThanOrEqualTo(3));
    expect(
        recipes.where((r) => r.minutes <= 10).length, greaterThanOrEqualTo(3));
  });

  test('recipe names and notes identify ingredient preparation', () {
    final byId = {for (final recipe in recipes) recipe.id: recipe};
    final taameya = byId['taameya_areesh']!;
    expect(taameya.name, 'Baked Taameya and Areesh Plate');
    expect(taameya.nameAr, 'طعمية مخبوزة وجبنة قريش');
    expect(taameya.description, 'Use prepared baked or air-fried taameya.');
    final expectedNotes = <String, List<String>>{
      'burger': ['before cooking'],
      'shake': ['fresh peeled banana', 'roasted peanuts'],
      'ful_egg': ['boiled ful', 'boiled eggs'],
      'chicken_rice': ['grilled chicken', 'steamed or boiled rice'],
      'chicken_molokhia': ['grilled chicken', 'molokhia cooked'],
      'yogurt_banana': ['fresh peeled banana'],
      'areesh_egg': ['boiled egg'],
      'koshary_chicken': ['fried onions', 'grilled chicken'],
    };
    for (final entry in expectedNotes.entries) {
      for (final phrase in entry.value) {
        expect(byId[entry.key]!.description, contains(phrase));
      }
    }
    final portion =
        calculateRecipeNutrition(taameya, FoodDatabase().foods)!.portion;
    expect(portion.kcal, 313);
    expect(portion.proteinG, 30);
    expect(portion.carbsG, 36.9);
    expect(portion.fatG, 5.7);
  });

  test('fit sorting and filters use calories and protein contribution', () {
    final foods = FoodDatabase().foods;
    final entries = [
      for (final recipe in recipes)
        (recipe: recipe, nutrition: calculateRecipeNutrition(recipe, foods))
    ];
    List<RecipeEntry> select(RecipeFilter filter, int? kcal, int? protein) =>
        selectRecipes(entries,
            filter: filter, remainingCalories: kcal, remainingProtein: protein);
    final all = select(RecipeFilter.all, 350, 50);
    expect(all.length, 10);
    final firstOver = all.indexWhere((e) => e.nutrition!.portion.kcal > 350);
    expect(firstOver, greaterThan(0));
    expect(all.take(firstOver).every((e) => e.nutrition!.portion.kcal <= 350),
        isTrue);
    expect(all.skip(firstOver).every((e) => e.nutrition!.portion.kcal > 350),
        isTrue);
    for (final group in [
      all.take(firstOver).toList(),
      all.skip(firstOver).toList()
    ]) {
      for (var i = 1; i < group.length; i++) {
        final previous = group[i - 1].nutrition!.portion.proteinG.clamp(0, 50);
        final current = group[i].nutrition!.portion.proteinG.clamp(0, 50);
        expect(previous, greaterThanOrEqualTo(current));
      }
    }
    expect(
        select(RecipeFilter.fits, 350, 50)
            .every((e) => e.nutrition!.portion.kcal <= 350),
        isTrue);
    expect(
        select(RecipeFilter.highProtein, 350, 50)
            .every((e) => e.nutrition!.portion.proteinG >= 30),
        isTrue);
    expect(
        select(RecipeFilter.quick, 350, 50)
            .every((e) => e.recipe.minutes <= 10),
        isTrue);
    expect(select(RecipeFilter.fits, null, null).length, 10);
    expect(select(RecipeFilter.fits, 0, 50).length, 10);
    expect(select(RecipeFilter.fits, -100, 50).length, 10);
  });

  testWidgets('remaining totals, filters and unavailable states update live',
      (tester) async {
    final oldTarget = appState.targetCalories;
    final oldMeals = List<MealItem>.of(appState.meals);
    final oldLoading = appState.activityLoading;
    final oldError = appState.activityError;
    addTearDown(() {
      appState.targetCalories = oldTarget;
      appState.meals
        ..clear()
        ..addAll(oldMeals);
      appState.activityLoading = oldLoading;
      appState.activityError = oldError;
    });
    appState.targetCalories = 1000;
    appState.activityLoading = false;
    appState.activityError = null;
    appState.meals.clear();
    await tester.pumpWidget(_app(RecipesScreen(
      accountId: () => 'a',
      database: CaloriesTestDatabase(FoodDatabase()),
    )));
    await tester.pumpAndSettle();
    final initialProtein = CalorieTarget.calculateMacros(
      1000,
      appState.profile.hasWeight ? appState.profile.weightKg : null,
      appState.calorieTarget.goal,
      appState.calorieTarget.age,
    ).protein;
    expect(find.text('Remaining today: 1000 kcal · $initialProtein g protein'),
        findsOneWidget);
    expect(find.text('Fits today'), findsWidgets);

    await tester.tap(find.widgetWithText(ChoiceChip, 'High protein'));
    await tester.pumpAndSettle();
    expect(find.text('Greek Yogurt and Banana'), findsNothing);
    expect(find.text('Chicken and Rice Bowl'), findsOneWidget);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    appState.targetCalories = 200;
    appState.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.textContaining('Over by'), findsWidgets);
    appState.meals.add(const MealItem(
        id: 'm',
        name: 'Meal',
        time: '',
        calories: 1000,
        proteinGrams: 20,
        carbsGrams: 0,
        fatGrams: 0,
        fiberGrams: 0,
        icon: '',
        consumed: true,
        category: MealCategory.lunch));
    appState.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text("You have reached today's target"), findsOneWidget);
    final newProtein = CalorieTarget.calculateMacros(
      200,
      appState.profile.hasWeight ? appState.profile.weightKg : null,
      appState.calorieTarget.goal,
      appState.calorieTarget.age,
    ).protein;
    expect(
        find.text(
            'Remaining today: 0 kcal · ${newProtein > 20 ? newProtein - 20 : 0} g protein'),
        findsOneWidget);
    expect(find.textContaining('Over by'), findsNothing);
    expect(
        find.descendant(
            of: find.byType(Panel), matching: find.text('Fits today')),
        findsNothing);
    appState.targetCalories = 0;
    appState.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Daily target unavailable.'), findsOneWidget);
    expect(find.text("You have reached today's target"), findsNothing);
    expect(
        find.descendant(
            of: find.byType(Panel), matching: find.text('Fits today')),
        findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Fits today'));
    await tester.pumpAndSettle();
    expect(find.text('No recipes match this filter.'), findsNothing);
    appState.activityError = 'error';
    appState.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Today’s activity is unavailable.'), findsOneWidget);
  });

  testWidgets('card and details use bundled photo and ordered steps',
      (tester) async {
    final recipe = recipes.firstWhere((r) => r.id == 'chicken_rice');
    final path = recipePhotoPath(recipe.id);
    final bundle = _PhotoBundle(path);
    MealItem? logged;
    await tester.pumpWidget(DefaultAssetBundle(
      bundle: bundle,
      child: _app(RecipesScreen(
        accountId: () => 'a',
        database: CaloriesTestDatabase(FoodDatabase()),
        recipeList: [recipe],
        saveMeal: (meal) async => logged = meal,
      )),
    ));
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).width, greaterThan(0));
    await tester.runAsync(() async {
      await precacheImage(image.image, tester.element(find.byType(Image)));
    });
    await tester.pumpAndSettle();
    expect(tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
        16 / 9);
    final card = find.byType(Panel);
    expect(find.descendant(of: card, matching: find.text('High protein')),
        findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Light')),
        findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Quick')),
        findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('High fiber')),
        findsNothing);
    await tester.ensureVisible(find.text(recipe.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(recipe.name));
    await tester.pumpAndSettle();
    expect(find.text('Photo is for illustration'), findsOneWidget);
    final detailScroll = find
        .descendant(
            of: find.byType(ListView).last, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('Ingredients'), 300,
        scrollable: detailScroll);
    final nutrition = calculateRecipeNutrition(recipe, FoodDatabase().foods)!;
    expect(find.text('${nutrition.portion.kcal} kcal'), findsOneWidget);
    expect(find.textContaining('Protein ${nutrition.portion.proteinG} g'),
        findsOneWidget);
    expect(find.textContaining('Fiber '), findsOneWidget);
    expect(find.textContaining('Sugar '), findsOneWidget);
    expect(find.textContaining('Sodium '), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.text(recipe.description), findsOneWidget);
    for (final (food, grams) in nutrition.ingredients) {
      final ingredient =
          find.text('${food.nameEn}: ${grams.toStringAsFixed(0)} g');
      await tester.scrollUntilVisible(ingredient, 200,
          scrollable: detailScroll);
      expect(ingredient, findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('How to cook'), 300,
        scrollable: detailScroll);
    expect(find.text('How to cook'), findsOneWidget);
    for (var i = 0; i < recipe.steps.length; i++) {
      expect(find.text('${i + 1}. ${recipe.steps[i]}'), findsOneWidget);
      if (i > 0) {
        expect(
            tester.getTopLeft(find.text('${i + 1}. ${recipe.steps[i]}')).dy,
            greaterThan(
                tester.getTopLeft(find.text('$i. ${recipe.steps[i - 1]}')).dy));
      }
    }
    final stepWidgets = find.byWidgetPredicate(
        (w) => w is Text && RegExp(r'^[1-3]\. ').hasMatch(w.data ?? ''));
    expect(stepWidgets, findsNWidgets(recipe.steps.length));
    await tester.scrollUntilVisible(find.text('Log'), 200,
        scrollable: detailScroll);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    expect(logged!.servingLabel, 'Recipe');
    expect(logged!.calories,
        calculateRecipeNutrition(recipe, FoodDatabase().foods)!.portion.kcal);
  });

  testWidgets('missing bundled photo uses icon without an illustration label',
      (tester) async {
    final recipe = recipes.first;
    await tester.pumpWidget(_app(RecipesScreen(
      accountId: () => 'a',
      database: CaloriesTestDatabase(FoodDatabase()),
      recipeList: [recipe],
    )));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.restaurant), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.text(recipe.name));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.restaurant), findsOneWidget);
    expect(find.text('Photo is for illustration'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('high fiber tag is based on calculated ingredient totals',
      (tester) async {
    const recipe = Recipe(
      id: 'fiber_test',
      name: 'Fiber test',
      nameAr: 'اختبار',
      minutes: 20,
      difficulty: 'Easy',
      description: 'Prepared ful.',
      ingredients: [RecipeIngredient('eg_ful_medames_plain', 200)],
      steps: ['One', 'Two', 'Three'],
      emoji: '',
      category: MealCategory.lunch,
    );
    await tester.pumpWidget(_app(RecipesScreen(
      accountId: () => 'a',
      database: CaloriesTestDatabase(FoodDatabase()),
      recipeList: const [recipe],
    )));
    await tester.pumpAndSettle();
    expect(find.text('High fiber'), findsOneWidget);
    final card = find.byType(Panel);
    expect(find.descendant(of: card, matching: find.text('High protein')),
        findsNothing);
    expect(find.text('Light'), findsOneWidget);
    expect(
        find.descendant(of: card, matching: find.text('Quick')), findsNothing);
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets('compact recipes and academy fit 360x640 at scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget scaled(Widget child) => MaterialApp(
            theme: buildTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(body: child),
          );
      await tester.pumpWidget(scaled(RecipesScreen(
          accountId: () => 'a',
          database: CaloriesTestDatabase(FoodDatabase()))));
      await tester.pumpAndSettle();
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, 10000));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Chicken and Rice Bowl'), 300,
          scrollable: find
              .descendant(
                  of: find.byType(ListView).first,
                  matching: find.byType(Scrollable))
              .first);
      await tester.tap(find.text('Chicken and Rice Bowl'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(scaled(const AcademyScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Barbell Bench Press'));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('General information, not professional advice'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('photo card and details fit 360x640 at text scale 1.5',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final recipe = recipes.first;
    await tester.pumpWidget(DefaultAssetBundle(
      bundle: _PhotoBundle(recipePhotoPath(recipe.id)),
      child: MaterialApp(
        theme: buildTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
            body: RecipesScreen(
          accountId: () => 'a',
          database: CaloriesTestDatabase(FoodDatabase()),
          recipeList: [recipe],
        )),
      ),
    ));
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    await tester.runAsync(() async {
      await precacheImage(image.image, tester.element(find.byType(Image)));
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(recipe.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(recipe.name));
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -350));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing ingredient disables logging', (tester) async {
    const missing = Recipe(
      id: 'missing',
      name: 'Missing food',
      nameAr: 'طعام',
      minutes: 1,
      difficulty: 'Easy',
      description: '',
      ingredients: [RecipeIngredient('does-not-exist', 100)],
      steps: ['One', 'Two', 'Three'],
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
    await tester.tap(find.text('Missing food'));
    await tester.pumpAndSettle();
    expect(find.text('Nutrition not available'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Log'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable))
            .first);
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

  testWidgets('academy shows activity icons and approximate burn estimates',
      (tester) async {
    await tester.pumpWidget(_app(const AcademyScreen()));
    expect(find.byIcon(Icons.fitness_center), findsWidgets);
    expect(find.text('about 120 kcal / 15 mins'), findsOneWidget);
    final scrollable = find
        .descendant(
            of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.byIcon(Icons.sports_basketball), 300,
        scrollable: scrollable);
    expect(find.byIcon(Icons.sports_basketball), findsOneWidget);
    await tester.scrollUntilVisible(find.byIcon(Icons.sports_mma), 300,
        scrollable: scrollable);
    expect(find.byIcon(Icons.sports_mma), findsOneWidget);
    await tester.scrollUntilVisible(find.byIcon(Icons.directions_run), 300,
        scrollable: scrollable);
    expect(find.byIcon(Icons.directions_run), findsOneWidget);
    expect(find.text('Lifetime Knowledge'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
    final mastered = find.text('Mastered Cue');
    await tester.scrollUntilVisible(mastered, 300,
        scrollable: find
            .descendant(
                of: find.byType(DraggableScrollableSheet),
                matching: find.byType(Scrollable))
            .first);
    await tester.ensureVisible(mastered);
    await tester.pumpAndSettle();
    await tester.tap(mastered);
    await tester.pumpAndSettle();
    expect(mastered, findsNothing);
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(mastered, 300,
        scrollable: find
            .descendant(
                of: find.byType(DraggableScrollableSheet),
                matching: find.byType(Scrollable))
            .first);
    expect(mastered, findsOneWidget);
  });
}
