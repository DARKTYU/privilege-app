import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_recovery.dart';

class LevelProgress {
  const LevelProgress({
    required this.name,
    required this.xp,
    required this.minimum,
    required this.nextName,
    required this.nextMinimum,
  });
  final String name;
  final int xp;
  final int minimum;
  final String? nextName;
  final int? nextMinimum;

  double get fraction => nextMinimum == null
      ? 1
      : ((xp - minimum) / (nextMinimum! - minimum)).clamp(0, 1).toDouble();
}

class StoreReward {
  const StoreReward({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.cost,
    required this.stock,
    required this.tier,
    required this.owned,
  });
  final String id, name, description, kind, tier;
  final int cost;
  final int? stock;
  final bool owned;
}

class BadgeProgress {
  const BadgeProgress(this.name, this.description, this.earned, {this.code});
  final String name, description;
  final String? code;
  final bool earned;
}

class AchievementProgress {
  const AchievementProgress(
      this.name, this.description, this.progress, this.threshold, this.xp,
      {this.code});
  final String name, description;
  final String? code;
  final int progress, threshold, xp;
}

class ActivityCounts {
  const ActivityCounts({required this.meals, required this.workouts});
  final int meals, workouts;
}

class StoreSnapshot {
  const StoreSnapshot(this.balance, this.tokens, this.rewards,
      {this.tier = 'Free'});
  final int balance, tokens;
  final List<StoreReward> rewards;
  final String tier;
}

int subscriptionTierRank(String tier) => switch (tier) {
      'Gold' => 2,
      'Silver' => 1,
      _ => 0,
    };

abstract interface class ProgressionDataSource {
  String get accountId;
  Future<LevelProgress?> level();
  Future<int> points();
  Future<int> freezeTokens();
  Future<String> subscriptionTier();
  Future<StoreSnapshot> store();
  Future<List<BadgeProgress>> badges();
  Future<List<AchievementProgress>> achievements();
  Future<ActivityCounts> activityCounts();
  Future<List<BadgeProgress>> publicBadges(String userId);
  Future<void> redeem(String rewardId, String requestId);
}

class ProgressionRepository implements ProgressionDataSource {
  ProgressionRepository({SupabaseClient? client}) : _providedClient = client;
  final SupabaseClient? _providedClient;
  SupabaseClient get client => _providedClient ?? Supabase.instance.client;
  Future<T> _request<T>(Future<T> Function() action) =>
      SessionRecovery.forClient(client).request(action);
  String get _userId =>
      client.auth.currentUser?.id ?? (throw const SessionExpiredException());
  @override
  String get accountId => _userId;

  @override
  Future<int> points() async =>
      (await _request(() => client.rpc('store_points_balance')) as num).toInt();

  @override
  Future<LevelProgress?> level() async {
    final userId = _userId;
    final profile = await _request(() =>
        client.from('profiles').select('level_id').eq('id', userId).single());
    final levels = await _request(
        () => client.from('levels').select().order('min_xp', ascending: true));
    var xp = 0;
    const pageSize = 500;
    for (var start = 0;; start += pageSize) {
      final rows = await _request(() => client
          .from('xp_points')
          .select('id,points')
          .eq('user_id', userId)
          .order('id')
          .range(start, start + pageSize - 1));
      for (final row in rows) {
        xp += (row['points'] as num).toInt();
      }
      if (rows.length < pageSize) break;
    }
    if (levels.isEmpty) return null;
    final index = levels.indexWhere((row) => row['id'] == profile['level_id']);
    if (index < 0) {
      throw const FormatException('Your current level is unavailable.');
    }
    final current = levels[index];
    final next = index + 1 < levels.length ? levels[index + 1] : null;
    return LevelProgress(
      name: current['name'] as String,
      xp: xp,
      minimum: (current['min_xp'] as num).toInt(),
      nextName: next?['name'] as String?,
      nextMinimum: (next?['min_xp'] as num?)?.toInt(),
    );
  }

  @override
  Future<int> freezeTokens() async =>
      (await _request(() => client.rpc('my_freeze_token_balance')) as num)
          .toInt();

  @override
  Future<String> subscriptionTier() async {
    final userId = _userId;
    final subscriptions = await _request(() => client
        .from('user_subscriptions')
        .select('started_at,expires_at,subscription_plans(name)')
        .eq('user_id', userId)
        .eq('status', 'active'));
    final now = DateTime.now().toUtc();
    var tier = 'Free';
    for (final subscription in subscriptions) {
      final started = DateTime.parse(subscription['started_at'] as String);
      final expires = subscription['expires_at'] == null
          ? null
          : DateTime.parse(subscription['expires_at'] as String);
      if (started.isAfter(now) || (expires != null && !expires.isAfter(now))) {
        continue;
      }
      final plan = subscription['subscription_plans'] as Map<String, dynamic>?;
      final candidate = plan?['name'] as String? ?? 'Free';
      if (subscriptionTierRank(candidate) > subscriptionTierRank(tier)) {
        tier = candidate;
      }
    }
    return tier;
  }

