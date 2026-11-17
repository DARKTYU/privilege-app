import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/progression_repository.dart';
import '../services/session_recovery.dart';
import '../state.dart';
import '../ui.dart';

class ProgressionChanges extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final progressionChanges = ProgressionChanges();

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
              const Text('Could not load progress. Check your connection.'),
              TextButton(onPressed: _reload, child: const Text('Retry')),
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
              return const Text('No levels are available yet.');
            }
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level: ${level.name}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: level.fraction,
                    color: kGold,
                    backgroundColor: kLine,
                  ),
                  const SizedBox(height: 6),
                  Text(level.nextMinimum == null
                      ? '${level.xp} XP · Highest level'
                      : '${level.xp} XP · ${level.nextMinimum! - level.xp < 0 ? 0 : level.nextMinimum! - level.xp} XP to ${level.nextName}'),
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
        builder: (_, count) => Text('Freeze tokens: $count'),
      );
}

class StorePointsCount extends StatelessWidget {
  const StorePointsCount({super.key, required this.repository});
  final ProgressionDataSource repository;
  @override
  Widget build(BuildContext context) => LiveProgress<int>(
        repository: repository,
        load: repository.points,
        builder: (_, count) => Text('$count store points',
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
        title: Text('Redeem ${reward.name}?'),
        content: Text('Spend ${reward.cost} store points?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Redeem')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = reward.id);
    String? key;
    SharedPreferences? preferences;
    try {
      preferences = await SharedPreferences.getInstance();
      key = 'pending_redemption_${_repository.accountId}_${reward.id}';
      final request = preferences.getString(key) ?? newRedemptionRequestId();
      if (!await preferences.setString(key, request)) {
        throw StateError('Could not save the redemption request.');
      }
      await _repository.redeem(reward.id, request);
      if (!await preferences.remove(key)) {
        throw StateError('Could not clear the completed redemption request.');
      }
      progressionChanges.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Reward redeemed.')));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(redemptionError(error))));
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
                  Text('${store.balance} store points',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  Text('Freeze tokens: ${store.tokens} / 3'),
                ])),
                const Text(
                    'Digital items only. Themes, frames and titles are saved to your rewards; applying them is not available yet.'),
                const SizedBox(height: 12),
                if (store.rewards.isEmpty)
                  const Panel(
                      child: Text('No rewards are available right now.'))
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
                          Text(
                              '${reward.cost} points · ${reward.tier} tier · ${reward.stock == null ? 'Unlimited stock' : '${reward.stock} remaining'}'),
                          if (subscriptionTierRank(store.tier) <
                              subscriptionTierRank(reward.tier))
                            Text('Requires ${reward.tier} tier'),
                          if (store.balance < reward.cost)
                            Text(
                                'Need ${reward.cost - store.balance} more points'),
                          Align(
                            alignment: Alignment.centerRight,
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
                                  ? 'Redeeming...'
                                  : reward.owned
                                      ? 'Owned'
                                      : reward.stock == 0
                                          ? 'Out of stock'
                                          : 'Redeem'),
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
          sectionTitle('Badges'),
          LiveProgress<List<BadgeProgress>>(
            repository: _repository,
            load: _repository.badges,
            builder: (_, badges) => badges.isEmpty
                ? const Panel(child: Text('No badges available yet.'))
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
                        subtitle: Text(
                            '${badge.description}\n${badge.earned ? 'Earned' : 'Locked'}'),
                      ))
                  ]),
          ),
          sectionTitle('Achievements'),
          LiveProgress<List<AchievementProgress>>(
            repository: _repository,
            load: _repository.achievements,
            builder: (_, items) => items.isEmpty
                ? const Panel(child: Text('No achievements available yet.'))
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
                            Text(
                                '${item.progress} / ${item.threshold} · ${item.xp} XP'),
                            if (item.progress >= item.threshold)
                              const Text('Completed'),
                          ]))
                  ]),
          ),
        ],
      );
}
