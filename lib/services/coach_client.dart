import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class CoachException implements Exception {
  const CoachException(this.code, {this.resetAt});
  final String code;
  final DateTime? resetAt;
}

class CoachReply {
  const CoachReply(this.text, this.remaining, this.resetAt);
  final String text;
  final int? remaining;
  final DateTime? resetAt;
}

abstract class CoachClient {
  String? get accountId;
  Future<CoachReply> send(Map<String, Object> body);
}

class SupabaseCoachClient implements CoachClient {
  SupabaseCoachClient({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;
  SupabaseClient get client => _client ?? Supabase.instance.client;

  @override
  String? get accountId => client.auth.currentSession?.user.id;

  Map<String, dynamic>? _map(dynamic value) {
    if (value is String) {
      try {
        value = jsonDecode(value);
      } on FormatException {
        return null;
      }
    }
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  CoachException _error(dynamic details, {int? status}) {
    final map = _map(details);
    final code = map?['error'];
    return CoachException(
      code is String
          ? code
          : (status == 401 ? 'authentication_required' : 'unavailable'),
      resetAt: map?['reset_at'] is String
          ? DateTime.tryParse(map!['reset_at'] as String)
          : null,
    );
  }

  @override
  Future<CoachReply> send(Map<String, Object> body) async {
    final session = client.auth.currentSession;
    if (session == null) throw const CoachException('authentication_required');
    final abort = Completer<void>();
    final timer = Timer(const Duration(seconds: 100), abort.complete);
    try {
      final response = await client.functions
          .invoke(
            'coach',
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
            body: body,
            abortSignal: abort.future,
          )
          .timeout(const Duration(seconds: 101));
      final data = _map(response.data);
      if (response.status < 200 ||
          response.status >= 300 ||
          data?['error'] != null) {
        throw _error(data, status: response.status);
      }
      final text = data?['reply'];
      final remaining = data?['remaining'];
      final reset = data?['reset_at'];
      if (text is! String ||
          text.trim().isEmpty ||
          (remaining != null && (remaining is! int || remaining < 0)) ||
          (reset != null &&
              (reset is! String || DateTime.tryParse(reset) == null))) {
        throw const CoachException('unavailable');
      }
      return CoachReply(text, remaining as int?,
          reset == null ? null : DateTime.parse(reset as String));
    } on FunctionException catch (error) {
      throw _error(error.details, status: error.status);
    } on TimeoutException {
      throw const CoachException('unavailable');
    } finally {
      timer.cancel();
    }
  }
}
