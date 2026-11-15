import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/privacy_note.dart';
import '../../../items/presentation/providers/items_provider.dart';
import '../../../settings/data/data_export.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/screens/profile_details_screen.dart';
import '../../../settings/presentation/screens/reminder_settings_screen.dart';
import '../../../settings/presentation/widgets/settings_tile.dart';

/// The account tab, which doubles as the settings hub: who is signed in, the
/// settings rows, what can be done with the data, and log out.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _confirmLogOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final shouldLogOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Your bills stay on this phone. You can log back in any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogOut ?? false) {
      await auth.logOut();
    }
  }

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // Only what the user actually saved: the sample catalogue is not theirs
    // to export.
    final items = context.read<ItemsProvider>().items;
    if (items.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nothing saved yet to export.')),
      );
      return;
    }

    final json = buildExportJson(
      items: items,
      at: DateTime.now(),
      accountEmail: context.read<AuthProvider>().user?.email,
    );

    await Clipboard.setData(ClipboardData(text: json));
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${items.length} ${items.length == 1 ? 'item' : 'items'} copied to '
          'the clipboard as JSON.',
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final settings = context.watch<SettingsProvider>().settings;

    final reminderSummary = !settings.remindersEnabled
        ? 'Off — nothing will be sent'
        : settings.leadDays.isEmpty
        ? 'On, but no lead time is chosen'
        : '${ReminderSettingsScreen.leadDaysSummary(settings.leadDays)} · '
              '${TimeOfDay(hour: settings.reminderHour, minute: settings.reminderMinute).format(context)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _ProfileCard(
            initials: user?.initials ?? '?',
            greeting: 'Hi ${user?.firstName ?? 'there'}',
            email: user?.email ?? '',
          ),
          const SizedBox(height: 22),
          const SettingsSectionLabel('Settings'),
          SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Profile details',
            subtitle: user?.phone == null
                ? 'Name and mobile number'
                : '${user?.name} · ${user?.phone}',
            onTap: () => _open(context, const ProfileDetailsScreen()),
          ),
          const SizedBox(height: 10),
          SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Reminder settings',
            subtitle: reminderSummary,
            onTap: () => _open(context, const ReminderSettingsScreen()),
          ),
          const SizedBox(height: 10),
          const SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'App lock',
            subtitle: 'Face unlock or a PIN before BillBox opens',
            enabled: false,
            trailing: SoonBadge(),
          ),
          const SizedBox(height: 22),
          const SettingsSectionLabel('Your data'),
          SettingsTile(
            icon: Icons.ios_share_rounded,
            title: 'Export data',
            subtitle: 'Copy every item as JSON',
            onTap: () => _export(context),
            trailing: const Icon(Icons.content_copy_rounded, size: 20),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => _confirmLogOut(context),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Log out'),
          ),
          const SizedBox(height: 20),
          const PrivacyNote(
            text:
                'Your bills, photos and settings never leave this phone. '
                'Nothing is uploaded anywhere.',
          ),
        ],
      ),
    );
  }
}

/// Who is signed in, on the tonal card at the top of the tab.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.initials,
    required this.greeting,
    required this.email,
  });

  final String initials;
  final String greeting;
  final String email;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
