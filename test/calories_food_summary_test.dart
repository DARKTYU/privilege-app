import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/models/food_item.dart';
import 'package:privilege/screens/calories_food_summary.dart';
import 'package:privilege/services/food_database.dart';
import 'package:privilege/state.dart';
import 'package:privilege/theme_settings.dart';
import 'package:privilege/ui.dart';

class FakeCaloriesState extends AppState {
  MealItem? manualCopy;
  FoodItem? copiedFood;
  PortionResult? copiedPortion;
  MealCategory? copiedCategory;
  String? copiedLabel;
  String? deleted;
  bool failDelete = false;

  @override
  Future<void> addMeal(MealItem item) async {
    manualCopy = item;
  }

  @override
  Future<void> logFood(
      FoodItem food, PortionResult portion, MealCategory mealType,
      {String? servingLabel}) async {
    copiedFood = food;
    copiedPortion = portion;
    copiedCategory = mealType;
    copiedLabel = servingLabel;
  }

  @override
  Future<void> removeMeal(String id) async {
    if (failDelete) throw StateError('failed');
    deleted = id;
    meals.removeWhere((meal) => meal.id == id);
    notifyListeners();
  }

  @override
  Future<void> toggleMeal(String id) async {
    final index = meals.indexWhere((meal) => meal.id == id);
    meals[index] = meals[index].copyWith(consumed: !meals[index].consumed);
    notifyListeners();
  }
}

class FakeFoodDatabase extends FoodDatabase {
  FakeFoodDatabase(this.items) : super.withBundle(rootBundle);
  final List<FoodItem> items;

  @override
  Future<void> load() async {}

  @override
  List<FoodItem> get foods => items;
}

MealItem manual({bool consumed = true}) => MealItem(
      id: 'manual',
      name: 'Manual breakfast',
      time: 'now',
      calories: 300,
      proteinGrams: 20,
      carbsGrams: 30,
      fatGrams: 10,
      fiberGrams: 4,
      icon: '🍽️',
      consumed: consumed,
      category: MealCategory.breakfast,
    );

