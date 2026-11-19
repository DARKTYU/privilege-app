import 'dart:math' as math;

import '../data.dart';
import 'recipe_nutrition.dart';

enum RecipeFilter { all, fits, highProtein, quick }

typedef RecipeEntry = ({Recipe recipe, RecipeNutrition? nutrition});

List<RecipeEntry> selectRecipes(List<RecipeEntry> entries,
    {required RecipeFilter filter,
    required int? remainingCalories,
    required int? remainingProtein}) {
  final canFit = remainingCalories != null && remainingCalories > 0;
  final selected = entries.where((entry) {
    final nutrition = entry.nutrition?.portion;
    return switch (filter) {
      RecipeFilter.all => true,
      RecipeFilter.fits =>
        !canFit || (nutrition != null && nutrition.kcal <= remainingCalories),
      RecipeFilter.highProtein => nutrition != null && nutrition.proteinG >= 30,
      RecipeFilter.quick => entry.recipe.minutes <= 10,
    };
  }).toList();
  if (!canFit || remainingProtein == null) return selected;
  final original = {
    for (var i = 0; i < entries.length; i++) entries[i].recipe.id: i
  };
  selected.sort((a, b) {
    final aPortion = a.nutrition?.portion;
    final bPortion = b.nutrition?.portion;
    if (aPortion == null || bPortion == null) {
      if (aPortion == null && bPortion != null) return 1;
      if (aPortion != null && bPortion == null) return -1;
      return original[a.recipe.id]!.compareTo(original[b.recipe.id]!);
    }
    final aFits = aPortion.kcal <= remainingCalories;
    final bFits = bPortion.kcal <= remainingCalories;
    if (aFits != bFits) return aFits ? -1 : 1;
    final aHelp = math.min(aPortion.proteinG, math.max(0, remainingProtein));
    final bHelp = math.min(bPortion.proteinG, math.max(0, remainingProtein));
    final compare = bHelp.compareTo(aHelp);
    return compare != 0
        ? compare
        : original[a.recipe.id]!.compareTo(original[b.recipe.id]!);
  });
  return selected;
}
