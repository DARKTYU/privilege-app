import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/logic/food_nutrition.dart';
import 'package:privilege/models/food_item.dart';
import 'package:privilege/screens/calories_food_explorer.dart';
import 'package:privilege/screens/calories.dart';
import 'package:privilege/services/food_database.dart';
import 'package:privilege/state.dart';
import 'package:privilege/ui.dart';
import 'calories_test_database.dart';

class _FakeState extends AppState {
  FoodItem? food;
  PortionResult? portion;
  MealCategory? meal;
  String? label;
  MealItem? edited;
  double? newGrams;

  @override
  Future<void> logFood(
      FoodItem food, PortionResult portion, MealCategory mealType,
      {String? servingLabel}) async {
    this.food = food;
    this.portion = portion;
    meal = mealType;
    label = servingLabel;
  }

  @override
  Future<void> updateFoodPortion(MealItem log, double grams) async {
    edited = log;
    newGrams = grams;
    final index = meals.indexWhere((item) => item.id == log.id);
    if (index >= 0) {
      meals[index] = log.copyWith(grams: grams, clearServingLabel: true);
      notifyListeners();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => FoodDatabase().load());

  Future<void> setup(WidgetTester tester, _FakeState state,
      {String language = 'en', Size size = const Size(400, 900)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(),
      home: FoodExplorerPage(
          state: state,
          onManual: () {},
          database: CaloriesTestDatabase(FoodDatabase())),
    ));
    await tester.pumpAndSettle();
  }

