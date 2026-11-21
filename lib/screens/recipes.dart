import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data.dart';
import '../l10n_strings.dart';
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

enum _FavoriteError { signIn, load, save, deviceSave }

String _recipeName(BuildContext context, Recipe recipe) =>
    recipe.localizedName(Localizations.localeOf(context).languageCode == 'ar');

String _difficulty(BuildContext context, String difficulty) {
  final l = strings(context);
  return switch (difficulty) {
    'Easy' => l.recipeDifficultyEasy,
    'Easy / Medium' => l.recipeDifficultyEasyMedium,
    'Instant' => l.recipeDifficultyInstant,
    _ => difficulty,
  };
}

String _recipeSummary(BuildContext context, Recipe recipe) =>
    strings(context).recipeSummary(
        recipe.minutes,
        _difficulty(context, recipe.difficulty),
        _mealLabel(context, recipe.category));

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
  _FavoriteError? error;
  Object? errorDetail;
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
        error = _FavoriteError.signIn;
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
        error = _FavoriteError.load;
        errorDetail = e;
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
    bool deviceSaveFailed = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setStringList(
          'privilege_recipe_favorites_$id', next.toList())) {
        deviceSaveFailed = true;
        throw StateError('Favorite persistence failed');
      }
      if (mounted && account == id && _accountId() == id) {
        setState(() => favorites = next);
      }
    } catch (e) {
      if (mounted && account == id) {
        setState(() {
          error = deviceSaveFailed
              ? _FavoriteError.deviceSave
              : _FavoriteError.save;
          errorDetail = e;
        });
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
        toast(
            feedbackContext,
            strings(feedbackContext).recipeLogged(
                _recipeName(feedbackContext, recipe), p.kcal));
      }
    } catch (e) {
      if (feedbackContext.mounted) {
        ScaffoldMessenger.of(feedbackContext).showSnackBar(
          SnackBar(
              content: Text(strings(feedbackContext).recipeLogError(
                  friendlyError(e, localizations: strings(feedbackContext))))),
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
                    Text(strings(context).recipeDatabaseError),
                    TextButton(
                        onPressed: () =>
                            setState(() => loading = database.load()),
                        child: Text(strings(context).plannerRetry)),
                  ]),
                );
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final target = appState.targetCalories;
              final l = strings(context);
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
                  Text(l.recipeSampleNotice),
                  const SizedBox(height: 8),
                  if (!available)
                    Text(appState.activityLoading
                        ? l.recipeLoadingActivity
                        : appState.activityError != null
                            ? l.recipeActivityUnavailable
                            : l.recipeTargetUnavailable)
                  else ...[
                    Text(l.recipeRemaining(
                        remaining! > 0 ? remaining : 0,
                        fmt(protein! > 0 ? protein : 0))),
                    if (remaining <= 0) Text(l.recipeTargetReached),
                  ],
                  const SizedBox(height: 8),
                  Text(remaining != null && remaining > 0
                      ? l.recipeBestFit
                      : l.recipeAll),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final option in [
                        (RecipeFilter.all, l.recipeFilterAll),
                        (RecipeFilter.fits, l.recipeFits),
                        (RecipeFilter.highProtein, l.recipeHighProtein),
                        (RecipeFilter.quick, l.recipeQuick),
                      ])
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
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
                    Text(
                        switch (error!) {
                          _FavoriteError.signIn => l.recipeSignIn,
                          _FavoriteError.load =>
                            l.recipeLoadFavoritesError(errorDetail.toString()),
                          _FavoriteError.save =>
                            l.recipeSaveFavoriteError(errorDetail.toString()),
                          _FavoriteError.deviceSave => l.recipeDeviceSaveError,
                        },
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    if (!favoritesLoading && account != null)
                      TextButton(
                          onPressed: _loadFavorites,
                          child: Text(l.recipeRetryFavorites)),
                  ],
                  const SizedBox(height: 12),
                  if (entries.isEmpty) Text(l.recipeNoMatches),
                  for (final entry in entries)
                    _recipeCard(entry.recipe, entry.nutrition, remaining),
                ],
              );
            },
          ));

  Widget _recipeCard(
      Recipe recipe, RecipeNutrition? nutrition, int? remaining) {
    final p = nutrition?.portion;
    final l = strings(context);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RecipePhoto(
                  recipe: recipe,
                  manifest: _assetManifest,
                  cardHeader: true),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _recipeName(context, recipe),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: favorites.contains(recipe.id)
                              ? l.recipeRemoveFavorite
                              : l.recipeAddFavorite,
                          icon: Icon(favorites.contains(recipe.id)
                              ? Icons.favorite
                              : Icons.favorite_border),
                          onPressed: favoritesLoading ||
                                  favoriteSaving ||
                                  account == null
                              ? null
                              : () => _toggleFavorite(recipe.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (p != null)
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        _recipePill(context, l.mergeCalories(p.kcal, fmt(p.kcal)),
                            Theme.of(context).colorScheme.secondary),
                        _recipePill(
                            context,
                            l.recipeMacro(formatCaloriesGrams(p.proteinG),
                                l.foodProtein.toLowerCase()),
                            CaloriesPalette.protein),
                        _recipePill(
                            context,
                            l.recipeMacro(formatCaloriesGrams(p.carbsG),
                                l.foodCarbs.toLowerCase()),
                            CaloriesPalette.carbs),
                        _recipePill(
                            context,
                            l.recipeMacro(formatCaloriesGrams(p.fatG),
                                l.foodFat.toLowerCase()),
                            CaloriesPalette.fat),
                      ]),
                    const SizedBox(height: 8),
                    Text(_recipeSummary(context, recipe),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text(l.recipeEstimated,
                        style: Theme.of(context).textTheme.bodySmall),
                    if (remaining != null && remaining > 0 && p != null)
                      _recipePill(
                          context,
                          p.kcal <= remaining
                              ? l.recipeFits
                              : l.recipeOver(p.kcal - remaining),
                          Theme.of(context).colorScheme.secondary),
                    if (nutrition == null)
                      Text(l.recipeNutritionUnavailable),
                    const SizedBox(height: 8),
                    _recipeTags(context, recipe, nutrition),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      loggingId == recipe.id ? l.recipeLogging : l.recipeLog,
                      icon: Icons.add,
                      onPressed: nutrition == null || loggingId != null
                          ? null
                          : () => _log(recipe, nutrition, context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _mealLabel(BuildContext context, MealCategory category) {
  final l = strings(context);
  return switch (category) {
    MealCategory.breakfast => l.foodBreakfast,
    MealCategory.lunch => l.foodLunch,
    MealCategory.dinner => l.foodDinner,
    MealCategory.snack || MealCategory.shake => l.foodSnackSingular,
  };
}

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
  final l = strings(context);
  final tags = [
    if (portion != null && portion.proteinG >= 30) l.recipeHighProtein,
    if (portion != null && portion.fiberG >= 8) l.recipeHighFiber,
    if (portion != null && portion.kcal < 400) l.recipeLight,
    if (recipe.minutes <= 10) l.recipeQuick,
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
      {required this.recipe,
      required this.manifest,
      this.detail = false,
      this.cardHeader = false});

  final Recipe recipe;
  final Future<AssetManifest> manifest;
  final bool detail, cardHeader;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Padding(
          padding: cardHeader
              ? const EdgeInsets.fromLTRB(14, 14, 14, 0)
              : EdgeInsets.zero,
          child: imagePlaceholder(context,
              width: 56,
              height: 56,
              radius: BorderRadius.circular(12),
              icon: Icons.restaurant),
        );
    return FutureBuilder<AssetManifest>(
      future: manifest,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                placeholder(),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 14),
                  child: Text(strings(context).recipePhotosError),
                ),
              ]);
        }
        final path = recipePhotoPath(recipe.id);
        if (!snapshot.hasData || !snapshot.data!.listAssets().contains(path)) {
          return placeholder();
        }
        final cacheWidth = (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(1, 1600);
        final radius = cardHeader
            ? const BorderRadius.vertical(top: Radius.circular(15))
            : BorderRadius.circular(12);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              image: true,
              label: _recipeName(context, recipe),
              child: Image.asset(
                path,
                cacheWidth: cacheWidth,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Could not load recipe photo $path: $error');
                  return placeholder();
                },
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (frame == null && !wasSynchronouslyLoaded) {
                    return placeholder();
                  }
                  final clipped = ClipRRect(
                    borderRadius: radius,
                    child: AspectRatio(aspectRatio: 16 / 9, child: child),
                  );
                  if (wasSynchronouslyLoaded) return clipped;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 180),
                    builder: (context, opacity, child) => Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                    child: clipped,
                  );
                },
              ),
            ),
            if (detail) ...[
              const SizedBox(height: 4),
              Text(strings(context).recipePhotoIllustration,
                  style: Theme.of(context).textTheme.bodySmall),
              if (recipePhotoCredits[recipe.id] case final credit?)
                Text(strings(context).recipePhotoCredit(credit),
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
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
    final l = strings(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String g(double value) => formatCaloriesGrams(value);
    return Scaffold(
      appBar: AppBar(title: Text(l.recipeDetails)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _RecipePhoto(recipe: recipe, manifest: widget.manifest, detail: true),
          const SizedBox(height: 12),
          Text(_recipeName(context, recipe),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_recipeSummary(context, recipe)),
          const SizedBox(height: 8),
          _recipeTags(context, recipe, nutrition),
          const SizedBox(height: 16),
          Text(l.recipeNutritionPerServing,
              style: Theme.of(context).textTheme.titleMedium),
          Text(l.recipeEstimated),
          if (p == null)
            Text(l.recipeNutritionUnavailable)
          else ...[
            Text(l.mergeCalories(p.kcal, fmt(p.kcal))),
            Text(l.recipeMacroLine(g(p.proteinG), g(p.carbsG), g(p.fatG))),
            Text(l.recipeMicroLine(
                g(p.fiberG), g(p.sugarG), fmt(p.sodiumMg))),
          ],
          const SizedBox(height: 16),
          Text(l.recipeIngredients,
              style: Theme.of(context).textTheme.titleMedium),
          Text(recipe.localizedDescription(arabic)),
          if (nutrition != null)
            for (final (food, grams) in nutrition.ingredients)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.recipeIngredientAmount(
                          localizedContent(food.nameEn, food.nameAr, arabic),
                          g(grams))),
                    ]),
              )
          else
            Text(l.recipeIngredientUnavailable),
          const SizedBox(height: 16),
          Text(l.recipeHowToCook,
              style: Theme.of(context).textTheme.titleMedium),
          for (var i = 0; i < recipe.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.recipeStep(
                  (i + 1).toString(), recipe.localizedStep(i, arabic))),
            ),
          const SizedBox(height: 16),
          PrimaryButton(logging ? l.recipeLogging : l.recipeLog,
              icon: Icons.add,
              onPressed: nutrition == null || logging ? null : _log),
        ]),
      ),
    );
  }
}