const foodMeal = MealItem(
  id: 'food',
  name: 'Saved koshary',
  time: 'now',
  calories: 344,
  proteinGrams: 11,
  carbsGrams: 57,
  fatGrams: 8,
  fiberGrams: 6,
  icon: '🍽️',
  consumed: true,
  category: MealCategory.lunch,
  foodId: 'eg_koshary_traditional',
  grams: 200,
  servingLabel: 'Two bowls',
  sugarG: 4.2,
  sodiumMg: 100.5,
  source: 'food_db',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => FoodDatabase().load());

  Future<void> showSummary(WidgetTester tester, FakeCaloriesState state,
      {Brightness brightness = Brightness.dark, VoidCallback? onAdd}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CaloriesFoodSummary(
            state: state,
            database: FakeFoodDatabase(FoodDatabase().foods),
            onAdd: onAdd ?? () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('empty state and add food callback', (tester) async {
    final state = FakeCaloriesState();
    addTearDown(state.dispose);
    var added = false;
    await showSummary(tester, state, onAdd: () => added = true);
    expect(find.text('Your daily log is empty'), findsOneWidget);
    await tester.ensureVisible(find.text('Add food'));
    await tester.tap(find.text('Add food'));
    expect(added, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mixed meals use saved totals and Arabic is RTL', (tester) async {
    final state = FakeCaloriesState()..meals.addAll([manual(), foodMeal]);
    addTearDown(state.dispose);
    await showSummary(tester, state);
    expect(find.text('644'), findsOneWidget);
    expect(find.text('Sugar 4.2 g'), findsOneWidget);
    expect(find.text('Sodium 100.5 mg'), findsOneWidget);
    expect(find.text('Manual breakfast'), findsOneWidget);
    expect(find.text('Saved koshary'), findsOneWidget);
    final name =
        FoodDatabase().foods.firstWhere((f) => f.id == foodMeal.foodId).nameAr;
    final text = tester.widget<Text>(find.text(name));
    expect(text.textDirection, TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('over target colors ring and remaining text', (tester) async {
    final state = FakeCaloriesState()
      ..targetCalories = 100
      ..meals.add(manual());
    addTearDown(state.dispose);
    await showSummary(tester, state);
    final remaining =
        tester.widget<Text>(find.byKey(const ValueKey('calories-remaining')));
    expect(remaining.style!.color, CaloriesPalette.over);
    expect(find.text('kcal over'), findsOneWidget);
    final ring = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<CaloriesEnergyRingPainter>()
        .single;
    expect(ring.color, CaloriesPalette.over);
    expect(ring.progress, 1);
  });

  testWidgets('meal tabs filter and unchecked meals do not count',
      (tester) async {
    final state = FakeCaloriesState()
      ..meals.addAll([manual(consumed: false), foodMeal]);
    addTearDown(state.dispose);
    await showSummary(tester, state);
    expect(find.text('344'), findsOneWidget);
    expect(find.text('Manual breakfast'), findsOneWidget);
    await tester.tap(find.text('Lunch').first);
    await tester.pumpAndSettle();
    expect(find.text('Manual breakfast'), findsNothing);
    expect(find.text('Saved koshary'), findsOneWidget);
    await tester.tap(find.text('Breakfast').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('644'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicates saved food snapshot and manual meal', (tester) async {
    final state = FakeCaloriesState()..meals.addAll([manual(), foodMeal]);
    addTearDown(state.dispose);
    await showSummary(tester, state);
    final foodButton = find.byTooltip('Duplicate Saved koshary');
    await tester.ensureVisible(foodButton);
    await tester.tap(foodButton);
    await tester.pumpAndSettle();
    expect(state.copiedFood!.id, foodMeal.foodId);
    expect(state.copiedPortion!.grams, 200);
    expect(state.copiedPortion!.kcal, 344);
    expect(state.copiedPortion!.proteinG, 11);
    expect(state.copiedPortion!.sodiumMg, 100.5);
    expect(state.copiedCategory, MealCategory.lunch);
    expect(state.copiedLabel, 'Two bowls');
    expect(find.text('Food duplicated.'), findsOneWidget);
    final manualButton = find.byTooltip('Duplicate Manual breakfast');
    await tester.ensureVisible(manualButton);
    await tester.tap(manualButton);
    await tester.pumpAndSettle();
    expect(state.manualCopy!.id, '');
    expect(state.manualCopy!.calories, 300);
  });

  testWidgets('delete reports errors and then deletes', (tester) async {
    final state = FakeCaloriesState()
      ..meals.add(manual())
      ..failDelete = true;
    addTearDown(state.dispose);
    await showSummary(tester, state);
    final button = find.byTooltip('Delete Manual breakfast');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not delete food'), findsOneWidget);
    expect(state.meals.length, 1);
    state.failDelete = false;
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(state.deleted, 'manual');
    expect(find.text('Food deleted.'), findsOneWidget);
  });

  testWidgets('missing bundled food cannot be duplicated', (tester) async {
    final state = FakeCaloriesState()..meals.add(foodMeal);
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CaloriesFoodSummary(
            state: state,
            database: FakeFoodDatabase(const []),
            onAdd: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final button = find.byTooltip('Duplicate Saved koshary');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.textContaining('no longer available to duplicate'),
        findsOneWidget);
    expect(state.copiedFood, isNull);
  });

  testWidgets('light palette renders without overflow', (tester) async {
    final state = FakeCaloriesState()..meals.add(foodMeal);
    addTearDown(state.dispose);
    await showSummary(tester, state, brightness: Brightness.light);
    expect(find.text('Saved koshary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all theme presets and light variants render with themed accents',
      (tester) async {
    final state = FakeCaloriesState()..meals.add(foodMeal);
    addTearDown(state.dispose);
    for (final preset in AppThemePreset.values) {
      for (final brightness in Brightness.values) {
        final theme = brightness == Brightness.dark
            ? buildTheme(preset)
            : ThemeData(
                brightness: brightness,
                colorScheme: ColorScheme.fromSeed(
                    seedColor: preset.primary, brightness: brightness),
              );
        final palette = CaloriesPalette(theme);
        double contrast(Color a, Color b) {
          final l1 = a.computeLuminance();
          final l2 = b.computeLuminance();
          return (l1 > l2 ? l1 + .05 : l2 + .05) /
              (l1 > l2 ? l2 + .05 : l1 + .05);
        }

        expect(contrast(palette.text, palette.card), greaterThanOrEqualTo(4.5));
        expect(
            contrast(palette.muted, palette.card), greaterThanOrEqualTo(4.5));
        expect(contrast(palette.accentText, palette.card),
            greaterThanOrEqualTo(4.5));
        expect(contrast(palette.accentText, palette.inner),
            greaterThanOrEqualTo(4.5));
        expect(contrast(palette.onAccent, palette.accent),
            greaterThanOrEqualTo(4.5));
        expect(contrast(CaloriesPalette.over, palette.overBackground),
            greaterThanOrEqualTo(4.5));
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CaloriesFoodSummary(
                state: state,
                database: FakeFoodDatabase(FoodDatabase().foods),
                onAdd: () {},
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        final ring = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((paint) => paint.painter)
            .whereType<CaloriesEnergyRingPainter>()
            .single;
        expect(ring.color, theme.colorScheme.secondary);
        expect(tester.takeException(), isNull,
            reason: '${preset.label} $brightness');
      }
    }
  });
}
