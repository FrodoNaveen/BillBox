import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/features/settings/data/app_settings.dart';
import 'package:billbox/features/settings/data/data_export.dart';
import 'package:billbox/features/settings/data/settings_repository.dart';
import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/sample_items.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStore store;
  late SettingsRepository repository;

  setUp(() {
    store = InMemoryStore();
    repository = SettingsRepository(store);
  });

  group('AppSettings', () {
    test('defaults nudge 30, 7 and 1 day ahead at 9am', () {
      final settings = AppSettings();

      expect(settings.remindersEnabled, isTrue);
      expect(settings.leadDays.toList(), [30, 7, 1]);
      expect(settings.reminderTimeLabel, '09:00');
    });

    test('lead days are sorted largest first and unknown ones dropped', () {
      final settings = AppSettings(leadDays: {7, 90, 30});

      expect(settings.leadDays.toList(), [30, 7]);
    });

    test('toggling adds and removes a lead time', () {
      final settings = AppSettings(leadDays: {7});

      expect(settings.toggleLeadDay(30).leadDays.toList(), [30, 7]);
      expect(settings.toggleLeadDay(7).leadDays, isEmpty);
    });

    test('an out-of-range time falls back to the default', () {
      final settings = AppSettings.fromJson(<String, dynamic>{
        'reminderHour': 25,
        'reminderMinute': -1,
      });

      expect(settings.reminderTimeLabel, '09:00');
    });
  });

  group('SettingsRepository', () {
    test('reads defaults when nothing has been saved', () async {
      expect(await repository.read(), AppSettings());
    });

    test('a saved change comes back', () async {
      await repository.write(
        AppSettings(
          remindersEnabled: false,
          leadDays: {14},
          reminderHour: 20,
          reminderMinute: 30,
        ),
      );

      final restored = await repository.read();
      expect(restored.remindersEnabled, isFalse);
      expect(restored.leadDays.toList(), [14]);
      expect(restored.reminderTimeLabel, '20:30');
    });

    test('corrupt storage falls back to defaults', () async {
      await store.write(SettingsRepository.settingsKey, 'not json at all');

      expect(await repository.read(), AppSettings());
    });
  });

  group('buildExportJson', () {
    test('carries every item and the account it belongs to', () {
      final json = buildExportJson(
        items: sampleBillItems,
        at: DateTime.utc(2026, 11, 15, 10, 30),
        accountEmail: 'naveen@example.com',
      );

      expect(json, contains('"itemCount": ${sampleBillItems.length}'));
      expect(json, contains('"exportedAt": "2026-11-15T10:30:00.000Z"'));
      expect(json, contains('naveen@example.com'));
      expect(json, contains('Samsung 1.5T Split AC'));
    });

    test('leaves the account out when nobody is signed in', () {
      final json = buildExportJson(
        items: const <BillItem>[],
        at: DateTime.utc(2026, 11, 15),
      );

      expect(json, isNot(contains('"account"')));
      expect(json, contains('"itemCount": 0'));
    });
  });
}
