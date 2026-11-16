import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/models/community_post.dart';

void main() {
  test('feed row preserves cursor, profile and counts', () {
    final post = CommunityPost.fromJson({
      'id': 'post-id',
      'author_id': 'author-id',
      'username': 'athlete',
      'full_name': null,
      'avatar_url': null,
      'body': 'Hello',
      'visibility': 'friends',
      'image_path': null,
      'created_at': '2026-01-01T10:00:00Z',
      'friend_group': 0,
      'like_count': 3,
      'comment_count': 2,
      'liked_by_me': true,
    });
    expect(post.friendGroup, 0);
    expect(
        post.createdAt.toUtc().toIso8601String(), '2026-01-01T10:00:00.000Z');
    expect(post.likeCount, 3);
    expect(post.likedByMe, isTrue);
    expect(post.fullName, isNull);
  });
}
