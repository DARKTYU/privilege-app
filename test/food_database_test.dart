import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/food_nutrition.dart';
import 'package:privilege/services/food_database.dart';
import 'package:privilege/l10n/app_localizations_ar.dart';
import 'package:privilege/l10n/app_localizations_en.dart';

class _CountingBundle extends CachingAssetBundle {
  int reads = 0;
  @override
  Future<ByteData> load(String key) async {
    reads++;
    return rootBundle.load(key);
  }
}

class _RetryBundle extends CachingAssetBundle {
  int reads = 0;
  @override
  Future<ByteData> load(String key) async {
    reads++;
    if (reads == 1) throw StateError('Asset temporarily unavailable');
    return rootBundle.load(key);
  }
}

class _FixtureBundle extends CachingAssetBundle {
  _FixtureBundle(this.document);
  final String document;
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(document)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FoodDatabase database;

  setUpAll(() async {
    database = FoodDatabase();
    await database.load();
  });

  test('asset has 275 foods, unique IDs and nine categories', () {
    expect(database.foods, hasLength(275));
    expect(database.foods.map((food) => food.id).toSet(), hasLength(275));
    expect(database.categoryGroups, hasLength(9));
    expect(() => database.foods.clear(), throwsUnsupportedError);
    expect(database.foods.first.servings, isNotEmpty);
    expect(database.foods.first.dataSource, isNotEmpty);
  });

  test('all stored categories and displayed cuisines have lookup entries', () {
    final categories = database.foods.map((f) => f.category).toSet();
    final cuisines = database.foods.map((f) => f.cuisineOrBrand).toSet();
    expect(categories, hasLength(10));
    expect(cuisines, hasLength(118));
    for (final value in {...categories, ...cuisines}) {
      expect(foodLabelsAr.containsKey(value), isTrue, reason: value);
      expect(foodLabelsAr[value]!.trim(), isNotEmpty, reason: value);
    }
    expect(foodLabel('American BBQ', arabic: true), 'مشويات أمريكية');
    expect(foodLabel('Chinese Fine Dining', arabic: true), 'مطبخ صيني راقٍ');
    expect(foodLabel('Unknown label', arabic: true), 'Unknown label');
    expect(foodLabel('American BBQ', arabic: false), 'American BBQ');
  });

  test(
      'search indexes displayed category, cuisine and tag labels in both languages',
      () {
    final en = AppLocalizationsEn();
    final ar = AppLocalizationsAr();
    for (final food in database.foods) {
      for (final term in [
        localizedFoodGroup(food.categoryGroup, ar),
        foodLabel(food.cuisineOrBrand, arabic: true),
        food.cuisineOrBrand,
        ...food.tags.where(displayedFoodTags.contains).expand(
            (tag) => [localizedFoodTag(tag, ar), localizedFoodTag(tag, en)]),
      ]) {
        expect(database.search(term).map((f) => f.id), contains(food.id),
            reason: '${food.id}: $term');
      }
    }
  });

  test('only exact default names are translated', () {
    final ar = AppLocalizationsAr();
    final en = AppLocalizationsEn();
    for (final (name, translation) in [
      ('High-Protein Fuel', ar.defaultHighProteinFuel),
      ('Athletic Training', ar.defaultAthleticTraining),
      ('Quick Calorie Snack', ar.defaultQuickCalorieSnack),
      ('Quick Exercise Burn', ar.defaultQuickExerciseBurn),
    ]) {
      expect(defaultActivityName(name, ar), translation);
      expect(defaultActivityName(name, en), name);
      expect(defaultActivityName('$name custom', ar), '$name custom');
      expect(defaultActivityName(name.toLowerCase(), ar), name.toLowerCase());
    }
  });

  test('concurrent loads read the asset only once', () async {
    final bundle = _CountingBundle();
    final db = FoodDatabase.withBundle(bundle);
    await Future.wait([db.load(), db.load(), db.load()]);
    await db.load();
    expect(bundle.reads, 1);
    expect(db.foods, hasLength(275));
  });

  test('failed loads surface errors and can be retried', () async {
    final bundle = _RetryBundle();
    final db = FoodDatabase.withBundle(bundle);
    await expectLater(db.load(), throwsStateError);
    expect(() => db.search(''), throwsStateError);
    await db.load();
    expect(bundle.reads, 2);
    expect(db.foods, hasLength(275));
  });

