import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/data.dart';
import 'package:privilege/logic/fitness_logic.dart';

void main() {
  test('all recipe and guide fields have complete Arabic translations', () {
    expect(recipes, hasLength(10));
    expect(guides, hasLength(6));
    for (final recipe in recipes) {
      expect(recipe.nameAr.trim(), isNotEmpty, reason: recipe.id);
      expect(recipe.descriptionAr.trim(), isNotEmpty, reason: recipe.id);
      expect(recipe.stepsAr, hasLength(recipe.steps.length), reason: recipe.id);
      expect(recipe.stepsAr.every((s) => s.trim().isNotEmpty), isTrue,
          reason: recipe.id);
    }
    expect(recipes.fold<int>(0, (n, r) => n + r.steps.length), 30);
    for (final guide in guides) {
      for (final field in [
        guide.titleAr,
        guide.subCategoryAr,
        guide.difficultyAr
      ]) {
        expect(field.trim(), isNotEmpty, reason: guide.id);
      }
      for (final pair in [
        (guide.muscles, guide.musclesAr),
        (guide.cues, guide.cuesAr),
        (guide.mistakes, guide.mistakesAr),
      ]) {
        expect(pair.$2, hasLength(pair.$1.length), reason: guide.id);
        expect(pair.$2.every((s) => s.trim().isNotEmpty), isTrue,
            reason: guide.id);
      }
    }
    expect(guides.fold<int>(0, (n, g) => n + g.cues.length), 24);
    expect(guides.fold<int>(0, (n, g) => n + g.mistakes.length), 15);
  });

  test('missing or blank Arabic fields fall back individually to English', () {
    const recipe = Recipe(
      id: 'example',
      name: 'Name',
      nameAr: ' ',
      minutes: 1,
      difficulty: 'Easy',
      description: 'Description',
      ingredients: [],
      steps: ['First', 'Second'],
      stepsAr: [' ', 'الثانية'],
      emoji: '',
      category: MealCategory.lunch,
    );
    expect(recipe.localizedName(true), 'Name');
    expect(recipe.localizedDescription(true), 'Description');
    expect(recipe.localizedStep(0, true), 'First');
    expect(recipe.localizedStep(1, true), 'الثانية');
    expect(recipe.localizedStep(1, false), 'Second');
    const guide = ExerciseGuide(
      id: 'example',
      title: 'Title',
      category: 'gym',
      subCategory: 'Category',
      difficulty: 'Beginner',
      muscles: ['Muscle', 'Other'],
      musclesAr: ['عضلة'],
      cues: ['Cue'],
      cuesAr: [' '],
      mistakes: ['Mistake'],
      burnRate: '0',
    );
    expect(guide.localizedTitle(true), 'Title');
    expect(guide.localizedSubCategory(true), 'Category');
    expect(guide.localizedDifficulty(true), 'Beginner');
    expect(guide.localizedMuscles(true), ['عضلة', 'Other']);
    expect(guide.localizedCues(true), ['Cue']);
    expect(guide.localizedMistakes(true), ['Mistake']);
  });
}
