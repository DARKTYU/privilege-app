import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/screens/groups.dart';
import 'package:privilege/screens/alerts.dart';
import 'package:privilege/models/community_models.dart';
import 'package:privilege/services/community_repository.dart';
import 'package:privilege/services/groups_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  setUpAll(() {
    client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
  });
  tearDownAll(() => client.dispose());

  testWidgets('create group sends the form to the secure function',
      (tester) async {
    final repo = _GroupsRepo(client);
    await tester
        .pumpWidget(MaterialApp(home: GroupSettingsPage(repository: repo)));
    await tester.enterText(
        find.widgetWithText(TextField, 'Name'), 'Fitness friends');
    await tester.enterText(
        find.widgetWithText(TextField, 'Category'), 'Fitness');
    await tester.scrollUntilVisible(find.text('Save'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.lastCall, 'group_create');
    expect(repo.lastParams?['p_name'], 'Fitness friends');
    expect(repo.lastParams?['p_member_limit'], 100);
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
    expect(find.text('No posts yet.'), findsOneWidget);
    await tester.tap(find.text('Leave group'));
    await tester.pumpAndSettle();
    expect(find.text('Join'), findsOneWidget);
  });

  testWidgets('owner can save settings including chat placeholder',
      (tester) async {
    final repo = _GroupsRepo(client);
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
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.lastCall, 'group_update_settings');
    expect(repo.lastParams?['p_member_limit'], 15);
    expect(repo.lastParams?['p_chat_enabled'], true);
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

  testWidgets('approval requests can be cancelled', (tester) async {
    final repo = _GroupsRepo(client)..joinMode = 'approval';
    await tester.pumpWidget(
        MaterialApp(home: GroupPage(repository: repo, groupId: 'group')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request to join'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel request'), findsOneWidget);
    await tester.tap(find.text('Cancel request'));
    await tester.pumpAndSettle();
    expect(find.text('Request to join'), findsOneWidget);
  });

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
    expect(groupError(const GroupException('You are banned from this group')),
        'You are banned from this group.');
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
  bool hiddenUntilJoin = false;
  Map<String, dynamic>? lastParams;
  Object? failure;
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
        'avatar_url': null,
        'who_can_post': 'everyone',
        'images_allowed': false,
        'chat_enabled': false,
      });
  @override
  Future<Group?> group(String id) async =>
      hiddenUntilJoin && status != 'active' ? null : item;
  @override
  Future<String?> notificationTarget(String id) async => 'group';
  @override
  Future<int> count(String id) async => status == 'active' ? 2 : 1;
  @override
  Future<List<Map<String, dynamic>>> members(String id) async => status == null
      ? []
      : [
          {'user_id': 'me', 'status': status, 'role': 'member'}
        ];
  @override
  Future<List<Map<String, dynamic>>> posts(String id) async => [];
  @override
  Future<Map<String, dynamic>?> profile(String id) async => {'username': 'me'};
  @override
  Future<dynamic> rpc(String name, Map<String, dynamic> params) async {
    lastCall = name;
    lastParams = params;
    if (failure != null) throw failure!;
    if (name == 'group_join') {
      status = joinMode == 'approval' ? 'pending' : 'active';
    }
    if (name == 'group_leave') status = null;
    return null;
  }
}
