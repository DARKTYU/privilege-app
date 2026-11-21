import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privilege/services/account_types.dart' show AuthException;
import 'package:privilege/services/supabase_auth_service.dart';
import 'package:privilege/logic/calorie_target.dart';
import 'package:privilege/logic/user_profile.dart';
import 'package:privilege/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final user = {
    'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'email': 'test@example.com',
    'aud': 'authenticated',
    'created_at': '2026-01-01T00:00:00Z',
  };
  final session = {
    'access_token': 'test-token',
    'refresh_token': 'test-refresh',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': user,
  };
  var loginFails = false;
  var profileMissing = false;
  var signOutCount = 0;
  var signUpWithSession = false;
  var userJwtExpired = false;
  var refreshFails = false;
  var profileSaveFails = false;
  var networkFails = false;
  Map<String, dynamic>? savedProfile;
  final mock = MockClient((request) async {
    final path = request.url.path;
    if (networkFails) throw http.ClientException('offline');
    if (path.endsWith('/signup')) {
      return http.Response(jsonEncode(signUpWithSession ? session : user), 200);
    }
    if (path.endsWith('/token')) {
      final grantType = request.url.queryParameters['grant_type'];
      if (grantType == 'refresh_token') {
        if (refreshFails) {
          return http.Response(
            jsonEncode({
              'code': 'refresh_token_not_found',
              'msg': 'Invalid refresh token'
            }),
            401,
          );
        }
        return http.Response(jsonEncode(session), 200);
      }
      if (loginFails) {
        return http.Response(
          jsonEncode(
              {'code': 'invalid_credentials', 'msg': 'Invalid credentials'}),
          400,
        );
      }
      return http.Response(jsonEncode(session), 200);
    }
    if (path.endsWith('/user')) {
      if (userJwtExpired) {
        return http.Response(
          jsonEncode({'code': 'PGRST301', 'msg': 'JWT expired'}),
          401,
        );
      }
      return http.Response(jsonEncode(user), 200);
    }
    if (path.endsWith('/logout')) {
      signOutCount++;
      return http.Response('', 204);
    }
    if (path.endsWith('/profiles')) {
      if (request.method == 'PATCH') {
        savedProfile = jsonDecode(request.body) as Map<String, dynamic>;
        if (profileSaveFails) {
          return http.Response(
              jsonEncode({'code': '23514', 'message': 'invalid profile'}), 400,
              request: request);
        }
        return http.Response(jsonEncode({'id': user['id']}), 200,
            request: request);
      }
      if (profileMissing) return http.Response('[]', 200, request: request);
      return http.Response(
        jsonEncode([
          {
            'username': 'user_test',
            'full_name': null,
            'weight_kg': null,
            'height_cm': null,
            'training_goal': null,
            'bio': '',
            'daily_calorie_target': null,
            'onboarding_completed': false,
          }
        ]),
        200,
        request: request,
      );
    }
    return http.Response('Unexpected request', 500);
  });

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      httpClient: mock,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
  });

  test('confirmation required does not create a session', () async {
    final message =
        await SupabaseAuthService.register('test@example.com', 'Password1');
    expect(message, contains('confirmation'));
    expect(SupabaseAuthService.client.auth.currentSession, isNull);
  });

  test('signup with confirmation disabled signs out before login', () async {
    signUpWithSession = true;
    final message =
        await SupabaseAuthService.register('test@example.com', 'Password1');
    expect(message, contains('Log in'));
    expect(SupabaseAuthService.client.auth.currentSession, isNull);
    expect(signOutCount, greaterThan(0));
    signUpWithSession = false;
  });

  test('login, restore and logout use the profile and session', () async {
    final account =
        await SupabaseAuthService.login('test@example.com', 'Password1');
    expect(account.username, 'user_test');
    expect((await SupabaseAuthService.restore())?.email, 'test@example.com');
    await SupabaseAuthService.logout();
    expect(SupabaseAuthService.client.auth.currentSession, isNull);
    expect(await SupabaseAuthService.restore(), isNull);
  });

  test('personal target saves profile fields atomically', () async {
    await SupabaseAuthService.login('test@example.com', 'Password1');
    final state = AppState()
      ..profile = defaultUserProfile.copyWith(
        targetGoal: 'Metabolic Fat Loss & Calorie Deficit',
        nutritionGoal: NutritionGoal.maintain,
      );
    addTearDown(state.dispose);
    final oldProfile = state.profile;
    profileSaveFails = true;
    await expectLater(
      state.saveTargetProfile(
        weightKg: 80,
        heightCm: 180,
        birthDate: DateTime(1996, 1, 2),
        sex: TargetSex.male,
        activity: TargetActivity.moderate,
      ),
      throwsA(isA<AuthException>()),
    );
    expect(state.profile, same(oldProfile));
    profileSaveFails = false;
    await state.saveTargetProfile(
      weightKg: 80,
      heightCm: 180,
      birthDate: DateTime(1996, 1, 2),
      sex: TargetSex.male,
      activity: TargetActivity.moderate,
    );
    expect(savedProfile!['birth_date'], '1996-01-02');
    expect(savedProfile!['gender'], 'male');
    expect(savedProfile!['activity_level'], 'moderate');
    expect(savedProfile!['goal'], 'lose');
    expect(savedProfile!['daily_calorie_target'], state.targetCalories);
    expect(state.calorieTarget.goal, NutritionGoal.lose);
    expect(state.profile.weightKg, 80);
    await SupabaseAuthService.logout();
  });

  test('login, signup and reset map connection failures to the network text',
      () async {
    networkFails = true;
    addTearDown(() => networkFails = false);
    for (final call in [
      () => SupabaseAuthService.login('test@example.com', 'Password1'),
      () => SupabaseAuthService.register('test@example.com', 'Password1'),
      () => SupabaseAuthService.requestPasswordReset('test@example.com'),
    ]) {
      await expectLater(
        call(),
        throwsA(isA<AuthException>()
            .having((error) => error.code, 'code', 'network')),
      );
    }
  });

  test('invalid credentials and missing profile are surfaced', () async {
    loginFails = true;
    await expectLater(
      SupabaseAuthService.login('test@example.com', 'wrong'),
      throwsA(isA<AuthException>()),
    );
    loginFails = false;
    profileMissing = true;
    await expectLater(
      SupabaseAuthService.login('test@example.com', 'Password1'),
      throwsA(isA<AuthException>()
          .having((e) => e.code, 'code', 'missing_profile')),
    );
    profileMissing = false;
    await SupabaseAuthService.logout();
  });

  test('restore clears expired session when refresh fails', () async {
    await SupabaseAuthService.login('test@example.com', 'Password1');
    userJwtExpired = true;
    refreshFails = true;
    expect(await SupabaseAuthService.restore(), isNull);
    expect(SupabaseAuthService.client.auth.currentSession, isNull);
    userJwtExpired = false;
    refreshFails = false;
  });
}
