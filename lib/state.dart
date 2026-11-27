import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'logic/fitness_logic.dart';
import 'l10n_strings.dart';
import 'logic/calorie_target.dart';
import 'logic/food_nutrition.dart';
import 'logic/user_profile.dart';
import 'models/food_item.dart';
import 'services/account_types.dart';
import 'services/activity_repository.dart';
import 'services/food_database.dart';
import 'services/supabase_auth_service.dart';
import 'services/session_recovery.dart';
import 'services/planner_repository.dart';
import 'services/cravings_repository.dart';
import 'services/classified_checks_repository.dart';

/// Port of FitnessContext.tsx plus profile, subscription and streak-arena state.
class AppState extends ChangeNotifier {
  AppState(
      {ActivityRepository? activityRepository,
      FoodDatabase? foodDatabase,
      PlannerDataSource? plannerRepository,
      CravingsDataSource? cravingsRepository,
      ClassifiedChecksDataSource? classifiedChecksRepository})
      : _activityRepository = activityRepository ?? ActivityRepository(),
        _foodDatabase = foodDatabase ?? FoodDatabase(),
        _plannerRepository = plannerRepository ?? PlannerRepository(),
        _cravingsRepository = cravingsRepository ?? CravingsRepository(),
        _classifiedRepository =
            classifiedChecksRepository ?? ClassifiedChecksRepository();

  Timer? _toastTimer;
  final ActivityRepository _activityRepository;
  final FoodDatabase _foodDatabase;
  final PlannerDataSource _plannerRepository;
  final CravingsDataSource _cravingsRepository;
  final ClassifiedChecksDataSource _classifiedRepository;

  String? get cravingsAccountId => _cravingsRepository.accountId;
  String? get classifiedAccountId => _classifiedRepository.accountId;

  Future<T> _accountRequest<T>(
      String? Function() account, Future<T> Function() action) async {
    final user = account();
    final generation = _plannerAccountGeneration;
    if (user == null) throw StateError(savedLanguageStrings().sessionExpired);
    final result = await action();
    if (user != account() || generation != _plannerAccountGeneration) {
      throw StateError(savedLanguageStrings().errorAccountChanged);
    }
    return result;
  }

  Future<List<Craving>> loadCravings(String start, String end) =>
      _accountRequest(() => cravingsAccountId,
          () => _cravingsRepository.loadMonth(start, end));
  Future<Craving> addCraving(String date, String notes) => _accountRequest(
      () => cravingsAccountId, () => _cravingsRepository.add(date, notes));
  Future<Craving> editCraving(String id, String date, String notes,
          {required String originalDate}) =>
      _accountRequest(
          () => cravingsAccountId,
          () => _cravingsRepository.edit(id, date, notes,
              originalDate: originalDate));
  Future<void> deleteCraving(String id) => _accountRequest(
      () => cravingsAccountId, () => _cravingsRepository.delete(id));
  Future<Set<String>> loadClassifiedChecks() =>
      _accountRequest(() => classifiedAccountId, _classifiedRepository.load);
  Future<void> setClassifiedChecked(String key, bool checked) =>
      _accountRequest(() => classifiedAccountId,
          () => _classifiedRepository.setChecked(key, checked));
  int _plannerGeneration = 0;
  int _plannerAccountGeneration = 0;
  bool _plannerSaving = false;
  bool plannerLoading = false;
  String? plannerError;
  String? plannerToday;
  String? plannerStart, plannerEnd;
  List<PlannerSplit> plannerSplits = [];
  List<PlannerDay> plannerDays = [];
  Set<String> plannerWorkoutDates = {};

  Future<String> plannerLocalToday() => _plannerRepository.today();
  String? get plannerAccountId => _plannerRepository.accountId;
  Future<List<PlannerSplit>> loadPlannerSplits() =>
      _plannerRepository.loadSplits();
  Future<PlannerDay?> loadPlannerDay(String date) =>
      _plannerRepository.loadDay(date);

