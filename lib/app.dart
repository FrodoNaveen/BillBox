import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/expenses/data/expenses_repository.dart';
import 'features/expenses/presentation/providers/expenses_provider.dart';
import 'features/items/data/items_repository.dart';
import 'features/items/presentation/providers/items_provider.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/splash/presentation/screens/auth_gate.dart';

class BillBoxApp extends StatelessWidget {
  const BillBoxApp({
    super.key,
    required this.authRepository,
    required this.settingsRepository,
    required this.itemsRepository,
    required this.expensesRepository,
  });

  final AuthRepository authRepository;
  final SettingsRepository settingsRepository;
  final ItemsRepository itemsRepository;
  final ExpensesRepository expensesRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(repository: authRepository)..bootstrap(),
        ),
        Provider<SettingsRepository>.value(value: settingsRepository),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) =>
              SettingsProvider(repository: settingsRepository)..load(),
        ),
        Provider<ItemsRepository>.value(value: itemsRepository),
        ChangeNotifierProvider<ItemsProvider>(
          create: (_) => ItemsProvider(repository: itemsRepository)..load(),
        ),
        Provider<ExpensesRepository>.value(value: expensesRepository),
        ChangeNotifierProvider<ExpensesProvider>(
          create: (_) =>
              ExpensesProvider(repository: expensesRepository)..load(),
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
