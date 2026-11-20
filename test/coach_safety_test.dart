import 'package:flutter_test/flutter_test.dart';
import 'package:privilege/logic/coach_safety.dart';

void main() {
  test('English emergency phrases return the supportive response', () {
    for (final phrase in [
      'end it all',
      'take my own life',
      "don't want to live",
      'no reason to live',
      'hurting myself',
      'cut myself',
      'cutting myself',
      'having a heart attack',
      'having a stroke',
      'passed out',
      'fainted',
      'bleeding heavily',
      'bleeding badly',
    ]) {
      expect(coachEmergencyReply(phrase), contains('local emergency services'),
          reason: phrase);
    }
  });

  test('Arabic emergency phrases match after normalization', () {
    for (final phrase in [
      'هنتحر',
      'هانتحر',
      'مش عايز اعيش',
      'مش عايزه اعيش',
      'اخلص على نفسي',
      'أزمة قلبية',
      'جلطة',
      'أغمي علي',
      'نزيف شديد',
    ]) {
      expect(coachEmergencyReply(phrase), contains('الطوارئ المحلية'),
          reason: phrase);
    }
  });

  test('ordinary nutrition questions do not trigger emergency response', () {
    expect(coachEmergencyReply('high protein breakfast'), isNull);
    expect(coachEmergencyReply('فطار فيه بروتين'), isNull);
  });
}
