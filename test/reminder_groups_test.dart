import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/sample_items.dart';
import 'package:billbox/features/reminders/data/reminder_groups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 15);

  BillItem item(String id, {int? daysLeft}) {
    return BillItem(
      id: id,
      title: id,
      category: 'Appliances',
      kind: ItemKind.bill,
      savedAt: now,
      expiryDate: daysLeft == null ? null : now.add(Duration(days: daysLeft)),
    );
  }

  group('groupByReminderWindow', () {
    test('sorts deadlines into bands, soonest first', () {
      final groups = groupByReminderWindow(<BillItem>[
        item('later', daysLeft: 120),
        item('week', daysLeft: 6),
        item('overdue', daysLeft: -3),
        item('month', daysLeft: 21),
        item('tomorrow', daysLeft: 1),
      ], now: now);

      expect(groups.map((g) => g.window), [
        ReminderWindow.overdue,
        ReminderWindow.thisWeek,
        ReminderWindow.next30,
        ReminderWindow.later,
      ]);
      expect(groups[1].items.map((i) => i.id), ['tomorrow', 'week']);
    });

    test('a band with nothing in it is left out', () {
      final groups = groupByReminderWindow(<BillItem>[
        item('a', daysLeft: 200),
      ], now: now);

      expect(groups, hasLength(1));
      expect(groups.single.window, ReminderWindow.later);
    });

    test('the edges of each band', () {
      final groups = groupByReminderWindow(<BillItem>[
        item('today', daysLeft: 0),
        item('seven', daysLeft: 7),
        item('eight', daysLeft: 8),
        item('thirty', daysLeft: 30),
        item('thirtyone', daysLeft: 31),
      ], now: now);

      Iterable<String> idsIn(ReminderWindow window) =>
          groups.firstWhere((g) => g.window == window).items.map((i) => i.id);

      expect(idsIn(ReminderWindow.thisWeek), ['today', 'seven']);
      expect(idsIn(ReminderWindow.next30), ['eight', 'thirty']);
      expect(idsIn(ReminderWindow.later), ['thirtyone']);
    });

    test('items with no date are left out — there is nothing to remind', () {
      final groups = groupByReminderWindow(<BillItem>[
        item('dateless'),
        item('dated', daysLeft: 4),
      ], now: now);

      expect(groups.single.items.map((i) => i.id), ['dated']);
    });

    test('nothing dated means no groups at all', () {
      expect(groupByReminderWindow(<BillItem>[item('a')], now: now), isEmpty);
    });
  });

  group('countDueWithinMonth', () {
    test('counts overdue and anything inside thirty days', () {
      final count = countDueWithinMonth(<BillItem>[
        item('overdue', daysLeft: -2),
        item('soon', daysLeft: 6),
        item('edge', daysLeft: 30),
        item('later', daysLeft: 31),
        item('dateless'),
      ], now: now);

      expect(count, 3);
    });
  });

  test('the sample catalogue fills the week, the month and later', () {
    final groups = groupByReminderWindow(buildSampleItems(now: now), now: now);

    expect(groups.map((g) => g.window), [
      ReminderWindow.thisWeek,
      ReminderWindow.next30,
      ReminderWindow.later,
    ]);
  });
}
