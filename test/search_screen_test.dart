import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/core/theme/app_theme.dart';
import 'package:billbox/core/utils/formatting.dart';
import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/items_repository.dart';
import 'package:billbox/features/items/presentation/providers/items_provider.dart';
import 'package:billbox/features/search/presentation/screens/search_screen.dart';
import 'package:billbox/features/search/presentation/widgets/search_result_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Nine saved items spread across the categories and the expiry windows, so
/// the chips, the counts and the sort all have something to work on.
List<BillItem> _savedItems() {
  final today = dayOf(DateTime.now());

  BillItem item(
    String id,
    String title,
    String category,
    int daysLeft,
    String scannedText, {
    ItemKind kind = ItemKind.bill,
  }) {
    return BillItem(
      id: id,
      title: title,
      category: category,
      kind: kind,
      savedAt: today.subtract(Duration(days: daysLeft)),
      expiryDate: today.add(Duration(days: daysLeft)),
      scannedText: scannedText,
    );
  }

  return <BillItem>[
    item(
      'i_ac',
      'Samsung 1.5T Split AC',
      'Appliances',
      6,
      'Extended insurance plan not opted',
    ),
    item(
      'i_purifier',
      'Water purifier AMC',
      'Appliances',
      7,
      'AMC 2 services remaining, ticket 7781',
    ),
    item(
      'i_rent',
      'Flat rental agreement',
      'Home / Rent',
      15,
      'Rent 18,500 per month, 11 months',
      kind: ItemKind.document,
    ),
    item('i_two', 'Two-wheeler insurance', 'Insurance', 21, 'Policy no. 4471'),
    item('i_mac', 'MacBook Air M2', 'Electronics', 48, 'Serial C02XK'),
    item(
      'i_health',
      'Family health insurance',
      'Insurance',
      124,
      'Sum insured 5,00,000',
    ),
    item('i_fridge', 'LG 190L refrigerator', 'Appliances', 270, 'Invoice 8821'),
    item(
      'i_activa',
      'Honda Activa registration',
      'Vehicle',
      941,
      'Registration TN 22',
      kind: ItemKind.document,
    ),
    item(
      'i_passport',
      'Passport',
      'Identity',
      1541,
      'Place of issue Chennai',
      kind: ItemKind.document,
    ),
  ];
}

Future<void> _pumpSearch(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final repository = ItemsRepository(InMemoryStore());
  await repository.writeAll(_savedItems());
  final provider = ItemsProvider(repository: repository);
  await provider.load();

  await tester.pumpWidget(
    ChangeNotifierProvider<ItemsProvider>.value(
      value: provider,
      child: MaterialApp(theme: AppTheme.light(), home: const SearchScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens with every item, soonest first', (tester) async {
    await _pumpSearch(tester);

    expect(find.text('9 results'), findsOneWidget);
    expect(find.text('Samsung 1.5T Split AC'), findsOneWidget);
  });

  testWidgets('typing narrows the rows and counts scanned-text matches', (
    tester,
  ) async {
    await _pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'insur');
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(SearchResultTile, 'Two-wheeler insurance'),
      findsOneWidget,
    );
    expect(find.text('3 results · including scanned text'), findsOneWidget);
  });

  testWidgets('a category chip filters, and clearing brings the rows back', (
    tester,
  ) async {
    await _pumpSearch(tester);

    await tester.ensureVisible(find.text('Identity'));
    await tester.tap(find.text('Identity'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchResultTile), findsOneWidget);
    expect(find.text('Passport'), findsOneWidget);

    await tester.ensureVisible(find.text('Identity'));
    await tester.tap(find.text('Identity'));
    await tester.pumpAndSettle();

    expect(find.text('9 results'), findsOneWidget);
  });

  testWidgets('the expiry window chip keeps only what is due', (tester) async {
    await _pumpSearch(tester);

    await tester.tap(find.text('Any date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next 30 days').last);
    await tester.pumpAndSettle();

    expect(find.text('Expiring 30 d'), findsOneWidget);
    expect(find.byType(SearchResultTile), findsNWidgets(4));
  });

  testWidgets('no match shows the empty state, and clearing resets it', (
    tester,
  ) async {
    await _pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'tractor');
    await tester.pumpAndSettle();

    expect(find.text('0 results'), findsOneWidget);
    expect(find.text('No match for “tractor”'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('9 results'), findsOneWidget);
  });
}
