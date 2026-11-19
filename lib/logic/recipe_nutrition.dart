import '../data.dart';
import '../models/food_item.dart';
import 'food_nutrition.dart';

class RecipeNutrition {
  const RecipeNutrition(this.ingredients, this.portion);
  final List<(FoodItem, double)> ingredients;
  final PortionResult portion;
}

RecipeNutrition? calculateRecipeNutrition(Recipe recipe, List<FoodItem> foods) {
  final byId = {for (final food in foods) food.id: food};
  final resolved = <(FoodItem, double)>[];
  final portions = <PortionResult>[];
  for (final ingredient in recipe.ingredients) {
    final food = byId[ingredient.foodId];
    if (food == null) return null;
    resolved.add((food, ingredient.grams));
    portions.add(calculateFoodPortion(food.per100g, ingredient.grams));
  }
  double sum(double Function(PortionResult) field) =>
      portions.fold(0.0, (total, portion) => total + field(portion));
  double rounded(double value) => (value * 10).round() / 10;
  return RecipeNutrition(
    List.unmodifiable(resolved),
    PortionResult(
      grams: sum((p) => p.grams),
      kcal: portions.fold(0, (total, p) => total + p.kcal),
      proteinG: rounded(sum((p) => p.proteinG)),
      carbsG: rounded(sum((p) => p.carbsG)),
      fatG: rounded(sum((p) => p.fatG)),
      fiberG: rounded(sum((p) => p.fiberG)),
      sugarG: rounded(sum((p) => p.sugarG)),
      sodiumMg: rounded(sum((p) => p.sodiumMg)),
    ),
  );
}
