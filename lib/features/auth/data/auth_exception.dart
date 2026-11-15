/// An expected, user-facing authentication failure.
///
/// [message] is written to be shown as-is in the UI.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
