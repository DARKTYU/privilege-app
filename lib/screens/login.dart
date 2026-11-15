import 'package:flutter/material.dart';

import '../logic/validators.dart';
import '../services/account_types.dart' show AuthException;
import '../services/supabase_auth_service.dart';
import '../state.dart';
import '../ui.dart';

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
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _success = false;
          _message = error.message;
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
          error: _errors[key],
          suffix: IconButton(
            icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _hide = !_hide),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: PrivilegeLogo(width: _register ? 150 : 220)),
                    const SizedBox(height: 16),
                    Text(
                      _register ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _register
                          ? 'Create an account with your email and password.'
                          : 'Log in with your email and password.',
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
                        child: Text(_message!, style: TextStyle(color: kCream)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      onChanged: (_) => _revalidate(),
                      decoration: fieldDecoration('Email',
                          icon: Icons.email_outlined, error: _errors['email']),
                    ),
                    const SizedBox(height: 12),
                    _passwordField(_password, 'Password', 'password'),
                    if (_register) ...[
                      const SizedBox(height: 12),
                      _passwordField(_confirm, 'Confirm password', 'confirm'),
                      const SizedBox(height: 8),
                      Text(
                        'Use 8-72 characters with at least one letter and one number.',
                        style: TextStyle(fontSize: 11, color: kMuted),
                      ),
                    ],
                    const SizedBox(height: 18),
                    PrimaryButton(
                      _busy
                          ? 'Please wait…'
                          : (_register ? 'Create account' : 'Log In'),
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
                          ? 'Already have an account? Log in'
                          : 'New here? Create an account'),
                    ),
                    if (!_register)
                      Text(
                        'Password reset and social sign-in will be available after setup.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: kMuted),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
