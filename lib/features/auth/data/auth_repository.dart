import '../../../core/utils/password_hasher.dart';
import 'auth_exception.dart';
import 'auth_local_data_source.dart';
import 'models/billbox_user.dart';
import 'models/user_record.dart';

/// The only door between the auth UI and storage.
///
/// Everything above this layer deals in [BillBoxUser] and [AuthException].
class AuthRepository {
  AuthRepository({
    required AuthLocalDataSource dataSource,
    PasswordHasher? hasher,
  }) : _dataSource = dataSource,
       _hasher = hasher ?? PasswordHasher();

  final AuthLocalDataSource _dataSource;
  final PasswordHasher _hasher;

  /// The account kept signed in on this device, if any.
  Future<BillBoxUser?> currentUser() async {
    final sessionId = await _dataSource.readSessionUserId();
    if (sessionId == null) return null;
    final users = await _dataSource.readUsers();
    for (final record in users) {
      if (record.user.id == sessionId) return record.user;
    }
    // Session points at an account that no longer exists.
    await _dataSource.clearSession();
    return null;
  }

  Future<BillBoxUser> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final normalisedEmail = _normaliseEmail(email);
    final records = await _dataSource.readUsers();

    final alreadyUsed = records.any(
      (r) => _normaliseEmail(r.user.email) == normalisedEmail,
    );
    if (alreadyUsed) {
      throw const AuthException(
        'That email already has an account. Log in instead.',
      );
    }

    final salt = _hasher.generateSalt();
    final user = BillBoxUser(
      id: _newId(),
      name: name.trim(),
      email: normalisedEmail,
      phone: _normalisePhone(phone),
      createdAt: DateTime.now(),
    );

    await _dataSource.writeUsers(<UserRecord>[
      ...records,
      UserRecord(
        user: user,
        passwordSalt: salt,
        passwordHash: _hasher.hash(password, salt),
      ),
    ]);
    await _dataSource.writeSession(user.id);
    return user;
  }

  Future<BillBoxUser> logIn({
    required String email,
    required String password,
  }) async {
    final normalisedEmail = _normaliseEmail(email);
    final records = await _dataSource.readUsers();

    UserRecord? match;
    for (final record in records) {
      if (_normaliseEmail(record.user.email) == normalisedEmail) {
        match = record;
        break;
      }
    }

    // Same message for both cases, so the screen never reveals which
    // emails have accounts.
    const failed = AuthException('Email or password is incorrect.');
    if (match == null) throw failed;

    final ok = _hasher.verify(
      password: password,
      salt: match.passwordSalt,
      expectedHash: match.passwordHash,
    );
    if (!ok) throw failed;

    await _dataSource.writeSession(match.user.id);
    return match.user;
  }

  Future<void> logOut() => _dataSource.clearSession();

  String _normaliseEmail(String email) => email.trim().toLowerCase();

  String? _normalisePhone(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : digits;
  }

  String _newId() => 'u_${DateTime.now().microsecondsSinceEpoch}';
}
