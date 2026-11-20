import 'package:flutter/material.dart';

import '../l10n_strings.dart';
import '../logic/fitness_logic.dart';
import '../logic/food_nutrition.dart';
import '../models/food_item.dart';
import '../services/food_database.dart';
import '../state.dart';
import 'calories_display_format.dart';
import 'calories_food_summary.dart';

String _groupName(BuildContext context, String group) {
  final l = strings(context);
  return switch (group) {
    'American & Latin' => l.groupAmerican,
    'Asian' => l.groupAsian,
    'Cafes & Bakeries' => l.groupCafes,
    'Egyptian' => l.groupEgyptian,
    'European' => l.groupEuropean,
    'Middle Eastern & African' => l.groupMiddleEastern,
    'Raw & Fitness Staples' => l.groupRaw,
    'Restaurants & Fast Food' => l.groupRestaurants,
    'Snacks' => l.groupSnacks,
    _ => group,
  };
}

String _tagName(BuildContext context, String tag) {
  final l = strings(context);
  return switch (tag) {
    'high-protein' => l.tagProtein,
    'fitness-staple' => l.tagFitness,
    'breakfast' => l.foodBreakfast,
    'street-food' => l.tagStreet,
    'vegan' => l.tagVegan,
    'keto-friendly' => l.tagKeto,
    'low-carb' => l.tagLowCarb,
    'cooking-oil' => l.tagOils,
    'topping' => l.tagToppings,
    'snack' => l.foodSnacks,
    'dessert' => l.tagDesserts,
    'raw' => l.tagRaw,
    'cooked' => l.tagCooked,
    _ => tag,
  };
}

String _foodName(BuildContext context, FoodItem food) =>
    Localizations.localeOf(context).languageCode == 'ar'
        ? food.nameAr
        : food.nameEn;

class FoodExplorerPage extends StatefulWidget {
  const FoodExplorerPage({
    super.key,
    required this.state,
    required this.onManual,
    this.database,
  });
  final AppState state;
  final VoidCallback onManual;
  final FoodDatabase? database;

  @override
  State<FoodExplorerPage> createState() => _FoodExplorerPageState();
}

class _FoodExplorerPageState extends State<FoodExplorerPage> {
  late final database = widget.database ?? FoodDatabase();
  late Future<void> loading = database.load();
  final query = TextEditingController();
  final tags = <String>{};
  String? category;

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = CaloriesPalette(Theme.of(context));
    final l = strings(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: Text(l.foodAdd)),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: loading,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(l.explorerLoadError),
                TextButton(
                    onPressed: () => setState(() => loading = database.load()),
                    child: Text(l.plannerRetry)),
                TextButton(
                    onPressed: widget.onManual, child: Text(l.explorerManual)),
              ]));
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final results = database.search(query.text,
                categoryGroup: category, tags: tags);
            final availableTags =
                database.foods.expand((food) => food.tags).toSet();
            const choices = [
              'high-protein',
              'fitness-staple',
              'breakfast',
              'street-food',
              'vegan',
              'keto-friendly',
              'low-carb',
              'cooking-oil',
              'topping',
              'snack',
              'dessert',
              'raw',
              'cooked',
            ];
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  key: const ValueKey('food-search'),
                  controller: query,
                  textDirection: query.text.isEmpty
                      ? Directionality.of(context)
                      : foodNameDirection(query.text),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l.explorerSearch,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: l.explorerClear,
                      onPressed: () => setState(query.clear),
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                ),
              ),
              SizedBox(
                  height: 52,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filter(p, l.foodAll, category == null,
                          () => setState(() => category = null)),
                      for (final group in database.categoryGroups)
                        _filter(
                            p,
                            _groupName(context, group),
                            category == group,
                            () => setState(() => category = group)),
                    ],
                  )),
              SizedBox(
                  height: 52,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final choice in choices)
                        if (availableTags.contains(choice))
                          _filter(
                              p,
                              _tagName(context, choice),
                              tags.contains(choice),
                              () => setState(() {
                                    if (!tags.add(choice)) {
                                      tags.remove(choice);
                                    }
                                  })),
                    ],
                  )),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                        l.explorerShowing(results.length.toString(),
                            database.foods.length.toString()),
                        style: TextStyle(color: p.muted))),
              ),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(l.explorerEmpty, style: TextStyle(color: p.text)),
                        Text(l.explorerEmptyHint,
                            style: TextStyle(color: p.muted)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: results.length,
                        itemBuilder: (context, index) =>
                            _foodCard(context, p, results[index]),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Column(children: [
                  Text(l.explorerDisclaimer,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.muted, fontSize: 11)),
                  TextButton(
                    onPressed: widget.onManual,
                    child: Text(l.explorerManual),
                  ),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _filter(
          CaloriesPalette p, String label, bool selected, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 6),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          selectedColor: p.accent.withAlpha(55),
          checkmarkColor: p.accentText,
          onSelected: (_) => onTap(),
        ),
      );

  Widget _foodCard(BuildContext context, CaloriesPalette p, FoodItem food) {
    final l = strings(context);
    final serving = food.servings.isEmpty ? null : food.servings.first;
    final grams = serving?.grams ?? 100.0;
    final portion = calculateFoodPortion(food.per100g, grams);
    final servingName = serving == null
        ? l.explorerStandard
        : (Localizations.localeOf(context).languageCode == 'ar'
            ? serving.nameAr
            : serving.nameEn);
    return Card(
      color: p.card,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showFoodPortionSheet(context, widget.state, food),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      formatCaloriesCategory(
                          _groupName(context, food.categoryGroup),
                          food.categoryGroup == food.cuisineOrBrand
                              ? ''
                              : food.cuisineOrBrand),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.accentText, fontSize: 10)),
                  Text(_foodName(context, food),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: p.text, fontWeight: FontWeight.bold)),
                  Wrap(spacing: 5, children: [
                    Text(l.explorerPer100(food.per100g.kcal.toStringAsFixed(0)),
                        style: TextStyle(color: p.muted, fontSize: 10)),
                    _macroDot(
                        p,
                        CaloriesPalette.protein,
                        l.foodProteinShort(
                            formatCaloriesGrams(food.per100g.proteinG))),
                    _macroDot(
                        p,
                        CaloriesPalette.carbs,
                        l.foodCarbsShort(
                            formatCaloriesGrams(food.per100g.carbsG))),
                    _macroDot(
                        p,
                        CaloriesPalette.fat,
                        l.foodFatsShort(
                            formatCaloriesGrams(food.per100g.fatG))),
                  ]),
                ])),
            const SizedBox(width: 8),
            SizedBox(
                width: 100,
                child: Column(children: [
                  Text(l.mergeCalories(portion.kcal.toString()),
                      style: TextStyle(
                          color: p.accentText, fontWeight: FontWeight.bold)),
                  Text(
                      l.foodServing(
                          servingName, l.foodGrams(formatCaloriesGrams(grams))),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.muted, fontSize: 10)),
                  TextButton(
                    style: TextButton.styleFrom(
                        minimumSize: const Size(40, 40),
                        foregroundColor: p.accentText),
                    onPressed: () =>
                        showFoodPortionSheet(context, widget.state, food),
                    child: Text(l.explorerLog),
                  ),
                ])),
          ]),
        ),
      ),
    );
  }
}

