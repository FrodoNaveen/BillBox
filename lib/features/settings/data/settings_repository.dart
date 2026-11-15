import 'dart:convert';

import '../../../core/storage/key_value_store.dart';
import 'app_settings.dart';

/// Reads and writes the settings blob in local storage.
///
/// The whole thing is one JSON value, so a new preference costs no migration.
class SettingsRepository {
  SettingsRepository(this._store);

  static const String settingsKey = 'billbox.settings';

  final KeyValueStore _store;

  /// Defaults when nothing has been saved yet, or when what was saved can no
  /// longer be read — settings are never worth crashing over.
  Future<AppSettings> read() async {
    final raw = await _store.read(settingsKey);
    if (raw == null || raw.isEmpty) return AppSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return AppSettings();
      return AppSettings.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return AppSettings();
    }
  }

  Future<void> write(AppSettings settings) =>
      _store.write(settingsKey, jsonEncode(settings.toJson()));
}
