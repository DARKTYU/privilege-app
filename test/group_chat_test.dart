import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/screens/groups.dart';
import 'package:privilege/services/groups_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  setUpAll(() {
    client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
  });
  tearDownAll(() => client.dispose());

  Group group() => Group.fromJson({
        'id': 'group',
        'owner_id': 'owner',
        'name': 'Fitness friends',
        'description': '',
        'category': 'Fitness',
        'visibility': 'public',
        'join_mode': 'open',
        'member_limit': 100,
        'rules': '',
        'avatar_url': null,
        'who_can_post': 'everyone',
        'images_allowed': false,
        'chat_enabled': true,
      });

  Widget app(_ChatRepo repo,
          {bool moderator = false,
          Locale locale = const Locale('en'),
          void Function(String)? onReport}) =>
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: GroupChatPage(
            repository: repo,
            group: group(),
            moderator: moderator,
            onReport: onReport ?? (_) {}),
      );

  testWidgets('shows messages with author names and an empty state',
      (tester) async {
    final empty = _ChatRepo(client);
    await tester.pumpWidget(app(empty));
    await tester.pumpAndSettle();
    expect(find.text('No messages yet. Say hello!'), findsOneWidget);

    final repo = _ChatRepo(client)
      ..rows = [
        {'id': '2', 'author_id': 'me', 'body': 'Great session!',
         'created_at': '2026-11-25T10:05:00Z'},
        {'id': '1', 'author_id': 'sara', 'body': 'Who is training today?',
         'created_at': '2026-11-25T10:00:00Z'},
      ];
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('Who is training today?'), findsOneWidget);
    expect(find.text('Great session!'), findsOneWidget);
    expect(find.text('Sara Ali'), findsOneWidget);
    expect(find.text('Group chat'), findsOneWidget);
    expect(find.text('Fitness friends'), findsOneWidget);
    // The newest message is below the older one.
    expect(tester.getTopLeft(find.text('Great session!')).dy,
        greaterThan(tester.getTopLeft(find.text('Who is training today?')).dy));
  });

  testWidgets('sending trims text, clears the box and refreshes',
      (tester) async {
    final repo = _ChatRepo(client);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    final send = find.widgetWithIcon(IconButton, Icons.send);
    expect(tester.widget<IconButton>(send).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '   Hello team  ');
    await tester.pump();
    expect(tester.widget<IconButton>(send).onPressed, isNotNull);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(repo.sent, ['Hello team']);
    expect(find.text('Hello team'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
  });

  testWidgets('a failed send keeps the text and shows a friendly message',
      (tester) async {
    final repo = _ChatRepo(client)
      ..sendFailure = const GroupException('Chat rate limit');
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Too fast');
    await tester.pump();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Too fast'), findsOneWidget);
    expect(find.textContaining('Chat rate limit'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(repo.sent, isEmpty);
  });

  testWidgets('authors can delete their own messages', (tester) async {
    final repo = _ChatRepo(client)
      ..rows = [
        {'id': 'mine', 'author_id': 'me', 'body': 'Oops wrong chat',
         'created_at': '2026-11-25T10:05:00Z'},
      ];
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Oops wrong chat'));
    await tester.pumpAndSettle();
    expect(find.text('Report member'), findsNothing);
    await tester.tap(find.text('Delete message'));
    await tester.pumpAndSettle();
    expect(repo.deleted, ['mine']);
    expect(find.text('Oops wrong chat'), findsNothing);
  });

  testWidgets('members report other people and moderators can also delete',
      (tester) async {
    final reported = <String>[];
    final repo = _ChatRepo(client)
      ..rows = [
        {'id': 'theirs', 'author_id': 'sara', 'body': 'Rude message',
         'created_at': '2026-11-25T10:05:00Z'},
      ];
    await tester.pumpWidget(app(repo, onReport: reported.add));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Rude message'));
    await tester.pumpAndSettle();
    expect(find.text('Delete message'), findsNothing);
    await tester.tap(find.text('Report member'));
    await tester.pumpAndSettle();
    expect(reported, ['sara']);

    await tester.pumpWidget(app(repo, moderator: true, onReport: reported.add));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Rude message'));
    await tester.pumpAndSettle();
    expect(find.text('Delete message'), findsOneWidget);
    expect(find.text('Report member'), findsOneWidget);
    await tester.tap(find.text('Delete message'));
    await tester.pumpAndSettle();
    expect(repo.deleted, ['theirs']);
  });

  testWidgets('load failure can be retried and realtime adds messages',
      (tester) async {
    final repo = _ChatRepo(client)..loadFailure = const GroupException('Offline');
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    repo.loadFailure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No messages yet. Say hello!'), findsOneWidget);

    repo.rows = [
      {'id': 'new', 'author_id': 'sara', 'body': 'Just arrived',
       'created_at': '2026-11-25T10:05:00Z'},
    ];
    repo.onChange!();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Just arrived'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(repo.stopped, isTrue);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('chat fits at 360 in $language', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _ChatRepo(client)
        ..rows = [
          for (var i = 0; i < 12; i++)
            {
              'id': '$i',
              'author_id': i.isEven ? 'me' : 'sara',
              'body': 'A fairly long message number $i that wraps over several lines in the bubble',
              'created_at': '2026-11-25T10:0${i % 10}:00Z',
            },
        ];
      await tester.pumpWidget(app(repo, locale: Locale(language)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'x' * 400);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

class _ChatRepo extends GroupsRepository {
  _ChatRepo(super.client);
  List<Map<String, dynamic>> rows = [];
  final sent = <String>[];
  final deleted = <String>[];
  Object? sendFailure, loadFailure;
  void Function()? onChange;
  bool stopped = false;
  @override
  String get userId => 'me';
  @override
  Future<List<Map<String, dynamic>>> chatMessages(String groupId,
      {int limit = 60}) async {
    if (loadFailure != null) throw loadFailure!;
    return List.of(rows);
  }

  @override
  Future<void> sendChatMessage(String groupId, String body) async {
    if (sendFailure != null) throw sendFailure!;
    sent.add(body);
    rows = [
      {'id': 'sent${sent.length}', 'author_id': 'me', 'body': body,
       'created_at': '2026-11-25T10:10:00Z'},
      ...rows,
    ];
  }

  @override
  Future<void> deleteChatMessage(String messageId) async {
    deleted.add(messageId);
    rows = rows.where((r) => r['id'] != messageId).toList();
  }

  @override
  void Function() watchChat(String groupId, void Function() onChange) {
    this.onChange = onChange;
    return () => stopped = true;
  }

  @override
  Future<Map<String, dynamic>?> profile(String id) async =>
      {'username': id, 'full_name': id == 'sara' ? 'Sara Ali' : 'Me'};
}
