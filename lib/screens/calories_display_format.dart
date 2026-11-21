import '../ui.dart';

String formatCaloriesGrams(double value) => fmt(value);

String formatCaloriesServingLabel(String label) => label.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*g\b'),
      (match) => '${formatCaloriesGrams(double.parse(match[1]!))} g',
    );

String formatCaloriesCategory(String category, String brand) {
  final normalizedCategory = category.trim();
  final normalizedBrand = brand.trim();
  if (normalizedBrand.isEmpty ||
      normalizedCategory.toLowerCase() == normalizedBrand.toLowerCase()) {
    return normalizedCategory;
  }
  if (normalizedCategory.isEmpty) return normalizedBrand;
  return '$normalizedCategory • $normalizedBrand';
}
