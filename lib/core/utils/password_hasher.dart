import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 hashing for the locally stored accounts.
///
/// Passwords are never written to disk; only the salt and the hash are. This
/// is not a slow KDF — when a real backend arrives, authentication moves
/// there and this class goes away.
class PasswordHasher {
  PasswordHasher({Random? random}) : _random = random ?? Random.secure();

  static const int _saltBytes = 16;

  final Random _random;

  String generateSalt() {
    final bytes = List<int>.generate(_saltBytes, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String hash(String password, String salt) {
    final digest = sha256.convert(utf8.encode('$salt::$password'));
    return digest.toString();
  }

  bool verify({
    required String password,
    required String salt,
    required String expectedHash,
  }) {
    return hash(password, salt) == expectedHash;
  }
}
