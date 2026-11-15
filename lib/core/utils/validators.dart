/// Form validation shared by the login and sign-up screens.
///
/// Each method returns `null` when the value is acceptable, or the message to
/// show under the field.
class Validators {
  const Validators._();

  static const int minPasswordLength = 8;

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@([\w-]+\.)+[A-Za-z]{2,}$',
  );
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  static String? name(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your name';
    if (trimmed.length < 2) return 'Name looks too short';
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter a password';
    if (text.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    return null;
  }

  /// Login only checks that something was typed — the stored hash decides.
  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password';
    return null;
  }

  /// The mobile number is optional in v1; validated only when filled in.
  static String? optionalIndianMobile(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\s+'), '');
    if (digits.isEmpty) return null;
    if (!_digitsOnly.hasMatch(digits)) return 'Digits only';
    if (digits.length != 10) return 'Enter a 10-digit number';
    return null;
  }

  /// 0 = weak, 3 = strong. Drives the meter under the password field.
  static int passwordStrength(String value) {
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= minPasswordLength) score++;
    if (RegExp(r'\d').hasMatch(value) && RegExp(r'[A-Za-z]').hasMatch(value)) {
      score++;
    }
    if (value.length >= 12 || RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score;
  }

  static String passwordStrengthLabel(String value) {
    switch (passwordStrength(value)) {
      case 0:
        return 'Too short';
      case 1:
        return 'Weak · add a number';
      case 2:
        return 'Good · add a symbol';
      default:
        return 'Strong';
    }
  }
}
