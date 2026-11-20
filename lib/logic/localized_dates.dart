import 'package:intl/intl.dart';

String westernDigits(String text) => text.replaceAllMapped(
      RegExp('[\u0660-\u0669\u06f0-\u06f9]'),
      (match) {
        final digit = match[0]!.codeUnitAt(0);
        return (digit >= 0x06f0 ? digit - 0x06f0 : digit - 0x0660).toString();
      },
    );

String localizedPlannerDate(DateTime date, String languageCode) =>
    westernDigits(
        DateFormat.yMMMd(languageCode == 'en' ? 'en_US' : languageCode)
            .format(date));

String localizedPlannerWeekday(DateTime date, String languageCode) =>
    westernDigits(DateFormat.E(languageCode == 'en' ? 'en_US' : languageCode)
        .format(date));
