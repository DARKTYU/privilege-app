import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/arena_models.dart';
import '../models/community_models.dart';
import 'session_recovery.dart';

abstract interface class ArenaDataSource {
  Future<List<ArenaChallenge>> challenges(String scope);
  Future<List<ArenaInvitation>> invitations();
  Future<List<ArenaLeaderboardEntry>> leaderboard({
    required String scope,
    required String period,
    required String metric,
  });
  Future<List<ArenaStanding>> standings(String challengeId);
  Future<List<CommunityPerson>> friends();
  Future<void> createPublicChallenge({
    required String title,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String description,
  });
  Future<void> createFriendChallenge({
    required String friendId,
    required String title,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<void> joinChallenge(String challengeId);
  Future<void> respondToInvitation(String invitationId, String action);
}

class ArenaRepository implements ArenaDataSource {
  ArenaRepository({SupabaseClient? client}) : _providedClient = client;

  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  Future<T> _request<T>(Future<T> Function() action) =>
      SessionRecovery.forClient(_client).request(action);

  String _date(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Future<List<ArenaChallenge>> challenges(String scope) async {
    final rows = await _request(() => _client.rpc('arena_challenges', params: {
          'p_scope': scope,
          'p_limit': 50,
        }));
    return (rows as List)
        .map((row) =>
            ArenaChallenge.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<List<ArenaInvitation>> invitations() async {
    final rows = await _request(() => _client.rpc('arena_challenge_inbox'));
    return (rows as List)
        .map((row) =>
            ArenaInvitation.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<List<ArenaLeaderboardEntry>> leaderboard({
    required String scope,
    required String period,
    required String metric,
  }) async {
    final rows = await _request(() => _client.rpc('arena_leaderboard', params: {
          'p_scope': scope,
          'p_period': period,
          'p_metric': metric,
          'p_level_id': null,
          'p_limit': 50,
        }));
    return (rows as List)
        .map((row) => ArenaLeaderboardEntry.fromJson(
            Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<List<ArenaStanding>> standings(String challengeId) async {
    final rows = await _request(() => _client.rpc('arena_challenge_standings',
        params: {'p_challenge_id': challengeId}));
    return (rows as List)
        .map((row) =>
            ArenaStanding.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<List<CommunityPerson>> friends() async {
    final rows = await _request(() => _client.rpc('community_friends'));
    return (rows as List).map((row) {
      final json = Map<String, dynamic>.from(row as Map)
        ..['relationship'] = 'friends';
      return CommunityPerson.fromJson(json);
    }).toList();
  }

  @override
  Future<void> createPublicChallenge({
    required String title,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String description = '',
  }) async {
    await _request(() => _client.rpc('create_public_arena_challenge', params: {
          'p_title': title,
          'p_type': type,
          'p_start_date': _date(startDate),
          'p_end_date': _date(endDate),
          'p_description': description,
        }));
  }

  @override
  Future<void> createFriendChallenge({
    required String friendId,
    required String title,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _request(() => _client.rpc('create_friend_arena_challenge', params: {
          'p_friend_id': friendId,
          'p_title': title,
          'p_type': type,
          'p_start_date': _date(startDate),
          'p_end_date': _date(endDate),
        }));
  }

  @override
  Future<void> joinChallenge(String challengeId) async {
    await _request(() => _client.rpc('join_public_arena_challenge',
        params: {'p_challenge_id': challengeId}));
  }

  @override
  Future<void> respondToInvitation(String invitationId, String action) async {
    await _request(() => _client.rpc('respond_to_arena_invitation', params: {
          'p_invitation_id': invitationId,
          'p_action': action,
        }));
  }
}
