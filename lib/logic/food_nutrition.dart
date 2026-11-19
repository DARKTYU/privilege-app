import 'dart:ui' show TextDirection;

import '../models/food_item.dart';

const foodNutritionDisclaimer = 'Nutrition values are approximate estimates.';

PortionResult calculateFoodPortion(Nutrition nutrition, double grams) {
  if (!grams.isFinite || grams < 1 || grams > 3000) {
    throw RangeError.range(grams, 1, 3000, 'grams');
  }
  final scale = grams / 100;
  double rounded(double value) => (value * scale * 10).round() / 10;
  return PortionResult(
    grams: grams,
    kcal: (nutrition.kcal * scale).round(),
    proteinG: rounded(nutrition.proteinG),
    carbsG: rounded(nutrition.carbsG),
    fatG: rounded(nutrition.fatG),
    fiberG: rounded(nutrition.fiberG),
    sugarG: rounded(nutrition.sugarG),
    sodiumMg: rounded(nutrition.sodiumMg),
  );
}

List<FoodPortionOption> foodPortionOptions(FoodItem food) => List.unmodifiable([
      ...food.servings.map(FoodPortionOption.serving),
      const FoodPortionOption.custom(),
    ]);

TextDirection foodNameDirection(String name) =>
    RegExp(r'[\u0620-\u063f\u0641-\u064a\u066e-\u06d3\u06fa-\u06fc\u0750-\u077f\u08a0-\u08c9\ufb50-\ufdff\ufe70-\ufefc]')
            .hasMatch(name)
        ? TextDirection.rtl
        : TextDirection.ltr;
