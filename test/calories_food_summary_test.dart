import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/logic/fitness_logic.dart';
import 'package:privilege/models/food_item.dart';
import 'package:privilege/screens/calories_food_summary.dart';
import 'package:privilege/screens/calories_display_format.dart';
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

MealItem manual(
        {bool consumed = true,
        String id = 'manual',
        String name = 'Manual breakfast'}) =>
    MealItem(
      id: id,
      name: name,
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

  test('display formatting preserves fractional grams and distinct brands', () {
    expect(formatCaloriesGrams(200), '200');
    expect(formatCaloriesGrams(200.5), '200.5');
    expect(formatCaloriesServingLabel('Bowl (200.0g)'), 'Bowl (200 g)');
    expect(formatCaloriesServingLabel('200.5g custom'), '200.5 g custom');
    expect(formatCaloriesCategory('Egyptian', 'Egyptian'), 'Egyptian');
    expect(formatCaloriesCategory('Dairy', 'Brand'), 'Dairy • Brand');
  });

  Future<void> showSummary(WidgetTester tester, FakeCaloriesState state,
      {Brightness brightness = Brightness.dark,
      VoidCallback? onAdd,
      ValueChanged<MealItem>? onEdit,
      double width = 400,
      String language = 'en'}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CaloriesFoodSummary(
            state: state,
            database: FakeFoodDatabase(FoodDatabase().foods),
            onAdd: onAdd ?? () {},
            onEdit: onEdit,
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

  testWidgets('Arabic food log translates only exact default names',
      (tester) async {
    final state = FakeCaloriesState()
      ..meals.addAll([
        manual(name: 'High-Protein Fuel'),
        manual(id: 'renamed', name: 'High-Protein Fuel custom'),
        manual(id: 'quick', name: 'Quick Calorie Snack'),
      ]);
    addTearDown(state.dispose);
    await showSummary(tester, state, language: 'ar', width: 360);
    final l =
        AppLocalizations.of(tester.element(find.byType(CaloriesFoodSummary)))!;
    expect(find.text(l.defaultHighProteinFuel), findsOneWidget);
    expect(find.text(l.defaultQuickCalorieSnack), findsOneWidget);
    expect(find.text('High-Protein Fuel custom'), findsOneWidget);
    expect(state.meals.first.name, 'High-Protein Fuel');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'recipe labels survive duplication while manual entries stay manual',
      (tester) async {
    final state = FakeCaloriesState()
      ..meals.addAll([
        manual(),
        const MealItem(
          id: 'recipe',
          name: 'Recipe meal',
          time: 'now',
          calories: 200,
          proteinGrams: 10,
          carbsGrams: 20,
          fatGrams: 5,
          fiberGrams: 2,
          icon: '',
          consumed: true,
          category: MealCategory.breakfast,
          servingLabel: 'Recipe',
        ),
      ]);
    addTearDown(state.dispose);
    await showSummary(tester, state);
    expect(find.text('Manual entry'), findsOneWidget);
    expect(find.text('Recipe'), findsOneWidget);
    final copy = find.byTooltip('Duplicate Recipe meal');
    await tester.ensureVisible(copy);
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(state.manualCopy!.servingLabel, 'Recipe');
    expect(state.manualCopy!.source, 'manual');
  });

  testWidgets('mixed meals use saved totals in English', (tester) async {
    final state = FakeCaloriesState()..meals.addAll([manual(), foodMeal]);
    addTearDown(state.dispose);
    await showSummary(tester, state);
    expect(find.text('644'), findsOneWidget);
    expect(find.text('Sugar 4.2 g'), findsOneWidget);
    expect(find.text('Sodium 101 mg'), findsOneWidget);
    expect(find.text('Manual breakfast'), findsOneWidget);
    expect(find.text('Saved koshary'), findsOneWidget);
    final name =
        FoodDatabase().foods.firstWhere((f) => f.id == foodMeal.foodId).nameAr;
    expect(find.text(name), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic summary translates food and keeps custom text',
      (tester) async {
    final state = FakeCaloriesState()..meals.addAll([manual(), foodMeal]);
    addTearDown(state.dispose);
    await showSummary(tester, state, language: 'ar', width: 360);
    final l =
        AppLocalizations.of(tester.element(find.byType(CaloriesFoodSummary)))!;
    final arabicName =
        FoodDatabase().foods.firstWhere((f) => f.id == foodMeal.foodId).nameAr;
    expect(find.text(arabicName), findsOneWidget);
    expect(find.text('Saved koshary'), findsNothing);
    expect(find.text('Manual breakfast'), findsOneWidget);
    expect(find.text(l.foodBalance), findsOneWidget);
    expect(find.text(l.foodToday), findsOneWidget);
    expect(find.text(l.foodLabelValue(l.foodSugar, l.foodGrams('4.2'))),
        findsOneWidget);
    expect(find.text(l.foodLabelValue(l.foodSodium, l.foodMilligrams('101'))),
        findsOneWidget);
    expect(Directionality.of(tester.element(find.text(arabicName))),
        TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sodium is displayed in whole milligrams', (tester) async {
    final state = FakeCaloriesState()
      ..meals.add(foodMeal.copyWith(sodiumMg: 3600));
    addTearDown(state.dispose);
    await showSummary(tester, state);
    expect(find.text('Sodium 3600 mg'), findsOneWidget);
    expect(find.text('Sodium 3600.0 mg'), findsNothing);
  });

  testWidgets('portion labels format grams and edit action fits narrow rows',
      (tester) async {
    final state = FakeCaloriesState()
      ..meals.addAll([
        manual().copyWith(grams: 200),
        foodMeal.copyWith(clearServingLabel: true),
        foodMeal.copyWith(
            id: 'decimal', grams: 125.5, servingLabel: 'Bowl (125.5g)'),
        foodMeal.copyWith(id: 'saved-label', servingLabel: '200.0g custom'),
      ]);
    addTearDown(state.dispose);
    MealItem? edited;
    await showSummary(tester, state,
        width: 320, onEdit: (meal) => edited = meal);
    expect(find.text('200 g custom'), findsNWidgets(2));
    expect(find.text('200 g'), findsOneWidget);
    expect(find.text('Bowl (125.5 g)'), findsOneWidget);
    expect(find.byTooltip('Edit portion Manual breakfast'), findsNothing);
    final edit = find.byTooltip('Edit portion Saved koshary').first;
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    expect(tester.getSize(edit).width, greaterThanOrEqualTo(40));
    expect(tester.getSize(edit).height, greaterThanOrEqualTo(40));
    await tester.tap(edit);
    expect(edited!.id, 'food');
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
