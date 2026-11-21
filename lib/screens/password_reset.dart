import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/validators.dart';
import '../l10n_strings.dart';
import '../services/account_types.dart' show AuthException;
import '../services/supabase_auth_service.dart';
import '../ui.dart';
import '../widgets/auth_language_toggle.dart';

abstract class PasswordResetService {
  Future<void> requestCode(String email);
  Future<void> resetPassword(String email, String code, String password);
}

class SupabasePasswordResetService implements PasswordResetService {
  const SupabasePasswordResetService();

  @override
  Future<void> requestCode(String email) =>
      SupabaseAuthService.requestPasswordReset(email);

  @override
  Future<void> resetPassword(String email, String code, String password) =>
      SupabaseAuthService.completePasswordReset(email, code, password);
}

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key, this.service});

  final PasswordResetService? service;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final PasswordResetService _service =
      widget.service ?? const SupabasePasswordResetService();
  Timer? _timer;
  int _remaining = 0;
  bool _codeSent = false;
  bool _busy = false;
  bool _hide = true;
  bool _success = false;
  String? _message;
  String? _emailError;
  String? _codeError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _remaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _remaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _remaining = 0);
        return;
      }
      setState(() => _remaining--);
    });
  }

  String _authMessage(AuthException error) {
    final l = strings(context);
    return switch (error.code) {
      'network' => l.networkError,
      'too_many_requests' => l.resetTooManyRequests,
      'invalid_code' => l.resetInvalidCode,
      'weak_password' => l.invalidPassword,
      _ => l.resetError,
    };
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    final error = validateEmail(_email.text);
    setState(() {
      _emailError = error == null ? null : strings(context).invalidEmail;
      _message = null;
    });
    if (error != null || _remaining > 0) return;
    setState(() => _busy = true);
    try {
      await _service.requestCode(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _message = strings(context).resetNeutralMessage;
        _success = true;
      });
      _startCooldown();
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.code == 'network' || error.code == 'too_many_requests') {
        setState(() {
          _message = _authMessage(error);
          _success = false;
        });
      } else {
        setState(() {
          _codeSent = true;
          _message = strings(context).resetNeutralMessage;
          _success = true;
        });
        _startCooldown();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _canReset =>
      RegExp(r'^\d{6,10}$').hasMatch(_code.text.trim()) &&
      validatePassword(_password.text) == null &&
      _password.text == _confirm.text;

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    final passwordError = validatePassword(_password.text);
    setState(() {
      _codeError = RegExp(r'^\d{6,10}$').hasMatch(_code.text.trim())
          ? null
          : strings(context).resetCodeFormatError;
      _passwordError =
          passwordError == null ? null : strings(context).invalidPassword;
      _confirmError = _password.text == _confirm.text
          ? null
          : strings(context).passwordMismatch;
      _message = null;
    });
    if (_codeError != null || _passwordError != null || _confirmError != null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _service.resetPassword(
          _email.text.trim(), _code.text.trim(), _password.text);
      if (!mounted) return;
      setState(() {
        _message = strings(context).resetSuccess;
        _success = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings(context).resetSuccess)),
      );
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = _authMessage(error);
          _success = false;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _passwordField(
          TextEditingController controller, String hint, String? error) =>
      TextField(
        controller: controller,
        obscureText: _hide,
        onChanged: (_) => setState(() {
          _passwordError = validatePassword(_password.text) == null
              ? null
              : strings(context).invalidPassword;
          _confirmError = _password.text == _confirm.text
              ? null
              : strings(context).passwordMismatch;
        }),
        decoration: fieldDecoration(hint,
            icon: Icons.lock_outline,
            error: error,
            suffix: IconButton(
              icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _hide = !_hide),
            )),
      );

  @override
  Widget build(BuildContext context) {
    final l = strings(context);
    return Scaffold(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: BackButton(
                          onPressed: _busy ? null : Navigator.of(context).pop),
                    ),
                    const Center(child: PrivilegeLogo(width: 150)),
                    const SizedBox(height: 16),
                    Text(
                      _codeSent ? l.resetChoosePassword : l.resetPassword,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _codeSent ? l.resetCodeInstructions : l.resetInstructions,
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
                      enabled: !_codeSent && !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: fieldDecoration(l.email,
                          icon: Icons.email_outlined, error: _emailError),
                    ),
                    const SizedBox(height: 12),
                    if (!_codeSent)
                      PrimaryButton(
                        _busy ? l.pleaseWait : l.resetSendCode,
                        onPressed: _busy ? null : _sendCode,
                      )
                    else ...[
                      TextField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {
                          final code = _code.text.trim();
                          _codeError = code.isNotEmpty &&
                                  !RegExp(r'^\d{6,10}$').hasMatch(code)
                              ? l.resetCodeFormatError
                              : null;
                        }),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: fieldDecoration(l.resetCode,
                            icon: Icons.pin_outlined, error: _codeError),
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                          _password, l.resetNewPassword, _passwordError),
                      const SizedBox(height: 12),
                      _passwordField(
                          _confirm, l.confirmPassword, _confirmError),
                      const SizedBox(height: 8),
                      Text(l.passwordHint,
                          style: TextStyle(fontSize: 11, color: kMuted)),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        _busy ? l.pleaseWait : l.resetUpdatePassword,
                        onPressed: _busy || !_canReset ? null : _reset,
                      ),
                      TextButton(
                        onPressed: _busy || _remaining > 0 ? null : _sendCode,
                        child: Text(_remaining > 0
                            ? l.resetResendCountdown(_remaining)
                            : l.resetResendCode),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
