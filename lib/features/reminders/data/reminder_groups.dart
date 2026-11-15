import '../../../core/utils/formatting.dart';
import '../../items/data/bill_item.dart';

/// The bands the reminders tab sorts deadlines into.
enum ReminderWindow {
  overdue('Already passed'),
  thisWeek('This week'),
  next30('Next 30 days'),
  later('Later');

  const ReminderWindow(this.title);

  final String title;
}

/// One band with the items due in it, soonest first.
class ReminderGroup {
  const ReminderGroup({required this.window, required this.items});

  final ReminderWindow window;
  final List<BillItem> items;
}

/// Sorts dated items into bands, soonest first, dropping the bands that have
/// nothing in them. Items with no date are left out: there is nothing to
/// remind anyone about.
List<ReminderGroup> groupByReminderWindow(
  List<BillItem> items, {
  DateTime? now,
}) {
  final today = dayOf(now ?? DateTime.now());

  final dated = items.where((item) => item.expiryDate != null).toList()
    ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

  final buckets = <ReminderWindow, List<BillItem>>{
    for (final window in ReminderWindow.values) window: <BillItem>[],
  };

  for (final item in dated) {
    final days = daysBetween(today, item.expiryDate!);
    final window = days < 0
        ? ReminderWindow.overdue
        : days <= 7
        ? ReminderWindow.thisWeek
        : days <= 30
        ? ReminderWindow.next30
        : ReminderWindow.later;
    buckets[window]!.add(item);
  }

  return <ReminderGroup>[
    for (final window in ReminderWindow.values)
      if (buckets[window]!.isNotEmpty)
        ReminderGroup(window: window, items: buckets[window]!),
  ];
}

/// How many items are due within a month, which is what the dashboard bell
/// and the summary card count.
int countDueWithinMonth(List<BillItem> items, {DateTime? now}) {
  final today = dayOf(now ?? DateTime.now());
  return items.where((item) {
    final date = item.expiryDate;
    if (date == null) return false;
    return daysBetween(today, date) <= 30;
  }).length;
}
