import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/username.dart';

void main() {
  test('username accepts only 3 to 20 ASCII letters, numbers and underscores',
      () {
    for (final valid in ['abc', 'User_123', 'a' * 20]) {
      expect(validateUsername(valid), isNull);
    }
    for (final invalid in ['', 'ab', 'a' * 21, 'bad-name', 'a b', 'éabc']) {
      expect(validateUsername(invalid), isNotNull);
    }
  });
}
