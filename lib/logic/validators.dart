// Same rules as the server (authCore.ts), so users get instant feedback before any network call.

String? validateUsername(String v) =>
    RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(v.trim())
        ? null
        : 'Username must be 3-20 characters: letters, numbers or underscore.';

String? validateEmail(String v) {
  final s = v.trim();
  return s.length <= 254 && RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s)
      ? null
      : 'Enter a valid email address.';
}

String? validatePassword(String v) => v.length >= 8 &&
        v.length <= 72 &&
        RegExp(r'[A-Za-z]').hasMatch(v) &&
        RegExp(r'\d').hasMatch(v)
    ? null
    : 'Password must be 8-72 characters and include a letter and a number.';

String? validateConfirm(String password, String confirm) =>
    password == confirm ? null : 'Passwords do not match.';

/// 0 = empty, 1 = weak, 2 = good, 3 = strong (only a hint for the strength meter).
int passwordStrength(String v) {
  if (v.isEmpty) return 0;
  var s = 0;
  if (validatePassword(v) == null) s++;
  if (v.length >= 12 && validatePassword(v) == null) s++;
  if (RegExp(r'[A-Z]').hasMatch(v) &&
      RegExp(r'[a-z]').hasMatch(v) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(v)) s++;
  return s.clamp(1, 3).toInt();
}
