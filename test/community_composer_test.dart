import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:privilege/models/community_models.dart';
import 'package:privilege/models/community_post.dart';
import 'package:privilege/screens/community.dart';
import 'package:privilege/services/community_repository.dart';
import 'package:privilege/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  setUpAll(() {
    client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
  });
  tearDownAll(() => client.dispose());
  for (final count in [1, 3]) {
    testWidgets('composer posts $count time(s) while the keyboard is visible',
        (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final repository = _FakeCommunityRepository(client);
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: AppPage(
          title: 'Community',
          builder: () => CommunityScreen(repository: repository),
        ),
      ));
      await tester.pumpAndSettle();

      for (var i = 0; i < count; i++) {
        await tester.tap(find.byTooltip('Create a post'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextField).last);
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        final feedReads = repository.feedReads;
        await tester.enterText(find.byType(TextField).last, 'Post $i');
        await tester.pump();
        expect(repository.feedReads, feedReads);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Share post'));
        await tester.tap(find.text('Share post'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Create a post'), findsNothing);
        expect(find.text('Post $i'), findsOneWidget);
      }
      expect(repository.bodies, [for (var i = 0; i < count; i++) 'Post $i']);
    });
  }

  testWidgets('closing the focused composer without posting is safe',
      (tester) async {
    final repository = _FakeCommunityRepository(client);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: AppPage(
        title: 'Community',
        builder: () => CommunityScreen(repository: repository),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Create a post'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Draft');
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(repository.bodies, isEmpty);
  });

  testWidgets('alert post opens its comments and can toggle a comment like',
      (tester) async {
    final repository = _FakeCommunityRepository(client);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: AppPage(
        title: 'Community',
        builder: () =>
            CommunityScreen(repository: repository, openPostId: 'target'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Post from an alert'), findsOneWidget);
    expect(find.text('A comment'), findsOneWidget);
    expect(find.text('Liked by author'), findsOneWidget);
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(find.text('Liked by'), findsOneWidget);
    expect(find.text('@liker'), findsOneWidget);
    Navigator.of(tester.element(find.text('Liked by'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Like comment'));
    await tester.pumpAndSettle();
    expect(repository.commentLiked, isTrue);
    expect(find.byTooltip('Unlike comment'), findsOneWidget);
    await tester.tap(find.byTooltip('Unlike comment'));
    await tester.pumpAndSettle();
    expect(repository.commentLiked, isFalse);
  });

  testWidgets('comments start at top and zero likes have no count',
      (tester) async {
    final repository = _FakeCommunityRepository(client)..zeroLikes = true;
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: AppPage(
        title: 'Community',
        builder: () =>
            CommunityScreen(repository: repository, openPostId: 'target'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsNothing);
    final scroll = tester.widget<ListView>(find.byType(ListView).last);
    expect(scroll.reverse, isFalse);
    expect(tester.getTopLeft(find.text('A comment')).dy,
        lessThan(tester.getBottomLeft(find.text('Comments')).dy + 150));
  });

  testWidgets('discover excludes friends and pending requests', (tester) async {
    final repository = _FakeCommunityRepository(client)
      ..people = [
        _person('friend', 'friends'),
        _person('pending', 'request_outgoing'),
        _person('discovery', 'none'),
      ]
      ..friendList = [_person('friend', 'friends')];
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: AppPage(
          title: 'Community',
          builder: () => CommunityScreen(repository: repository)),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    expect(find.text('friend'), findsOneWidget);
    expect(find.text('pending'), findsNothing);
    expect(find.text('discovery'), findsOneWidget);
  });
}

CommunityPerson _person(String name, String relationship) => CommunityPerson(
      id: name,
      username: name,
      fullName: null,
      avatarUrl: null,
      relationship: relationship,
      followedByMe: false,
    );

class _FakeCommunityRepository extends CommunityRepository {
  _FakeCommunityRepository(super.client);
  final List<String> bodies = [];
  int feedReads = 0;
  bool commentLiked = false;
  bool zeroLikes = false;
  List<CommunityPerson> people = [];
  List<CommunityPerson> friendList = [];

  @override
  Future<CommunityPost?> postById(String id) async => CommunityPost(
        id: id,
        authorId: 'user',
        username: 'runner',
        fullName: null,
        avatarUrl: null,
        body: 'Post from an alert',
        visibility: 'public',
        imagePath: null,
        createdAt: DateTime.utc(2026),
        friendGroup: 0,
        likeCount: 0,
        commentCount: 1,
        likedByMe: false,
      );

  @override
  Future<List<CommunityComment>> comments(String postId,
          {CommunityComment? before}) async =>
      [
        CommunityComment(
          id: 'comment',
          postId: postId,
          authorId: 'user',
          username: 'runner',
          fullName: null,
          avatarUrl: null,
          body: 'A comment',
          createdAt: DateTime.utc(2026),
          likedByMe: commentLiked,
          likeCount: zeroLikes ? 0 : 2,
          likedByAuthor: !zeroLikes,
        )
      ];

  @override
  Future<void> setCommentLiked(String id, bool liked) async {
    commentLiked = liked;
  }

  @override
  Future<List<CommunityPerson>> commentLikers(String commentId) async => [
        const CommunityPerson(
          id: 'liker',
          username: 'liker',
          fullName: null,
          avatarUrl: null,
          relationship: 'none',
          followedByMe: false,
        )
      ];

  @override
  Future<List<CommunityPost>> feed({CommunityPost? before}) async {
    feedReads++;
    return [
      for (var i = bodies.length - 1; i >= 0; i--)
        CommunityPost(
          id: '$i',
          authorId: 'user',
          username: 'runner',
          fullName: null,
          avatarUrl: null,
          body: bodies[i],
          visibility: 'public',
          imagePath: null,
          createdAt: DateTime.utc(2026),
          friendGroup: 1,
          likeCount: 0,
          commentCount: 0,
          likedByMe: false,
        )
    ];
  }

  @override
  Future<void> post(String body, String visibility, {XFile? image}) async {
    bodies.add(body);
  }

  @override
  Future<List<CommunityPerson>> searchUsers(String query) async => people;
  @override
  Future<List<CommunityPerson>> friends() async => friendList;
  @override
  Future<List<CommunityPerson>> friendRequests() async => [];
  @override
  Future<List<CommunityNotification>> notifications() async => [];
  @override
  Future<int> unreadCount() async => 0;
}