  Future<void> loadPlanner(String start, String end) async {
    final user = _plannerRepository.accountId;
    final generation = ++_plannerGeneration;
    plannerLoading = true;
    plannerError = null;
    notifyListeners();
    try {
      if (user == null) throw StateError(savedLanguageStrings().sessionExpired);
      final result = await _plannerRepository.load(start, end);
      if (generation != _plannerGeneration ||
          user != _plannerRepository.accountId) {
        return;
      }
      plannerToday = result.today;
      plannerStart = start;
      plannerEnd = end;
      plannerSplits = List.unmodifiable(result.splits);
      plannerDays = List.unmodifiable(result.days);
      plannerWorkoutDates = Set.unmodifiable(result.workoutDates);
    } catch (error) {
      if (generation == _plannerGeneration &&
          user == _plannerRepository.accountId) {
        plannerError = friendlyError(error);
      }
    } finally {
      if (generation == _plannerGeneration &&
          user == _plannerRepository.accountId) {
        plannerLoading = false;
        notifyListeners();
      }
    }
  }

  Future<T> _plannerWrite<T>(
      Future<T> Function() action, void Function(T) apply) async {
    if (_plannerSaving) {
      throw StateError(savedLanguageStrings().errorPlannerBusy);
    }
    final user = _plannerRepository.accountId;
    if (user == null) throw StateError(savedLanguageStrings().sessionExpired);
    final accountGeneration = _plannerAccountGeneration;
    _plannerSaving = true;
    try {
      final result = await action();
      if (user == _plannerRepository.accountId &&
          accountGeneration == _plannerAccountGeneration) {
        _plannerGeneration++;
        plannerLoading = false;
        apply(result);
        notifyListeners();
      }
      return result;
    } finally {
      _plannerSaving = false;
    }
  }

  Future<void> createPlannerSplits(List<PlannerSplit> splits) async {
    await _plannerWrite(() => _plannerRepository.createSplits(splits),
        (created) {
      plannerSplits = List.unmodifiable([...plannerSplits, ...created]);
    });
  }

  Future<void> editPlannerSplit(PlannerSplit split) async {
    await _plannerWrite(() => _plannerRepository.updateSplit(split), (saved) {
      plannerSplits = List.unmodifiable([
        for (final item in plannerSplits)
          if (item.id == saved.id) saved else item
      ]);
    });
  }

  Future<void> deletePlannerSplit(String id) async {
    await _plannerWrite(() => _plannerRepository.deleteSplit(id), (_) {
      plannerSplits =
          List.unmodifiable(plannerSplits.where((item) => item.id != id));
    });
  }

  Future<void> savePlannerDay(PlannerDay day) async {
    await _plannerWrite(() => _plannerRepository.saveDay(day), (saved) {
      if (plannerStart != null &&
          plannerEnd != null &&
          saved.date.compareTo(plannerStart!) >= 0 &&
          saved.date.compareTo(plannerEnd!) <= 0) {
        plannerDays = List.unmodifiable(
            [...plannerDays.where((item) => item.date != saved.date), saved]);
      }
    });
  }

  Future<void> planDayFromSplit(String date, PlannerSplit split) =>
      savePlannerDay(PlannerDay(
          date: date,
          name: split.name,
          kind: split.kind,
          sourceSplitId: split.id,
          duration: split.duration,
          effort: split.effort));
  Future<void> markPlannerRest(String date) =>
      savePlannerDay(PlannerDay(date: date, name: 'Rest day', kind: 'rest'));
  Future<void> editPlannerDay(PlannerDay day) => savePlannerDay(day);

  Future<void> removePlannerDay(String date) async {
    await _plannerWrite(() => _plannerRepository.deleteDay(date), (_) {
      plannerDays =
          List.unmodifiable(plannerDays.where((item) => item.date != date));
    });
  }

  int _activityGeneration = 0;
  int _activityLoadGeneration = 0;
  String? _activityUserId;

  // ───────── account: sign-in, session, onboarding, profile, subscription ─────────
  bool loggedIn = false;
  bool onboardingDone = false;
  bool targetPromptDismissed = false;
  bool restoring =
      true; // true while the saved session is being checked at app start
  String?
      authNotice; // message shown on the login screen (e.g. "session expired")
  StreamSubscription<supabase.AuthState>? _authSubscription;
  // Set while a Google or Facebook sign-in is open in the browser, so that
  // only that sign-in (not registering or a password login) is completed
  // from the session event.
  DateTime? _socialSignInStarted;
  bool _socialSignInRunning = false;
  String email = '';
  String? profilePhotoBase64;
  UserProfile profile = defaultUserProfile;

