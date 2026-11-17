import 'package:privilege/services/progression_repository.dart';

class FakeProgression implements ProgressionDataSource {
  int balance = 200;
  int tokens = 1;
  Object? error;
  Object? redemptionFailure;
  String? lastRequest;
  final List<String> requests = [];
  int redemptions = 0;
  @override
  String get accountId => 'test-user';
  @override
  Future<int> points() async => balance;
  @override
  Future<int> freezeTokens() async => tokens;
  @override
  Future<LevelProgress?> level() async => const LevelProgress(
      name: 'Bronze',
      xp: 100,
      minimum: 0,
      nextName: 'Silver',
      nextMinimum: 500);
  @override
  Future<StoreSnapshot> store() async {
    if (error != null) throw error!;
    return StoreSnapshot(balance, tokens, [
      const StoreReward(
        id: 'freeze',
        name: 'Streak freeze token',
        description: 'One freeze',
        kind: 'freeze',
        cost: 50,
        stock: null,
        tier: 'Free',
        owned: false,
      )
    ]);
  }

  @override
  Future<List<BadgeProgress>> badges() async => [
        const BadgeProgress('First meal', 'Log a meal', true),
        const BadgeProgress('More meals', 'Log more meals', false),
      ];
  @override
  Future<List<AchievementProgress>> achievements() async => [
        const AchievementProgress('Workouts', 'Log workouts', 10, 100, 150),
      ];
  @override
  Future<List<BadgeProgress>> publicBadges(String userId) async => [];
  @override
  Future<void> redeem(String rewardId, String requestId) async {
    lastRequest = requestId;
    requests.add(requestId);
    if (redemptionFailure != null) throw redemptionFailure!;
    redemptions++;
    balance -= 50;
    tokens++;
  }
}
