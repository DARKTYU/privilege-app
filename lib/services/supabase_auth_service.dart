import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../l10n_strings.dart';
import 'account_types.dart';
import 'session_recovery.dart';

class SupabaseAuthService {
  static sb.SupabaseClient get client => sb.Supabase.instance.client;

  static AuthException _authError(sb.AuthException error) {
    final code = error.code ?? 'auth_error';
    final details = error.message.toLowerCase();
    if (code == 'network_request_failed' ||
        details.contains('offline') ||
        details.contains('failed to fetch') ||
        details.contains('clientexception') ||
        details.contains('connection') ||
        details.contains('timed out') ||
        details.contains('timeout')) {
      return _connectionError();
    }
    if (code == 'invalid_credentials') {
      return AuthException(code, savedLanguageStrings().invalidCredentials);
    }
    if (code == 'email_not_confirmed') {
      return AuthException(code, savedLanguageStrings().emailNotConfirmed);
    }
    return AuthException(code, savedLanguageStrings().registrationError);
  }

  static AuthException _connectionError() =>
      AuthException('network', savedLanguageStrings().networkError);

  static Future<String> register(String email, String password) async {
    try {
      final result = await client.auth.signUp(email: email, password: password);
      if (result.session != null) {
        await client.auth.signOut();
        return savedLanguageStrings().registrationCreated;
      }
      return savedLanguageStrings().registrationConfirm;
    } on sb.AuthException catch (error) {
      throw _authError(error);
    } on SocketException {
      throw _connectionError();
    } on http.ClientException {
      throw _connectionError();
    } on TimeoutException {
      throw _connectionError();
    }
  }