  Future<void> restoreSession() async {
    _authSubscription ??=
        SupabaseAuthService.client.auth.onAuthStateChange.listen(
      (event) {
        if (event.event == supabase.AuthChangeEvent.signedOut &&
            SupabaseAuthService.client.auth.currentSession == null) {
          _clearAccount();
        } else if (event.event == supabase.AuthChangeEvent.signedIn &&
            event.session != null &&
            _socialSignInIsOpen) {
          unawaited(_completeSocialSignIn());
        }
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('Supabase authentication event failed: $error');
        final userId = SupabaseAuthService.client.auth.currentUser?.id;
        if (userId != null) {
          unawaited(SessionRecovery.forClient(SupabaseAuthService.client)
              .signOutIfCurrent(userId));
        } else {
          _clearAccount();
        }
      },
    );
    try {
      final acc = await SupabaseAuthService.restore();
      if (acc != null) {
        await signInWithAccount(acc);
      }
    } catch (error, stack) {
      debugPrint('Could not restore the Supabase session: $error\n$stack');
      final userId = SupabaseAuthService.client.auth.currentUser?.id;
      if (userId != null) {
        await SessionRecovery.forClient(SupabaseAuthService.client)
            .signOutIfCurrent(userId);
      }
      _clearAccount();
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> login(String identifier, String password) async =>
      signInWithAccount(await SupabaseAuthService.login(identifier, password));

  bool get _socialSignInIsOpen {
    final started = _socialSignInStarted;
    return started != null &&
        !loggedIn &&
        DateTime.now().difference(started) < const Duration(minutes: 5);
  }

  /// Opens the Google or Facebook sign-in page. The sign-in finishes when the
  /// browser returns to the app (see [_completeSocialSignIn]).
  Future<void> signInWithSocial(SocialProvider provider) async {
    _socialSignInStarted = DateTime.now();
    try {
      await SupabaseAuthService.startSocialSignIn(provider);
    } catch (_) {
      _socialSignInStarted = null;
      rethrow;
    }
  }

  /// Forgets an open social sign-in, e.g. when the person starts a password
  /// login or registration instead.
  void cancelSocialSignIn() => _socialSignInStarted = null;

  Future<void> _completeSocialSignIn() async {
    if (_socialSignInRunning) return;
    _socialSignInRunning = true;
    try {
      final acc = await SupabaseAuthService.restore();
      if (acc != null && !loggedIn) {
        _socialSignInStarted = null;
        await signInWithAccount(acc);
      }
    } catch (error, stack) {
      debugPrint('Could not finish the social sign-in: $error\n$stack');
      final userId = SupabaseAuthService.client.auth.currentUser?.id;
      if (userId != null) {
        await SessionRecovery.forClient(SupabaseAuthService.client)
            .signOutIfCurrent(userId);
      }
      _socialSignInStarted = null;
      authNotice = savedLanguageStrings().socialSignInFailed;
      notifyListeners();
    } finally {
      _socialSignInRunning = false;
    }
  }

  Future<void> signInWithAccount(AccountData acc) async {
    final preferences = await SharedPreferences.getInstance();
    final userId = SupabaseAuthService.client.auth.currentUser?.id;
    if (userId != acc.userId) throw const SessionExpiredException();
    profilePhotoBase64 =
        preferences.getString('privilege_profile_photo_$userId');
    _applyAccount(acc);
    authNotice = null;
    notifyListeners();
    await loadActivity();
  }

  void _applyAccount(AccountData a) {
    _clearPlanner();
    final p = a.profile;
    email = a.email;
    profile = defaultUserProfile.copyWith(
      username: a.username,
      name: p['full_name'] as String? ?? '',
      weightKg: (p['weight_kg'] as num?)?.toDouble(),
      heightCm: (p['height_cm'] as num?)?.toDouble(),
      targetGoal: p['training_goal'] as String? ?? '',
      bio: p['bio'] as String? ?? '',
      dailyCalorieTarget: (p['daily_calorie_target'] as num?)?.toInt(),
      hasWeight: p['weight_kg'] != null,
      hasHeight: p['height_cm'] != null,
      hasSavedTarget: p['daily_calorie_target'] != null,
      birthDate: DateTime.tryParse(p['birth_date'] as String? ?? ''),
      sex: TargetSex.values.where((v) => v.name == p['gender']).firstOrNull,
      activity: TargetActivity.values
          .where((v) => v.name == p['activity_level'])
          .firstOrNull,
      nutritionGoal:
          NutritionGoal.values.where((v) => v.name == p['goal']).firstOrNull,
      onboardingCompleted: p['onboarding_completed'] == true,
    );
    onboardingDone = p['onboarding_completed'] == true;
    targetPromptDismissed = false;
    targetCalories = targetForProfile(profile).target ?? 0;
    if (targetCalories > 0) {
      profile = profile.copyWith(dailyCalorieTarget: targetCalories);
    }
    loggedIn = true;
  }

  Future<void> logout() async {
    await SupabaseAuthService.logout();
    if (loggedIn) _clearAccount();
  }

  /// Permanently deletes the signed-in account on the server, then clears
  /// everything this phone still holds for it. Throws when the password is
  /// wrong or the server could not finish; nothing is cleared in that case.
  Future<void> deleteAccount(String password) async {
    final userId = SupabaseAuthService.client.auth.currentUser?.id;
    await SupabaseAuthService.deleteAccount(password);
    if (userId != null) {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove('privilege_profile_photo_$userId');
      } catch (_) {
        // The account is already gone; a leftover local photo is harmless.
      }
    }
    final notice = savedLanguageStrings().privacyDeleteDone;
    _clearAccount();
    authNotice = notice;
    notifyListeners();
  }

  void _clearAccount() {
    _activityGeneration++;
    _clearPlanner();
    _activityUserId = null;
    authNotice = null;
    loggedIn = false;
    onboardingDone = false;
    targetPromptDismissed = false;
    email = '';
    profile = defaultUserProfile;
    profilePhotoBase64 = null;
    _resetLocalData();
    notifyListeners();
  }

  void _clearPlanner() {
    _plannerGeneration++;
    _plannerAccountGeneration++;
    plannerSplits = [];
    plannerDays = [];
    plannerWorkoutDates = {};
    plannerToday = null;
    plannerStart = null;
    plannerEnd = null;
    plannerLoading = false;
    plannerError = null;
  }

  Future<void> setProfilePhoto(Uint8List bytes) async {
    final encoded = base64Encode(bytes);
    final preferences = await SharedPreferences.getInstance();
    final userId = SupabaseAuthService.client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException(
          'invalid_session', savedLanguageStrings().sessionExpired);
    }
    await preferences.setString('privilege_profile_photo_$userId', encoded);
    profilePhotoBase64 = encoded;
    notifyListeners();
  }

