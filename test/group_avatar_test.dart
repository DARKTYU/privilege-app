import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:privilege/screens/groups.dart';
import 'package:privilege/services/groups_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient widgetClient;
  setUpAll(() {
    widgetClient = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
  });
  tearDownAll(() => widgetClient.dispose());
  test('resizes a pathless image and rejects invalid or oversized files',
      () async {
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(client.dispose);
    final repo = GroupsRepository(client);
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 1200, 600), Paint()..color = Colors.blue);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1200, 600);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    final file = _pathless(data!.buffer.asUint8List(), 'photo.png');
    final result = await repo.prepareAvatar(file);
    final buffer = await ui.ImmutableBuffer.fromUint8List(result.bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    expect(descriptor.width, 1024);
    expect(descriptor.height, 512);
    expect(result.bytes.length, lessThanOrEqualTo(2 * 1024 * 1024));
    expect(result.contentType, 'image/png');
    descriptor.dispose();
    buffer.dispose();
    await expectLater(repo.prepareAvatar(_pathless(Uint8List(4), 'bad.gif')),
        throwsA(isA<GroupException>()));
    await expectLater(repo.prepareAvatar(_pathless(Uint8List(4), 'bad.png')),
        throwsA(isA<GroupException>()));
    final huge = Uint8List(2 * 1024 * 1024 + 1);
    final original = result.bytes;
    huge.setRange(0, original.length, original);
    await expectLater(
        repo.prepareAvatar(_pathless(huge, 'large.png')),
        throwsA(isA<GroupException>()
            .having((e) => e.message, 'message', contains('too large'))));
  });

  test(
      'upload happens before set, then delete; failed setter never deletes old',
      () async {
    final calls = <http.Request>[];
    var failSet = false;
    var failUpload = false;
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      calls.add(request);
      http.Response json(Object? value, [int status = 200]) =>
          http.Response(jsonEncode(value), status,
              request: request, headers: {'content-type': 'application/json'});
      if (request.url.path.endsWith('/token')) {
        return json({
          'access_token': 'token',
          'refresh_token': 'refresh',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            'aud': 'authenticated',
            'created_at': '2026-01-01T00:00:00Z'
          }
        });
      }
      if (request.url.path.endsWith('/group_set_avatar')) {
        return failSet
            ? json({'message': 'failed', 'code': 'P0001'}, 400)
            : json(null);
      }
      if (request.url.path.contains('/storage/v1/object/sign/')) {
        return json({'signedURL': '/signed-photo?token=test'});
      }
      if (request.url.path.contains('/storage/v1/object/')) {
        if (failUpload && request.method == 'POST') {
          return json({'message': 'failed'}, 400);
        }
        return request.method == 'DELETE'
            ? json([])
            : json({'Key': request.url.path});
      }
      return json({'message': 'unexpected'}, 500);
    }));
    addTearDown(client.dispose);
    await client.auth
        .signInWithPassword(email: 'a@example.com', password: 'password');
    final repo = GroupsRepository(client);
    calls.clear();
    final firstUrl = await repo.signedAvatarUrl('group/photo.png');
    final secondUrl =
        await GroupsRepository(client).signedAvatarUrl('group/photo.png');
    expect(firstUrl, secondUrl);
    expect(calls, hasLength(1));
    final payload =
        GroupAvatarImage(Uint8List.fromList([1, 2, 3]), 'png', 'image/png');
    calls.clear();
    await repo.setAvatar('group', payload, 'group/old.png');
    expect(calls.map((r) => r.method).toList(), ['POST', 'POST', 'DELETE']);
    expect(calls[0].url.path, matches(RegExp(r'/group/[0-9a-f]{32}\.png$')));
    expect(calls[0].body, contains('content-type: image/png'));
    expect(jsonDecode(calls[1].body)['p_path'],
        endsWith(calls[0].url.path.split('/group-avatars/').last));
    expect(calls[2].body, contains('group/old.png'));
    calls.clear();
    failSet = true;
    await expectLater(repo.setAvatar('group', payload, 'group/old.png'),
        throwsA(isA<GroupException>()));
    expect(calls.map((r) => r.method).toList(), ['POST', 'POST']);
    calls.clear();
    failSet = false;
    await repo.setAvatar('group', null, 'group/old.png');
    expect(calls.map((r) => r.method).toList(), ['POST', 'DELETE']);
    expect(jsonDecode(calls.first.body)['p_path'], isNull);
    calls.clear();
    failUpload = true;
    await expectLater(repo.setAvatar('group', payload, 'group/old.png'),
        throwsA(isA<GroupException>()));
    expect(calls.map((r) => r.method).toList(), ['POST']);
  });

  testWidgets('owner sees photo controls, other users do not', (tester) async {
    final repo = _AvatarRepo(widgetClient);
    await tester.pumpWidget(MaterialApp(
        home: GroupSettingsPage(repository: repo, group: repo.groupData)));
    await tester.pumpAndSettle();
    expect(find.text('Choose photo'), findsOneWidget);
    expect(find.text('Remove photo'), findsOneWidget);
    repo.currentUser = 'member';
    await tester.pumpWidget(MaterialApp(
        key: UniqueKey(),
        home: GroupSettingsPage(
            key: UniqueKey(), repository: repo, group: repo.groupData)));
    await tester.pumpAndSettle();
    expect(find.text('Choose photo'), findsNothing);
    expect(find.text('Remove photo'), findsNothing);
  });

  testWidgets('create upload failure leaves group and shows friendly message',
      (tester) async {
    final repo = _AvatarRepo(widgetClient)..failAvatar = true;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      final message = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => GroupSettingsPage(
                                  repository: repo,
                                  pickPhoto: () async => _pathless(
                                      Uint8List.fromList([1]), 'test.png'))));
                      if (context.mounted && message != null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose photo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'New group');
    await tester.scrollUntilVisible(find.text('Save'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.created, isTrue);
    expect(
        find.text(
            'Group created, but the photo could not be uploaded. You can add it from group settings.'),
        findsOneWidget);
  });

  testWidgets('editing replaces and removes the photo after settings save',
      (tester) async {
    final repo = _AvatarRepo(widgetClient);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => GroupSettingsPage(
                                  repository: repo,
                                  group: repo.groupData,
                                  pickPhoto: () async => _pathless(
                                      Uint8List.fromList([1]), 'test.png')))),
                      child: const Text('Open settings'),
                    )))));
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose photo'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Save'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.savedPhoto, isNotNull);
    expect(repo.oldPath, 'group/old.png');
    expect(repo.avatarCalls, 1);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo'));
    await tester.scrollUntilVisible(find.text('Save'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.avatarCalls, 2);
    expect(repo.savedPhoto, isNull);
    expect(repo.oldPath, 'group/old.png');
  });

  testWidgets('editing reports photo failure without leaving settings',
      (tester) async {
    final repo = _AvatarRepo(widgetClient)..failAvatar = true;
    await tester.pumpWidget(MaterialApp(
        home: GroupSettingsPage(repository: repo, group: repo.groupData)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo'));
    await tester.scrollUntilVisible(find.text('Save'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save the group photo. Please try again.'),
        findsOneWidget);
  });

  testWidgets('signed URL failure shows initials', (tester) async {
    final repo = _AvatarRepo(widgetClient);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GroupAvatar(
                id: 'group',
                name: 'Fitness friends',
                path: 'group/old.png',
                repository: repo))));
    await tester.pumpAndSettle();
    expect(find.text('FF'), findsOneWidget);
    expect(
        tester.widget<CircleAvatar>(find.byType(CircleAvatar)).foregroundImage,
        isNull);
    expect(tester.takeException(), isNull);
  });
}

