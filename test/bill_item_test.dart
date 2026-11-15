import 'package:billbox/features/home/data/home_sample_data.dart';
import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/item_category_catalog.dart';
import 'package:billbox/features/items/data/item_formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final savedAt = DateTime(2026, 11, 15, 9, 30);

  BillItem itemWith({
    String title = 'Samsung 1.5T Split AC',
    String category = 'Appliances',
    ItemKind kind = ItemKind.bill,
    DateTime? expiry,
    String? store,
    double? amount,
    String scannedText = '',
  }) {
    return BillItem(
      id: 'i_1',
      title: title,
      category: category,
      kind: kind,
      savedAt: savedAt,
      store: store,
      amount: amount,
      purchaseDate: DateTime(2024, 11, 20),
      expiryDate: expiry,
      scannedText: scannedText,
      reminderLeadDays: const {30, 7},
      imageName: 'bill.jpg',
    );
  }

  group('formatting', () {
    test('dates read the way the design shows them', () {
      expect(formatItemDate(DateTime(2026, 11, 20)), '20 Nov 2026');
      expect(formatItemDate(DateTime(2031, 2, 3)), '3 Feb 2031');
    });

    test('rupees group the Indian way', () {
      expect(formatRupees(999), '₹999');
      expect(formatRupees(39699), '₹39,699');
      expect(formatRupees(500000), '₹5,00,000');
      expect(formatRupees(12345678), '₹1,23,45,678');
    });

    test('part days count as a whole day', () {
      final from = DateTime(2026, 11, 15, 23, 0);
      final to = DateTime(2026, 11, 16, 1, 0);

      expect(daysBetween(from, to), 1);
      expect(daysBetween(to, from), -1);
    });
  });

  group('BillItem', () {
    test('the date line names what the date is', () {
      final bill = itemWith(expiry: DateTime(2026, 11, 20));
      final document = itemWith(
        kind: ItemKind.document,
        expiry: DateTime(2031, 2, 3),
      );

      expect(bill.dateLabel(), 'Warranty 20 Nov 2026');
      expect(document.dateLabel(), 'Expires 3 Feb 2031');
    });

    test('with no date it falls back to the store', () {
      expect(itemWith(store: 'Sri Electronics').dateLabel(), 'Sri Electronics');
      expect(itemWith().dateLabel(), 'No date saved');
    });

    test('days left is counted from today and can be negative', () {
      final item = itemWith(expiry: DateTime(2026, 11, 21));

      expect(item.daysLeft(now: DateTime(2026, 11, 15)), 6);
      expect(item.daysLeft(now: DateTime(2026, 11, 25)), -4);
      expect(itemWith().daysLeft(), isNull);
    });

    test('the dashboard row is urgent within a week', () {
      final soon = itemWith(
        expiry: DateTime(2026, 11, 21),
      ).toExpiringItem(now: DateTime(2026, 11, 15));
      final later = itemWith(
        expiry: DateTime(2026, 12, 20),
      ).toExpiringItem(now: DateTime(2026, 11, 15));

      expect(soon.daysLeft, 6);
      expect(soon.urgency, ExpiryUrgency.urgent);
      expect(later.urgency, ExpiryUrgency.soon);
    });

    test(
      'a search row without scanned text falls back to store and amount',
      () {
        final row = itemWith(
          store: 'Sri Electronics',
          amount: 39699,
          expiry: DateTime(2026, 11, 20),
        ).toSearchableItem(now: DateTime(2026, 11, 15));

        expect(row.scannedText, 'Sri Electronics · ₹39,699');
        expect(row.category, 'Appliances');
        expect(row.icon, iconForCategory('Appliances'));
      },
    );

    test('a dateless item sorts last in search', () {
      expect(itemWith().toSearchableItem().daysLeft, greaterThan(9999));
    });

    test('json survives a round trip', () {
      final item = itemWith(
        expiry: DateTime(2026, 11, 20),
        store: 'Sri Electronics',
        amount: 39699,
        scannedText: 'TOTAL 39,699.00',
      );

      final restored = BillItem.fromJson(item.toJson());

      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.kind, ItemKind.bill);
      expect(restored.amount, 39699);
      expect(restored.expiryDate, item.expiryDate);
      expect(restored.reminderLeadDays, {30, 7});
      expect(restored.scannedText, 'TOTAL 39,699.00');
      expect(restored.imageName, 'bill.jpg');
    });

    test('an unreadable row is patched, not thrown away', () {
      final restored = BillItem.fromJson(<String, dynamic>{
        'id': 'i_9',
        'category': 'Spaceships',
        'kind': 'nonsense',
        'expiryDate': 'not a date',
        'reminderLeadDays': 'not a list',
      });

      expect(restored.title, 'Untitled item');
      expect(restored.category, fallbackCategory);
      expect(restored.kind, ItemKind.bill);
      expect(restored.expiryDate, isNull);
      expect(restored.reminderLeadDays, isEmpty);
    });
  });
}
