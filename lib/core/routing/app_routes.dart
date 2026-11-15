/// Named routes. The signed-in/signed-out split is decided by AuthGate, so
/// only the pushable screens need names.
class AppRoutes {
  const AppRoutes._();

  static const String gate = '/';
  static const String signUp = '/sign-up';
}