XFile _pathless(Uint8List bytes, String name) => _BytesFile(bytes, name);

class _BytesFile extends XFile {
  _BytesFile(super.bytes, this.fileName) : super.fromData();
  final String fileName;
  @override
  String get name => fileName;
  @override
  String get path => throw StateError('Web image has no path');
}

class _AvatarRepo extends GroupsRepository {
  _AvatarRepo(super.client);
  String currentUser = 'owner';
  bool failAvatar = false;
  bool created = false;
  GroupAvatarImage? savedPhoto;
  String? oldPath;
  int avatarCalls = 0;
  @override
  String get userId => currentUser;
  Group get groupData => Group.fromJson({
        'id': 'group',
        'owner_id': 'owner',
        'name': 'Fitness friends',
        'description': '',
        'category': 'Other',
        'visibility': 'public',
        'join_mode': 'open',
        'member_limit': 100,
        'rules': '',
        'avatar_url': null,
        'avatar_path': 'group/old.png',
        'who_can_post': 'everyone',
        'images_allowed': false,
        'chat_enabled': false,
      });
  @override
  Future<String> signedAvatarUrl(String path) async =>
      throw const GroupException('Unavailable');
  @override
  Future<GroupAvatarImage> prepareAvatar(XFile image) async =>
      GroupAvatarImage(Uint8List.fromList([1]), 'png', 'image/png');
  @override
  Future<void> setAvatar(
      String groupId, GroupAvatarImage? image, String? oldPath) async {
    savedPhoto = image;
    this.oldPath = oldPath;
    avatarCalls++;
    if (failAvatar) throw const GroupException('Upload failed');
  }

  @override
  Future<dynamic> rpc(String name, Map<String, dynamic> params) async {
    if (name == 'group_create') {
      created = true;
      return 'new-group';
    }
    return null;
  }
}
