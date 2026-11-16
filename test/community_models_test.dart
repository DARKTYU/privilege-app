import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/models/community_models.dart';

void main() {
  test('person row parses friendship request state', () {
    final person = CommunityPerson.fromJson({
      'friendship_id': 'friendship-id',
      'user_id': 'user-id',
      'username': 'runner',
      'full_name': 'Runner One',
      'avatar_url': null,
      'request_direction': 'incoming',
      'created_at': '2026-01-01T10:00:00Z',
    });

    expect(person.id, 'user-id');
    expect(person.relationship, 'none');
    expect(person.friendshipId, 'friendship-id');
    expect(person.requestDirection, 'incoming');
    expect(person.createdAt?.toUtc(), DateTime.utc(2026, 1, 1, 10));
  });

  test('notification row tracks unread state and safe actor fields', () {
    final notification = CommunityNotification.fromJson({
      'id': 'notification-id',
      'notification_type': 'post_comment',
      'post_id': 'post-id',
      'friendship_id': null,
      'read_at': null,
      'created_at': '2026-01-01T10:00:00Z',
      'actor_id': 'actor-id',
      'username': 'runner',
      'full_name': null,
      'avatar_url': null,
    });

    expect(notification.isRead, isFalse);
    expect(notification.postId, 'post-id');
    expect(notification.username, 'runner');
  });

  test('public profile contains aggregates without private profile fields', () {
    final profile = CommunityPublicProfile.fromJson({
      'user_id': 'user-id',
      'username': 'runner',
      'full_name': null,
      'avatar_url': null,
      'level_name': 'Bronze',
      'current_streak': 3,
      'longest_streak': 8,
      'post_count': 4,
      'friend_count': 2,
      'follower_count': 5,
      'followed_by_me': true,
      'relationship': 'friends',
    });

    expect(profile.currentStreak, 3);
    expect(profile.postCount, 4);
    expect(profile.relationship, 'friends');
  });
}
