class CommunityPerson {
  const CommunityPerson({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.relationship,
    required this.followedByMe,
    this.friendshipId,
    this.requestDirection,
    this.createdAt,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String relationship;
  final bool followedByMe;
  final String? friendshipId;
  final String? requestDirection;
  final DateTime? createdAt;

  factory CommunityPerson.fromJson(Map<String, dynamic> json) =>
      CommunityPerson(
        id: (json['user_id'] ?? json['id']) as String,
        username: json['username'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        relationship: json['relationship'] as String? ?? 'none',
        followedByMe: json['followed_by_me'] as bool? ?? false,
        friendshipId: json['friendship_id'] as String?,
        requestDirection: json['request_direction'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String body;
  final DateTime createdAt;

  factory CommunityComment.fromJson(Map<String, dynamic> json) =>
      CommunityComment(
        id: json['id'] as String,
        postId: json['post_id'] as String,
        authorId: json['author_id'] as String,
        username: json['username'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class CommunityNotification {
  const CommunityNotification({
    required this.id,
    required this.type,
    required this.postId,
    required this.friendshipId,
    required this.readAt,
    required this.createdAt,
    required this.actorId,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
  });

  final String id;
  final String type;
  final String? postId;
  final String? friendshipId;
  final DateTime? readAt;
  final DateTime createdAt;
  final String? actorId;
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  bool get isRead => readAt != null;

  String get message {
    final name = fullName?.trim().isNotEmpty == true
        ? fullName!.trim()
        : username?.trim().isNotEmpty == true
            ? '@${username!.trim()}'
            : 'Someone';
    return switch (type) {
      'friend_request' => '$name sent you a friend request.',
      'friend_accepted' => '$name accepted your friend request.',
      'post_comment' => '$name commented on your post.',
      'post_like' => '$name liked your post.',
      'challenge_invite' => '$name invited you to a challenge.',
      'challenge_result' => 'Your challenge results are ready.',
      'badge_earned' => 'You earned a badge!',
      'achievement_earned' => 'You completed an achievement!',
      'level_up' => 'You reached a new level!',
      'reward_redeemed' => 'Your reward has been redeemed.',
      _ => 'You have a new notification.',
    };
  }

  factory CommunityNotification.fromJson(Map<String, dynamic> json) =>
      CommunityNotification(
        id: json['id'] as String,
        type: json['notification_type'] as String,
        postId: json['post_id'] as String?,
        friendshipId: json['friendship_id'] as String?,
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        actorId: json['actor_id'] as String?,
        username: json['username'] as String?,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}

class CommunityPublicProfile {
  const CommunityPublicProfile({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.levelName,
    required this.currentStreak,
    required this.longestStreak,
    required this.postCount,
    required this.friendCount,
    required this.followerCount,
    required this.followedByMe,
    required this.relationship,
  });

  final String userId;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? levelName;
  final int currentStreak;
  final int longestStreak;
  final int postCount;
  final int friendCount;
  final int followerCount;
  final bool followedByMe;
  final String relationship;

  factory CommunityPublicProfile.fromJson(Map<String, dynamic> json) =>
      CommunityPublicProfile(
        userId: json['user_id'] as String,
        username: json['username'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        levelName: json['level_name'] as String?,
        currentStreak: (json['current_streak'] as num).toInt(),
        longestStreak: (json['longest_streak'] as num).toInt(),
        postCount: (json['post_count'] as num).toInt(),
        friendCount: (json['friend_count'] as num).toInt(),
        followerCount: (json['follower_count'] as num).toInt(),
        followedByMe: json['followed_by_me'] as bool,
        relationship: json['relationship'] as String,
      );
}
