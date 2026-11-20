import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/food_item.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_en.dart';
import '../l10n/app_localizations_ar.dart';

const foodLabelsAr = <String, String>{
  'American & Latin': 'أمريكي ولاتيني',
  'Asian': 'آسيوي',
  'Cafes & Bakeries': 'المقاهي والمخابز',
  'Egyptian': 'مصري',
  'European': 'أوروبي',
  'Middle Eastern & African': 'شرق أوسطي وأفريقي',
  'Raw & Fitness Staples': 'مكونات نيئة وأطعمة رياضية',
  'Restaurants & Fast Food': 'مطاعم ووجبات سريعة',
  'Snacks': 'وجبات خفيفة',
  'Asian Traditional & Fancy Food': 'أطعمة آسيوية تقليدية وراقية',
  'Egyptian Traditional & Homemade Food': 'أطعمة مصرية تقليدية ومنزلية',
  'European Traditional & Fancy Food': 'أطعمة أوروبية تقليدية وراقية',
  'European Traditional Food': 'أطعمة أوروبية تقليدية',
  'European, American & Asian Cuisines': 'مطابخ أوروبية وأمريكية وآسيوية',
  'Middle Eastern & African Cuisine': 'المطبخ الشرق أوسطي والأفريقي',
  'Popular Restaurants & Fast Food Chains': 'مطاعم شهيرة وسلاسل وجبات سريعة',
  'Raw Ingredients & Fitness Staples': 'مكونات نيئة وأطعمة رياضية',
  'Snacks & Street Nibbles': 'وجبات خفيفة وأطعمة الشارع',
  'American': 'أمريكي',
  'American BBQ': 'مشويات أمريكية',
  'Austrian / German': 'نمساوي / ألماني',
  'B.Laban (بـ لبن)': 'بـ لبن',
  'Bahraini / Gulf': 'بحريني / خليجي',
  'Bakery / Cafe': 'مخبز / مقهى',
  'Bazooka (بازوكا)': 'بازوكا',
  'Belgian': 'بلجيكي',
  'British': 'بريطاني',
  'Cadbury / Galaxy': 'Cadbury / Galaxy',
  'Cafe / Patisserie': 'مقهى / حلويات',
  'Chinese': 'صيني',
  'Chinese (Cantonese)': 'صيني كانتوني',
  'Chinese (Shanghainese)': 'صيني من شنغهاي',
  'Chinese (Sichuan)': 'صيني من سيتشوان',
  'Chinese Fine Dining': 'مطبخ صيني راقٍ',
  "Chipsy / Lay's": "Chipsy / Lay's",
  'Cinnabon / Cafe': 'Cinnabon / مقهى',
  'Doritos': 'Doritos',
  'Edita (مولتو)': 'مولتو',
  'Egyptian Bakery': 'مخبز مصري',
  'Egyptian Homemade': 'أكل مصري منزلي',
  'El Dahan (الدهان)': 'الدهان',
  'Emirati': 'إماراتي',
  'Emirati / Gulf': 'إماراتي / خليجي',
  'Emirati / Kuwaiti': 'إماراتي / كويتي',
  'Emirati / Kuwaiti / Bahraini': 'إماراتي / كويتي / بحريني',
  'Emirati / Kuwaiti / Qatari': 'إماراتي / كويتي / قطري',
  'Emirati / Omani Fine Dining': 'مطبخ إماراتي / عماني راقٍ',
  'Emirati / Qatari / Bahraini': 'إماراتي / قطري / بحريني',
  'Ethiopian': 'إثيوبي',
  'Ethiopian / Eritrean': 'إثيوبي / إريتري',
  'Ethiopian Fine Dining': 'مطبخ إثيوبي راقٍ',
  'Fitness Staple': 'طعام رياضي أساسي',
  'French': 'فرنسي',
  'French / Belgian': 'فرنسي / بلجيكي',
  'Gad (جاد)': 'جاد',
  'German': 'ألماني',
  'German / Austrian': 'ألماني / نمساوي',
  'Ghanaian': 'غاني',
  'Greek': 'يوناني',
  'Hungarian': 'مجري',
  'Indian': 'هندي',
  'Indonesian / Malaysian': 'إندونيسي / ماليزي',
  'Irish': 'أيرلندي',
  'Italian': 'إيطالي',
  'Italian (Coastal)': 'إيطالي ساحلي',
  'Italian (Emilian)': 'إيطالي من إميليا',
  'Italian (Ligurian)': 'إيطالي من ليغوريا',
  'Italian (Neapolitan)': 'إيطالي من نابولي',
  'Italian (Piedmontese)': 'إيطالي من بيدمونت',
  'Italian (Pugliese)': 'إيطالي من بوليا',
  'Italian (Roman)': 'إيطالي من روما',
  'Italian (Sicilian)': 'إيطالي من صقلية',
  'Italian (Southern)': 'إيطالي جنوبي',
  'Italian (Tuscan)': 'إيطالي من توسكانا',
  'Italian / Italian-American': 'إيطالي / إيطالي أمريكي',
  'Italian Fine Dining': 'مطبخ إيطالي راقٍ',
  'Italian Fine Dining (Piedmontese)': 'مطبخ إيطالي راقٍ من بيدمونت',
  'Italian Fine Dining (Tuscan)': 'مطبخ إيطالي راقٍ من توسكانا',
  'Italian Fine Dining (Venetian)': 'مطبخ إيطالي راقٍ من البندقية',
  'Japanese': 'ياباني',
  'Japanese Fine Dining': 'مطبخ ياباني راقٍ',
  'Jordanian / Levantine': 'أردني / شامي',
  'Kenyan / Tanzanian': 'كيني / تنزاني',
  'KFC': 'KFC',
  'Korean': 'كوري',
  'Koshary El Tahrir (كشري التحرير)': 'كشري التحرير',
  'Krispy Kreme / Dunkin / Bakery': 'Krispy Kreme / Dunkin / مخبز',
  'Kuwaiti / Gulf': 'كويتي / خليجي',
  'Levantine': 'شامي',
  "McDonald's": "McDonald's",
  "McVitie's / Packaged": "McVitie's / معبأ",
  'Mexican': 'مكسيكي',
  'Middle Eastern / Fitness Staple': 'شرق أوسطي / طعام رياضي أساسي',
  'Moroccan': 'مغربي',
  'Moroccan / Maghrebi': 'مغربي / من المغرب العربي',
  'Moroccan Fine Dining': 'مطبخ مغربي راقٍ',
  'Nigerian': 'نيجيري',
  'Nigerian / Ghanaian': 'نيجيري / غاني',
  'Omani': 'عماني',
  'Oreo / Mondelez': 'Oreo / Mondelez',
  'Packaged Snack': 'وجبة خفيفة معبأة',
  'Palestinian / Levantine': 'فلسطيني / شامي',
  'Peruvian': 'بيروفي',
  'Polish': 'بولندي',
  'Portuguese': 'برتغالي',
  'Qatari / Bahraini': 'قطري / بحريني',
  'Qatari / Emirati / Gulf': 'قطري / إماراتي / خليجي',
  'Raw Ingredient': 'مكون نيء',
  'Saudi (Hijazi)': 'سعودي حجازي',
  'Saudi (Najdi)': 'سعودي نجدي',
  'Saudi (Qassim)': 'سعودي من القصيم',
  'Saudi / Gulf': 'سعودي / خليجي',
  'Saudi / Yemeni': 'سعودي / يمني',
  'Senegalese': 'سنغالي',
  'Snack / Cinema': 'وجبة خفيفة / سينما',
  'Snack Staple': 'وجبة خفيفة أساسية',
  'South African': 'جنوب أفريقي',
  'Spanish': 'إسباني',
  'Starbucks': 'Starbucks',
  'Sudanese': 'سوداني',
  'Supplement / Fitness Staple': 'مكمل / طعام رياضي أساسي',
  'Swedish': 'سويدي',
  'Swiss': 'سويسري',
  'Thai': 'تايلاندي',
  'Toppings, Oils & Condiments': 'إضافات وزيوت وتوابل',
  'Tunisian': 'تونسي',
  'Tunisian / Maghrebi': 'تونسي / من المغرب العربي',
  'Turkish': 'تركي',
  'Turkish (Hatay)': 'تركي من هاتاي',
  'Turkish (Kayseri)': 'تركي من قيصري',
  'Turkish (Ottoman)': 'تركي عثماني',
  'Vietnamese': 'فيتنامي',
  'West African': 'غرب أفريقي',
  'Yemeni / Gulf': 'يمني / خليجي',
  'Yemeni / Saudi': 'يمني / سعودي',
};

