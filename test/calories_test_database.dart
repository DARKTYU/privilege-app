import 'package:flutter/services.dart';
import 'package:privilege/models/food_item.dart';
import 'package:privilege/services/food_database.dart';

class CaloriesTestDatabase extends FoodDatabase {
  CaloriesTestDatabase(this.source) : super.withBundle(rootBundle);
  final FoodDatabase source;

  @override
  Future<void> load() async {}

  @override
  List<FoodItem> get foods => source.foods;

  @override
  List<String> get categoryGroups => source.categoryGroups;

  @override
  List<FoodItem> search(String query,
          {String? categoryGroup,
          Iterable<String> tags = const [],
          int? limit}) =>
      source.search(query,
          categoryGroup: categoryGroup, tags: tags, limit: limit);
}
