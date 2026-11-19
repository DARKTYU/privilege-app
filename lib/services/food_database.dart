import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/food_item.dart';

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
          food.cuisineOrBrand,
          ...food.tags,
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
