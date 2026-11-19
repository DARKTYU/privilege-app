import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data.dart';
import '../logic/fitness_logic.dart';
import '../logic/recipe_nutrition.dart';
import '../logic/recipe_fit.dart';
import '../logic/calorie_target.dart';
import '../services/food_database.dart';
import '../state.dart';
import '../ui.dart';
import 'calories_display_format.dart';
import 'calories_food_summary.dart' show CaloriesPalette;

const Map<String, String> recipePhotoCredits = {};

String recipePhotoPath(String recipeId) =>
    'assets/images/recipes/$recipeId.jpg';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({
    super.key,
    this.database,
    this.accountId,
    this.saveMeal,
    this.recipeList = recipes,
  });
  final FoodDatabase? database;
  final String? Function()? accountId;
  final Future<void> Function(MealItem)? saveMeal;
  final List<Recipe> recipeList;

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  late final database = widget.database ?? FoodDatabase();
  late Future<void> loading = database.load();
  Set<String> favorites = {};
  String? account;
  bool favoritesLoading = true;
  bool favoriteSaving = false;
  String? error;
  String? loggingId;
  RecipeFilter filter = RecipeFilter.all;
  AssetBundle? _assetBundle;
  late Future<AssetManifest> _assetManifest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (_assetBundle != bundle) {
      _assetBundle = bundle;
      _assetManifest = AssetManifest.loadFromAssetBundle(bundle);
    }
  }

  String? _accountId() => widget.accountId != null
      ? widget.accountId!()
      : Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    appState.addListener(_accountChanged);
    _loadFavorites();
  }

  void _accountChanged() {
    if (_accountId() != account) _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final id = _accountId();
    setState(() {
      account = id;
      favorites = {};
      favoritesLoading = true;
      error = null;
    });
    if (id == null) {
      setState(() {
        favoritesLoading = false;
        error = 'Sign in to save favorites.';
      });
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('privilege_recipe_favorites_$id') ?? [];
      if (!mounted || account != id || _accountId() != id) return;
      setState(() {
        favorites = saved.toSet();
        favoritesLoading = false;
      });
    } catch (e) {
      if (!mounted || account != id) return;
      setState(() {
        favoritesLoading = false;
        error = 'Could not load favorites: $e';
      });
    }
  }

  Future<void> _toggleFavorite(String recipeId) async {
    final id = account;
    if (id == null || id != _accountId() || favoriteSaving) return;
    final next = Set<String>.of(favorites);
    if (!next.remove(recipeId)) next.add(recipeId);
    setState(() {
      favoriteSaving = true;
      error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setStringList(
          'privilege_recipe_favorites_$id', next.toList())) {
        throw StateError('The device did not save the favorite.');
      }
      if (mounted && account == id && _accountId() == id) {
        setState(() => favorites = next);
      }
    } catch (e) {
      if (mounted && account == id) {
        setState(() => error = 'Could not save favorite: $e');
      }
    } finally {
      if (mounted) setState(() => favoriteSaving = false);
    }
  }

  Future<void> _log(Recipe recipe, RecipeNutrition nutrition,
      BuildContext feedbackContext) async {
    final p = nutrition.portion;
    setState(() {
      loggingId = recipe.id;
      error = null;
    });
    try {
      await (widget.saveMeal ?? appState.addMeal)(MealItem(
        id: '',
        name: recipe.name,
        time: 'Just now',
        calories: p.kcal,
        proteinGrams: p.proteinG.round(),
        carbsGrams: p.carbsG.round(),
        fatGrams: p.fatG.round(),
        fiberGrams: p.fiberG.round(),
        sugarG: p.sugarG,
        sodiumMg: p.sodiumMg,
        icon: recipe.emoji,
        consumed: true,
        category: recipe.category,
        servingLabel: 'Recipe',
      ));
      if (feedbackContext.mounted) {
        toast(feedbackContext, 'Logged ${recipe.name} (${p.kcal} kcal)');
      }
    } catch (e) {
      if (feedbackContext.mounted) {
        ScaffoldMessenger.of(feedbackContext).showSnackBar(
          SnackBar(content: Text('Could not log recipe: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loggingId = null);
    }
  }

  @override
  void dispose() {
    appState.removeListener(_accountChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) => FutureBuilder<void>(
            future: loading,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Could not load the food database.'),
                    TextButton(
                        onPressed: () =>
                            setState(() => loading = database.load()),
                        child: const Text('Retry')),
                  ]),
                );
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final target = appState.targetCalories;
              final available = target > 0 &&
                  !appState.activityLoading &&
                  appState.activityError == null;
              final totals = appState.totals;
              final calculation = appState.calorieTarget;
              final macros = available
                  ? CalorieTarget.calculateMacros(
                      target,
                      appState.profile.hasWeight
                          ? appState.profile.weightKg
                          : null,
                      calculation.goal,
                      calculation.age)
                  : null;
              final remaining =
                  available ? target - totals.totalMealCalories : null;
              final protein =
                  macros == null ? null : macros.protein - totals.proteinGrams;
              final entries = selectRecipes([
                for (final recipe in widget.recipeList)
                  (
                    recipe: recipe,
                    nutrition: calculateRecipeNutrition(recipe, database.foods)
                  ),
              ],
                  filter: filter,
                  remainingCalories: remaining,
                  remainingProtein: protein);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                      'Sample recipes. Favorites are saved on this device.'),
                  const SizedBox(height: 8),
                  if (!available)
                    Text(appState.activityLoading
                        ? 'Loading today’s activity...'
                        : appState.activityError != null
                            ? 'Today’s activity is unavailable.'
                            : 'Daily target unavailable.')
                  else ...[
                    Text(
                        'Remaining today: ${remaining! > 0 ? remaining : 0} kcal · ${protein! > 0 ? protein : 0} g protein'),
                    if (remaining <= 0)
                      const Text("You have reached today's target"),
                  ],
                  const SizedBox(height: 8),
                  Text(remaining != null && remaining > 0
                      ? 'Best fit for today'
                      : 'All recipes'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final option in const [
                        (RecipeFilter.all, 'All'),
                        (RecipeFilter.fits, 'Fits today'),
                        (RecipeFilter.highProtein, 'High protein'),
                        (RecipeFilter.quick, 'Quick'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(option.$2),
                            selected: filter == option.$1,
                            onSelected: (_) =>
                                setState(() => filter = option.$1),
                          ),
                        ),
                    ]),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    if (!favoritesLoading && account != null)
                      TextButton(
                          onPressed: _loadFavorites,
                          child: const Text('Retry favorites')),
                  ],
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    const Text('No recipes match this filter.'),
                  for (final entry in entries)
                    _recipeCard(entry.recipe, entry.nutrition, remaining),
                ],
              );
            },
          ));

  Widget _recipeCard(
      Recipe recipe, RecipeNutrition? nutrition, int? remaining) {
    final p = nutrition?.portion;
    return Panel(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => _RecipeDetailPage(
                      recipe: recipe,
                      nutrition: nutrition,
                      manifest: _assetManifest,
                      onLog: _log,
                    ),
                  )),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RecipePhoto(recipe: recipe, manifest: _assetManifest),
                      const SizedBox(height: 8),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(recipe.name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                                  Text(recipe.nameAr,
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.right),
                                ])),
                            IconButton(
                              tooltip: favorites.contains(recipe.id)
                                  ? 'Remove favorite'
                                  : 'Add favorite',
                              icon: Icon(favorites.contains(recipe.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              onPressed: favoritesLoading ||
                                      favoriteSaving ||
                                      account == null
                                  ? null
                                  : () => _toggleFavorite(recipe.id),
                            ),
                          ]),
                      const SizedBox(height: 8),
                      if (p != null)
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          _recipePill(context, '${p.kcal} kcal',
                              Theme.of(context).colorScheme.secondary),
                          _recipePill(
                              context,
                              '${formatCaloriesGrams(p.proteinG)} g protein',
                              CaloriesPalette.protein),
                          _recipePill(
                              context,
                              '${formatCaloriesGrams(p.carbsG)} g carbs',
                              CaloriesPalette.carbs),
                          _recipePill(
                              context,
                              '${formatCaloriesGrams(p.fatG)} g fat',
                              CaloriesPalette.fat),
                        ]),
                      const SizedBox(height: 8),
                      Text(
                          '${recipe.minutes} min · ${recipe.difficulty} · ${_mealLabel(recipe.category)}',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Text('Estimated from ingredients',
                          style: Theme.of(context).textTheme.bodySmall),
                      if (remaining != null && remaining > 0 && p != null)
                        _recipePill(
                            context,
                            p.kcal <= remaining
                                ? 'Fits today'
                                : 'Over by ${p.kcal - remaining} kcal',
                            Theme.of(context).colorScheme.secondary),
                      if (nutrition == null)
                        const Text('Nutrition not available'),
                      const SizedBox(height: 8),
                      _recipeTags(context, recipe, nutrition),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        loggingId == recipe.id ? 'Logging...' : 'Log',
                        icon: Icons.add,
                        onPressed: nutrition == null || loggingId != null
                            ? null
                            : () => _log(recipe, nutrition, context),
                      ),
                    ]),
              ))),
    );
  }
}

