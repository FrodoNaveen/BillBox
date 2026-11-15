import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../shell/presentation/screens/app_shell.dart';

/// Decides what the app opens on: a brief splash while local storage is read,
/// then either the login screen or the tabbed app shell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((p) => p.status);

    switch (status) {
      case AuthStatus.unknown:
        return const _SplashView();
      case AuthStatus.authenticated:
        return const AppShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: scheme.onPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
