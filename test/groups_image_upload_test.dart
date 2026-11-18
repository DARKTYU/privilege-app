import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:privilege/services/groups_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('uploads pathless image bytes with a unique safe name and content type',
      () async {
    final requests = <http.Request>[];
    var rejectUpload = false;
    final mock = MockClient((request) async {
      requests.add(request);
      http.Response json(Object? value) => http.Response(jsonEncode(value), 200,
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
            'created_at': '2026-01-01T00:00:00Z',
          },
        });
      }
      if (request.url.path.contains('/storage/v1/object/')) {
        if (rejectUpload) {
          return http.Response('{"message":"storage failure"}', 400,
              request: request, headers: {'content-type': 'application/json'});
        }
        return json({'Key': request.url.path});
      }
      if (request.url.path.endsWith('/group_create_post')) return json('post');
      return http.Response('Unexpected request', 500);
    });
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        httpClient: mock,
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(client.dispose);
    await client.auth.signInWithPassword(email: 'a@example.com', password: 'password');
    final repo = GroupsRepository(client);
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    for (final entry in {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
    }.entries) {
      await repo.createPost('group', 'Photo', _BytesOnlyFile(bytes, entry.key));
    }
    final uploads = requests.where((r) => r.url.path.contains('/storage/v1/object/')).toList();
    expect(uploads, hasLength(3));
    expect(uploads.map((r) => r.url.path).toSet(), hasLength(3));
    for (var i = 0; i < uploads.length; i++) {
      final type = ['image/jpeg', 'image/png', 'image/webp'][i];
      final suffix = ['jpg', 'png', 'webp'][i];
      expect(uploads[i].headers['content-type'], startsWith('multipart/form-data'));
      expect(uploads[i].body, contains('content-type: $type'));
      expect(uploads[i].bodyBytes, containsAllInOrder(bytes));
      expect(uploads[i].url.path,
          matches(RegExp('/group/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/[0-9a-f]{32}\\.$suffix\$')));
      final post = requests.where((r) => r.url.path.endsWith('/group_create_post')).elementAt(i);
      expect(jsonDecode(post.body)['p_image_path'], endsWith(uploads[i].url.path.split('/group-post-images/').last));
    }
    await expectLater(
      repo.createPost('group', 'Photo', _BytesOnlyFile(Uint8List(0), 'image/png')),
      throwsA(isA<GroupException>().having((e) => e.message, 'message', contains('Choose a JPG'))),
    );
    rejectUpload = true;
    await expectLater(
      repo.createPost('group', 'Photo', _BytesOnlyFile(bytes, 'image/png')),
      throwsA(isA<GroupException>().having(
          (e) => e.message, 'message', 'Could not upload the image. Please try again.')),
    );
    await expectLater(
      repo.createPost('group', 'Photo', _UnreadableImage(bytes, 'image/png')),
      throwsA(isA<GroupException>().having(
          (e) => e.message, 'message', 'Could not read the image. Please choose it again.')),
    );
  });
}

class _UnreadableImage extends _BytesOnlyFile {
  _UnreadableImage(super.bytes, super.mime);
  @override
  Future<Uint8List> readAsBytes() async => throw StateError('read failed');
}

class _BytesOnlyFile extends XFile {
  _BytesOnlyFile(super.bytes, String mime)
      : super.fromData(mimeType: mime, name: '');

  @override
  String get path => throw StateError('A web image has no filesystem path');
}
