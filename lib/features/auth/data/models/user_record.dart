import 'billbox_user.dart';

/// One stored account: the profile plus its password salt and hash.
///
/// Stays inside the data layer — the presentation layer only ever sees
/// [BillBoxUser].
class UserRecord {
  const UserRecord({
    required this.user,
    required this.passwordSalt,
    required this.passwordHash,
  });

  final BillBoxUser user;
  final String passwordSalt;
  final String passwordHash;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'user': user.toJson(),
    'passwordSalt': passwordSalt,
    'passwordHash': passwordHash,
  };

  factory UserRecord.fromJson(Map<String, dynamic> json) => UserRecord(
    user: BillBoxUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    passwordSalt: json['passwordSalt'] as String,
    passwordHash: json['passwordHash'] as String,
  );
}
