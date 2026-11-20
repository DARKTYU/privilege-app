import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/screens/groups.dart';
import 'package:privilege/screens/alerts.dart';
import 'package:privilege/models/community_models.dart';
import 'package:privilege/services/community_repository.dart';
import 'package:privilege/services/groups_repository.dart';
import 'package:privilege/widgets/post_image.dart';
import 'package:privilege/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  setUpAll(() {
    client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
  });
  tearDownAll(() => client.dispose());

  test('groups screen has no hardcoded UI literals or Arabic', () {
    final source = File('lib/screens/groups.dart').readAsStringSync();
    final pattern = RegExp(
        r"""(?:Text\(\s*(?:const\s*)?|(?:labelText|hintText|tooltip|semanticLabel)\s*:\s*)['"]""");
    expect(pattern.allMatches(source), isEmpty);
    expect(source, isNot(contains(RegExp(r'[\u0600-\u06ff]'))));
  });

  testWidgets('group settings validation follows a live language change',
      (tester) async {
    final repo = _GroupsRepo(client);
    Widget app(Locale locale) => MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GroupSettingsPage(repository: repo),
        );
    await tester.pumpWidget(app(const Locale('en')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Save'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter a name of at least'), findsOneWidget);
    await tester.pumpWidget(app(const Locale('ar')));
    await tester.pumpAndSettle();
    final l =
        AppLocalizations.of(tester.element(find.byType(GroupSettingsPage)))!;
    expect(find.text(l.groupsValidation), findsOneWidget);
    expect(find.textContaining('Enter a name of at least'), findsNothing);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('group membership and reporting at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _GroupsRepo(client);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: GroupPage(repository: repo, groupId: 'group'),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(GroupPage)))!;
      expect(find.text('Fitness friends'), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text(l.groupJoinToSee), findsOneWidget);
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.groupReportGroup));
      await tester.pumpAndSettle();
      expect(find.text(l.groupReport), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextField, l.groupReason), 'Reason typed');
      await tester.tap(find.text(l.communitySubmit));
      await tester.pumpAndSettle();
      expect(repo.lastParams?['p_reason'], 'Reason typed');
      expect(find.text(l.communityReportSubmitted), findsOneWidget);
      await tester.tap(find.text(l.groupJoin));
      await tester.pumpAndSettle();
      expect(find.text(l.groupLeave), findsOneWidget);
      expect(find.text(l.groupNoPosts), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('group posts comments and member actions at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _GroupsRepo(client)
        ..status = 'active'
        ..role = 'owner'
        ..showPost = true
        ..postHasImage = false
        ..extraMembers = [
          {'user_id': 'requester', 'status': 'pending', 'role': 'member'}
        ];
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: GroupPage(repository: repo, groupId: 'group'),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(GroupPage)))!;
      await tester.tap(find.text(l.groupCreatePost));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, l.groupWritePost), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(l.groupCancel));
      await tester.pumpAndSettle();
      expect(find.text('Group post'), findsOneWidget);
      await tester.tap(find.text(l.communityComments));
      await tester.pumpAndSettle();
      expect(find.text(l.groupNoComments), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextField, l.groupComment), 'A typed comment');
      await tester.tap(find.byTooltip(l.groupSendComment));
      await tester.pumpAndSettle();
      expect(repo.lastParams?['p_body'], 'A typed comment');
      expect(find.text('A typed comment'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('requester'), 200,
          scrollable: find.byType(Scrollable).first);
      final tile = find
          .ancestor(of: find.text('requester'), matching: find.byType(ListTile))
          .first;
      await tester.tap(find.descendant(
          of: tile, matching: find.byType(PopupMenuButton<String>)));
      await tester.pumpAndSettle();
      expect(find.text(l.groupApproveRequest), findsOneWidget);
      await tester.tap(find.text(l.groupBan));
      await tester.pumpAndSettle();
      expect(find.text(l.groupBanDetails), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(l.groupCancel));
      await tester.pumpAndSettle();
    });

    testWidgets('banned members and invite screens at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _GroupsRepo(client)
        ..status = 'active'
        ..role = 'moderator'
        ..banned = [
          {
            'user_id': 'banned',
            'full_name': 'Banned Person',
            'username': 'person',
            'banned_at': '2026-01-02T00:00:00Z',
            'banned_by_full_name': 'Moderator Name'
          }
        ];
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: GroupPage(repository: repo, groupId: 'group'),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(GroupPage)))!;
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.groupBannedMembers));
      await tester.pumpAndSettle();
      expect(find.text('Banned Person'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
      expect(find.textContaining(l.groupBannedBy('Moderator Name')),
          findsOneWidget);
      await tester.tap(find.text(l.groupUnban));
      await tester.pumpAndSettle();
      expect(find.text(l.groupUnbanDetails), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(l.groupCancel));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.groupInvitePeople));
      await tester.pumpAndSettle();
      expect(find.text(l.groupSearchInvite), findsOneWidget);
      expect(
          find.widgetWithText(TextField, l.groupSearchUsers), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('group discovery and settings at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _GroupsRepo(client);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: GroupsTab(repository: repo)),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(GroupsTab)))!;
      expect(find.text(l.groupsDiscover), findsOneWidget);
      expect(find.text(l.groupsMine), findsOneWidget);
      expect(find.text('Fitness friends'), findsOneWidget);
      expect(find.text(l.groupsSummary('Fitness', l.groupsPublic)),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip(l.groupsCreate));
      await tester.pumpAndSettle();
      expect(find.text(l.groupsCreate), findsOneWidget);
      expect(find.text(l.groupsFitness), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(l.groupsFitness));
      await tester.pumpAndSettle();
      expect(find.text(l.groupsRunning), findsWidgets);
      await tester.tap(find.text(l.groupsRunning).last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(l.groupsPublic), 160,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(l.groupsPublic));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.groupsPrivate).last);
      await tester.pumpAndSettle();
      expect(find.text(l.groupsPrivateInvitation), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text(l.groupsSave), 250,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(l.groupsSave));
      await tester.pumpAndSettle();
      expect(find.text(l.groupsValidation), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
          find.widgetWithText(TextField, l.groupsName), -250,
          scrollable: find.byType(Scrollable).first);
      await tester.enterText(
          find.widgetWithText(TextField, l.groupsName), 'Fitness friends');
      await tester.scrollUntilVisible(find.text(l.groupsSave), 250,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(l.groupsSave));
      await tester.pumpAndSettle();
      expect(repo.lastParams?['p_name'], 'Fitness friends');
      expect(repo.lastParams?['p_category'], 'Running & cardio');
      expect(repo.lastParams?['p_visibility'], 'private');
      expect(tester.takeException(), isNull);
    });

    testWidgets('group invitations and pending status at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _GroupsRepo(client)
        ..status = 'pending'
        ..showInvitation = true;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: GroupsTab(repository: repo)),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(GroupsTab)))!;
      expect(
          find.text(l.groupsPendingSummary(
              l.groupsSummary('Fitness', l.groupsPublic))),
          findsOneWidget);
      await tester.tap(find.text(l.groupsMine));
      await tester.pumpAndSettle();
      expect(find.text(l.groupsInvitations), findsOneWidget);
      expect(find.text(l.groupsOpenToAccept), findsOneWidget);
      expect(find.text('Fitness friends'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty and error groups states at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _GroupsRepo(client)..emptyGroups = true;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: GroupsTab(repository: repo)),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(GroupsTab)))!;
      expect(find.text(l.groupsNone), findsOneWidget);
      expect(tester.takeException(), isNull);
      repo.groupsFailure = const GroupException('This group is full.');
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: GroupsTab(key: UniqueKey(), repository: repo)),
      ));
      await tester.pumpAndSettle();
      expect(find.text(l.groupsFullError), findsOneWidget);
      expect(find.text(l.groupsRetry), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('create group sends the form to the secure function',
      (tester) async {
    final repo = _GroupsRepo(client);
    await tester
        .pumpWidget(MaterialApp(home: GroupSettingsPage(repository: repo)));
    await tester.enterText(
        find.widgetWithText(TextField, 'Name'), 'Fitness friends');
    await tester.tap(find.text('General fitness'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Running & cardio').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Save'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Avatar image URL'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.lastCall, 'group_create');
    expect(repo.lastParams?['p_name'], 'Fitness friends');
    expect(repo.lastParams?['p_category'], 'Running & cardio');
    expect(repo.lastParams?['p_member_limit'], 100);
    expect(repo.lastParams!.containsKey('p_avatar_url'), isTrue);
    expect(repo.lastParams?['p_avatar_url'], isNull);
  });

  testWidgets('moderators see pending requests and can approve them',
      (tester) async {
    final repo = _GroupsRepo(client)
      ..status = 'active'
      ..role = 'moderator'
      ..extraMembers = [
        {'user_id': 'requester', 'status': 'pending', 'role': 'member'}
      ];
    await tester.pumpWidget(
        MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('requester'), 180,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Join requests'), findsOneWidget);
    final tile = find
        .ancestor(of: find.text('requester'), matching: find.byType(ListTile))
        .first;
    await tester.tap(find.descendant(
        of: tile, matching: find.byType(PopupMenuButton<String>)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve request'));
    await tester.pumpAndSettle();
    expect(repo.lastParams?['p_action'], 'approve');
    expect(repo.memberReads, greaterThan(1));
    expect(repo.postReads, greaterThan(1));
    expect(repo.countReads, greaterThan(1));
  });

  testWidgets('group refreshes on app resume and pull to refresh',
      (tester) async {
    final repo = _GroupsRepo(client)..status = 'active';
    await tester.pumpWidget(
        MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
    await tester.pumpAndSettle();
    final before = repo.memberReads;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.memberReads, greaterThan(before));
    final afterResume = repo.memberReads;
    await tester.drag(find.byType(ListView).first, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(repo.memberReads, greaterThan(afterResume));
  });

  testWidgets('join and leave update the group page', (tester) async {
    final repo = _GroupsRepo(client);
    await tester.pumpWidget(
        MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
    await tester.pumpAndSettle();
    expect(find.text('Join'), findsOneWidget);
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    expect(find.text('Leave group'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Leave group'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create post'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsWidgets);
    expect(find.text('No posts yet.'), findsOneWidget);
    final readsAfterJoin = repo.memberReads;
    await tester.tap(find.text('Leave group'));
    await tester.pumpAndSettle();
    expect(find.text('Join'), findsOneWidget);
    expect(repo.memberReads, greaterThan(readsAfterJoin));
  });

  testWidgets('owner can save settings including chat placeholder',
      (tester) async {
    final repo = _GroupsRepo(client)
      ..avatarUrl = 'https://example.com/group-avatar.png';
    await tester.pumpWidget(MaterialApp(
        home: GroupSettingsPage(repository: repo, group: repo.item)));
    await tester.scrollUntilVisible(
        find.widgetWithText(TextField, 'Member limit'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(
        find.widgetWithText(TextField, 'Member limit'), '15');
    await tester.scrollUntilVisible(find.text('Chat (coming in phase 2)'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Chat (coming in phase 2)'));
    await tester.scrollUntilVisible(find.text('Save'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Avatar image URL'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.lastCall, 'group_update_settings');
    expect(repo.lastParams?['p_member_limit'], 15);
    expect(repo.lastParams?['p_chat_enabled'], true);
    expect(repo.lastParams?['p_avatar_url'], repo.avatarUrl);
  });

  testWidgets('external group avatar URL is not loaded', (tester) async {
    final repo = _GroupsRepo(client)
      ..avatarUrl = 'https://example.com/group-avatar.png';
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GroupsTab(repository: repo))));
    await tester.pumpAndSettle();
    final avatar = tester.widget<CircleAvatar>(find.descendant(
        of: find.byType(GroupAvatar), matching: find.byType(CircleAvatar)));
    expect(avatar.foregroundImage, isNull);
    await tester.tap(find.text('Fitness friends'));
    await tester.pumpAndSettle();
    final pageAvatar = tester.widget<CircleAvatar>(find.descendant(
        of: find.byType(GroupAvatar), matching: find.byType(CircleAvatar)));
    expect(pageAvatar.foregroundImage, isNull);
  });

  testWidgets('join failures show a clear message', (tester) async {
    final repo = _GroupsRepo(client)
      ..failure = const GroupException('Group is full');
    await tester.pumpWidget(
        MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    expect(find.text('This group is full.'), findsOneWidget);
    expect(find.text('Join'), findsOneWidget);
  });

  testWidgets('posts and members show display name, username and avatar',
      (tester) async {
    final repo = _GroupsRepo(client)
      ..status = 'active'
      ..showPost = true;
    await tester.pumpWidget(
        MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
    await tester.pumpAndSettle();
    expect(find.text('Hossam Ahmed'), findsOneWidget);
    expect(find.text('@hossam'), findsOneWidget);
    expect(find.byType(PostImage), findsOneWidget);
    final post = tester.element(find.text('Hossam Ahmed'));
    final tile = tester.widget<ListTile>(find
        .ancestor(
            of: find.byElementPredicate((e) => e == post),
            matching: find.byType(ListTile))
        .first);
    final avatar = tile.leading as CircleAvatar;
    expect(avatar.foregroundImage, isA<NetworkImage>());
    await tester.scrollUntilVisible(find.text('Members'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Hossam Ahmed'), findsNWidgets(2));
    expect(find.text('@hossam'), findsNWidgets(2));
    expect(find.textContaining('active'), findsNothing);
  });

  testWidgets(
      'group avatars stay consistent across tabs, page and invite screen',
      (tester) async {
    final repo = _GroupsRepo(client)
      ..status = 'active'
      ..role = 'owner';
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GroupsTab(repository: repo))));
    await tester.pumpAndSettle();
    final discoverAvatar = tester.widget<CircleAvatar>(find
        .descendant(
            of: find.byType(GroupAvatar), matching: find.byType(CircleAvatar))
        .first);
    expect(find.text('FF'), findsOneWidget);
    await tester.tap(find.text('My groups'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<CircleAvatar>(find
                .descendant(
                    of: find.byType(GroupAvatar),
                    matching: find.byType(CircleAvatar))
                .first)
            .backgroundColor,
        discoverAvatar.backgroundColor);
    await tester.tap(find.text('Fitness friends'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<CircleAvatar>(find
                .descendant(
                    of: find.byType(GroupAvatar),
                    matching: find.byType(CircleAvatar))
                .first)
            .backgroundColor,
        discoverAvatar.backgroundColor);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite people'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<CircleAvatar>(find
                .descendant(
                    of: find.byType(GroupAvatar),
                    matching: find.byType(CircleAvatar))
                .first)
            .backgroundColor,
        discoverAvatar.backgroundColor);
  });

  testWidgets('selected tab has an underline and distinct color',
      (tester) async {
    final repo = _GroupsRepo(client);
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GroupsTab(repository: repo))));
    await tester.pumpAndSettle();
    Color? color(String label) {
      final button =
          tester.widget<TextButton>(find.widgetWithText(TextButton, label));
      return button.style!.foregroundColor!.resolve({});
    }

    final selected = color('Discover');
    final unselected = color('My groups');
    expect(selected, isNot(unselected));
    await tester.tap(find.text('My groups'));
    await tester.pumpAndSettle();
    expect(color('Discover'), unselected);
    expect(color('My groups'), selected);
  });

  testWidgets('fixed category filter includes legacy values under Other',
      (tester) async {
    final repo = _GroupsRepo(client);
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GroupsTab(repository: repo))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fitness · Public'), findsOneWidget);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    for (final category in groupCategories) {
      expect(find.text(category), findsOneWidget);
    }
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Fitness · Public'), findsOneWidget);
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nutrition').last);
    await tester.pumpAndSettle();
    expect(find.text('No groups found.'), findsOneWidget);
  });

  testWidgets('legacy category is preserved when editing', (tester) async {
    final repo = _GroupsRepo(client);
    await tester.pumpWidget(MaterialApp(
        home: GroupSettingsPage(repository: repo, group: repo.item)));
    expect(find.text('Fitness'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Save'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.lastParams?['p_category'], 'Fitness');
  });

  testWidgets('member counts, role badges and username layout', (tester) async {
    final repo = _GroupsRepo(client)
      ..status = 'active'
      ..role = 'owner'
      ..extraMembers = [
        {'user_id': 'mod', 'status': 'active', 'role': 'moderator'}
      ];
    await tester.pumpWidget(
        MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
    await tester.pumpAndSettle();
    expect(find.text('Fitness · 2 members'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Moderator'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Moderator'), findsOneWidget);
    final username = tester.widget<Text>(find.text('@mod'));
    expect(username.maxLines, 1);
    expect(username.overflow, TextOverflow.ellipsis);
    expect(find.textContaining('· active'), findsNothing);
    repo.status = null;
    await tester.pumpWidget(MaterialApp(
        home: GroupPage(key: UniqueKey(), repository: repo, groupId: 'group')));
    await tester.pumpAndSettle();
    expect(find.text('Fitness · 1 member'), findsOneWidget);
  });

  testWidgets('form counters align and rules remain reachable with keyboard',
      (tester) async {
    final repo = _GroupsRepo(client);
    await tester
        .pumpWidget(MaterialApp(home: GroupSettingsPage(repository: repo)));
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Fit');
    await tester.pumpAndSettle();
    expect(find.text('3 / 80'), findsOneWidget);
    final counter = tester.widget<Align>(find
        .ancestor(of: find.text('3 / 80'), matching: find.byType(Align))
        .first);
    expect(counter.alignment, AlignmentDirectional.centerEnd);
    final keyboardInset = 300 * tester.view.devicePixelRatio;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.widgetWithText(TextField, 'Rules'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.widgetWithText(TextField, 'Rules'), 'Be kind');
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(find.text('7 / 5000'), findsOneWidget);
    final rulesRect = tester.getRect(find.widgetWithText(TextField, 'Rules'));
    expect(
        rulesRect.bottom,
        lessThanOrEqualTo(
            tester.view.physicalSize.height / tester.view.devicePixelRatio -
                300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('approval requests can be cancelled', (tester) async {
    final repo = _GroupsRepo(client)..joinMode = 'approval';
    await tester.pumpWidget(
        MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request to join'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel request'), findsOneWidget);
    expect(find.text('Request pending'), findsOneWidget);
    await tester.tap(find.text('Cancel request'));
    await tester.pumpAndSettle();
    expect(find.text('Request to join'), findsOneWidget);
  });

  testWidgets('discover displays pending request', (tester) async {
    final repo = _GroupsRepo(client)..status = 'pending';
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GroupsTab(repository: repo))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Request pending'), findsOneWidget);
  });

  testWidgets('banned join error is specific and does not add membership',
      (tester) async {
    final repo = _GroupsRepo(client)
      ..failure = const GroupException('banned_from_group');
    await tester.pumpWidget(
        MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'You are banned from this group. Only the group owner or a moderator can unban you.'),
        findsOneWidget);
    expect(find.text('Join'), findsOneWidget);
    expect(repo.status, isNull);
  });

  for (final role in ['owner', 'moderator']) {
    testWidgets('$role can view and unban banned members', (tester) async {
      final repo = _GroupsRepo(client)
        ..status = 'active'
        ..role = role
        ..banned = [
          {
            'user_id': 'banned',
            'full_name': 'Banned Person',
            'username': 'banned_user',
            'avatar_url': null,
            'banned_at': '2026-01-02T00:00:00Z',
            'banned_by_full_name': 'Moderator Name'
          }
        ];
      await tester.pumpWidget(
          MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Banned members'));
      await tester.pumpAndSettle();
      expect(find.text('Banned Person'), findsOneWidget);
      expect(find.textContaining('By Moderator Name'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
      await tester.tap(find.text('Unban'));
      await tester.pumpAndSettle();
      expect(find.text('Unban member?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Unban').last);
      await tester.pumpAndSettle();
      expect(repo.lastCall, 'group_unban');
      expect(repo.lastParams?['p_user'], 'banned');
      expect(find.text('No banned members.'), findsOneWidget);
      expect(repo.memberReads, greaterThan(1));
      expect(repo.postReads, greaterThan(1));
      expect(repo.countReads, greaterThan(1));
    });
  }

  testWidgets('regular members cannot access banned list or pending members',
      (tester) async {
    final repo = _GroupsRepo(client)
      ..status = 'active'
      ..extraMembers = [
        {'user_id': 'pending', 'status': 'pending', 'role': 'member'},
        {'user_id': 'former', 'status': 'left', 'role': 'member'},
        {'user_id': 'banned', 'status': 'banned', 'role': 'member'},
      ];
    await tester.pumpWidget(
        MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Banned members'), findsNothing);
    expect(repo.bannedReads, 0);
    expect(find.text('pending'), findsNothing);
    expect(find.text('former'), findsNothing);
    expect(find.text('banned'), findsNothing);
  });

  for (final operation in ['Remove', 'Ban']) {
    testWidgets('$operation confirms and refreshes the group after success',
        (tester) async {
      final repo = _GroupsRepo(client)
        ..status = 'active'
        ..role = 'owner'
        ..extraMembers = [
          {'user_id': 'target', 'status': 'active', 'role': 'member'}
        ];
      await tester.pumpWidget(
          MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('target'), 180,
          scrollable: find.byType(Scrollable).first);
      final tile = find
          .ancestor(of: find.text('target'), matching: find.byType(ListTile))
          .first;
      await tester.tap(find.descendant(
          of: tile, matching: find.byType(PopupMenuButton<String>)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(operation).last);
      await tester.pumpAndSettle();
      expect(
          find.text(operation == 'Remove'
              ? 'This removes the member and hides their posts and comments in this group. They can join again.'
              : 'This bans the member until you unban them. Their posts and comments in this group are hidden and they cannot join again.'),
          findsOneWidget);
      expect(repo.lastCall, isNull);
      await tester.tap(find.widgetWithText(TextButton, operation).last);
      await tester.pumpAndSettle();
      expect(repo.lastParams?['p_action'], operation.toLowerCase());
      expect(repo.memberReads, greaterThan(1));
      expect(repo.postReads, greaterThan(1));
      expect(repo.countReads, greaterThan(1));
      expect(find.text('target'), findsNothing);
    });
  }

  testWidgets('private invitation can be accepted without exposing the group',
      (tester) async {
    final repo = _GroupsRepo(client)..hiddenUntilJoin = true;
    await tester.pumpWidget(MaterialApp(
        home: GroupPage(repository: repo, groupId: 'group', invited: true)));
    await tester.pumpAndSettle();
    expect(find.text('Fitness friends'), findsNothing);
    await tester.tap(find.text('Accept invitation'));
    await tester.pumpAndSettle();
    expect(find.text('Fitness friends'), findsOneWidget);
    expect(find.text('Leave group'), findsOneWidget);
    await tester.tap(find.text('Leave group'));
    await tester.pumpAndSettle();
    expect(find.text('Accept invitation'), findsNothing);
  });

  testWidgets('group alert opens its private invitation', (tester) async {
    final repo = _GroupsRepo(client)..hiddenUntilJoin = true;
    final alert = CommunityNotification(
      id: 'alert',
      type: 'group_invited',
      postId: null,
      friendshipId: null,
      readAt: null,
      createdAt: DateTime.utc(2026),
      actorId: 'owner',
      username: 'owner',
      fullName: null,
      avatarUrl: null,
    );
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => TextButton(
        onPressed: () => openAlertTarget(
            context, alert, CommunityRepository(client),
            groupsRepository: repo),
        child: const Text('Open alert'),
      ),
    ))));
    await tester.tap(find.text('Open alert'));
    await tester.pumpAndSettle();
    expect(find.text('Accept invitation'), findsOneWidget);
    await tester.tap(find.text('Accept invitation'));
    await tester.pumpAndSettle();
    expect(find.text('Fitness friends'), findsOneWidget);
  });

  test('group errors are friendly', () {
    final wrapped =
        groupError(const PostgrestException(message: 'banned_from_group'));
    expect(groupError(GroupException(wrapped)),
        'You are banned from this group. Only the group owner or a moderator can unban you.');
    expect(groupError(const GroupException('You are banned from this group')),
        'You are banned from this group. Only the group owner or a moderator can unban you.');
    expect(groupError(const GroupException('Only moderators can post')),
        'Only moderators can post in this group.');
    expect(
        groupError(
            const GroupException('Posting limit reached; try again later')),
        'Posting limit reached. Please try again later.');
    expect(groupError(const GroupException('You can own at most three groups')),
        'You can create up to 3 groups.');
  });
}

class _GroupsRepo extends GroupsRepository {
  _GroupsRepo(super.client);
  String? status, lastCall;
  String joinMode = 'open';
  String role = 'member';
  bool hiddenUntilJoin = false;
  bool showPost = false;
  bool postHasImage = true;
  final List<Map<String, dynamic>> testComments = [];
  bool emptyGroups = false;
  bool showInvitation = false;
  Object? groupsFailure;
  String? avatarUrl;
  Map<String, dynamic>? lastParams;
  Object? failure;
  List<Map<String, dynamic>> extraMembers = [];
  List<Map<String, dynamic>> banned = [];
  int memberReads = 0, postReads = 0, countReads = 0, bannedReads = 0;
  @override
  String get userId => 'me';
  Group get item => Group.fromJson({
        'id': 'group',
        'owner_id': 'owner',
        'name': 'Fitness friends',
        'description': 'Welcome',
        'category': 'Fitness',
        'visibility': 'public',
        'join_mode': joinMode,
        'member_limit': 100,
        'rules': '',
        'avatar_url': avatarUrl,
        'who_can_post': 'everyone',
        'images_allowed': false,
        'chat_enabled': false,
      });
  @override
  Future<Group?> group(String id) async =>
      hiddenUntilJoin && status != 'active' ? null : item;
  @override
  Future<List<Group>> groups() async {
    if (groupsFailure != null) throw groupsFailure!;
    return emptyGroups ? [] : [item];
  }

  @override
  Future<List<Map<String, dynamic>>> myMemberships() async => status == null
      ? []
      : [
          {'group_id': 'group', 'status': status}
        ];
  @override
  Future<List<Map<String, dynamic>>> invitations() async => showInvitation
      ? [
          {'group_id': 'group'}
        ]
      : [];
  @override
  Future<List<Map<String, dynamic>>> bannedMembers(String id) async {
    bannedReads++;
    return List.of(banned);
  }

  @override
  Future<String?> notificationTarget(String id) async => 'group';
  @override
  Future<int> count(String id) async {
    countReads++;
    return status == 'active' ? 2 : 1;
  }

  @override
  Future<List<Map<String, dynamic>>> members(String id) async {
    memberReads++;
    return [
      if (status != null) {'user_id': 'me', 'status': status, 'role': role},
      ...extraMembers
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> posts(String id) async {
    postReads++;
    return showPost
        ? [
            {
              'id': 'post',
              'author_id': 'me',
              'body': 'Group post',
              'image_path': postHasImage ? 'photo' : null
            }
          ]
        : [];
  }

  @override
  Future<List<Map<String, dynamic>>> likes(String id) async => [];
  @override
  Future<List<Map<String, dynamic>>> comments(String id) async =>
      List.of(testComments);
  @override
  Future<String> imageUrl(String path) async =>
      '${SupabaseConfig.url}/storage/v1/object/sign/posts/image.png';
  @override
  Future<Map<String, dynamic>?> profile(String id) async =>
      showPost && id == 'me'
          ? {
              'username': 'hossam',
              'full_name': 'Hossam Ahmed',
              'avatar_url':
                  '${SupabaseConfig.url}/storage/v1/object/public/avatars/avatar.png'
            }
          : {'username': id};
  @override
  Future<dynamic> rpc(String name, Map<String, dynamic> params) async {
    lastCall = name;
    lastParams = params;
    if (failure != null) throw failure!;
    if (name == 'group_join') {
      status = joinMode == 'approval' ? 'pending' : 'active';
    }
    if (name == 'group_leave') status = null;
    if (name == 'group_unban') {
      banned.removeWhere((m) => m['user_id'] == params['p_user']);
    }
    if (name == 'group_create_comment') {
      testComments.add({'body': params['p_body'], 'author_id': 'me'});
    }
    if (name == 'group_manage_member' &&
        ['remove', 'ban'].contains(params['p_action'])) {
      extraMembers.removeWhere((m) => m['user_id'] == params['p_user']);
    }
    return null;
  }
}
