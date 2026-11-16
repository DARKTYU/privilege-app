import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/models/arena_models.dart';
import 'package:privilege/models/community_models.dart';
import 'package:privilege/screens/arena.dart';
import 'package:privilege/services/arena_repository.dart';
import 'package:privilege/ui.dart';

void main() {
  testWidgets('Streak Arena loads challenges and real-data leaderboard states',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: AppPage(
          title: 'Streak Arena',
          builder: () => ArenaScreen(repository: _ArenaDataSource()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ArenaScreen), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('YOUR ACTIVITY STREAK'), findsOneWidget);
    expect(find.text('ARENA'), findsOneWidget);
    expect(find.text('Morning movement'), findsOneWidget);
    expect(find.text('Join challenge'), findsOneWidget);
    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();
    expect(find.text('Active days'), findsOneWidget);
    expect(find.text('@runner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ArenaDataSource implements ArenaDataSource {
  @override
  Future<List<ArenaChallenge>> challenges(String scope) async => [
        ArenaChallenge(
          id: 'challenge-1',
          creatorId: 'creator-1',
          title: 'Morning movement',
          description: '',
          type: 'streak',
          visibility: 'public',
          isOneVOne: false,
          startDate: DateTime(2026, 11, 16),
          endDate: DateTime(2026, 11, 22),
          finalizedAt: null,
          winnerId: null,
          participantCount: 1,
          myScore: 0,
          myRank: 1,
          joined: false,
          creatorUsername: 'runner',
          creatorFullName: null,
        )
      ];

  @override
  Future<List<ArenaInvitation>> invitations() async => [];

  @override
  Future<List<ArenaLeaderboardEntry>> leaderboard({
    required String scope,
    required String period,
    required String metric,
  }) async =>
      [
        const ArenaLeaderboardEntry(
          userId: 'user-1',
          username: 'runner',
          fullName: null,
          avatarUrl: null,
          score: 4,
          currentStreak: 2,
          levelId: null,
          levelName: null,
          place: 1,
          isMe: true,
        )
      ];

  @override
  Future<List<ArenaStanding>> standings(String challengeId) async => [];

  @override
  Future<List<CommunityPerson>> friends() async => [];

  @override
  Future<void> createPublicChallenge({
    required String title,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String description = '',
  }) async {}

  @override
  Future<void> createFriendChallenge({
    required String friendId,
    required String title,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {}

  @override
  Future<void> joinChallenge(String challengeId) async {}

  @override
  Future<void> respondToInvitation(String invitationId, String action) async {}
}
