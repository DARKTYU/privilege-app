import 'package:flutter/widgets.dart';

import 'l10n/app_localizations.dart';
import 'l10n/app_localizations_en.dart';

AppLocalizations strings(BuildContext context) =>
    AppLocalizations.of(context) ?? AppLocalizationsEn();