const displayedFoodTags = <String>[
  'high-protein',
  'fitness-staple',
  'breakfast',
  'street-food',
  'vegan',
  'keto-friendly',
  'low-carb',
  'cooking-oil',
  'topping',
  'snack',
  'dessert',
  'raw',
  'cooked',
];

String foodLabel(String value, {required bool arabic}) =>
    arabic ? foodLabelsAr[value] ?? value : value;

String localizedFoodGroup(String group, AppLocalizations l) => switch (group) {
      'American & Latin' => l.groupAmerican,
      'Asian' => l.groupAsian,
      'Cafes & Bakeries' => l.groupCafes,
      'Egyptian' => l.groupEgyptian,
      'European' => l.groupEuropean,
      'Middle Eastern & African' => l.groupMiddleEastern,
      'Raw & Fitness Staples' => l.groupRaw,
      'Restaurants & Fast Food' => l.groupRestaurants,
      'Snacks' => l.groupSnacks,
      _ => group,
    };

String localizedFoodTag(String tag, AppLocalizations l) => switch (tag) {
      'high-protein' => l.tagProtein,
      'fitness-staple' => l.tagFitness,
      'breakfast' => l.foodBreakfast,
      'street-food' => l.tagStreet,
      'vegan' => l.tagVegan,
      'keto-friendly' => l.tagKeto,
      'low-carb' => l.tagLowCarb,
      'cooking-oil' => l.tagOils,
      'topping' => l.tagToppings,
      'snack' => l.foodSnacks,
      'dessert' => l.tagDesserts,
      'raw' => l.tagRaw,
      'cooked' => l.tagCooked,
      _ => tag,
    };