  @override
  Future<StoreSnapshot> store() async {
    final userId = _userId;
    final balance = await points();
    final tokens = await freezeTokens();
    final tier = await subscriptionTier();
    final rows = await _request(() => client
        .from('rewards')
        .select(
            'id,name,description,reward_kind,cost_points,stock,required_tier')
        .eq('is_active', true)
        .order('cost_points', ascending: true)
        .order('id', ascending: true));
    final owned = await _request(() => client
        .from('reward_redemptions')
        .select('reward_id')
        .eq('user_id', userId)
        .eq('status', 'fulfilled')
        .neq('reward_kind', 'freeze'));
    final ownedIds = owned.map((row) => row['reward_id']).toSet();
    return StoreSnapshot(
      (balance as num).toInt(),
      tokens,
      rows
          .map((row) => StoreReward(
                id: row['id'] as String,
                name: row['name'] as String,
                description: row['description'] as String,
                kind: row['reward_kind'] as String,
                cost: (row['cost_points'] as num).toInt(),
                stock: (row['stock'] as num?)?.toInt(),
                tier: row['required_tier'] as String,
                owned: ownedIds.contains(row['id']) &&
                    row['reward_kind'] != 'freeze',
              ))
          .toList(),
      tier: tier,
    );
  }

  @override
  Future<List<BadgeProgress>> badges() async {
    final userId = _userId;
    final definitions = await _request(() =>
        client.from('badges').select().order('metric').order('threshold'));
    final earned = await _request(() =>
        client.from('user_badges').select('badge_id').eq('user_id', userId));
    final ids = earned.map((row) => row['badge_id']).toSet();
    return definitions
        .map((row) => BadgeProgress(
              row['name'] as String,
              row['description'] as String,
              ids.contains(row['id']),
              code: row['code'] as String,
            ))
        .toList();
  }

  @override
  Future<List<AchievementProgress>> achievements() async {
    final userId = _userId;
    final definitions = await _request(() => client
        .from('achievements')
        .select()
        .order('metric')
        .order('threshold'));
    final progress = await _request(() => client
        .from('user_achievements')
        .select('achievement_id,progress')
        .eq('user_id', userId));
    final byId = {
      for (final row in progress)
        row['achievement_id']: (row['progress'] as num).toInt()
    };
    return definitions
        .map((row) => AchievementProgress(
              row['name'] as String,
              row['description'] as String,
              byId[row['id']] ?? 0,
              (row['threshold'] as num).toInt(),
              (row['xp_award'] as num).toInt(),
              code: row['code'] as String,
            ))
        .toList();
  }

  @override
  Future<ActivityCounts> activityCounts() async {
    final userId = _userId;
    final meals = await _request(() => client
        .from('meal_logs')
        .count(CountOption.exact)
        .eq('user_id', userId)
        .eq('consumed', true));
    final workouts = await _request(() => client
        .from('workout_logs')
        .count(CountOption.exact)
        .eq('user_id', userId));
    return ActivityCounts(meals: meals, workouts: workouts);
  }

  @override
  Future<List<BadgeProgress>> publicBadges(String userId) async {
    final rows = await _request(
        () => client.rpc('public_user_badges', params: {'p_user_id': userId}));
    return (rows as List)
        .map((row) => BadgeProgress(
              row['name'] as String,
              row['description'] as String,
              true,
              code: row['code'] as String,
            ))
        .toList();
  }

  @override
  Future<void> redeem(String rewardId, String requestId) async {
    await _request(() => client.rpc('redeem_digital_reward', params: {
          'p_reward_id': rewardId,
          'p_request_id': requestId,
        }));
  }
}

String newRedemptionRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

String redemptionError(Object error) {
  if (error is PostgrestException) {
    final message = error.message.toLowerCase();
    if (message.contains('insufficient store points')) {
      return 'Not enough store points.';
    }
    if (message.contains('out of stock')) return 'This reward is out of stock.';
    if (message.contains('subscription tier')) {
      return 'Your subscription tier does not qualify for this reward.';
    }
    if (message.contains('at most three')) {
      return 'You can hold at most three freeze tokens.';
    }
    if (message.contains('already own')) return 'You already own this item.';
    if (message.contains('not available')) {
      return 'This reward is no longer available.';
    }
  }
  return 'Could not confirm redemption. Check your connection and retry.';
}
