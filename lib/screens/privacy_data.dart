import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coach_preferences.dart';
import '../language_settings.dart';
import '../l10n_strings.dart';
import '../services/account_types.dart';
import '../state.dart';
import '../ui.dart';

const privacySupportEmail = 'supportprivilegefitness@gmail.com';

/// Permanently deletes the signed-in account after the password is confirmed.
typedef DeleteAccountAction = Future<void> Function(String password);

class PrivacyDataScreen extends StatefulWidget {
  const PrivacyDataScreen({super.key, this.deleteAccount});

  /// Replaceable so tests can run without a server.
  final DeleteAccountAction? deleteAccount;

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

  Future<void> _confirmDeleteAccount() async {
    final navigator = Navigator.of(context);
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountDialog(
          onDelete: widget.deleteAccount ?? appState.deleteAccount),
    );
    if (deleted == true && mounted) {
      // The login screen takes over once the account state is cleared.
      navigator.popUntil((route) => route.isFirst);
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
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _confirmDeleteAccount,
                  icon: const Icon(Icons.delete_forever_outlined, size: 20),
                  label: Text(l.privacyDeleteButton),
                ),
                const SizedBox(height: 16),
                Text(l.privacySupport,
                    style: TextStyle(color: kMuted, fontSize: 12)),
                const SizedBox(height: 4),
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

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.onDelete});
  final DeleteAccountAction onDelete;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l = strings(context);
    final password = _password.text;
    if (password.isEmpty) {
      setState(() => _error = l.enterPassword);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onDelete(password);
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l.privacyDeleteFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = strings(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        backgroundColor: kCard,
        title: Text(l.privacyDeleteDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.privacyDeleteDialogBody),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                enabled: !_busy,
                obscureText: _hide,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l.privacyDeletePasswordLabel,
                  errorText: _error,
                  errorMaxLines: 3,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _hide ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.privacyDeleteConfirm),
          ),
        ],
      ),
    );
  }
}