Widget _macroDot(CaloriesPalette p, Color color, String value) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(radius: 3, backgroundColor: color),
      const SizedBox(width: 3),
      Flexible(
          child: Text(value, style: TextStyle(color: p.text, fontSize: 10))),
    ]);

Future<void> showFoodPortionSheet(
    BuildContext context, AppState state, FoodItem food,
    {MealItem? log}) async {
  final message = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PortionSheet(state: state, food: food, log: log),
  );
  if (!context.mounted || message == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _PortionSheet extends StatefulWidget {
  const _PortionSheet({required this.state, required this.food, this.log});
  final AppState state;
  final FoodItem food;
  final MealItem? log;
  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  late final List<FoodServing> servings = [
    ...widget.food.servings,
    const FoodServing(
        nameEn: '100 g standard reference', nameAr: '', grams: 100),
  ];
  late final TextEditingController weight = TextEditingController(
      text: formatCaloriesGrams(widget.log?.grams ?? servings.first.grams));
  late MealCategory meal = widget.log?.category ??
      (widget.food.tags.contains('breakfast')
          ? MealCategory.breakfast
          : widget.food.tags.any((tag) => tag == 'snack' || tag == 'dessert')
              ? MealCategory.snack
              : MealCategory.lunch);
  bool saving = false;
  String? error;

  double? get grams {
    final value = double.tryParse(weight.text.trim());
    if (value == null || !value.isFinite || value < 1 || value > 3000) {
      return null;
    }
    return (value * 10).round() / 10;
  }

  void setWeight(double value) {
    weight.text = formatCaloriesGrams(value);
    setState(() => error = null);
  }

  @override
  void dispose() {
    weight.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final g = grams;
    if (g == null) {
      setState(() => error = strings(context).explorerInvalidWeight);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final portion = calculateFoodPortion(widget.food.per100g, g);
    try {
      if (widget.log != null) {
        await widget.state.updateFoodPortion(widget.log!, g);
      } else {
        FoodServing? selected;
        for (final serving in servings) {
          if (serving.grams == g) {
            selected = serving;
            break;
          }
        }
        final label = selected == null
            ? '${formatCaloriesGrams(g)}g custom'
            : '${selected.nameEn} (${formatCaloriesGrams(g)}g)';
        await widget.state
            .logFood(widget.food, portion, meal, servingLabel: label);
      }
      if (!mounted) return;
      final message = widget.state.activityError != null
          ? strings(context).workoutRefreshError
          : widget.log != null
              ? strings(context)
                  .explorerUpdated(_foodName(context, widget.food))
              : strings(context).explorerLogged(
                  _foodName(context, widget.food), portion.kcal.toString());
      Navigator.pop(context, message);
    } catch (e) {
      if (mounted) {
        setState(
            () => error = strings(context).explorerSaveError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = CaloriesPalette(Theme.of(context));
    final l = strings(context);
    final g = grams;
    final portion =
        g == null ? null : calculateFoodPortion(widget.food.per100g, g);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: .9,
        child: Material(
          color: p.card,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      formatCaloriesCategory(
                          _groupName(context, widget.food.categoryGroup),
                          widget.food.categoryGroup ==
                                  widget.food.cuisineOrBrand
                              ? ''
                              : widget.food.cuisineOrBrand),
                      style: TextStyle(color: p.muted)),
                  Text(_foodName(context, widget.food),
                      style: TextStyle(
                          color: p.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(l.explorerPortions),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: servings.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 82,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8),
                    itemBuilder: (context, index) {
                      final s = servings[index];
                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: g == s.grams ? p.accent : p.border),
                          padding: const EdgeInsets.all(6),
                        ),
                        onPressed: () => setWeight(s.grams),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                  index == servings.length - 1
                                      ? l.explorerStandard
                                      : (Localizations.localeOf(context)
                                                  .languageCode ==
                                              'ar'
                                          ? s.nameAr
                                          : s.nameEn),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(l.foodGrams(formatCaloriesGrams(s.grams)),
                                  style:
                                      TextStyle(color: p.muted, fontSize: 11)),
                            ]),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('portion-grams'),
                    controller: weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() => error = null),
                    decoration: InputDecoration(
                        labelText: l.explorerExactWeight,
                        suffixText: l.unitGrams),
                  ),
                  Slider(
                    key: const ValueKey('portion-slider'),
                    value: (g ?? 5).clamp(5, 800).toDouble(),
                    min: 5,
                    max: 800,
                    divisions: 159,
                    activeColor: p.accent,
                    onChanged: (value) => setWeight(value),
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.foodGrams('5')),
                        Text(l.foodGrams('250')),
                        Text(l.foodGrams('500')),
                        Text(l.foodGrams('800')),
                      ]),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _preview(p, l.calories, portion?.kcal.toString() ?? '—',
                        p.accent),
                    _preview(
                        p,
                        l.foodProtein,
                        portion == null
                            ? '—'
                            : l.foodGrams(
                                formatCaloriesGrams(portion.proteinG)),
                        CaloriesPalette.protein),
                    _preview(
                        p,
                        l.foodCarbs,
                        portion == null
                            ? '—'
                            : l.foodGrams(formatCaloriesGrams(portion.carbsG)),
                        CaloriesPalette.carbs),
                    _preview(
                        p,
                        l.foodFat,
                        portion == null
                            ? '—'
                            : l.foodGrams(formatCaloriesGrams(portion.fatG)),
                        CaloriesPalette.fat),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 4, children: [
                    Text(l.explorerNutrient(
                        l.foodFiber,
                        l.foodGrams(portion == null
                            ? '—'
                            : formatCaloriesGrams(portion.fiberG)))),
                    Text(l.explorerNutrient(
                        l.foodSugar,
                        l.foodGrams(portion == null
                            ? '—'
                            : formatCaloriesGrams(portion.sugarG)))),
                    Text(l.explorerNutrient(
                        l.foodSodium,
                        l.foodMilligrams(
                            portion?.sodiumMg.toStringAsFixed(0) ?? '—'))),
                  ]),
                  const SizedBox(height: 16),
                  Text(l.explorerMeal),
                  Wrap(spacing: 6, children: [
                    for (final choice in [
                      MealCategory.breakfast,
                      MealCategory.lunch,
                      MealCategory.dinner,
                      MealCategory.snack
                    ])
                      ChoiceChip(
                        label: Text(switch (choice) {
                          MealCategory.breakfast => l.foodBreakfast,
                          MealCategory.lunch => l.foodLunch,
                          MealCategory.dinner => l.foodDinner,
                          MealCategory.snack => l.foodSnackSingular,
                          MealCategory.shake => l.foodSnackSingular,
                        }),
                        selected: meal == choice,
                        selectedColor: p.accent.withAlpha(55),
                        onSelected: widget.log != null
                            ? null
                            : (_) => setState(() => meal = choice),
                      ),
                  ]),
                  if (error != null)
                    Text(error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: TextButton(
                            onPressed:
                                saving ? null : () => Navigator.pop(context),
                            child: Text(l.plannerCancel))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: p.accent,
                          foregroundColor: p.onAccent),
                      onPressed: saving ? null : save,
                      child: Text(widget.log == null
                          ? l.explorerAdd
                          : l.explorerSaveChanges),
                    )),
                  ]),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _preview(CaloriesPalette p, String label, String value, Color color) =>
      Container(
        width: 76,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: p.inner,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.text, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: p.muted, fontSize: 10)),
        ]),
      );
}
