/// The signed-in person, as the UI sees them. Holds no credentials.
class BillBoxUser {
  const BillBoxUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime createdAt;

  /// "Naveen Kumar" -> "NK", for the account avatar.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BillBoxUser.fromJson(Map<String, dynamic> json) => BillBoxUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  /// [clearPhone] is how the profile form removes a number: passing null for
  /// [phone] alone cannot tell "leave it" from "delete it".
  BillBoxUser copyWith({
    String? name,
    String? email,
    String? phone,
    bool clearPhone = false,
  }) {
    return BillBoxUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: clearPhone ? null : (phone ?? this.phone),
      createdAt: createdAt,
    );
  }
}
