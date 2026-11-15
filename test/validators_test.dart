import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/validators.dart';

void main() {
  test('username rules', () {
    expect(validateUsername('Alex_Athlete'), isNull);
    expect(validateUsername('ab'), isNotNull);
    expect(validateUsername('has space'), isNotNull);
    expect(validateUsername('this_username_is_way_too_long'), isNotNull);
  });

  test('email rules', () {
    expect(validateEmail('alex@example.com'), isNull);
    expect(validateEmail(' alex@example.com '), isNull);
    expect(validateEmail('alex@example'), isNotNull);
    expect(validateEmail('not-an-email'), isNotNull);
  });

  test('password rules', () {
    expect(validatePassword('Strong123'), isNull);
    expect(validatePassword('short1'), isNotNull);
    expect(validatePassword('onlyletters'), isNotNull);
    expect(validatePassword('12345678'), isNotNull);
  });

  test('confirm password must match', () {
    expect(validateConfirm('Strong123', 'Strong123'), isNull);
    expect(validateConfirm('Strong123', 'strong123'), isNotNull);
  });

  test('password strength meter', () {
    expect(passwordStrength(''), 0);
    expect(passwordStrength('abc'), 1);
    expect(passwordStrength('Strong123'), 1);
    expect(passwordStrength('Strong123456'), 2);
    expect(passwordStrength('Str0ng!Password#99'), 3);
  });
}
