import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'account_types.dart';

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
    return AuthException(code, error.message);
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
    if (client.auth.currentSession == null) return null;
    try {
      final response = await client.auth.getUser();
      final user = response.user;
      if (user == null) {
        throw AuthException(
            'invalid_session', 'Your session expired. Please log in again.');
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

  static Future<AccountData> _account(sb.User user) async {
    try {
      final row = await client
          .from('profiles')
          .select(
            'username, full_name, weight_kg, height_cm, training_goal, bio, daily_calorie_target, onboarding_completed',
          )
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) {
        throw AuthException('missing_profile',
            'Your profile could not be found. Contact the app administrator.');
      }
      return AccountData(
        username: row['username'] as String,
        email: user.email ?? '',
        profile: row,
        token: client.auth.currentSession?.accessToken,
      );
    } on sb.PostgrestException catch (error) {
      throw AuthException('profile_error',
          'Could not load your profile. Check that the Supabase auth migration has been applied. (${error.code ?? 'database error'})');
    }
  }

  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw AuthException('invalid_session', 'Please log in again.');
    }
    try {
      final row = await client
          .from('profiles')
          .update(profile)
          .eq('id', user.id)
          .select('id')
          .maybeSingle();
      if (row == null) {
        throw AuthException(
            'missing_profile', 'Your profile could not be saved.');
      }
    } on sb.PostgrestException catch (error) {
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
