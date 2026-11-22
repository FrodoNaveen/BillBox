import 'package:flutter/foundation.dart';

import '../../data/app_settings.dart';
import '../../data/settings_repository.dart';

/// Holds the saved settings for the whole app.
///
/// Every change is applied in memory and written to storage in the same call,
/// so a screen never has to remember to save.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({required SettingsRepository repository})
    : _repository = repository;

  final SettingsRepository _repository;

  AppSettings _settings = AppSettings();
  bool _isLoaded = false;

  AppSettings get settings => _settings;

  /// False until [load] has read storage once.
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _settings = await _repository.read();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setRemindersEnabled(bool enabled) =>
      _apply(_settings.copyWith(remindersEnabled: enabled));

  Future<void> toggleLeadDay(int days) => _apply(_settings.toggleLeadDay(days));

  Future<void> setReminderTime({required int hour, required int minute}) =>
      _apply(_settings.copyWith(reminderHour: hour, reminderMinute: minute));

  Future<void> setHandsFreeEnabled(bool enabled) =>
      _apply(_settings.copyWith(handsFreeEnabled: enabled));

  Future<void> resetToDefaults() => _apply(AppSettings());

  Future<void> _apply(AppSettings next) async {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
    await _repository.write(next);
  }
}