  test('digit normalization works in search and malformed assets fail',
      () async {
    final document =
        jsonDecode(await rootBundle.loadString(FoodDatabase.assetPath))
            as Map<String, dynamic>;
    final foods = document['foods'] as List<dynamic>;
    (foods.first as Map<String, dynamic>)['name_ar'] = 'تمر 123';
    final db = FoodDatabase.withBundle(_FixtureBundle(jsonEncode(document)));
    await db.load();
    expect(db.search('تمر ١٢٣').first.id, 'eg_koshary_traditional');
    document['count'] = 1;
    final invalid =
        FoodDatabase.withBundle(_FixtureBundle(jsonEncode(document)));
    await expectLater(invalid.load(), throwsFormatException);
  });

  test('search ranks whole words ahead of substring matches', () {
    expect(database.search('koshary').first.id, 'eg_koshary_traditional');
    expect(database.search('KOSHARY').first.id, 'eg_koshary_traditional');
    expect(database.search('ful').first.id, 'eg_ful_medames_plain');
    expect(database.search('كشري').first.id, 'eg_koshary_traditional');
    expect(database.search('فول').first.id, 'eg_ful_medames_plain');
    expect(database.search('تمر').first.id, 'snk_medjool_dates_pitted');
    expect(database.search('medames').first.id, 'eg_ful_medames_plain');
    expect(database.search('street-food'), isNotEmpty);
    expect(database.search('this food does not exist'), isEmpty);
  });

  test('Arabic normalization handles variants, diacritics and digits', () {
    expect(normalizeFoodSearch('إِأآ ى ة تـمر ١٢٣ ۴۵'), 'ااا ي ه تمر 123 45');
    expect(database.search('فُــول').first.id, 'eg_ful_medames_plain');
    expect(database.search('كِشْرِي').first.id, 'eg_koshary_traditional');
    expect(normalizeFoodSearch('رقم ١٢٣'), normalizeFoodSearch('رقم 123'));
  });

  test('filters use category groups and require every tag', () {
    final filtered = database
        .search('', categoryGroup: 'Egyptian', tags: ['vegan', 'street-food']);
    expect(filtered, isNotEmpty);
    expect(
        filtered.every((food) =>
            food.categoryGroup == 'Egyptian' &&
            food.tags.contains('vegan') &&
            food.tags.contains('street-food')),
        isTrue);
    expect(database.search('', tags: ['not-a-tag']), isEmpty);
    expect(database.search('', limit: 3), hasLength(3));
    expect(database.search('', limit: 0), isEmpty);
    expect(() => database.search('', limit: -1), throwsRangeError);
    expect(foodDietaryTags, hasLength(7));
  });

  test('portion math and custom serving option', () {
    final food = database.foods
        .firstWhere((food) => food.id == 'eg_koshary_traditional');
    final result = calculateFoodPortion(food.per100g, 200);
    expect(result.grams, 200);
    expect(result.kcal, 344);
    expect(result.proteinG, 10.8);
    expect(result.carbsG, 57);
    expect(result.fatG, 8.2);
    expect(result.fiberG, 6.4);
    expect(result.sugarG, 4.8);
    expect(result.sodiumMg, 770);
    expect(calculateFoodPortion(food.per100g, 33).proteinG, 1.8);
    expect(calculateFoodPortion(food.per100g, 1).grams, 1);
    expect(calculateFoodPortion(food.per100g, 3000).grams, 3000);
    for (final grams in [0.0, 3001.0, double.nan, double.infinity]) {
      expect(() => calculateFoodPortion(food.per100g, grams), throwsRangeError);
    }
    final options = foodPortionOptions(food);
    expect(options.length, food.servings.length + 1);
    expect(options.first.serving, food.servings.first);
    expect(options.last.isCustom, isTrue);
    expect(
        foodNutritionDisclaimer, 'Nutrition values are approximate estimates.');
  });

  test('direction depends on Arabic letters, not Arabic digits alone', () {
    expect(foodNameDirection('Koshary'), TextDirection.ltr);
    expect(foodNameDirection('كشري'), TextDirection.rtl);
    expect(foodNameDirection('Food ١٢'), TextDirection.ltr);
  });

  test('asset metadata matches the parsed list', () async {
    final document =
        jsonDecode(await rootBundle.loadString(FoodDatabase.assetPath))
            as Map<String, dynamic>;
    expect(document['version'], 1);
    expect(document['count'], database.foods.length);
  });
}
