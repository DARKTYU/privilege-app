import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:privilege/l10n/app_localizations.dart';
import 'package:privilege/models/community_models.dart';
import 'package:privilege/models/community_post.dart';
import 'package:privilege/screens/community.dart';
import 'package:privilege/services/community_repository.dart';
import 'package:privilege/supabase_config.dart';
import 'package:privilege/ui.dart';
import 'package:privilege/widgets/post_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  setUpAll(() {
    client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
  });
  tearDownAll(() => client.dispose());
  test('Community has no hardcoded UI strings or Arabic', () {
    final source = File('lib/screens/community.dart').readAsStringSync();
    final pattern = RegExp(
        r"""(?:Text\(\s*(?:const\s*)?|(?:labelText|hintText|tooltip|semanticLabel|message)\s*:\s*|(?:_showMessage|_message|_sectionTitle)\(\s*)['"]""");
    final matches =
        pattern.allMatches(source).map((match) => match.group(0)).toList();
    expect(matches, isEmpty);
    expect(source, isNot(contains(RegExp(r'[\u0600-\u06ff]'))));
  });
  for (final language in ['en', 'ar']) {
    testWidgets('post validation is localized in $language', (tester) async {
      final repository = _FakeCommunityRepository(client)
        ..postError = const CommunityException(
            'Write something before sharing your post.');
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: CommunityScreen(repository: repository)),
      ));
      await tester.pumpAndSettle();
      final l =
          AppLocalizations.of(tester.element(find.byType(CommunityScreen)))!;
      await tester.tap(find.byTooltip(l.communityCreatePost));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.communitySharePost));
      await tester.pumpAndSettle();
      expect(find.text(l.communityErrorEmptyPost), findsOneWidget);
      expect(repository.bodies, isEmpty);
    });

    testWidgets('localized post, report and comments at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _FakeCommunityRepository(client);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildTheme(),
        home: Scaffold(body: CommunityScreen(repository: repository)),
      ));
      await tester.pumpAndSettle();
      final l =
          AppLocalizations.of(tester.element(find.byType(CommunityScreen)))!;
      await tester.tap(find.byTooltip(l.communityCreatePost));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'composer');
      await tester.enterText(find.byType(TextField).last, 'User text');
      await tester.tap(find.text(l.communitySharePost));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'post');
      expect(repository.bodies, ['User text']);
      expect(find.text('User text'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'menu');
      await tester.tap(find.text(l.communityReportPost));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'report');
      expect(find.text(l.communityReportPost), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'reason');
      await tester.tap(find.text(l.communitySubmit));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'report submitted');
      expect(repository.reportReason, 'reason');
      await tester.tap(find.byIcon(Icons.mode_comment_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'comments');
      expect(find.text(l.communityComments), findsOneWidget);
      expect(find.text('A comment'), findsOneWidget);
      expect(find.byTooltip(l.communityLikeComment), findsOneWidget);
      expect(find.byTooltip(l.communitySendComment), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('community header and tabs at 360 in $language',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _FakeCommunityRepository(client);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildTheme(),
        home: Scaffold(body: CommunityScreen(repository: repository)),
      ));
      await tester.pumpAndSettle();
      final l =
          AppLocalizations.of(tester.element(find.byType(CommunityScreen)))!;
      expect(find.text(l.communityHeading), findsOneWidget);
      expect(find.text(l.communityFeedEmpty), findsOneWidget);
      expect(find.text(l.communityGroups), findsOneWidget);
      await tester.tap(find.text(l.communityPeople));
      await tester.pumpAndSettle();
      expect(find.text(l.communityNoPeople), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
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

  testWidgets('community feed uses the uncropped image viewer', (tester) async {
    final repository = _FakeCommunityRepository(client)
      ..bodies.add('Picture post')
      ..hasImage = true;
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: AppPage(
        title: 'Community',
        builder: () => CommunityScreen(repository: repository),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(PostImage), findsOneWidget);
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
  bool hasImage = false;
  List<CommunityPerson> people = [];
  List<CommunityPerson> friendList = [];
  String? reportReason;
  CommunityException? postError;

  @override
  Future<void> reportPost(String postId, String reason) async {
    reportReason = reason;
  }

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
          imagePath: hasImage ? 'image' : null,
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
    if (postError != null) throw postError!;
    bodies.add(body);
  }

  @override
  Future<String> signedImageUrl(String path) async =>
      '${SupabaseConfig.url}/storage/v1/object/sign/posts/image.png';

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
