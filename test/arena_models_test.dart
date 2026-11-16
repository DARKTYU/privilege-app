import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/models/arena_models.dart';

void main() {
  test('challenge row parses score and visibility fields', () {
    final challenge = ArenaChallenge.fromJson({
      'id': 'challenge-id',
      'creator_id': 'creator-id',
      'title': 'Active week',
      'description': '',
      'type': 'streak',
      'visibility': 'public',
      'is_one_v_one': false,
      'start_date': '2026-11-16',
      'end_date': '2026-11-22',
      'finalized_at': null,
      'winner_id': null,
      'participant_count': 4,
      'my_score': 3,
      'my_rank': 2,
      'joined': true,
      'creator_username': 'runner',
      'creator_full_name': null,
    });

    expect(challenge.type, 'streak');
    expect(challenge.myScore, 3);
    expect(challenge.myRank, 2);
    expect(challenge.isFinished, isFalse);
  });

  test('invitation and leaderboard rows parse safe display data', () {
    final invitation = ArenaInvitation.fromJson({
      'invitation_id': 'invite-id',
      'challenge_id': 'challenge-id',
      'title': 'Workout week',
      'challenge_type': 'workout_count',
      'start_date': '2026-11-16',
      'end_date': '2026-11-22',
      'inviter_id': 'friend-id',
      'inviter_username': 'friend',
      'inviter_full_name': 'Friend',
      'inviter_avatar_url': null,
      'expires_at': '2026-11-17T00:00:00Z',
      'created_at': '2026-11-16T00:00:00Z',
    });
    final entry = ArenaLeaderboardEntry.fromJson({
      'user_id': 'user-id',
      'username': 'runner',
      'full_name': null,
      'avatar_url': null,
      'score': 5,
      'current_streak': 3,
      'level_id': null,
      'level_name': null,
      'place': 1,
      'is_me': true,
    });

    expect(invitation.type, 'workout_count');
    expect(invitation.inviterUsername, 'friend');
    expect(entry.place, 1);
    expect(entry.isMe, isTrue);
  });
}
