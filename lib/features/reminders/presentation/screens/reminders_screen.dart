import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../items/presentation/providers/items_provider.dart';
import '../../../items/presentation/screens/item_detail_screen.dart';
import '../../../items/presentation/widgets/swipeable_item_row.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/screens/reminder_settings_screen.dart';
import '../../data/reminder_groups.dart';
import '../widgets/reminder_row.dart';

/// Everything with a date, nearest first, in bands: already passed, this
/// week, the next thirty days, then later. Each row swipes right to edit and
/// left to delete, for fixing a bill entered wrongly.
///
/// The card at the top is the honest state of notifications — what the
/// settings say, and the fact that nothing is being sent yet.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key, this.onAddItem});

  /// Opens the capture flow. The shell owns that route, so it passes this in.
  final VoidCallback? onAddItem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = context.watch<ItemsProvider>().items;
    final groups = groupByReminderWindow(items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ReminderSettingsScreen(),
              ),
            ),
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Reminder settings',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const _NotificationsCard(),
          const SizedBox(height: 18),
          if (groups.isEmpty)
            _NothingDue(onAddItem: onAddItem)
          else
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 10),
                child: Text(
                  group.window.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final item in group.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SwipeableItemRow(
                    item: item,
                    child: ReminderRow(
                      item: item,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ItemDetailScreen(itemId: item.id),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
        ],
      ),
      bottomNavigationBar: onAddItem == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton.icon(
                  onPressed: onAddItem,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add a bill or document'),
                ),
              ),
            ),
    );
  }
}

/// What the reminder settings currently say, and a switch to turn the lot
/// off without leaving the tab.
class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = context.watch<SettingsProvider>();
    final settings = provider.settings;
    final on = settings.remindersEnabled;
    final leadDays = settings.leadDays.toList()..sort((a, b) => b.compareTo(a));
    final time = TimeOfDay(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
    ).format(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: BoxDecoration(
        color: on ? scheme.secondaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            on
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            size: 22,
            color: on ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  on ? 'Reminders on' : 'Reminders off',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: on ? scheme.onSecondaryContainer : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  on
                      ? leadDays.isEmpty
                            ? 'No lead time chosen, so nothing will be sent'
                            : 'Alerts ${leadDays.join(' · ')} days before, '
                                  'at $time'
                      : 'Nothing will be sent until this is back on',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: on
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: on, onChanged: provider.setRemindersEnabled),
        ],
      ),
    );
  }
}

class _NothingDue extends StatelessWidget {
  const _NothingDue({this.onAddItem});

  final VoidCallback? onAddItem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, size: 46, color: scheme.outline),
          const SizedBox(height: 14),
          Text(
            'Nothing has a date yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Save a bill or document with a warranty or expiry date and it '
              'will be listed here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (onAddItem != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onAddItem, child: const Text('Add one now')),
          ],
        ],
      ),
    );
  }
}
