import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/calorie_target.dart';
import 'package:privilege/logic/user_profile.dart';
import 'package:privilege/screens/calorie_profile_sheet.dart';
import 'package:privilege/screens/calories.dart';
import 'package:privilege/services/food_database.dart';
import 'package:privilege/state.dart';
import 'package:privilege/ui.dart';

class _ProfileState extends AppState {
  bool fail = false;
  int saves = 0;

  @override
  Future<void> saveTargetProfile({
    required double weightKg,
    required double heightCm,
    required DateTime birthDate,
    required TargetSex sex,
    required TargetActivity activity,
  }) async {
    if (fail) throw StateError('offline');
    saves++;
    profile = profile.copyWith(
      weightKg: weightKg,
      heightCm: heightCm,
      hasWeight: true,
      hasHeight: true,
      birthDate: birthDate,
      sex: sex,
      activity: activity,
      nutritionGoal: NutritionGoal.maintain,
    );
    targetCalories = calorieTarget.target!;
    notifyListeners();
  }
}

void main() {
  setUpAll(() async => FoodDatabase().load());

  testWidgets('reminder dismisses only for the current session',
      (tester) async {
    final state = _ProfileState();
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(body: FoodLogTab(state: state)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Complete your profile for an accurate target'),
        findsOneWidget);
    expect(
        tester
            .getTopLeft(
                find.text('Complete your profile for an accurate target'))
            .dy,
        greaterThan(tester
            .getBottomLeft(find.byKey(const ValueKey('add-food-button')))
            .dy));
    expect(find.textContaining('Estimated'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Dismiss profile reminder'));
    await tester.tap(find.byTooltip('Dismiss profile reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Complete your profile for an accurate target'),
        findsNothing);
    final nextSession = _ProfileState();
    addTearDown(nextSession.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(body: FoodLogTab(state: nextSession)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Complete your profile for an accurate target'),
        findsOneWidget);
  });

  testWidgets('sheet previews and saves editable personal details',
      (tester) async {
    final state = _ProfileState()
      ..profile = defaultUserProfile.copyWith(
        weightKg: 80,
        heightCm: 180,
        birthDate: DateTime(DateTime.now().year - 30, 1, 1),
        nutritionGoal: NutritionGoal.maintain,
      );
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    onPressed: () => showCalorieProfileSheet(context, state),
                    child: const Text('Open'),
                  ))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male'));
    await tester.ensureVisible(find.text('Moderate'));
    await tester.tap(find.text('Moderate'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your daily target: 2760 kcal'), findsOneWidget);
    expect(find.textContaining('BMR: 1780'), findsOneWidget);
    expect(find.text('Estimates are not medical advice.'), findsOneWidget);
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(state.saves, 1);
    expect(state.targetCalories, 2760);
    expect(state.profile.sex, TargetSex.male);
    expect(state.profile.activity, TargetActivity.moderate);
    expect(find.text('Complete your profile'), findsNothing);
  });

  testWidgets('invalid details and save errors leave the sheet open',
      (tester) async {
    final state = _ProfileState()
      ..fail = true
      ..profile = defaultUserProfile.copyWith(
        birthDate: DateTime(DateTime.now().year - 30, 1, 1),
        sex: TargetSex.female,
        activity: TargetActivity.light,
        nutritionGoal: NutritionGoal.maintain,
      );
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    onPressed: () => showCalorieProfileSheet(context, state),
                    child: const Text('Open'),
                  ))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('target-weight')), '29');
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter a valid birth date'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('target-weight')));
    await tester.enterText(find.byKey(const ValueKey('target-weight')), '60');
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save your profile'), findsOneWidget);
    expect(state.saves, 0);
    expect(state.profile.weightKg, defaultUserProfile.weightKg);
  });
}
