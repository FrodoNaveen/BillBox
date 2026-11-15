import 'package:flutter/foundation.dart';

import '../../data/auth_exception.dart';
import '../../data/auth_repository.dart';
import '../../data/models/billbox_user.dart';

enum AuthStatus {
  /// Still reading local storage at startup.
  unknown,
  authenticated,
  unauthenticated,
}

/// Holds the session for the whole app.
///
/// Screens read [status] and [user]; the auth forms read [isSubmitting] and
/// [errorMessage] and call [logIn] / [signUp], which return `true` on success.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  BillBoxUser? _user;
  bool _isSubmitting = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  BillBoxUser? get user => _user;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _status == AuthStatus.authenticated;

  /// Restores the session saved on this device. Called once at startup.
  Future<void> bootstrap() async {
    final restored = await _repository.currentUser();
    _user = restored;
    _status = restored == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> logIn({required String email, required String password}) {
    return _submit(() => _repository.logIn(email: email, password: password));
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) {
    return _submit(
      () => _repository.signUp(
        name: name,
        email: email,
        password: password,
        phone: phone,
      ),
    );
  }

  /// Saves edited profile details. Returns false and sets [errorMessage]
  /// when the write fails, like the other form actions here.
  Future<bool> updateProfile({required String name, String? phone}) async {
    final current = _user;
    if (current == null) return false;
    return _submit(
      () => _repository.updateProfile(
        userId: current.id,
        name: name,
        phone: phone,
      ),
    );
  }

  Future<void> logOut() async {
    await _repository.logOut();
    _user = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _submit(Future<BillBoxUser> Function() action) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await action();
      _status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (error, stackTrace) {
      debugPrint('Unexpected auth failure: $error\n$stackTrace');
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