String _mealLabel(MealCategory category) => category == MealCategory.shake
    ? 'Snack'
    : '${category.name[0].toUpperCase()}${category.name.substring(1)}';

Widget _recipePill(BuildContext context, String label, Color color) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        border: Border.all(color: color.withAlpha(150)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );

Widget _recipeTags(
    BuildContext context, Recipe recipe, RecipeNutrition? nutrition) {
  final portion = nutrition?.portion;
  final tags = [
    if (portion != null && portion.proteinG >= 30) 'High protein',
    if (portion != null && portion.fiberG >= 8) 'High fiber',
    if (portion != null && portion.kcal < 400) 'Light',
    if (recipe.minutes <= 10) 'Quick',
  ];
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final tag in tags)
        _recipePill(context, tag, Theme.of(context).colorScheme.outline),
    ],
  );
}

class _RecipePhoto extends StatelessWidget {
  const _RecipePhoto(
      {required this.recipe, required this.manifest, this.detail = false});

  final Recipe recipe;
  final Future<AssetManifest> manifest;
  final bool detail;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => imagePlaceholder(context,
        width: 56,
        height: 56,
        radius: BorderRadius.circular(12),
        icon: Icons.restaurant);
    return FutureBuilder<AssetManifest>(
      future: manifest,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                placeholder(),
                const Text('Could not load recipe photos.'),
              ]);
        }
        final path = recipePhotoPath(recipe.id);
        if (!snapshot.hasData || !snapshot.data!.listAssets().contains(path)) {
          return placeholder();
        }
        final width = (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(1, 1600);
        return Image.asset(
          path,
          cacheWidth: width,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Could not load recipe photo $path: $error');
            return placeholder();
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame == null && !wasSynchronouslyLoaded) return placeholder();
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(aspectRatio: 16 / 9, child: child),
                  ),
                  if (detail) ...[
                    const SizedBox(height: 4),
                    Text('Photo is for illustration',
                        style: Theme.of(context).textTheme.bodySmall),
                    if (recipePhotoCredits[recipe.id] case final credit?)
                      Text('Photo: $credit',
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ]);
          },
        );
      },
    );
  }
}