  static Future<AccountData> login(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null || response.session == null) {
        throw AuthException(
            'invalid_session', savedLanguageStrings().errorSignInSession);
      }
      return await _account(user);
    } on sb.AuthException catch (error) {
      throw _authError(error);
    } on SocketException {
      throw _connectionError();
    } on http.ClientException {
      throw _connectionError();
    } on TimeoutException {
      throw _connectionError();
    }
  }

  static Future<AccountData?> restore() async {
    final session = client.auth.currentSession;
    if (session == null) return null;
    try {
      final recovery = SessionRecovery.forClient(client);
      if (session.isExpired && !await recovery.refresh()) return null;
      final response = await recovery.request(() => client.auth.getUser());
      final user = response.user;
      if (user == null) {
        await recovery.signOutIfCurrent(session.user.id);
        return null;
      }
      return await _account(user);
    } on SessionExpiredException {
      return null;
    } on sb.AuthException catch (error) {
      await SessionRecovery.forClient(client).signOutIfCurrent(session.user.id);
      if (SessionRecovery.isJwtError(error)) return null;
      throw _authError(error);
    } on SocketException {
      throw _connectionError();
    } on http.ClientException {
      throw _connectionError();
    } on TimeoutException {
      throw _connectionError();
    }
  }

  static Future<AccountData> _account(sb.User user) async {
    try {
      final row = await SessionRecovery.forClient(client).request(() => client
          .from('profiles')
          .select(
            'username, full_name, weight_kg, height_cm, birth_date, gender, activity_level, goal, training_goal, bio, daily_calorie_target, onboarding_completed',
          )
          .eq('id', user.id)
          .maybeSingle());
      if (row == null) {
        throw AuthException(
            'missing_profile', savedLanguageStrings().errorProfileMissing);
      }
      return AccountData(
        userId: user.id,
        username: row['username'] as String,
        email: user.email ?? '',
        profile: row,
      );
    } on sb.PostgrestException catch (error) {
      if (SessionRecovery.isJwtError(error)) {
        throw const SessionExpiredException();
      }
      throw AuthException(
          'profile_error', savedLanguageStrings().errorCompleteSignIn);
    }
  }

  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw AuthException(
          'invalid_session', savedLanguageStrings().sessionExpired);
    }
    try {
      final row = await SessionRecovery.forClient(client).request(() => client
          .from('profiles')
          .update(profile)
          .eq('id', user.id)
          .select('id')
          .maybeSingle());
      if (row == null) {
        throw AuthException(
            'missing_profile', savedLanguageStrings().errorProfileNotSaved);
      }
    } on sb.PostgrestException catch (error) {
      if (error.code == '23505' &&
          ('${error.message} ${error.details}').contains('username')) {
        throw AuthException(
            'username_taken', savedLanguageStrings().usernameTaken);
      }
      if (error.code == '23514' &&
          error.message.toLowerCase().contains('username')) {
        throw AuthException(
            'invalid_username', savedLanguageStrings().invalidUsername);
      }
      throw AuthException('profile_error', friendlyError(error));
    } on SocketException {
      throw _connectionError();
    } on http.ClientException {
      throw _connectionError();
    } on TimeoutException {
      throw _connectionError();
    }
  }

  static Future<void> requestPasswordReset(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } on sb.AuthException catch (error) {
      throw _resetError(error);
    } on SocketException {
      throw _connectionError();
    } on http.ClientException {
      throw _connectionError();
    } on TimeoutException {
      throw _connectionError();
    }
  }

  static Future<void> completePasswordReset(
      String email, String code, String password) async {
    try {
      await client.auth.verifyOTP(
        email: email,
        token: code,
        type: sb.OtpType.recovery,
      );
      await client.auth.updateUser(sb.UserAttributes(password: password));
      await client.auth.signOut();
    } on sb.AuthException catch (error) {
      throw _resetError(error);
    } on SocketException {
      throw _connectionError();
    } on http.ClientException {
      throw _connectionError();
    } on TimeoutException {
      throw _connectionError();
    }
  }

  static AuthException _resetError(sb.AuthException error) {
    final code = error.code ?? 'auth_error';
    final details = '${error.message} ${error.code ?? ''}'.toLowerCase();
    if (code == 'network_request_failed' ||
        details.contains('offline') ||
        details.contains('failed to fetch') ||
        details.contains('clientexception') ||
        details.contains('connection') ||
        details.contains('timed out') ||
        details.contains('timeout')) {
      return _connectionError();
    }
    if (code == 'over_request_rate_limit' ||
        details.contains('rate limit') ||
        details.contains('too many')) {
      return AuthException(
          'too_many_requests', savedLanguageStrings().resetTooManyRequests);
    }
    if (details.contains('otp') ||
        details.contains('token') ||
        details.contains('expired') ||
        details.contains('invalid')) {
      return AuthException(
          'invalid_code', savedLanguageStrings().resetInvalidCode);
    }
    if (details.contains('password') &&
        (details.contains('weak') ||
            details.contains('characters') ||
            details.contains('length'))) {
      return AuthException(
          'weak_password', savedLanguageStrings().invalidPassword);
    }
    return AuthException('reset_error', savedLanguageStrings().resetError);
  }

  /// Permanently deletes the signed-in account.
  ///
  /// The password is checked first by signing in again, so a stolen unlocked
  /// phone cannot delete an account without it. The server function then
  /// removes the account's photos and the account itself; all other data is
  /// removed by database cascades. Nothing is deleted when any step fails.
  static Future<void> deleteAccount(String password) async {
    final user = client.auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw AuthException(
          'invalid_session', savedLanguageStrings().sessionExpired);
    }
    try {
      final signedIn =
          await client.auth.signInWithPassword(email: email, password: password);
      final session = signedIn.session;
      if (signedIn.user?.id != user.id || session == null) {
        throw AuthException('invalid_credentials',
            savedLanguageStrings().privacyDeleteWrongPassword);
      }
      final response = await client.functions
          .invoke(
            'delete-account',
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
            body: {'confirm': 'DELETE'},
          )
          .timeout(const Duration(seconds: 60));
      if (response.status < 200 || response.status >= 300) {
        throw AuthException(
            'delete_failed', savedLanguageStrings().privacyDeleteFailed);
      }
    } on sb.AuthException catch (error) {
      if (error.code == 'invalid_credentials') {
        throw AuthException('invalid_credentials',
            savedLanguageStrings().privacyDeleteWrongPassword);
      }
      throw _authError(error);
    } on sb.FunctionException {
      throw AuthException(
          'delete_failed', savedLanguageStrings().privacyDeleteFailed);
    } on SocketException {
      throw _connectionError();
    } on http.ClientException {
      throw _connectionError();
    } on TimeoutException {
      throw _connectionError();
    }
    // The account no longer exists; clear the saved session on this phone.
    try {
      await client.auth.signOut(scope: sb.SignOutScope.local);
    } catch (_) {
      // Nothing left to sign out of on the server; local state is cleared next.
    }
  }

  static Future<void> logout() async {
    try {
      await client.auth.signOut();
    } on sb.AuthException catch (error) {
      throw _authError(error);
    } on SocketException {
      throw _connectionError();
    } on http.ClientException {
      throw _connectionError();
    } on TimeoutException {
      throw _connectionError();
    }
  }
}
