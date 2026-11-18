String? validateUsername(String value) {
  if (!RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(value)) {
    return 'Username must be 3 to 20 letters, numbers or underscores.';
  }
  return null;
}
