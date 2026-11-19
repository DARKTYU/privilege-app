import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/screens/calories.dart';
import 'package:privilege/services/food_database.dart';
import 'package:privilege/state.dart';
import 'package:privilege/theme_settings.dart';
import 'package:privilege/ui.dart';
import 'calories_test_database.dart';

class _FakeState extends AppState {
  @override
  Future<void> toggleMeal(String id) async {
    final index = meals.indexWhere((meal) => meal.id == id);
    meals[index] = meals[index].copyWith(consumed: !meals[index].consumed);
    notifyListeners();
  }
}

const _meal = MealItem(
  id: 'meal',
  name: 'Test breakfast',
  time: 'now',
  calories: 300,
  proteinGrams: 20,
  carbsGrams: 30,
  fatGrams: 10,
  fiberGrams: 4,
  icon: '🍽️',
  consumed: true,
  category: MealCategory.breakfast,
);

const _strength = BurnItem(
  id: 'strength',
  title: 'Test strength workout',
  time: 'now',
  calories: 150,
  type: BurnType.strength,
  durationMin: 30,
  icon: '🏋️',
);

const _cardio = BurnItem(
  id: 'cardio',
  title: 'Test cardio workout',
  time: 'now',
  calories: 75,
  type: BurnType.cardio,
  durationMin: 20,
  icon: '⚡',
);

const _zeroBurn = BurnItem(
  id: 'zero',
  title: 'Zero workout',
  time: 'now',
  calories: 0,
  type: BurnType.cardio,
  durationMin: 1,
  icon: '⚡',
);

const _mobility = BurnItem(
  id: 'mobility',
  title: 'Mobility session',
  time: 'now',
  calories: 50,
  type: BurnType.mobility,
  durationMin: 20,
  icon: '🧘',
);

const _snack = MealItem(
  id: 'snack',
  name: 'Last snack',
  time: 'now',
  calories: 100,
  proteinGrams: 2,
  carbsGrams: 3,
  fatGrams: 4,
  fiberGrams: 1,
  icon: '🍽️',
  consumed: true,
  category: MealCategory.snack,
);

