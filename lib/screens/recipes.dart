import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data.dart';
import '../logic/fitness_logic.dart';
import '../logic/recipe_nutrition.dart';
import '../services/food_database.dart';
import '../state.dart';
import '../ui.dart';
import 'calories_display_format.dart';

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

  Future<void> _log(Recipe recipe, RecipeNutrition nutrition) async {
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
      ));
      if (mounted) toast(context, 'Logged ${recipe.name} (${p.kcal} kcal)');
    } catch (e) {
      if (mounted) setState(() => error = 'Could not log recipe: $e');
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
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: loading,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Could not load the food database.'),
                TextButton(
                    onPressed: () => setState(() => loading = database.load()),
                    child: const Text('Retry')),
              ]),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Sample recipes. Favorites are saved on this device.'),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                if (!favoritesLoading && account != null)
                  TextButton(
                      onPressed: _loadFavorites,
                      child: const Text('Retry favorites')),
              ],
              const SizedBox(height: 12),
              for (final recipe in widget.recipeList)
                _recipeCard(
                    recipe, calculateRecipeNutrition(recipe, database.foods)),
            ],
          );
        },
      );

  Widget _recipeCard(Recipe recipe, RecipeNutrition? nutrition) {
    final p = nutrition?.portion;
    String g(double v) => formatCaloriesGrams(v);
    return Panel(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          imagePlaceholder(context,
              height: 140,
              radius: const BorderRadius.vertical(top: Radius.circular(16)),
              icon: Icons.restaurant),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              tooltip: favorites.contains(recipe.id)
                  ? 'Remove favorite'
                  : 'Add favorite',
              icon: Icon(favorites.contains(recipe.id)
                  ? Icons.favorite
                  : Icons.favorite_border),
              onPressed: favoritesLoading || favoriteSaving || account == null
                  ? null
                  : () => _toggleFavorite(recipe.id),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(recipe.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(recipe.description),
            const SizedBox(height: 8),
            Text('${recipe.prepTime} · ${recipe.difficulty}'),
            const SizedBox(height: 8),
            if (nutrition == null)
              const Text('Nutrition not available')
            else ...[
              const Text('Estimated from ingredients'),
              const Text('Per serving'),
              Text(
                  '${p!.kcal} kcal · Protein ${p.proteinG.round()} g · Carbs ${p.carbsG.round()} g · Fat ${p.fatG.round()} g'),
              Text(
                  'Fiber ${p.fiberG.round()} g · Sugar ${g(p.sugarG)} g · Sodium ${p.sodiumMg.toStringAsFixed(0)} mg'),
              const Text(
                  'Protein, carbs, fat and fiber are rounded to whole grams.'),
              const SizedBox(height: 8),
              for (final (food, grams) in nutrition.ingredients)
                Text('${food.nameEn}: ${g(grams)} g'),
            ],
            const SizedBox(height: 12),
            PrimaryButton(
              loggingId == recipe.id ? 'Logging...' : 'Log',
              icon: Icons.add,
              onPressed: nutrition == null || loggingId != null
                  ? null
                  : () => _log(recipe, nutrition),
            ),
          ]),
        ),
      ]),
    );
  }
}
