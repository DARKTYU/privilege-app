class ArenaChallenge {
  const ArenaChallenge({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.type,
    required this.visibility,
    required this.isOneVOne,
    required this.startDate,
    required this.endDate,
    required this.finalizedAt,
    required this.winnerId,
    required this.participantCount,
    required this.myScore,
    required this.myRank,
    required this.joined,
    required this.creatorUsername,
    required this.creatorFullName,
  });

  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String type;
  final String visibility;
  final bool isOneVOne;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? finalizedAt;
  final String? winnerId;
  final int participantCount;
  final double? myScore;
  final int? myRank;
  final bool joined;
  final String creatorUsername;
  final String? creatorFullName;

  bool get isFinished => finalizedAt != null;

  factory ArenaChallenge.fromJson(Map<String, dynamic> json) => ArenaChallenge(
        id: json['id'] as String,
        creatorId: json['creator_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        type: json['type'] as String,
        visibility: json['visibility'] as String,
        isOneVOne: json['is_one_v_one'] as bool,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        finalizedAt: json['finalized_at'] == null
            ? null
            : DateTime.parse(json['finalized_at'] as String),
        winnerId: json['winner_id'] as String?,
        participantCount: (json['participant_count'] as num).toInt(),
        myScore: (json['my_score'] as num?)?.toDouble(),
        myRank: (json['my_rank'] as num?)?.toInt(),
        joined: json['joined'] as bool,
        creatorUsername: json['creator_username'] as String,
        creatorFullName: json['creator_full_name'] as String?,
      );
}

class ArenaInvitation {
  const ArenaInvitation({
    required this.id,
    required this.challengeId,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.inviterId,
    required this.inviterUsername,
    required this.inviterFullName,
    required this.inviterAvatarUrl,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String challengeId;
  final String title;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String inviterId;
  final String inviterUsername;
  final String? inviterFullName;
  final String? inviterAvatarUrl;
  final DateTime expiresAt;
  final DateTime createdAt;

  factory ArenaInvitation.fromJson(Map<String, dynamic> json) =>
      ArenaInvitation(
        id: json['invitation_id'] as String,
        challengeId: json['challenge_id'] as String,
        title: json['title'] as String,
        type: json['challenge_type'] as String,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        inviterId: json['inviter_id'] as String,
        inviterUsername: json['inviter_username'] as String,
        inviterFullName: json['inviter_full_name'] as String?,
        inviterAvatarUrl: json['inviter_avatar_url'] as String?,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ArenaStanding {
  const ArenaStanding({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.score,
    required this.rank,
    required this.isMe,
  });

  final String userId;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final double score;
  final int? rank;
  final bool isMe;

  factory ArenaStanding.fromJson(Map<String, dynamic> json) => ArenaStanding(
        userId: json['user_id'] as String,
        username: json['username'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        score: (json['score'] as num).toDouble(),
        rank: (json['rank'] as num?)?.toInt(),
        isMe: json['is_me'] as bool,
      );
}

class ArenaLeaderboardEntry {
  const ArenaLeaderboardEntry({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.score,
    required this.currentStreak,
    required this.levelId,
    required this.levelName,
    required this.place,
    required this.isMe,
  });

  final String userId;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final int score;
  final int currentStreak;
  final String? levelId;
  final String? levelName;
  final int place;
  final bool isMe;

  factory ArenaLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      ArenaLeaderboardEntry(
        userId: json['user_id'] as String,
        username: json['username'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        score: (json['score'] as num).toInt(),
        currentStreak: (json['current_streak'] as num).toInt(),
        levelId: json['level_id'] as String?,
        levelName: json['level_name'] as String?,
        place: (json['place'] as num).toInt(),
        isMe: json['is_me'] as bool,
      );
}
