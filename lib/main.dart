import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/key_value_store.dart';
import 'features/auth/data/auth_local_data_source.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/settings/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage is the only data source in v1, so it is opened once here
  // and handed to the repository.
  final preferences = await SharedPreferences.getInstance();
  final store = SharedPreferencesStore(preferences);
  final authRepository = AuthRepository(dataSource: AuthLocalDataSource(store));
  final settingsRepository = SettingsRepository(store);

  runApp(
    BillBoxApp(
      authRepository: authRepository,
      settingsRepository: settingsRepository,
    ),
  );
}
