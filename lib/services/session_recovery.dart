import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n_strings.dart';

class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => savedLanguageStrings().sessionExpired;
}

class SessionRecovery {
  SessionRecovery(this.client);

  final SupabaseClient client;
  Future<bool>? _refreshing;
  Future<void>? _signingOut;
  static final Expando<SessionRecovery> _instances = Expando();

  static SessionRecovery forClient(SupabaseClient client) =>
      _instances[client] ??= SessionRecovery(client);

  static bool isJwtError(Object error) {
    String? code;
    String? message;
    if (error is PostgrestException) {
      code = error.code;
      message = error.message;
    } else if (error is StorageException) {
      code = error.statusCode;
      message = error.message;
    } else if (error is AuthException) {
      code = error.code;
      message = error.message;
    } else {
      return false;
    }
    final text = message.toLowerCase();
    return code == 'PGRST301' ||
        code == 'PGRST303' ||
        code == 'bad_jwt' ||
        code == 'jwt_expired' ||
        (text.contains('jwt') &&
            (text.contains('expired') ||
                text.contains('invalid') ||
                text.contains('signature')));
  }

  Future<T> request<T>(Future<T> Function() action) async {
    final session = client.auth.currentSession;
    if (session == null) throw const SessionExpiredException();
    try {
      return await action();
    } catch (error) {
      if (!isJwtError(error)) rethrow;
      final current = client.auth.currentSession;
      if (current == null || current.user.id != session.user.id) {
        throw const SessionExpiredException();
      }
      if (current.accessToken == session.accessToken && !await refresh()) {
        throw const SessionExpiredException();
      }
      if (client.auth.currentUser?.id != session.user.id) {
        throw const SessionExpiredException();
      }
      try {
        return await action();
      } catch (retryError) {
        if (!isJwtError(retryError)) rethrow;
        await signOutIfCurrent(session.user.id);
        throw const SessionExpiredException();
      }
    }
  }

  Future<bool> refresh() {
    final pending = _refreshing;
    if (pending != null) return pending;
    final future = _refreshSession();
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
  }

  Future<bool> _refreshSession() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final response = await client.auth.refreshSession();
      if (response.session != null && client.auth.currentUser?.id == userId) {
        return true;
      }
      await signOutIfCurrent(userId);
      return false;
    } catch (error, stack) {
      debugPrint('Supabase session refresh failed: $error\n$stack');
      await signOutIfCurrent(userId);
      return false;
    }
  }

  Future<void> signOutIfCurrent(String userId) {
    if (client.auth.currentUser?.id != userId) return Future.value();
    final pending = _signingOut;
    if (pending != null) return pending;
    final future = _signOut();
    _signingOut = future;
    return future.whenComplete(() {
      if (identical(_signingOut, future)) _signingOut = null;
    });
  }

  Future<void> _signOut() async {
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } catch (error, stack) {
      // Supabase clears the local session before attempting remote logout.
      debugPrint('Supabase local sign-out cleanup: $error\n$stack');
    }
  }
}
