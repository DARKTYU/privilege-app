import 'package:flutter/material.dart';

import '../l10n_strings.dart';
import '../language_settings.dart';
import '../ui.dart';

class AuthLanguageToggle extends StatelessWidget {
  const AuthLanguageToggle({super.key});

  Future<void> _select(BuildContext context, String language) async {
    try {
      await languageSettings.select(language);
    } on Exception catch (error) {
      if (context.mounted) {
        toast(context, friendlyError(error, localizations: strings(context)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: languageSettings,
        builder: (context, _) => Semantics(
          label: 'Language / اللغة',
          container: true,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              decoration: BoxDecoration(
                color: kCard,
                border: Border.all(color: kLine),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _option(context, 'en', 'EN', 'English'),
                ExcludeSemantics(
                    child: Text('|', style: TextStyle(color: kMuted))),
                _option(context, 'ar', 'ع', 'العربية'),
              ]),
            ),
          ),
        ),
      );

  Widget _option(
      BuildContext context, String language, String text, String label) {
    final selected = languageSettings.selected.languageCode == language;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: () => _select(context, language),
      child: ExcludeSemantics(
        child: Material(
          color: selected ? kMaroon : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () => _select(context, language),
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 48,
              height: 46,
              child: Center(
                child: Text(text,
                    style: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : kCream,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