  Future<void> removeProfilePhoto() async {
    final preferences = await SharedPreferences.getInstance();
    final userId = SupabaseAuthService.client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException(
          'invalid_session', savedLanguageStrings().sessionExpired);
    }
    await preferences.remove('privilege_profile_photo_$userId');
    profilePhotoBase64 = null;
    notifyListeners();
  }

  // Wipes everything personal so the next person on this device never sees it.
  void _resetLocalData() {
    meals.clear();
    burns.clear();
    targetCalories = 2500;
    recentActionToast = null;
    streak = 0;
    longestStreak = 0;
    lastActivityDate = null;
    storePoints = 0;
    activityLoading = false;
    activityError = null;
  }

  Future<void> completeOnboarding(UserProfile p) async {
    if (SupabaseAuthService.client.auth.currentSession == null) {
      throw AuthException(
          'invalid_session', savedLanguageStrings().errorLogInSetup);
    }
    final goal = resolveNutritionGoal(p.targetGoal, p.nutritionGoal);
    final result = targetForProfile(
        p.copyWith(nutritionGoal: goal, hasWeight: true, hasHeight: true));
    await SupabaseAuthService.saveProfile({
      'username': p.username,
      'full_name': p.name,
      'weight_kg': p.weightKg,
      'height_cm': p.heightCm,
      'training_goal': p.targetGoal,
      'goal': goal.name,
      'bio': p.bio,
      'daily_calorie_target': result.target,
      'onboarding_completed': true,
    });
    profile = p.copyWith(
        nutritionGoal: goal,
        dailyCalorieTarget: result.target,
        hasWeight: true,
        hasHeight: true,
        hasSavedTarget: result.target != null);
    targetCalories = result.target ?? 0;
    onboardingDone = true;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile p) async {
    if (SupabaseAuthService.client.auth.currentSession == null) {
      throw AuthException(
          'invalid_session', savedLanguageStrings().sessionExpired);
    }
    final goal = resolveNutritionGoal(p.targetGoal, p.nutritionGoal);
    final result = targetForProfile(p.copyWith(nutritionGoal: goal));
    await SupabaseAuthService.saveProfile({
      if (p.username != profile.username) 'username': p.username,
      'full_name': p.name,
      'weight_kg': p.hasWeight ? p.weightKg : null,
      'height_cm': p.hasHeight ? p.heightCm : null,
      'training_goal': p.targetGoal,
      'goal': goal.name,
      'bio': p.bio,
      'daily_calorie_target': result.target,
      'onboarding_completed': onboardingDone,
    });
    profile = p.copyWith(
        nutritionGoal: goal,
        dailyCalorieTarget: result.target,
        hasSavedTarget: result.target != null);
    targetCalories = result.target ?? 0;
    notifyListeners();
  }

  CalorieTarget targetForProfile(UserProfile p, {DateTime? today}) =>
      CalorieTarget.calculate(
        today: today ?? DateTime.now(),
        weightKg: p.hasWeight ? p.weightKg : null,
        heightCm: p.hasHeight ? p.heightCm : null,
        birthDate: p.birthDate,
        sex: p.sex,
        activity: p.activity,
        goal: p.nutritionGoal,
        legacyTrainingGoal: p.targetGoal,
        legacyTarget: p.hasSavedTarget ? p.dailyCalorieTarget : null,
      );

  CalorieTarget get calorieTarget => targetForProfile(profile);

  void dismissTargetPrompt() {
    targetPromptDismissed = true;
    notifyListeners();
  }

  Future<void> saveTargetProfile({
    required double weightKg,
    required double heightCm,
    required DateTime birthDate,
    required TargetSex sex,
    required TargetActivity activity,
  }) async {
    if (SupabaseAuthService.client.auth.currentSession == null) {
      throw AuthException(
          'invalid_session', savedLanguageStrings().sessionExpired);
    }
    final goal =
        resolveNutritionGoal(profile.targetGoal, profile.nutritionGoal);
    final candidate = profile.copyWith(
        weightKg: weightKg,
        heightCm: heightCm,
        hasWeight: true,
        hasHeight: true,
        birthDate: birthDate,
        sex: sex,
        activity: activity,
        nutritionGoal: goal);
    final result = targetForProfile(candidate);
    if (result.isEstimate || result.target == null) {
      throw StateError(savedLanguageStrings().errorProfileInvalid);
    }
    final date = '${birthDate.year.toString().padLeft(4, '0')}-'
        '${birthDate.month.toString().padLeft(2, '0')}-'
        '${birthDate.day.toString().padLeft(2, '0')}';
    await SupabaseAuthService.saveProfile({
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'birth_date': date,
      'gender': sex.name,
      'activity_level': activity.name,
      'goal': goal.name,
      'daily_calorie_target': result.target,
    });
    profile = candidate.copyWith(
        dailyCalorieTarget: result.target, hasSavedTarget: true);
    targetCalories = result.target!;
    targetPromptDismissed = false;
    notifyListeners();
  }

  // ───────── calories: meals & burns ─────────
  final List<MealItem> meals = [];
  final List<BurnItem> burns = [];
  int _targetCalories = 2500;
  DateTime _targetDate = DateTime.now();
  int get targetCalories {
    final now = DateTime.now();
    if (now.year != _targetDate.year ||
        now.month != _targetDate.month ||
        now.day != _targetDate.day) {
      _targetDate = now;
      if (loggedIn) {
        _targetCalories = targetForProfile(profile, today: now).target ?? 0;
      }
    }
    return _targetCalories;
  }

  set targetCalories(int value) {
    _targetCalories = value;
    _targetDate = DateTime.now();
  }

  int targetBurn = 1250;
  String? recentActionToast;
  int streak = 0;
  int longestStreak = 0;
  int storePoints = 0;
  DateTime? lastActivityDate;
  bool activityLoading = false;
  String? activityError;

  MacroTotals get totals => calculateMacroTotals(meals, burns,
      calorieTarget: targetCalories, burnTarget: targetBurn);
  CalorieBalance? get calorieBalance => calorieTarget.bmr == null
      ? null
      : calculateCalorieBalance(
          totals.totalMealCalories, totals.totalBurnedCalories,
          bmr: calorieTarget.bmr!);

  void showFeedback(String msg) {
    recentActionToast = msg;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      recentActionToast = null;
      notifyListeners();
    });
  }

  Future<void> loadActivity() async {
    final userId = SupabaseAuthService.client.auth.currentUser?.id;
    if (userId == null || !loggedIn) return;
    final generation = ++_activityGeneration;
    _activityUserId = userId;
    activityLoading = true;
    activityError = null;
    notifyListeners();
    await _loadActivityFor(userId, generation);
  }

  Future<bool> _loadActivityFor(String userId, int generation) async {
    final loadGeneration = ++_activityLoadGeneration;
    try {
      final snapshot = await _activityRepository.loadToday();
      if (!_isCurrentActivitySession(userId, generation) ||
          loadGeneration != _activityLoadGeneration) {
        return false;
      }
      meals
        ..clear()
        ..addAll(snapshot.meals);
      burns
        ..clear()
        ..addAll(snapshot.workouts);
      streak = snapshot.streak;
      longestStreak = snapshot.longestStreak;
      lastActivityDate = snapshot.lastActivityDate;
      storePoints = snapshot.storePoints;
      activityError = null;
      return true;
    } catch (error) {
      if (!_isCurrentActivitySession(userId, generation) ||
          loadGeneration != _activityLoadGeneration) {
        return false;
      }
      debugPrint('Could not load today’s activity: $error');
      activityError = savedLanguageStrings().errorActivityLoad;
      return false;
    } finally {
      if (_isCurrentActivitySession(userId, generation) &&
          loadGeneration == _activityLoadGeneration) {
        activityLoading = false;
        notifyListeners();
      }
    }
  }

  bool _isCurrentActivitySession(String userId, int generation) =>
      generation == _activityGeneration &&
      userId == _activityUserId &&
      userId == SupabaseAuthService.client.auth.currentUser?.id &&
      loggedIn;

  Future<void> _writeActivity(Future<void> Function() write,
      {String? successMessage}) async {
    final userId = SupabaseAuthService.client.auth.currentUser?.id;
    if (userId == null || !loggedIn) {
      throw AuthException(
          'invalid_session', savedLanguageStrings().sessionExpired);
    }
    await write();
    if (!loggedIn ||
        userId != SupabaseAuthService.client.auth.currentUser?.id ||
        userId != _activityUserId) {
      return;
    }
    final generation = _activityGeneration;
    activityLoading = true;
    activityError = null;
    notifyListeners();
    final refreshed = await _loadActivityFor(userId, generation);
    if (!refreshed) return;
    if (activityError == null &&
        successMessage != null &&
        _isCurrentActivitySession(userId, generation)) {
      showFeedback(successMessage);
    }
  }

  Future<void> toggleMeal(String id) async {
    final i = meals.indexWhere((m) => m.id == id);
    if (i < 0) return;
    final m = meals[i];
    final updated = !m.consumed;
    await _writeActivity(
      () => _activityRepository.setMealConsumed(id, updated),
      successMessage: updated
          ? savedLanguageStrings()
              .feedbackLoggedMeal(m.name, m.calories)
          : savedLanguageStrings()
              .feedbackUncheckedMeal(m.name, m.calories),
    );
  }

  Future<void> addMeal(MealItem item) async {
    await _writeActivity(
      () => _activityRepository.addMeal(item),
      successMessage: savedLanguageStrings()
          .feedbackAddedMeal(item.name, item.calories),
    );
  }

  Future<void> logFood(
      FoodItem food, PortionResult portion, MealCategory mealType,
      {String? servingLabel}) async {
    final grams = _foodGrams(portion.grams);
    final snapshot = grams == portion.grams
        ? portion
        : calculateFoodPortion(food.per100g, grams);
    await addMeal(MealItem(
      id: '',
      name: food.nameEn,
      time: 'Just now',
      calories: snapshot.kcal,
      proteinGrams: snapshot.proteinG.round(),
      carbsGrams: snapshot.carbsG.round(),
      fatGrams: snapshot.fatG.round(),
      fiberGrams: snapshot.fiberG.round(),
      icon: '🍽️',
      consumed: true,
      category: mealType,
      foodId: food.id,
      grams: grams,
      servingLabel: servingLabel,
      sugarG: (snapshot.sugarG * 10).round() / 10,
      sodiumMg: (snapshot.sodiumMg * 10).round() / 10,
      source: 'food_db',
    ));
  }

  Future<void> updateFoodPortion(MealItem log, double newGrams) async {
    if (log.source != 'food_db' || log.foodId == null || log.foodId!.isEmpty) {
      throw StateError(savedLanguageStrings().errorFoodNotLinked);
    }
    final grams = _foodGrams(newGrams);
    await _foodDatabase.load();
    FoodItem? food;
    for (final item in _foodDatabase.foods) {
      if (item.id == log.foodId) {
        food = item;
        break;
      }
    }
    if (food == null) {
      throw StateError(savedLanguageStrings().errorFoodUnavailable);
    }
    final portion = calculateFoodPortion(food.per100g, grams);
    final updated = log.copyWith(
      grams: grams,
      calories: portion.kcal,
      proteinGrams: portion.proteinG.round(),
      carbsGrams: portion.carbsG.round(),
      fatGrams: portion.fatG.round(),
      fiberGrams: portion.fiberG.round(),
      sugarG: portion.sugarG,
      sodiumMg: portion.sodiumMg,
      clearServingLabel: grams != log.grams,
    );
    await _writeActivity(
      () => _activityRepository.updateFoodPortion(updated),
      successMessage: savedLanguageStrings().feedbackUpdated(log.name),
    );
  }

  double _foodGrams(double grams) {
    if (!grams.isFinite || grams < 1 || grams > 3000) {
      throw RangeError.range(grams, 1, 3000, 'grams');
    }
    return (grams * 10).round() / 10;
  }

  Future<void> removeMeal(String id) async {
    final i = meals.indexWhere((m) => m.id == id);
    if (i < 0) return;
    final item = meals[i];
    await _writeActivity(
      () => _activityRepository.removeMeal(id),
      successMessage: savedLanguageStrings()
          .feedbackRemovedMeal(item.name, item.calories),
    );
  }

  Future<void> addBurn(BurnItem workout) async {
    await _writeActivity(
      () => _activityRepository.addWorkout(workout),
      successMessage: savedLanguageStrings()
          .feedbackAddedWorkout(workout.title, workout.calories),
    );
  }

  Future<void> removeBurn(String id) async {
    final i = burns.indexWhere((b) => b.id == id);
    if (i < 0) return;
    final item = burns[i];
    await _writeActivity(
      () => _activityRepository.removeWorkout(id),
      successMessage: savedLanguageStrings()
          .feedbackRemovedWorkout(item.title, item.calories),
    );
  }

  Future<void> quickAdjustConsumed(int delta) async {
    final amount = delta.abs();
    if (delta > 0) {
      await addMeal(
        MealItem(
          id: '',
          name: 'Quick Calorie Snack',
          time: 'Just now',
          calories: amount,
          proteinGrams: (amount * 0.08).round(),
          carbsGrams: (amount * 0.1).round(),
          fatGrams: (amount * 0.02).round(),
          fiberGrams: 2,
          icon: '🥪',
          consumed: true,
          category: MealCategory.snack,
        ),
      );
    } else {
      final i = meals.indexWhere((m) => m.consumed && m.calories >= amount);
      if (i == -1) {
        throw StateError(
            savedLanguageStrings().errorReduceMeal(amount));
      }
      final meal = meals[i];
      await _writeActivity(
        () => _activityRepository.setMealCalories(
            meal.id, meal.calories - amount),
        successMessage:
            savedLanguageStrings().feedbackDeductFood(amount),
      );
    }
  }

  Future<void> quickAdjustBurned(int delta) async {
    final amount = delta.abs();
    if (delta > 0) {
      await addBurn(
        BurnItem(
          id: '',
          title: 'Quick Exercise Burn',
          time: 'Just now',
          calories: amount,
          type: BurnType.cardio,
          durationMin: (amount / 10).round().clamp(1, 1000000).toInt(),
          icon: '🔥',
        ),
      );
    } else {
      if (burns.isEmpty) {
        throw StateError(savedLanguageStrings().errorReduceWorkout);
      }
      final workout = burns.first;
      await _writeActivity(
        () => _activityRepository.setWorkoutCalories(
            workout.id, (workout.calories - amount).clamp(0, 1000000).toInt()),
        successMessage:
            savedLanguageStrings().feedbackDeductWorkout(amount),
      );
    }
  }
}

final appState = AppState();
