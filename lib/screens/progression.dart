import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n_strings.dart';
import '../services/progression_repository.dart';
import '../services/session_recovery.dart';
import '../state.dart';
import '../ui.dart';

class ProgressionChanges extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final progressionChanges = ProgressionChanges();

String localizedLevelName(BuildContext context, String name) {
  final l = strings(context);
  return switch (name) {
    'Beginner' => l.levelBeginner,
    'Intermediate' => l.levelIntermediate,
    'Pro' => l.levelPro,
    'Bronze' => l.levelBronze,
    'Silver' => l.levelSilver,
    'Gold' => l.levelGold,
    'Platinum' => l.levelPlatinum,
    'Diamond' => l.levelDiamond,
    'Elite' => l.levelElite,
    'Champion' => l.levelChampion,
    _ => name,
  };
}

String _tierName(BuildContext context, String name) {
  final l = strings(context);
  return switch (name) {
    'Free' => l.memberFree,
    'Silver' => l.memberSilver,
    'Gold' => l.memberGold,
    _ => name,
  };
}

String _localizedRedemptionError(BuildContext context, Object error) {
  final l = strings(context);
  if (error is PostgrestException) {
    final message = error.message.toLowerCase();
    if (message.contains('insufficient store points')) {
      return l.rewardErrorPoints;
    }
    if (message.contains('out of stock')) return l.rewardErrorStock;
    if (message.contains('subscription tier')) return l.rewardErrorTier;
    if (message.contains('at most three')) return l.rewardErrorTokens;
    if (message.contains('already own')) return l.rewardErrorOwned;
    if (message.contains('not available')) return l.rewardErrorUnavailable;
  }
  return l.rewardErrorGeneral;
}

class LiveProgress<T> extends StatefulWidget {
  const LiveProgress({
    super.key,
    required this.repository,
    required this.load,
    required this.builder,
  });
  final ProgressionDataSource repository;
  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;

  @override
  State<LiveProgress<T>> createState() => _LiveProgressState<T>();
}

class _LiveProgressState<T> extends State<LiveProgress<T>> {
  late Future<T> _future;
  RealtimeChannel? _channel;
  Timer? _timer;
  SupabaseClient? _client;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
    appState.addListener(_schedule);
    progressionChanges.addListener(_schedule);
    final repository = widget.repository;
    if (repository is ProgressionRepository) {
      _client = repository.client;
      final userId = _client!.auth.currentUser?.id;
      if (userId != null) {
        _channel = _client!.channel('progress-${newRedemptionRequestId()}');
        for (final table in [
          'profiles',
          'xp_points',
          'store_points_ledger',
          'user_badges',
          'user_achievements',
          'reward_redemptions',
          'purchased_freeze_usage',
        ]) {
          _channel!.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: table == 'profiles' ? 'id' : 'user_id',
              value: userId,
            ),
            callback: (_) => _schedule(),
          );
        }
        _channel!.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rewards',
          callback: (_) => _schedule(),
        );
        _channel!.subscribe((status, error) {
          if (error != null) debugPrint('Progress realtime error: $error');
        });
      }
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 350), _reload);
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _future = widget.load();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    appState.removeListener(_schedule);
    progressionChanges.removeListener(_schedule);
    if (_channel != null) unawaited(_client!.removeChannel(_channel!));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            debugPrint('Progress load failed: ${snapshot.error}');
            return Column(children: [
              Text(strings(context).progressLoadError),
              TextButton(
                  onPressed: _reload,
                  child: Text(strings(context).plannerRetry)),
            ]);
          }
          return widget.builder(context, snapshot.data as T);
        },
      );
}

class LevelProgressPanel extends StatelessWidget {
  const LevelProgressPanel({super.key, required this.repository});
  final ProgressionDataSource repository;

  @override
  Widget build(BuildContext context) => Panel(
        child: LiveProgress<LevelProgress?>(
          repository: repository,
          load: repository.level,
          builder: (context, level) {
            if (level == null) {
              return Text(strings(context).progressNoLevels);
            }
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      strings(context).progressLevel(
                          localizedLevelName(context, level.name)),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: level.fraction,
                    color: kGold,
                    backgroundColor: kLine,
                  ),
                  const SizedBox(height: 6),
                  Text(level.nextMinimum == null
                      ? strings(context).progressHighest(level.xp.toString())
                      : strings(context).progressNext(
                          level.xp.toString(),
                          (level.nextMinimum! - level.xp < 0
                                  ? 0
                                  : level.nextMinimum! - level.xp)
                              .toString(),
                          level.nextName == null
                              ? strings(context).pathNotAvailable
                              : localizedLevelName(context, level.nextName!))),
                ]);
          },
        ),
      );
}

class FreezeTokenCount extends StatelessWidget {
  const FreezeTokenCount({super.key, required this.repository});
  final ProgressionDataSource repository;
  @override
  Widget build(BuildContext context) => LiveProgress<int>(
        repository: repository,
        load: repository.freezeTokens,
        builder: (context, count) =>
            Text(strings(context).progressFreeze(count.toString())),
      );
}

class StorePointsCount extends StatelessWidget {
  const StorePointsCount({super.key, required this.repository});
  final ProgressionDataSource repository;
  @override
  Widget build(BuildContext context) => LiveProgress<int>(
        repository: repository,
        load: repository.points,
        builder: (context, count) => Text(
            strings(context).progressPoints(count.toString()),
            style: TextStyle(
                color: kGold, fontSize: 13, fontWeight: FontWeight.w800)),
      );
}

class RewardsStoreScreen extends StatefulWidget {
  const RewardsStoreScreen({super.key, this.repository});
  final ProgressionDataSource? repository;
  @override
  State<RewardsStoreScreen> createState() => _RewardsStoreScreenState();
}

