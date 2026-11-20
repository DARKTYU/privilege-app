import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/models/arena_models.dart';
import 'package:privilege/models/community_models.dart';
import 'package:privilege/screens/arena.dart';
import 'package:privilege/services/arena_repository.dart';
import 'package:privilege/state.dart';
import 'package:privilege/ui.dart';
import 'progression_fake.dart';

void main() {
  test('Arena has no hardcoded UI labels or Arabic', () {
    final source = File('lib/screens/arena.dart').readAsStringSync();
    final visible = RegExp(
        r"""(?:Text\(\s*(?:const\s*)?|(?:labelText|hintText|tooltip|semanticLabel)\s*:\s*|sectionTitle\(\s*|_message\(\s*)['"]""");
    expect(visible.allMatches(source), isEmpty);
    expect(source, isNot(contains(RegExp(r'[\u0600-\u06ff]'))));
  });

  for (final language in ['en', 'ar']) {
    testWidgets('Arena fits and creates a challenge at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _ArenaDataSource();
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildTheme(),
        home: Scaffold(
            body: ArenaScreen(
          repository: repository,
          progressionRepository: FakeProgression(),
        )),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(ArenaScreen)))!;
      expect(find.text(l.arenaYourActivity.toUpperCase()), findsOneWidget);
      expect(find.text(l.progressFreeze(1)), findsOneWidget);
      await tester.ensureVisible(find.byTooltip(l.arenaCreateChallenge));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l.arenaCreateChallenge));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.arenaPublicChallenge));
      await tester.pumpAndSettle();
      expect(find.text(l.arenaCreatePublic), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'My challenge');
      await tester.enterText(find.byType(TextField).at(1), 'My description');
      await tester.tap(find.text(l.arenaCreate));
      await tester.pumpAndSettle();
      expect(repository.createdTitle, 'My challenge');
      expect(repository.createdDescription, 'My description');
      expect(repository.createdType, 'streak');
      expect(repository.createdDuration, 7);
      await tester.ensureVisible(find.text('Morning movement'));
      await tester.pumpAndSettle();
      expect(find.text('Morning movement'), findsOneWidget);
      await tester.tap(find.text('Morning movement'));
      await tester.pumpAndSettle();
      expect(find.text(l.arenaDays(0)), findsOneWidget);
      await tester.ensureVisible(find.text(l.arenaLeaderboard));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.arenaLeaderboard));
      await tester.pumpAndSettle();
      expect(find.text(l.arenaActiveDays), findsOneWidget);
      expect(find.text('@runner'), findsOneWidget);
      await tester.tap(find.text(l.arenaGlobal));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.arenaFriends).last);
      await tester.pumpAndSettle();
      expect(repository.lastScope, 'friends');
      expect(tester.takeException(), isNull);
    });
  }

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
          builder: () => ArenaScreen(
              repository: _ArenaDataSource(),
              progressionRepository: FakeProgression()),
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
    await tester.ensureVisible(find.text('Leaderboard'));
    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();
    expect(find.text('Active days'), findsOneWidget);
    expect(find.text('@runner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final count in [0, 1, 2]) {
    testWidgets('Arena displays $count with the correct day unit',
        (tester) async {
      tester.view.physicalSize = const Size(393, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previousStreak = appState.streak;
      final previousLongestStreak = appState.longestStreak;
      addTearDown(() {
        appState.streak = previousStreak;
        appState.longestStreak = previousLongestStreak;
      });
      appState.streak = count;
      appState.longestStreak = count;

      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: AppPage(
          title: 'Streak Arena',
          builder: () => ArenaScreen(
              repository: _ArenaDataSource(score: count),
              progressionRepository: FakeProgression()),
        ),
      ));
      await tester.pumpAndSettle();

      final label = '$count ${count == 1 ? 'day' : 'days'}';
      expect(find.text('Your streak: $label'), findsOneWidget);
      expect(find.text('Longest streak: $label'), findsOneWidget);
      expect(find.text('Your score: $label · #1'), findsOneWidget);
      await tester.ensureVisible(find.text('Morning movement'));
      await tester.tap(find.text('Morning movement'));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);

      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _ArenaDataSource implements ArenaDataSource {
  _ArenaDataSource({this.score});

  final int? score;
  String? createdTitle, createdDescription, createdType;
  String? lastScope;
  int? createdDuration;

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
          myScore: score?.toDouble() ?? 0,
          myRank: 1,
          joined: score != null,
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
  }) async {
    lastScope = scope;
    return [
      ArenaLeaderboardEntry(
        userId: 'user-1',
        username: 'runner',
        fullName: null,
        avatarUrl: null,
        score: score ?? 4,
        currentStreak: 2,
        levelId: null,
        levelName: null,
        place: 1,
        isMe: true,
      )
    ];
  }

  @override
  Future<List<ArenaStanding>> standings(String challengeId) async => [
        ArenaStanding(
          userId: 'user-1',
          username: 'runner',
          fullName: null,
          avatarUrl: null,
          score: (score ?? 0).toDouble(),
          rank: 1,
          isMe: true,
        )
      ];

  @override
  Future<List<CommunityPerson>> friends() async => [];

  @override
  Future<void> createPublicChallenge({
    required String title,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String description = '',
  }) async {
    createdTitle = title;
    createdDescription = description;
    createdType = type;
    createdDuration = endDate.difference(startDate).inDays + 1;
  }

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
