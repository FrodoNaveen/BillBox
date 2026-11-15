import 'dart:convert';

import '../../../core/storage/key_value_store.dart';
import 'models/user_record.dart';

/// Reads and writes the account list and the current session in local
/// storage. Knows about JSON and keys; knows nothing about passwords.
class AuthLocalDataSource {
  AuthLocalDataSource(this._store);

  static const String usersKey = 'billbox.auth.users';
  static const String sessionKey = 'billbox.auth.session_user_id';

  final KeyValueStore _store;

  Future<List<UserRecord>> readUsers() async {
    final raw = await _store.read(usersKey);
    if (raw == null || raw.isEmpty) return <UserRecord>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <UserRecord>[];
      return decoded
          .whereType<Map>()
          .map((e) => UserRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on FormatException {
      // Corrupt or hand-edited storage: start clean rather than crash.
      return <UserRecord>[];
    }
  }

  Future<void> writeUsers(List<UserRecord> records) async {
    final encoded = jsonEncode(records.map((r) => r.toJson()).toList());
    await _store.write(usersKey, encoded);
  }

  Future<String?> readSessionUserId() => _store.read(sessionKey);

  Future<void> writeSession(String userId) => _store.write(sessionKey, userId);

  Future<void> clearSession() => _store.delete(sessionKey);
}
