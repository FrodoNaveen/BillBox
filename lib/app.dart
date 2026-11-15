import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/splash/presentation/screens/auth_gate.dart';

class BillBoxApp extends StatelessWidget {
  const BillBoxApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(repository: authRepository)..bootstrap(),
        ),
      ],
      child: MaterialApp(
        title: 'BillBox',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        themeMode: ThemeMode.light,
        initialRoute: AppRoutes.gate,
        routes: {
          AppRoutes.gate: (_) => const AuthGate(),
          AppRoutes.signUp: (_) => const SignUpScreen(),
        },
      ),
    );
  }
}
