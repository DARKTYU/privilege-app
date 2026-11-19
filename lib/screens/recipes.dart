import 'package:flutter/material.dart';

import '../data.dart';
import '../logic/fitness_logic.dart';
import '../state.dart';
import '../ui.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final Set<String> _favorites = {};
  String? _loggingRecipeId;
  String? _error;

  Future<void> _log(Recipe r) async {
    setState(() {
      _loggingRecipeId = r.id;
      _error = null;
    });
    try {
      await appState.addMeal(MealItem(
        id: '',
        name: r.name,
        time: 'Just now',
        calories: r.calories,
        proteinGrams: r.protein,
        carbsGrams: 45,
        fatGrams: 14,
        fiberGrams: 6,
        icon: r.emoji,
        consumed: true,
        category: r.category,
      ));
      if (mounted) {
        toast(context,
            "Logged ${r.name} (${r.calories} kcal) to today's macros!");
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not log recipe: $error');
    } finally {
      if (mounted) setState(() => _loggingRecipeId = null);
    }
  }

  Widget _meta(IconData i, String label, String value) => Row(children: [
        Icon(i, size: 14, color: kGold),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(fontSize: 12, color: kMuted)),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
            'A small collection of sample recipes. Favorites are not saved yet.',
            style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 12),
        for (final r in recipes)
          Panel(
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.only(bottom: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                netImage(r.image,
                    width: double.infinity,
                    height: 180,
                    radius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    icon: Icons.restaurant),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Row(children: [
                    tag('${r.protein}g Protein', kRed),
                    const SizedBox(width: 6),
                    tag('${r.calories} kcal', kGold),
                  ]),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton(
                    style:
                        IconButton.styleFrom(backgroundColor: Colors.black45),
                    icon: Icon(
                        _favorites.contains(r.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _favorites.contains(r.id) ? kRed : Colors.white),
                    onPressed: () => setState(() {
                      if (!_favorites.remove(r.id)) _favorites.add(r.id);
                    }),
                  ),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.redAccent)),
                        ),
                      Text(r.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(r.description,
                          style: TextStyle(fontSize: 12, color: kMuted)),
                      const SizedBox(height: 10),
                      _meta(
                          Icons.timer_outlined, 'Preparation Time', r.prepTime),
                      const SizedBox(height: 4),
                      _meta(Icons.local_fire_department, 'Difficulty',
                          r.difficulty),
                      const SizedBox(height: 10),
                      Row(children: [
                        Icon(Icons.restaurant, size: 14, color: kGold),
                        SizedBox(width: 6),
                        Text('Ingredients',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 4),
                      Text(r.ingredients.join(', '),
                          style: TextStyle(fontSize: 12, color: kMuted)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: PrimaryButton(
                              _loggingRecipeId == r.id
                                  ? 'Logging...'
                                  : 'Quick-Action: Log',
                              icon: Icons.add,
                              gold: true,
                              onPressed: _loggingRecipeId == null
                                  ? () => _log(r)
                                  : null),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PrimaryButton(
                            _favorites.contains(r.id)
                                ? 'Favorited'
                                : 'Favorite',
                            icon: Icons.menu_book,
                            onPressed: () => setState(() {
                              if (!_favorites.remove(r.id))
                                _favorites.add(r.id);
                            }),
                          ),
                        ),
                      ]),
                    ]),
              ),
            ]),
          ),
      ],
    );
  }
}
