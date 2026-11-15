import 'package:billbox/features/search/data/item_search.dart';
import 'package:billbox/features/items/data/item_category_catalog.dart';
import 'package:billbox/features/items/data/sample_items.dart';
import 'package:billbox/features/search/data/search_sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _items = <SearchableItem>[
  SearchableItem(
    title: 'Samsung Split AC',
    category: 'Appliances',
    dateLabel: 'Warranty 20 Nov 2026',
    scannedText: 'Extended insurance plan not opted',
    daysLeft: 6,
    icon: Icons.ac_unit_rounded,
  ),
  SearchableItem(
    title: 'Two-wheeler insurance',
    category: 'Insurance',
    dateLabel: 'Renewal 5 Dec 2026',
    scannedText: 'Policy no. 4471',
    daysLeft: 21,
    icon: Icons.shield_outlined,
  ),
  SearchableItem(
    title: 'Passport',
    category: 'Identity',
    dateLabel: 'Expires 3 Feb 2031',
    scannedText: 'Place of issue Chennai',
    daysLeft: 1541,
    icon: Icons.badge_outlined,
  ),
];

void main() {
  group('searchItems', () {
    test('an empty query keeps everything, soonest first', () {
      final results = searchItems(source: _items);

      expect(results.map((item) => item.title), [
        'Samsung Split AC',
        'Two-wheeler insurance',
        'Passport',
      ]);
    });

    test('matches the title, the category and the scanned text', () {
      final results = searchItems(source: _items, query: 'INSUR');

      expect(results.map((item) => item.title), [
        'Samsung Split AC', // only in the scanned text
        'Two-wheeler insurance',
      ]);
    });

    test('the category chip narrows the rows', () {
      final results = searchItems(source: _items, category: 'Identity');

      expect(results.single.title, 'Passport');
    });

    test('the expiry window drops anything further out', () {
      final results = searchItems(source: _items, window: ExpiryWindow.days30);

      expect(results.map((item) => item.daysLeft), [6, 21]);
    });

    test('sorting by name ignores case', () {
      final results = searchItems(source: _items, sort: SearchSort.name);

      expect(results.map((item) => item.title), [
        'Passport',
        'Samsung Split AC',
        'Two-wheeler insurance',
      ]);
    });

    test('filters combine', () {
      final results = searchItems(
        source: _items,
        query: 'insur',
        category: 'Insurance',
        window: ExpiryWindow.days30,
      );

      expect(results.single.title, 'Two-wheeler insurance');
    });
  });

  group('countScannedTextOnlyMatches', () {
    test('counts rows found only by their scanned text', () {
      final results = searchItems(source: _items, query: 'insur');

      expect(countScannedTextOnlyMatches(results, 'insur'), 1);
    });

    test('is zero without a query', () {
      final results = searchItems(source: _items);

      expect(countScannedTextOnlyMatches(results, ''), 0);
    });
  });

  test('the sample catalogue covers every chip category', () {
    for (final name in itemCategories) {
      expect(
        sampleBillItems.any((item) => item.category == name),
        isTrue,
        reason: 'no sample item in $name',
      );
    }
  });
}
