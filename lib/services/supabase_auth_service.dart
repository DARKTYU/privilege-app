import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'account_types.dart';
import 'session_recovery.dart';

class SupabaseAuthService {
  static sb.SupabaseClient get client => sb.Supabase.instance.client;

  static AuthException _authError(sb.AuthException error) {
    final code = error.code ?? 'auth_error';
    if (code == 'invalid_credentials') {
      return AuthException(code, 'Incorrect email or password.');
    }
    if (code == 'email_not_confirmed') {
      return AuthException(
          code, 'Please confirm your email before logging in.');
    }
    return AuthException(code, 'Could not sign in. Please try again.');
  }

  static AuthException _connectionError() => AuthException('network',
      'Could not connect. Check your internet connection and try again.');

  static Future<String> register(String email, String password) async {
    try {
      final result = await client.auth.signUp(email: email, password: password);
      if (result.session != null) {
        await client.auth.signOut();
        return 'Account created. Log in to continue.';
      }
      return 'If this email can be registered, check your inbox for a confirmation link, then log in.';
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
            'invalid_session', 'Sign-in did not create a session.');
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
            'username, full_name, weight_kg, height_cm, training_goal, bio, daily_calorie_target, onboarding_completed',
          )
          .eq('id', user.id)
          .maybeSingle());
      if (row == null) {
        throw AuthException('missing_profile',
            'Your profile could not be found. Contact the app administrator.');
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
          'profile_error', 'Could not complete sign-in. Please try again.');
    }
  }

  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw AuthException('invalid_session', 'Please log in again.');
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
            'missing_profile', 'Your profile could not be saved.');
      }
    } on sb.PostgrestException catch (error) {
      if (error.code == '23505' &&
          ('${error.message} ${error.details}').contains('username')) {
        throw AuthException(
            'username_taken', 'That username is already taken.');
      }
      if (error.code == '23514' &&
          error.message.toLowerCase().contains('username')) {
        throw AuthException('invalid_username',
            'Username must be 3 to 20 letters, numbers or underscores.');
      }
      throw AuthException('profile_error',
          'Could not save your profile. Check that the Supabase auth migration has been applied. (${error.code ?? 'database error'})');
    } on SocketException {
      throw _connectionError();
    } on http.ClientException {
      throw _connectionError();
    } on TimeoutException {
      throw _connectionError();
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