void main() {
  setUpAll(() async => FoodDatabase().load());
  testWidgets('Calories screen renders in every preset and light variant',
      (tester) async {
    final previous = themeSettings.selected;
    final state = _FakeState();
    addTearDown(state.dispose);
    addTearDown(() => themeSettings.selected = previous);
    for (final preset in AppThemePreset.values) {
      themeSettings.selected = preset;
      for (final brightness in Brightness.values) {
        final theme = brightness == Brightness.dark
            ? buildTheme(preset)
            : ThemeData(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: preset.primary, brightness: brightness),
              );
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(body: CaloriesSection(state: state)),
        ));
        await tester.pumpAndSettle();
        expect(find.text("Today's Food Log"), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: '${preset.label} $brightness');
      }
    }
  });

  testWidgets('a food-only day shows the empty workout state', (tester) async {
    final state = _FakeState()..meals.add(_meal);
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(body: ActivityTab(state: state)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No workouts logged today yet.'), findsOneWidget);
    expect(find.text('Test breakfast'), findsNothing);
    expect(find.textContaining('meal'), findsNothing);
  });

  testWidgets('food log opens first and Add food is above the quick links',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = _FakeState()..meals.add(_meal);
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body: Column(children: [
          const SizedBox(height: 48),
          Expanded(
              child: CaloriesSection(
                  state: state,
                  database: CaloriesTestDatabase(FoodDatabase()))),
          const SizedBox(key: ValueKey('quick-links'), height: 80),
        ]),
        bottomNavigationBar: const SizedBox(height: 64),
      ),
    ));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TabBar>(find.byType(TabBar))
            .tabs
            .map((tab) => (tab as Tab).text),
        ['Food Log', 'Activity']);
    expect(find.text('Meals, macros & activity'), findsOneWidget);
    expect(find.text('Activity Rings & Workouts'), findsNothing);
    final button = find.text('Add food');
    final summary = find.text('DAILY ENERGY BALANCE');
    final log = find.text("Today's Food Log");
    expect(tester.getTopLeft(button).dy,
        greaterThan(tester.getTopLeft(summary).dy));
    expect(
        tester.getBottomLeft(button).dy, lessThan(tester.getTopLeft(log).dy));
    expect(
        tester.getBottomLeft(button).dy,
        lessThan(
            tester.getTopLeft(find.byKey(const ValueKey('quick-links'))).dy -
                8));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Add food'), findsWidgets);
    await tester.tap(find.text("Can't find it? Quick add manually"));
    await tester.pumpAndSettle();
    expect(find.text('Log Nutrition or Workout Burn'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '0');
    await tester.ensureVisible(find.text('Save activity'));
    await tester.tap(find.text('Save activity'));
    await tester.pumpAndSettle();
    final error = tester
        .widget<Text>(find.text('Enter a calorie amount greater than zero.'));
    expect(error.style?.color, buildTheme().colorScheme.error);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add food is visible without scrolling on a 360x640 phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = _FakeState();
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Column(children: [
            const SizedBox(height: 48),
            Expanded(child: CaloriesSection(state: state)),
            const SizedBox(key: ValueKey('quick-links'), height: 80),
          ]),
        ),
        bottomNavigationBar: const SizedBox(height: 64),
      ),
    ));
    await tester.pumpAndSettle();
    expect(
        tester.getBottomLeft(find.byKey(const ValueKey('add-food-button'))).dy,
        lessThan(
            tester.getTopLeft(find.byKey(const ValueKey('quick-links'))).dy -
                8));
    expect(find.text('Add food').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity shows only burn rings and retains workout data',
      (tester) async {
    final state = _FakeState()
      ..meals.add(_meal)
      ..burns.addAll([_strength, _cardio, _zeroBurn, _mobility]);
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(body: CaloriesSection(state: state)),
    ));
    await tester.pumpAndSettle();
    final checkbox = find.byType(Checkbox);
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(state.totals.totalMealCalories, 0);
    expect(
        tester
            .widget<Opacity>(find
                .ancestor(of: checkbox, matching: find.byType(Opacity))
                .first)
            .opacity,
        .6);
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Test breakfast'), findsNothing);
    expect(find.text('Total burn (275 kcal)'), findsOneWidget);
    expect(find.text('Strength burn (150 kcal)'), findsOneWidget);
    expect(find.text('Cardio burn (75 kcal)'), findsOneWidget);
    var ring = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<RingsPainter>()
        .single;
    expect(ring.outer, 275 / state.targetBurn);
    expect(ring.middle, 150 / state.targetBurn);
    expect(ring.inner, 75 / state.targetBurn);
    expect(find.text('Calories Consumed'), findsNothing);
    expect(find.textContaining('Food Intake'), findsNothing);
    expect(find.textContaining('Balance vs BMR'), findsNothing);
    expect(find.byTooltip('About the balance'), findsNothing);
    expect(find.byTooltip('Log meal or burn'), findsNothing);
    expect(find.textContaining('well below your daily target'), findsNothing);
    expect(find.text('Log workout'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Strength Burn'), 250,
        scrollable: find
            .descendant(
                of: find.byType(ActivityTab), matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    expect(find.text('Strength Burn'), findsOneWidget);
    expect(find.text('Cardio Burn'), findsOneWidget);
    expect(find.text('Deficit Goal'), findsNothing);
    expect(find.text('150 kcal'), findsOneWidget);
    expect(find.text('75 kcal'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Test cardio workout'), 250,
        scrollable: find
            .descendant(
                of: find.byType(ActivityTab), matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    expect(find.text('Test cardio workout'), findsOneWidget);
    expect(find.text('150 kcal burned'), findsOneWidget);
    expect(find.text('75 kcal burned'), findsOneWidget);
    expect(find.text('0 kcal burned'), findsOneWidget);
    expect(find.text('-0 kcal'), findsNothing);
    expect(find.text('kcal Consumed'), findsNothing);
    expect(find.text('Active Meals & Burn Logs'), findsNothing);
    await tester.tap(find.text('Food Log'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Total burn (275 kcal)'), findsOneWidget);
    ring = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<RingsPainter>()
        .single;
    expect(ring.outer, 275 / state.targetBurn);
    expect(ring.middle, 150 / state.targetBurn);
    expect(ring.inner, 75 / state.targetBurn);
    expect(tester.takeException(), isNull);
  });

  testWidgets('burn cards and workout button render in every theme',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previous = themeSettings.selected;
    addTearDown(() => themeSettings.selected = previous);
    final state = _FakeState()
      ..meals.add(_meal)
      ..burns.add(_strength);
    addTearDown(state.dispose);
    for (final preset in AppThemePreset.values) {
      themeSettings.selected = preset;
      for (final brightness in Brightness.values) {
        final theme = brightness == Brightness.dark
            ? buildTheme(preset)
            : ThemeData(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: preset.primary, brightness: brightness),
              );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(body: ActivityTab(state: state)),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining('Daily burn goal'), findsOneWidget);
        expect(
            find.text('Each ring uses the daily burn goal.'), findsOneWidget);
        expect(find.text('Strength burn (150 kcal)'), findsOneWidget);
        expect(find.textContaining('Food Intake'), findsNothing);
        expect(find.textContaining('Balance vs BMR'), findsNothing);
        final button = find.widgetWithText(FilledButton, 'Log workout');
        expect(button, findsOneWidget);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull,
            reason: '${preset.label} $brightness');
      }
    }
  });

  testWidgets('last food and workout entries scroll above the quick links',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = _FakeState()
      ..meals.addAll([_meal, _snack])
      ..burns.addAll([_strength, _cardio]);
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body: Column(children: [
          const SizedBox(height: 48),
          Expanded(child: CaloriesSection(state: state)),
          const SizedBox(key: ValueKey('quick-links'), height: 80),
        ]),
        bottomNavigationBar: const SizedBox(height: 64),
      ),
    ));
    await tester.pumpAndSettle();
    final quickLinks = find.byKey(const ValueKey('quick-links'));
    final lastFoodAction = find.byTooltip('Delete Last snack');
    await tester.ensureVisible(lastFoodAction);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(lastFoodAction).dy,
        lessThan(tester.getTopLeft(quickLinks).dy));
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    final lastWorkout = find.byTooltip('Delete Test cardio workout');
    await tester.scrollUntilVisible(lastWorkout, 250,
        scrollable: find
            .descendant(
                of: find.byType(ActivityTab), matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(lastWorkout).dy,
        lessThan(tester.getTopLeft(quickLinks).dy));
    expect(tester.takeException(), isNull);
  });
}
