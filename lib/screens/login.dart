import 'package:flutter/material.dart';

import '../logic/validators.dart';
import '../l10n_strings.dart';
import '../services/account_types.dart' show AuthException;
import '../services/supabase_auth_service.dart';
import '../services/session_recovery.dart';
import '../state.dart';
import '../ui.dart';
import '../widgets/auth_language_toggle.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hide = true;
  bool _showErrors = false;
  bool _success = false;
  String? _message;
  Map<String, String> _errors = {};

  String _translated(String value) {
    final l = strings(context);
    switch (value) {
      case 'Enter a valid email address.':
        return l.invalidEmail;
      case 'Enter your password.':
        return l.enterPassword;
      case 'Password must be 8-72 characters and include a letter and a number.':
        return l.invalidPassword;
      case 'Passwords do not match.':
        return l.passwordMismatch;
      case 'Incorrect email or password.':
        return l.invalidCredentials;
      case 'Please confirm your email before logging in.':
        return l.emailNotConfirmed;
      case 'Could not connect. Check your internet connection and try again.':
        return l.networkError;
      case 'Could not sign in right now. Please try again.':
        return l.signInError;
      case 'Could not sign in. Please try again.':
        return l.registrationError;
      case 'Account created. Log in to continue.':
        return l.registrationCreated;
      case 'If this email can be registered, check your inbox for a confirmation link, then log in.':
        return l.registrationConfirm;
      default:
        return friendlyError(value, localizations: l);
    }
  }

  String _loginMessage(AuthException error) {
    if (error.code == 'invalid_credentials' ||
        error.code == 'email_not_confirmed' ||
        error.code == 'network') {
      return error.message;
    }
    return 'Could not sign in right now. Please try again.';
  }

  @override
  void initState() {
    super.initState();
    _message = appState.authNotice;
    appState.authNotice = null;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};
    final emailError = validateEmail(_email.text);
    if (emailError != null) errors['email'] = emailError;
    final passwordError = _register
        ? validatePassword(_password.text)
        : (_password.text.isEmpty ? 'Enter your password.' : null);
    if (passwordError != null) errors['password'] = passwordError;
    if (_register && _password.text != _confirm.text) {
      errors['confirm'] = 'Passwords do not match.';
    }
    return errors;
  }

  void _revalidate() {
    if (_showErrors) setState(() => _errors = _validate());
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final errors = _validate();
    setState(() {
      _showErrors = true;
      _errors = errors;
      _message = null;
    });
    if (errors.isNotEmpty) return;
    setState(() => _busy = true);
    try {
      if (_register) {
        final message = await SupabaseAuthService.register(
          _email.text.trim(),
          _password.text,
        );
        if (!mounted) return;
        setState(() {
          _register = false;
          _password.clear();
          _confirm.clear();
          _errors = {};
          _showErrors = false;
          _success = true;
          _message = message;
        });
      } else {
        await appState.login(_email.text.trim(), _password.text);
      }
    } on SessionExpiredException {
      // Session loss returns to a clean login screen.
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _success = false;
          _message = _register ? error.message : _loginMessage(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _passwordField(
          TextEditingController controller, String hint, String key) =>
      TextField(
        controller: controller,
        obscureText: _hide,
        onChanged: (_) => _revalidate(),
        decoration: fieldDecoration(
          hint,
          icon: Icons.lock_outline,
          error: _errors[key] == null ? null : _translated(_errors[key]!),
          suffix: IconButton(
            icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _hide = !_hide),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(children: [
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AuthLanguageToggle(),
              ),
            ),
            Expanded(
                child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                          child: PrivilegeLogo(width: _register ? 150 : 220)),
                      const SizedBox(height: 16),
                      Text(
                        _register
                            ? strings(context).createYourAccount
                            : strings(context).welcomeBack,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _register
                            ? strings(context).createAccountDescription
                            : strings(context).loginDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: kMuted),
                      ),
                      const SizedBox(height: 18),
                      if (_message != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kCard2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _success ? kGreen : kRed),
                          ),
                          child: Text(_translated(_message!),
                              style: TextStyle(color: kCream)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        onChanged: (_) => _revalidate(),
                        decoration: fieldDecoration(strings(context).email,
                            icon: Icons.email_outlined,
                            error: _errors['email'] == null
                                ? null
                                : _translated(_errors['email']!)),
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                          _password, strings(context).password, 'password'),
                      if (_register) ...[
                        const SizedBox(height: 12),
                        _passwordField(_confirm,
                            strings(context).confirmPassword, 'confirm'),
                        const SizedBox(height: 8),
                        Text(
                          strings(context).passwordHint,
                          style: TextStyle(fontSize: 11, color: kMuted),
                        ),
                      ],
                      const SizedBox(height: 18),
                      PrimaryButton(
                        _busy
                            ? strings(context).pleaseWait
                            : (_register
                                ? strings(context).createAccount
                                : strings(context).logIn),
                        onPressed: _busy ? null : _submit,
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _register = !_register;
                                  _password.clear();
                                  _confirm.clear();
                                  _errors = {};
                                  _showErrors = false;
                                  _message = null;
                                }),
                        child: Text(_register
                            ? strings(context).alreadyAccount
                            : strings(context).newAccount),
                      ),
                      if (!_register)
                        Text(
                          strings(context).loginUnavailableFeatures,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: kMuted),
                        ),
                    ],
                  ),
                ),
              ),
            )),
          ]),
        ),
      );
}
