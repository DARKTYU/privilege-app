import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'logic/fitness_logic.dart';
import 'logic/user_profile.dart';
import 'services/account_types.dart';
import 'services/activity_repository.dart';
import 'services/supabase_auth_service.dart';
import 'services/session_recovery.dart';

/// Port of FitnessContext.tsx plus profile, subscription and streak-arena state.
class AppState extends ChangeNotifier {
  Timer? _toastTimer;
  final ActivityRepository _activityRepository = ActivityRepository();
  int _activityGeneration = 0;
  int _activityLoadGeneration = 0;
  String? _activityUserId;

  // ───────── account: sign-in, session, onboarding, profile, subscription ─────────
  bool loggedIn = false;
  bool onboardingDone = false;
  bool restoring =
      true; // true while the saved session is being checked at app start
  String?
      authNotice; // message shown on the login screen (e.g. "session expired")
  StreamSubscription<supabase.AuthState>? _authSubscription;
  String email = '';
  String? profilePhotoBase64;
  UserProfile profile = defaultUserProfile;

  SubscriptionTier get tier => profile.subscriptionTier;
  bool can(Feature f) => canAccessFeature(tier, f);

  Future<void> restoreSession() async {
    _authSubscription ??=
        SupabaseAuthService.client.auth.onAuthStateChange.listen(
      (event) {
        if (event.event == supabase.AuthChangeEvent.signedOut &&
            SupabaseAuthService.client.auth.currentSession == null) {
          _clearAccount();
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
    final p = a.profile;
    email = a.email;
    profile = defaultUserProfile.copyWith(
      username: a.username,
      name: p['full_name'] as String? ?? '',
      weightKg: (p['weight_kg'] as num?)?.toDouble(),
      heightCm: (p['height_cm'] as num?)?.toDouble(),
      targetGoal: p['training_goal'] as String?,
      bio: p['bio'] as String?,
      dailyCalorieTarget: (p['daily_calorie_target'] as num?)?.toInt(),
      onboardingCompleted: p['onboarding_completed'] == true,
    );
    onboardingDone = p['onboarding_completed'] == true;
    targetCalories = profile.dailyCalorieTarget;
    loggedIn = true;
  }

  Future<void> logout() async {
    await SupabaseAuthService.logout();
    if (loggedIn) _clearAccount();
  }

  void _clearAccount() {
    _activityGeneration++;
    _activityUserId = null;
    authNotice = null;
    loggedIn = false;
    onboardingDone = false;
    email = '';
    profile = defaultUserProfile;
    profilePhotoBase64 = null;
    _resetLocalData();
    notifyListeners();
  }

  Future<void> setProfilePhoto(Uint8List bytes) async {
    final encoded = base64Encode(bytes);
    final preferences = await SharedPreferences.getInstance();
    final userId = SupabaseAuthService.client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('invalid_session', 'Please log in again.');
    }
    await preferences.setString('privilege_profile_photo_$userId', encoded);
    profilePhotoBase64 = encoded;
    notifyListeners();
  }

  Future<void> removeProfilePhoto() async {
    final preferences = await SharedPreferences.getInstance();
    final userId = SupabaseAuthService.client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('invalid_session', 'Please log in again.');
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
          'invalid_session', 'Please log in again to finish setup.');
    }
    await SupabaseAuthService.saveProfile({
      'full_name': p.name,
      'weight_kg': p.weightKg,
      'height_cm': p.heightCm,
      'training_goal': p.targetGoal,
      'goal': _nutritionGoal(p.targetGoal),
      'bio': p.bio,
      'daily_calorie_target': p.dailyCalorieTarget,
      'onboarding_completed': true,
    });
    profile = p;
    targetCalories = p.dailyCalorieTarget;
    onboardingDone = true;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile p) async {
    if (SupabaseAuthService.client.auth.currentSession == null) {
      throw AuthException('invalid_session', 'Please log in again.');
    }
    await SupabaseAuthService.saveProfile({
      'full_name': p.name,
      'weight_kg': p.weightKg,
      'height_cm': p.heightCm,
      'training_goal': p.targetGoal,
      'goal': _nutritionGoal(p.targetGoal),
      'bio': p.bio,
      'daily_calorie_target': p.dailyCalorieTarget,
      'onboarding_completed': onboardingDone,
    });
    profile = p;
    targetCalories = p.dailyCalorieTarget;
    notifyListeners();
  }

  String _nutritionGoal(String trainingGoal) {
    if (trainingGoal == 'Metabolic Fat Loss & Calorie Deficit') return 'lose';
    if (trainingGoal == 'Lean Muscle Mass Hypertrophy') return 'gain';
    return 'maintain';
  }

  void setTier(SubscriptionTier t) {
    profile = profile.copyWith(subscriptionTier: t);
    notifyListeners();
  }

  // ───────── calories: meals & burns ─────────
  final List<MealItem> meals = [];
  final List<BurnItem> burns = [];
  int targetCalories = 2500;
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
  CalorieBalance get calorieBalance => calculateCalorieBalance(
      totals.totalMealCalories, totals.totalBurnedCalories);

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
      activityError = 'Could not load today’s activity: $error';
      debugPrint(activityError);
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
      throw AuthException('invalid_session', 'Please log in again.');
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
          ? 'Logged ${m.name} (+${m.calories} kcal)!'
          : 'Unchecked ${m.name} (-${m.calories} kcal)!',
    );
  }

  Future<void> addMeal(MealItem item) async {
    await _writeActivity(
      () => _activityRepository.addMeal(item),
      successMessage: 'Added meal ${item.name} (+${item.calories} kcal)!',
    );
  }

  Future<void> removeMeal(String id) async {
    final i = meals.indexWhere((m) => m.id == id);
    if (i < 0) return;
    final item = meals[i];
    await _writeActivity(
      () => _activityRepository.removeMeal(id),
      successMessage: 'Removed ${item.name} (-${item.calories} kcal)!',
    );
  }

  Future<void> addBurn(BurnItem workout) async {
    await _writeActivity(
      () => _activityRepository.addWorkout(workout),
      successMessage:
          'Added workout ${workout.title} (-${workout.calories} kcal burn)!',
    );
  }

  Future<void> removeBurn(String id) async {
    final i = burns.indexWhere((b) => b.id == id);
    if (i < 0) return;
    final item = burns[i];
    await _writeActivity(
      () => _activityRepository.removeWorkout(id),
      successMessage: 'Removed ${item.title} (-${item.calories} kcal burn)!',
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
        throw StateError('There is no logged meal to reduce by $amount kcal.');
      }
      final meal = meals[i];
      await _writeActivity(
        () => _activityRepository.setMealCalories(
            meal.id, meal.calories - amount),
        successMessage: 'Deducted $amount kcal from food intake!',
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
        throw StateError('There is no logged workout to reduce.');
      }
      final workout = burns.first;
      await _writeActivity(
        () => _activityRepository.setWorkoutCalories(
            workout.id, (workout.calories - amount).clamp(0, 1000000).toInt()),
        successMessage: 'Deducted $amount kcal from workout burn!',
      );
    }
  }
}

final appState = AppState();
