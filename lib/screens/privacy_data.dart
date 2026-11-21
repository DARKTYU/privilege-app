import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coach_preferences.dart';
import '../language_settings.dart';
import '../l10n_strings.dart';
import '../state.dart';
import '../ui.dart';

const privacySupportEmail = 'supportprivilegefitness@gmail.com';

class PrivacyDataScreen extends StatefulWidget {
  const PrivacyDataScreen({super.key});

  @override
  State<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends State<PrivacyDataScreen> {
  bool _consent = false;
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _restoreConsent();
  }

  Future<void> _restoreConsent() async {
    try {
      final value = await loadCoachConsent();
      if (!mounted) return;
      setState(() {
        _consent = value;
        _ready = true;
      });
    } catch (_) {
      if (mounted) setState(() => _ready = true);
    }
  }

  Future<void> _setConsent(bool value) async {
    if (!_ready || _saving) return;
    setState(() => _saving = true);
    try {
      if (!await saveCoachConsent(value)) throw StateError('Preference failed');
      if (mounted) setState(() => _consent = value);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copySupportEmail() async {
    final l = strings(context);
    try {
      await Clipboard.setData(const ClipboardData(text: privacySupportEmail));
      if (mounted) toast(context, l.privacyEmailCopied);
    } catch (_) {
      if (mounted) toast(context, l.privacyEmailCopyFailed);
    }
  }

  Future<void> _chooseLanguage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kCard,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: const Text('English', textDirection: TextDirection.ltr),
            selected: languageSettings.selected.languageCode == 'en',
            onTap: () => Navigator.pop(context, 'en'),
          ),
          ListTile(
            title: const Text('العربية', textDirection: TextDirection.rtl),
            selected: languageSettings.selected.languageCode == 'ar',
            onTap: () => Navigator.pop(context, 'ar'),
          ),
        ]),
      ),
    );
    if (choice != null) await languageSettings.select(choice);
  }

  Widget _section(IconData icon, String title, String body) => Panel(
        margin: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = strings(context);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text(l.privacyDataTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(l.privacyDataSubtitle,
              style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 14),
          _section(
              Icons.storage_outlined, l.privacyStoreTitle, l.privacyStoreBody),
          _section(Icons.smart_toy_outlined, l.privacyCoachTitle,
              l.privacyCoachBody),
          Panel(
            margin: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.tune, color: kGold),
                    const SizedBox(width: 12),
                    Text(l.privacyChoicesTitle,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.privacyConsentTitle),
                    subtitle: Text(l.privacyConsentSubtitle),
                    value: _consent,
                    onChanged: _ready && !_saving ? _setConsent : null,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language),
                    title: Text(l.language),
                    subtitle: Text(
                        languageSettings.selected.languageCode == 'ar'
                            ? 'العربية'
                            : 'English'),
                    onTap: _chooseLanguage,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout),
                    title: Text(l.privacySignOut),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await appState.logout();
                      if (mounted) navigator.popUntil((r) => r.isFirst);
                    },
                  ),
                ],
              ),
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.delete_outline, color: kGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l.privacyDeletionTitle,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(l.privacyDeletionBody),
                const SizedBox(height: 8),
                SelectableText(privacySupportEmail,
                    textDirection: TextDirection.ltr),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _copySupportEmail,
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l.privacyCopyEmail),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
