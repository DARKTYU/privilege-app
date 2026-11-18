import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/models/community_models.dart';
import 'package:privilege/models/community_post.dart';
import 'package:privilege/screens/alerts.dart';
import 'package:privilege/services/community_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  setUpAll(() {
    client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
  });
  tearDownAll(() => client.dispose());

  testWidgets('alert list shows actor text and marks an opened alert read',
      (tester) async {
    final repo = _AlertsRepo(client);
    CommunityNotification? opened;
    await tester.pumpWidget(MaterialApp(
      home: AlertsPage(
        repository: repo,
        openTarget: (_, item) async => opened = item,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('@hossam commented: Nice work'), findsOneWidget);
    expect(find.text('@hossam liked your post.'), findsOneWidget);
    await tester.tap(find.text('@hossam commented: Nice work'));
    await tester.pumpAndSettle();
    expect(repo.marked, ['comment']);
    expect(opened?.postId, 'post');
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    expect(repo.allRead, isTrue);
    expect(find.text('Mark all as read'), findsNothing);
  });

  testWidgets('bell count refreshes and opens alerts', (tester) async {
    final repo = _AlertsRepo(client);
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AlertBell(repository: repo))));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    repo.count = 4;
    refreshAlerts();
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.byTooltip('Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('@hossam liked your post.'), findsOneWidget);
  });

  testWidgets('settings load and save without changing other categories',
      (tester) async {
    final repo = _AlertsRepo(client);
    await tester.pumpWidget(
        MaterialApp(home: NotificationSettingsPage(repository: repo)));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<SwitchListTile>(
                find.widgetWithText(SwitchListTile, 'Likes'))
            .value,
        isTrue);
    await tester.tap(find.text('Likes'));
    await tester.pumpAndSettle();
    expect(repo.settings['likes_enabled'], isFalse);
    expect(repo.settings['comments_enabled'], isTrue);
    expect(
        tester
            .widget<SwitchListTile>(
                find.widgetWithText(SwitchListTile, 'Likes'))
            .value,
        isFalse);
  });

  testWidgets('challenge and achievement alerts navigate to their screens',
      (tester) async {
    final repo = _AlertsRepo(client);
    await tester.pumpWidget(MaterialApp(
      routes: {
        '/arena': (_) => const Scaffold(body: Text('Arena destination')),
        '/badges': (_) => const Scaffold(body: Text('Badges destination')),
      },
      home: AlertsPage(repository: repo),
    ));
    repo.items = [_notification('challenge', 'challenge_result')];
    refreshAlerts();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your challenge results are ready.'));
    await tester.pumpAndSettle();
    expect(find.text('Arena destination'), findsOneWidget);
    Navigator.of(tester.element(find.text('Arena destination'))).pop();
    await tester.pumpAndSettle();
    repo.items = [_notification('badge', 'badge_earned')];
    refreshAlerts();
    await tester.pumpAndSettle();
    await tester.tap(find.text('You earned a badge!'));
    await tester.pumpAndSettle();
    expect(find.text('Badges destination'), findsOneWidget);
  });

  testWidgets('follow alert opens the actor public profile', (tester) async {
    final repo = _AlertsRepo(client)
      ..items = [
        CommunityNotification(
          id: 'follow',
          type: 'follow',
          postId: null,
          friendshipId: null,
          readAt: null,
          createdAt: DateTime.utc(2026),
          actorId: 'actor',
          username: 'hossam',
          fullName: null,
          avatarUrl: null,
        )
      ];
    await tester.pumpWidget(MaterialApp(home: AlertsPage(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('@hossam started following you.'));
    await tester.pumpAndSettle();
    expect(repo.openedProfile, 'actor');
    expect(find.text('Profile is unavailable.'), findsOneWidget);
  });

  testWidgets('post alert opens its post even when the feed is empty',
      (tester) async {
    final repo = _AlertsRepo(client)
      ..items = [_notification('like', 'post_like')];
    await tester.pumpWidget(MaterialApp(home: AlertsPage(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('@hossam liked your post.'));
    await tester.pumpAndSettle();
    expect(repo.openedPost, 'post');
    expect(find.text('Post opened from alert'), findsOneWidget);
    expect(find.text('Be the first to comment.'), findsOneWidget);
  });

  test('messages cover new alert types and unknown types', () {
    expect(_notification('a', 'comment_like').message,
        '@hossam liked your comment.');
    expect(
        _notification('a', 'follow').message, '@hossam started following you.');
    expect(_notification('a', 'friend_post').message,
        '@hossam shared a new post.');
    expect(
        _notification('a', 'unknown').message, 'You have a new notification.');
  });
}

CommunityNotification _notification(String id, String type, {String? body}) =>
    CommunityNotification(
      id: id,
      type: type,
      postId: type.startsWith('post_') ? 'post' : null,
      friendshipId: null,
      readAt: null,
      createdAt: DateTime.utc(2026),
      actorId: type.startsWith('post_') ? 'actor' : null,
      username: 'hossam',
      fullName: null,
      avatarUrl: null,
      commentBody: body,
    );

class _AlertsRepo extends CommunityRepository {
  _AlertsRepo(super.client);
  int count = 2;
  List<String> marked = [];
  bool allRead = false;
  String? openedProfile;
  String? openedPost;
  List<CommunityNotification> items = [
    _notification('comment', 'post_comment', body: 'Nice work'),
    _notification('like', 'post_like'),
  ];
  Map<String, bool> settings = {
    'likes_enabled': true,
    'comments_enabled': true,
    'friend_posts_enabled': true,
    'friend_requests_enabled': true,
  };
  @override
  Future<int> unreadCount() async => count;
  @override
  Future<List<CommunityNotification>> notifications() async =>
      allRead ? [] : items;
  @override
  Future<void> markNotificationRead(String id) async {
    marked.add(id);
  }

  @override
  Future<void> markAllNotificationsRead() async {
    allRead = true;
  }

  @override
  Future<Map<String, bool>> notificationSettings() async => Map.of(settings);
  @override
  Future<CommunityPublicProfile?> publicProfile(String userId) async {
    openedProfile = userId;
    return null;
  }

  @override
  Future<List<CommunityPerson>> searchUsers(String query) async => [];
  @override
  Future<List<CommunityPerson>> friends() async => [];
  @override
  Future<List<CommunityPerson>> friendRequests() async => [];
  @override
  Future<List<CommunityPost>> feed({CommunityPost? before}) async => [];
  @override
  Future<CommunityPost?> postById(String id) async {
    openedPost = id;
    return CommunityPost(
      id: id,
      authorId: 'actor',
      username: 'hossam',
      fullName: null,
      avatarUrl: null,
      body: 'Post opened from alert',
      visibility: 'public',
      imagePath: null,
      createdAt: DateTime.utc(2026),
      friendGroup: 0,
      likeCount: 0,
      commentCount: 0,
      likedByMe: false,
    );
  }

  @override
  Future<List<CommunityComment>> comments(String postId,
          {CommunityComment? before}) async =>
      [];
  @override
  Future<void> saveNotificationSettings(Map<String, bool> value) async {
    settings = Map.of(value);
  }
}
