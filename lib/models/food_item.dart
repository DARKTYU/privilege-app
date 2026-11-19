class Nutrition {
  const Nutrition({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) => Nutrition(
        kcal: (json['kcal'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
        fiberG: (json['fiber_g'] as num).toDouble(),
        sugarG: (json['sugar_g'] as num).toDouble(),
        sodiumMg: (json['sodium_mg'] as num).toDouble(),
      );

  final double kcal, proteinG, carbsG, fatG, fiberG, sugarG, sodiumMg;
}

class FoodServing {
  const FoodServing({
    required this.nameEn,
    required this.nameAr,
    required this.grams,
  });

  factory FoodServing.fromJson(Map<String, dynamic> json) => FoodServing(
        nameEn: json['name_en'] as String,
        nameAr: json['name_ar'] as String,
        grams: (json['grams'] as num).toDouble(),
      );

  final String nameEn, nameAr;
  final double grams;
}

class FoodItem {
  FoodItem({
    required this.id,
    required this.batch,
    required this.nameEn,
    required this.nameAr,
    required this.category,
    required this.categoryGroup,
    required this.cuisineOrBrand,
    required this.per100g,
    required List<FoodServing> servings,
    required List<String> tags,
    required this.dataSource,
  })  : servings = List.unmodifiable(servings),
        tags = List.unmodifiable(tags);

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        batch: (json['batch'] as num).toInt(),
        nameEn: json['name_en'] as String,
        nameAr: json['name_ar'] as String,
        category: json['category'] as String,
        categoryGroup: json['category_group'] as String,
        cuisineOrBrand: json['cuisine_or_brand'] as String,
        per100g: Nutrition.fromJson(json['per_100g'] as Map<String, dynamic>),
        servings: (json['servings'] as List<dynamic>)
            .map((value) => FoodServing.fromJson(value as Map<String, dynamic>))
            .toList(),
        tags: (json['tags'] as List<dynamic>).cast<String>(),
        dataSource: json['data_source'] as String,
      );

  final String id, nameEn, nameAr, category, categoryGroup, cuisineOrBrand;
  final String dataSource;
  final int batch;
  final Nutrition per100g;
  final List<FoodServing> servings;
  final List<String> tags;
}

class PortionResult {
  const PortionResult({
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
  });

  final double grams, proteinG, carbsG, fatG, fiberG, sugarG, sodiumMg;
  final int kcal;
}

class FoodPortionOption {
  const FoodPortionOption.serving(this.serving);
  const FoodPortionOption.custom() : serving = null;
  final FoodServing? serving;
  bool get isCustom => serving == null;
}
