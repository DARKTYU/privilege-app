class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.body,
    required this.visibility,
    required this.createdAt,
    required this.friendGroup,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'] as String,
        authorId: json['author_id'] as String,
        username: json['username'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        body: json['body'] as String,
        visibility: json['visibility'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        friendGroup: (json['friend_group'] as num).toInt(),
        likeCount: (json['like_count'] as num).toInt(),
        commentCount: (json['comment_count'] as num).toInt(),
        likedByMe: json['liked_by_me'] as bool,
      );

  final String id, authorId, username, body, visibility;
  final String? fullName, avatarUrl;
  final DateTime createdAt;
  final int friendGroup, likeCount, commentCount;
  final bool likedByMe;
}