String defaultActivityName(String name, AppLocalizations l) => switch (name) {
      'High-Protein Fuel' => l.defaultHighProteinFuel,
      'Athletic Training' => l.defaultAthleticTraining,
      'Quick Calorie Snack' => l.defaultQuickCalorieSnack,
      'Quick Exercise Burn' => l.defaultQuickExerciseBurn,
      _ => name,
    };

const foodDietaryTags = <String>[
  'high-protein',
  'fitness-staple',
  'vegan',
  'keto-friendly',
  'street-food',
  'raw',
  'cooked',
];

String normalizeFoodSearch(String text) {
  final out = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    if ((rune >= 0x0610 && rune <= 0x061a) ||
        (rune >= 0x064b && rune <= 0x065f) ||
        rune == 0x0670 ||
        (rune >= 0x06d6 && rune <= 0x06ed) ||
        rune == 0x0640) {
      continue;
    }
    if (rune >= 0x0660 && rune <= 0x0669) {
      out.writeCharCode(0x30 + rune - 0x0660);
    } else if (rune >= 0x06f0 && rune <= 0x06f9) {
      out.writeCharCode(0x30 + rune - 0x06f0);
    } else if (rune == 0x0623 || rune == 0x0625 || rune == 0x0622) {
      out.write('ا');
    } else if (rune == 0x0649) {
      out.write('ي');
    } else if (rune == 0x0629) {
      out.write('ه');
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString().trim();
}

class _IndexedFood {
  _IndexedFood(this.food)
      : fields = [
          food.nameEn,
          food.nameAr,
          food.category,
          food.categoryGroup,
          food.cuisineOrBrand,
          ...food.tags,
          foodLabel(food.category, arabic: true),
          localizedFoodGroup(food.categoryGroup, AppLocalizationsAr()),
          foodLabel(food.cuisineOrBrand, arabic: true),
          ...food.tags.where(displayedFoodTags.contains).expand((tag) => [
                localizedFoodTag(tag, AppLocalizationsEn()),
                localizedFoodTag(tag, AppLocalizationsAr()),
              ]),
        ].map(normalizeFoodSearch).toList(growable: false);
  final FoodItem food;
  final List<String> fields;
}

List<FoodItem> _parseFoods(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  if (json['version'] != 1) {
    throw FormatException(
        'Unsupported food database version: ${json['version']}');
  }
  final foods = (json['foods'] as List<dynamic>)
      .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
      .toList();
  if (json['count'] != foods.length ||
      foods.map((item) => item.id).toSet().length != foods.length) {
    throw const FormatException('Food database count or IDs are invalid.');
  }
  return foods;
}

class FoodDatabase {
  FoodDatabase._(this._bundle);
  factory FoodDatabase() => _shared;
  @visibleForTesting
  FoodDatabase.withBundle(AssetBundle bundle) : _bundle = bundle;

  static final FoodDatabase _shared = FoodDatabase._(rootBundle);
  static const assetPath = 'assets/data/foods.json';
  final AssetBundle _bundle;
  Future<void>? _loading;
  List<FoodItem>? _foods;
  List<_IndexedFood>? _index;
  List<String>? _categoryGroups;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final source = await _bundle.loadString(assetPath, cache: false);
      final foods = await compute(_parseFoods, source);
      _foods = List.unmodifiable(foods);
      _index = foods.map(_IndexedFood.new).toList(growable: false);
      _categoryGroups =
          List.unmodifiable(foods.map((food) => food.categoryGroup).toSet());
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  List<FoodItem> get foods =>
      _foods ?? (throw StateError('Call and await FoodDatabase.load() first.'));
  List<String> get categoryGroups =>
      _categoryGroups ??
      (throw StateError('Call and await FoodDatabase.load() first.'));

  List<FoodItem> search(String query,
      {String? categoryGroup, Iterable<String> tags = const [], int? limit}) {
    if (limit != null && limit < 0) {
      throw RangeError.value(limit, 'limit', 'Must not be negative');
    }
    final index = _index ??
        (throw StateError('Call and await FoodDatabase.load() first.'));
    final normalized = normalizeFoodSearch(query);
    final requiredTags = tags.toSet();
    final matches = <(int, int, FoodItem)>[];
    for (var i = 0; i < index.length; i++) {
      final item = index[i];
      if (categoryGroup != null && item.food.categoryGroup != categoryGroup) {
        continue;
      }
      if (!requiredTags.every(item.food.tags.contains)) continue;
      var rank = normalized.isEmpty ? 0 : 4;
      for (final field in item.fields) {
        if (normalized.isEmpty) break;
        var start = field.indexOf(normalized);
        while (start >= 0) {
          final end = start + normalized.length;
          final before =
              start == 0 || !_wordCharacter(field.codeUnitAt(start - 1));
          final after =
              end == field.length || !_wordCharacter(field.codeUnitAt(end));
          final candidate = before && after
              ? 0
              : before
                  ? 1
                  : 2;
          if (candidate < rank) rank = candidate;
          start = field.indexOf(normalized, start + 1);
        }
      }
      if (rank < 4) matches.add((rank, i, item.food));
    }
    matches.sort((a, b) {
      final rank = a.$1.compareTo(b.$1);
      return rank != 0 ? rank : a.$2.compareTo(b.$2);
    });
    final result = matches.map((match) => match.$3);
    return List.unmodifiable(limit == null ? result : result.take(limit));
  }
}

bool _wordCharacter(int unit) =>
    (unit >= 0x30 && unit <= 0x39) ||
    (unit >= 0x61 && unit <= 0x7a) ||
    unit == 0x5f ||
    (unit >= 0x0600 && unit <= 0x06ff) ||
    (unit >= 0x0750 && unit <= 0x077f) ||
    (unit >= 0x08a0 && unit <= 0x08ff);