  test('explorer has no hardcoded UI labels', () {
    final source =
        File('lib/screens/calories_food_explorer.dart').readAsStringSync();
    expect(source, isNot(contains(RegExp(r'[\u0600-\u06ff]'))));
    expect(
        RegExp(r"""(?:Text\(\s*(?:const\s*)?|(?:labelText|hintText|helperText|tooltip|semanticLabel)\s*:\s*)['"]""")
            .allMatches(source),
        isEmpty);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('localized explorer and portions fit at 360 in $language',
        (tester) async {
      final state = _FakeState();
      addTearDown(state.dispose);
      await setup(tester, state,
          language: language, size: const Size(360, 640));
      final context = tester.element(find.byType(FoodExplorerPage));
      final l = AppLocalizations.of(context)!;
      expect(find.text(l.foodAdd), findsOneWidget);
      expect(find.text(l.tagProtein), findsOneWidget);
      expect(find.text(l.groupEgyptian), findsWidgets);
      await tester.enterText(find.byKey(const ValueKey('food-search')), 'كشري');
      await tester.pumpAndSettle();
      final food = FoodDatabase().search('koshary').first;
      final name = language == 'ar' ? food.nameAr : food.nameEn;
      expect(find.text(name), findsWidgets);
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
      expect(find.text(l.explorerPortions), findsOneWidget);
      expect(find.text(l.explorerStandard), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('portion-grams')));
      await tester.enterText(
          find.byKey(const ValueKey('portion-grams')), '200');
      await tester.ensureVisible(find.text(l.explorerAdd));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.explorerAdd));
      await tester.pumpAndSettle();
      expect(state.portion!.grams, 200);
      expect(state.label, '200g custom');
      expect(find.text(l.explorerLogged(name, state.portion!.kcal)),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English and Arabic search and category and tag filtering',
      (tester) async {
    final state = _FakeState();
    addTearDown(state.dispose);
    await setup(tester, state);
    final input = find.byKey(const ValueKey('food-search'));
    await tester.enterText(input, 'koshary');
    await tester.pumpAndSettle();
    expect(find.textContaining('Koshary'), findsWidgets);
    await tester.enterText(input, 'كشري');
    await tester.pumpAndSettle();
    expect(find.textContaining('Koshary'), findsWidgets);
    expect(tester.widget<TextField>(input).textDirection, TextDirection.rtl);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    final group = FoodDatabase().categoryGroups.first;
    await tester.tap(find.text(group).first);
    await tester.pumpAndSettle();
    final count = FoodDatabase().search('', categoryGroup: group).length;
    expect(find.text('Showing $count of 275'), findsOneWidget);
    await tester.tap(find.text('High Protein').first);
    await tester.pumpAndSettle();
    final filtered = FoodDatabase()
        .search('', categoryGroup: group, tags: ['high-protein']).length;
    expect(find.text('Showing $filtered of 275'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic cuisine appears on cards and details and is searchable',
      (tester) async {
    final state = _FakeState();
    addTearDown(state.dispose);
    await setup(tester, state, language: 'ar', size: const Size(360, 640));
    final input = find.byKey(const ValueKey('food-search'));
    await tester.enterText(input, 'مشويات أمريكية');
    await tester.pumpAndSettle();
    final food = FoodDatabase().search('American BBQ').first;
    expect(find.text(food.nameAr), findsWidgets);
    expect(find.textContaining('مشويات أمريكية'), findsWidgets);
    await tester.tap(find.text(food.nameAr).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('مشويات أمريكية'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic activity log translates default workouts only',
      (tester) async {
    final state = _FakeState()
      ..burns.addAll([
        const BurnItem(
            id: 'a',
            title: 'Athletic Training',
            time: 'now',
            calories: 100,
            type: BurnType.cardio,
            durationMin: 10,
            icon: ''),
        const BurnItem(
            id: 'b',
            title: 'Athletic Training custom',
            time: 'now',
            calories: 100,
            type: BurnType.cardio,
            durationMin: 10,
            icon: ''),
        const BurnItem(
            id: 'c',
            title: 'Quick Exercise Burn',
            time: 'now',
            calories: 100,
            type: BurnType.cardio,
            durationMin: 10,
            icon: ''),
      ]);
    addTearDown(state.dispose);
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(),
      home: Scaffold(body: ActivityTab(state: state)),
    ));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(ActivityTab)))!;
    await tester.scrollUntilVisible(find.text(l.defaultAthleticTraining), 200);
    expect(find.text(l.defaultAthleticTraining), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Athletic Training custom'), 200);
    expect(find.text('Athletic Training custom'), findsOneWidget);
    await tester.scrollUntilVisible(find.text(l.defaultQuickExerciseBurn), 200);
    expect(find.text(l.defaultQuickExerciseBurn), findsOneWidget);
    expect(state.burns.first.title, 'Athletic Training');
    expect(tester.takeException(), isNull);
  });

  testWidgets('presets, field, slider, preview and confirm use food math',
      (tester) async {
    final state = _FakeState();
    addTearDown(state.dispose);
    await setup(tester, state);
    await tester.enterText(
        find.byKey(const ValueKey('food-search')), 'koshary');
    await tester.pumpAndSettle();
    final food = FoodDatabase().search('koshary').first;
    expect(food.categoryGroup, food.cuisineOrBrand);
    expect(find.text('${food.categoryGroup} • ${food.cuisineOrBrand}'),
        findsNothing);
    await tester.tap(find.text(food.nameEn).first);
    await tester.pumpAndSettle();
    expect(find.text('${food.categoryGroup} • ${food.cuisineOrBrand}'),
        findsNothing);
    expect(find.text(food.categoryGroup), findsWidgets);
    final input = find.byKey(const ValueKey('portion-grams'));
    expect(
        tester.widget<TextField>(input).controller!.text,
        food.servings.first.grams
            .toStringAsFixed(food.servings.first.grams % 1 == 0 ? 0 : 1));
    await tester.tap(find.text('100 g standard reference'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).controller!.text, '100');
    await tester.ensureVisible(input);
    await tester.pumpAndSettle();
    await tester.enterText(input, '200');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Slider>(find.byKey(const ValueKey('portion-slider')))
            .value,
        200);
    final expected = calculateFoodPortion(food.per100g, 200);
    expect(find.text('${expected.kcal}'), findsOneWidget);
    final protein = expected.proteinG == expected.proteinG.roundToDouble()
        ? expected.proteinG.toStringAsFixed(0)
        : expected.proteinG.toStringAsFixed(1);
    expect(find.text('$protein g'), findsOneWidget);
    expect(find.text('Sodium: ${expected.sodiumMg.toStringAsFixed(0)} mg'),
        findsOneWidget);
    final slider = find.byKey(const ValueKey('portion-slider'));
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    tester.widget<Slider>(slider).onChanged!(250);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).controller!.text, '250');
    await tester.enterText(input, '200');
    await tester.pumpAndSettle();
    final confirm = find.text('+ Add to Daily Log');
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(state.food!.id, food.id);
    expect(state.portion!.kcal, expected.kcal);
    expect(state.portion!.grams, 200);
    expect(state.meal, MealCategory.lunch);
    expect(state.label, '200g custom');
    expect(find.text('Logged ${food.nameEn} (${expected.kcal} kcal)'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('food-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'editing a food log opens sheet and saves through updateFoodPortion',
      (tester) async {
    final food = FoodDatabase()
        .foods
        .firstWhere((f) => f.id == 'eg_koshary_traditional');
    final state = _FakeState();
    addTearDown(state.dispose);
    final log = MealItem(
      id: 'existing',
      name: food.nameEn,
      time: 'now',
      calories: 344,
      proteinGrams: 11,
      carbsGrams: 57,
      fatGrams: 8,
      fiberGrams: 6,
      icon: '🍽️',
      consumed: true,
      category: MealCategory.dinner,
      source: 'food_db',
      foodId: food.id,
      grams: 200,
    );
    state.meals.add(log);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
            body: CaloriesSection(
                state: state,
                database: CaloriesTestDatabase(FoodDatabase())))));
    await tester.pumpAndSettle();
    final row = find.byTooltip('Edit portion ${food.nameEn}');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Save changes'), findsOneWidget);
    final dinner =
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Dinner'));
    expect(dinner.selected, isTrue);
    expect(dinner.onSelected, isNull);
    final input = find.byKey(const ValueKey('portion-grams'));
    await tester.ensureVisible(input);
    await tester.pumpAndSettle();
    await tester.enterText(input, '250');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(state.edited, same(log));
    expect(state.newGrams, 250);
    expect(find.text('250 g custom'), findsOneWidget);
    await tester.ensureVisible(find.text(food.nameEn));
    await tester.tap(find.text(food.nameEn));
    await tester.pumpAndSettle();
    expect(find.text('Save changes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing bundled food is reported without changing the log',
      (tester) async {
    final state = _FakeState()
      ..meals.add(const MealItem(
          id: 'missing',
          name: 'Missing food',
          time: 'now',
          calories: 100,
          proteinGrams: 1,
          carbsGrams: 2,
          fatGrams: 3,
          fiberGrams: 1,
          icon: '🍽️',
          consumed: true,
          category: MealCategory.lunch,
          source: 'food_db',
          foodId: 'not-in-bundle',
          grams: 100));
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
            body: CaloriesSection(
                state: state,
                database: CaloriesTestDatabase(FoodDatabase())))));
    await tester.pumpAndSettle();
    final item = find.text('Missing food');
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
    expect(find.textContaining('no longer available'), findsOneWidget);
    expect(state.edited, isNull);
    expect(state.meals.single.grams, 100);
  });

  testWidgets('invalid grams are blocked and breakfast uses preset label',
      (tester) async {
    final state = _FakeState();
    addTearDown(state.dispose);
    await setup(tester, state);
    final food = FoodDatabase().foods.firstWhere(
        (food) => food.tags.contains('breakfast') && food.servings.isNotEmpty);
    await tester.enterText(
        find.byKey(const ValueKey('food-search')), food.nameEn);
    await tester.pumpAndSettle();
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('+ Log').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Log').first);
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey('portion-grams'));
    await tester.ensureVisible(input);
    await tester.pumpAndSettle();
    await tester.enterText(input, '3001');
    await tester.pumpAndSettle();
    final confirm = find.text('+ Add to Daily Log');
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.text('Enter a weight between 1 and 3000 g.'), findsOneWidget);
    expect(state.food, isNull);
    await tester.ensureVisible(find.text(food.servings.first.nameEn).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(food.servings.first.nameEn).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    final serving = food.servings.first;
    final g = serving.grams == serving.grams.roundToDouble()
        ? serving.grams.toStringAsFixed(0)
        : serving.grams.toStringAsFixed(1);
    expect(state.label, '${serving.nameEn} (${g}g)');
    expect(state.meal, MealCategory.breakfast);
  });
}
