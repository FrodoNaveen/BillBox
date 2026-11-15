import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/widgets/privacy_note.dart';
import '../../data/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_tile.dart';

/// When to be nudged: the master switch, how many days ahead, and the hour
/// the day's reminders are sent. Every change saves itself.
class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({super.key});

  static String leadDaysSummary(Set<int> days) {
    if (days.isEmpty) return 'no lead time chosen';
    return '${days.join(', ')} days before';
  }

  Future<void> _pickTime(BuildContext context, AppSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
      helpText: 'Send reminders at',
    );
    if (picked == null || !context.mounted) return;
    await context.read<SettingsProvider>().setReminderTime(
      hour: picked.hour,
      minute: picked.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = context.watch<SettingsProvider>();
    final settings = provider.settings;
    final on = settings.remindersEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          SettingsCard(
            children: [
              SwitchListTile(
                value: on,
                onChanged: provider.setRemindersEnabled,
                title: const Text(
                  'Expiry reminders',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  on ? 'On for every saved item' : 'Off — nothing will be sent',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                contentPadding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SettingsSectionLabel('Nudge me'),
          SettingsCard(
            children: [
              for (final days in AppSettings.leadDayOptions)
                CheckboxListTile(
                  value: settings.leadDays.contains(days),
                  onChanged: on ? (_) => provider.toggleLeadDay(days) : null,
                  controlAffinity: ListTileControlAffinity.trailing,
                  dense: true,
                  title: Text(
                    days == 1 ? '1 day before' : '$days days before',
                    style: const TextStyle(fontSize: 15),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
            ],
          ),
          if (on && settings.leadDays.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 4),
              child: Text(
                'Pick at least one lead time, or nothing will be sent.',
                style: TextStyle(fontSize: 12, color: scheme.error),
              ),
            ),
          const SizedBox(height: 22),
          const SettingsSectionLabel('Time of day'),
          SettingsTile(
            icon: Icons.schedule_rounded,
            title: 'Send reminders at',
            subtitle: 'The whole day’s nudges arrive together',
            enabled: on,
            onTap: () => _pickTime(context, settings),
            trailing: Text(
              TimeOfDay(
                hour: settings.reminderHour,
                minute: settings.reminderMinute,
              ).format(context),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: on ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const PrivacyNote(
            text:
                'Saved on this phone. The nudges themselves start arriving '
                'once the reminders tab is wired up.',
          ),
        ],
      ),
    );
  }
}