class _RewardsStoreScreenState extends State<RewardsStoreScreen> {
  late final ProgressionDataSource _repository =
      widget.repository ?? ProgressionRepository();
  String? _busy;

  Future<void> _redeem(StoreReward reward) async {
    if (_busy != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings(context).rewardConfirm(reward.name)),
        content: Text(strings(context).rewardSpend(reward.cost.toString())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings(context).plannerCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings(context).rewardRedeem)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = reward.id);
    String? key;
    SharedPreferences? preferences;
    final l = strings(context);
    String? localFailure;
    try {
      preferences = await SharedPreferences.getInstance();
      key = 'pending_redemption_${_repository.accountId}_${reward.id}';
      final request = preferences.getString(key) ?? newRedemptionRequestId();
      if (!await preferences.setString(key, request)) {
        localFailure = l.rewardRequestSaveError;
        throw StateError(l.rewardRequestSaveError);
      }
      await _repository.redeem(reward.id, request);
      if (!await preferences.remove(key)) {
        localFailure = l.rewardRequestClearError;
        throw StateError(l.rewardRequestClearError);
      }
      progressionChanges.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.rewardDone)));
      }
    } catch (error, stack) {
      debugPrint('Reward redemption failed: $error\n$stack');
      if (error is PostgrestException &&
          !SessionRecovery.isJwtError(error) &&
          error.code == 'P0001' &&
          key != null &&
          preferences != null) {
        if (!await preferences.remove(key)) {
          debugPrint('Could not clear rejected redemption request.');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                localFailure ?? _localizedRedemptionError(context, error))));
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LiveProgress<StoreSnapshot>(
            repository: _repository,
            load: _repository.store,
            builder: (context, store) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Panel(
                    child: Column(children: [
                  Text(
                      strings(context).progressPoints(store.balance.toString()),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  Text(strings(context)
                      .rewardFreezeCount(store.tokens.toString())),
                ])),
                Text(strings(context).rewardInfo),
                const SizedBox(height: 12),
                if (store.rewards.isEmpty)
                  Panel(child: Text(strings(context).rewardEmpty))
                else
                  for (final reward in store.rewards)
                    Panel(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(reward.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          Text(reward.description),
                          Text(strings(context).rewardDetails(
                              reward.cost.toString(),
                              _tierName(context, reward.tier),
                              reward.stock == null
                                  ? strings(context).rewardUnlimited
                                  : strings(context).rewardRemaining(
                                      reward.stock.toString()))),
                          if (subscriptionTierRank(store.tier) <
                              subscriptionTierRank(reward.tier))
                            Text(strings(context).rewardRequires(
                                _tierName(context, reward.tier))),
                          if (store.balance < reward.cost)
                            Text(strings(context).rewardNeedPoints(
                                (reward.cost - store.balance).toString())),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: FilledButton(
                              onPressed: _busy != null ||
                                      reward.owned ||
                                      reward.stock == 0 ||
                                      store.balance < reward.cost ||
                                      subscriptionTierRank(store.tier) <
                                          subscriptionTierRank(reward.tier)
                                  ? null
                                  : () => _redeem(reward),
                              child: Text(_busy == reward.id
                                  ? strings(context).rewardRedeeming
                                  : reward.owned
                                      ? strings(context).rewardOwned
                                      : reward.stock == 0
                                          ? strings(context).rewardOutOfStock
                                          : strings(context).rewardRedeem),
                            ),
                          ),
                        ])),
              ],
            ),
          ),
        ],
      );
}

class BadgesAchievementsScreen extends StatefulWidget {
  const BadgesAchievementsScreen({super.key, this.repository});
  final ProgressionDataSource? repository;
  @override
  State<BadgesAchievementsScreen> createState() =>
      _BadgesAchievementsScreenState();
}

class _BadgesAchievementsScreenState extends State<BadgesAchievementsScreen> {
  late final ProgressionDataSource _repository =
      widget.repository ?? ProgressionRepository();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          sectionTitle(strings(context).progressBadges),
          LiveProgress<List<BadgeProgress>>(
            repository: _repository,
            load: _repository.badges,
            builder: (context, badges) => badges.isEmpty
                ? Panel(child: Text(strings(context).progressNoBadges))
                : Column(children: [
                    for (final badge in [
                      ...badges.where((badge) => badge.earned),
                      ...badges.where((badge) => !badge.earned),
                    ])
                      Panel(
                          child: ListTile(
                        leading: Icon(
                            badge.earned
                                ? Icons.workspace_premium
                                : Icons.lock_outline,
                            color: badge.earned ? kGold : kMuted),
                        title: Text(badge.name),
                        subtitle: Text(strings(context).progressBadgeDetails(
                            badge.description,
                            badge.earned
                                ? strings(context).progressEarned
                                : strings(context).progressLocked)),
                      ))
                  ]),
          ),
          sectionTitle(strings(context).progressAchievements),
          LiveProgress<List<AchievementProgress>>(
            repository: _repository,
            load: _repository.achievements,
            builder: (context, items) => items.isEmpty
                ? Panel(child: Text(strings(context).progressNoAchievements))
                : Column(children: [
                    for (final item in items)
                      Panel(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text(item.description),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                                value: (item.progress / item.threshold)
                                    .clamp(0, 1),
                                color: kGold,
                                backgroundColor: kLine),
                            Text(strings(context).progressAchievementValue(
                                item.progress.toString(),
                                item.threshold.toString(),
                                item.xp.toString())),
                            if (item.progress >= item.threshold)
                              Text(strings(context).progressCompleted),
                          ]))
                  ]),
          ),
        ],
      );
}
