class AuthException implements Exception {
  AuthException(this.code, this.message,
      {this.fields = const {}, this.retryAfterSec});
  final String code, message;
  final Map<String, String> fields;
  final int? retryAfterSec;

  @override
  String toString() => message;
}

class AccountData {
  AccountData(
      {required this.username,
      required this.email,
      required this.profile,
      this.token});
  final String username, email;
  final Map<String, dynamic> profile;
  final String? token;
}