class _RecipeDetailPage extends StatefulWidget {
  const _RecipeDetailPage({
    required this.recipe,
    required this.nutrition,
    required this.manifest,
    required this.onLog,
  });
  final Recipe recipe;
  final RecipeNutrition? nutrition;
  final Future<AssetManifest> manifest;
  final Future<void> Function(Recipe, RecipeNutrition, BuildContext) onLog;

  @override
  State<_RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<_RecipeDetailPage> {
  bool logging = false;

  Future<void> _log() async {
    setState(() => logging = true);
    try {
      await widget.onLog(widget.recipe, widget.nutrition!, context);
    } finally {
      if (mounted) setState(() => logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final nutrition = widget.nutrition;
    final p = nutrition?.portion;
    String g(double value) => formatCaloriesGrams(value);
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe details')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _RecipePhoto(recipe: recipe, manifest: widget.manifest, detail: true),
          const SizedBox(height: 12),
          Text(recipe.name, style: Theme.of(context).textTheme.titleLarge),
          Text(recipe.nameAr,
              textDirection: TextDirection.rtl, textAlign: TextAlign.right),
          const SizedBox(height: 8),
          Text(
              '${recipe.minutes} min · ${recipe.difficulty} · ${_mealLabel(recipe.category)}'),
          const SizedBox(height: 8),
          _recipeTags(context, recipe, nutrition),
          const SizedBox(height: 16),
          Text('Nutrition per serving',
              style: Theme.of(context).textTheme.titleMedium),
          const Text('Estimated from ingredients'),
          if (p == null)
            const Text('Nutrition not available')
          else ...[
            Text('${p.kcal} kcal'),
            Text(
                'Protein ${g(p.proteinG)} g · Carbs ${g(p.carbsG)} g · Fat ${g(p.fatG)} g'),
            Text(
                'Fiber ${g(p.fiberG)} g · Sugar ${g(p.sugarG)} g · Sodium ${p.sodiumMg.toStringAsFixed(0)} mg'),
          ],
          const SizedBox(height: 16),
          Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
          Text(recipe.description),
          if (nutrition != null)
            for (final (food, grams) in nutrition.ingredients)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${food.nameEn}: ${g(grams)} g'),
                      Text(food.nameAr,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right),
                    ]),
              )
          else
            const Text('Ingredient details unavailable.'),
          const SizedBox(height: 16),
          Text('How to cook', style: Theme.of(context).textTheme.titleMedium),
          for (var i = 0; i < recipe.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('${i + 1}. ${recipe.steps[i]}'),
            ),
          const SizedBox(height: 16),
          PrimaryButton(logging ? 'Logging...' : 'Log',
              icon: Icons.add,
              onPressed: nutrition == null || logging ? null : _log),
        ]),
      ),
    );
  }
}
