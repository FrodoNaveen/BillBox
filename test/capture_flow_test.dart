import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/core/theme/app_theme.dart';
import 'package:billbox/features/expenses/data/expenses_repository.dart';
import 'package:billbox/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/bill_scanner.dart';
import 'package:billbox/features/items/data/items_repository.dart';
import 'package:billbox/features/items/presentation/providers/items_provider.dart';
import 'package:billbox/features/items/presentation/screens/add_item_screen.dart';
import 'package:billbox/features/items/presentation/screens/capture_bill_screen.dart';
import 'package:billbox/features/settings/data/settings_repository.dart';
import 'package:billbox/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late InMemoryStore store;
  late ItemsRepository items;
  late ExpensesRepository expenses;

  setUp(() {
    store = InMemoryStore();
    items = ItemsRepository(store);
    expenses = ExpensesRepository(store);
  });

  /// The capture screen with an instant reader, so no test waits 900ms.
  Future<void> pumpCapture(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ItemsProvider>(
            create: (_) => ItemsProvider(repository: items)..load(),
          ),
          ChangeNotifierProvider<ExpensesProvider>(
            create: (_) => ExpensesProvider(repository: expenses)..load(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) =>
                SettingsProvider(repository: SettingsRepository(store))..load(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: CaptureBillScreen(
            scanner: SampleBillScanner(
              delay: Duration.zero,
              now: DateTime(2026, 11, 15),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the shutter reads a bill into the review form', (tester) async {
    await pumpCapture(tester);

    expect(find.text('Scan bill'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Take photo'));
    await tester.pumpAndSettle();

    expect(find.byType(AddItemScreen), findsOneWidget);
    expect(find.text('Check the details'), findsOneWidget);
    expect(find.text('Samsung 1.5T Split AC'), findsOneWidget);
    expect(find.text('Appliances'), findsOneWidget);
    expect(find.text('39699'), findsOneWidget);
    expect(find.text('15 Nov 2028'), findsOneWidget);
    expect(find.text('read from bill'), findsWidgets);
    expect(
      find.textContaining('"Warranty 24 months" on the bill'),
      findsOneWidget,
    );
  });

  testWidgets('saving keeps the item and reports the reminders', (
    tester,
  ) async {
    await pumpCapture(tester);

    await tester.tap(find.bySemanticsLabel('Take photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    final saved = await items.readAll();
    expect(saved, hasLength(1));
    expect(saved.single.title, 'Samsung 1.5T Split AC');
    expect(saved.single.category, 'Appliances');
    expect(saved.single.amount, 39699);
    expect(saved.single.kind, ItemKind.bill);
    expect(saved.single.scannedText, contains('TOTAL 39,699.00'));
    expect(saved.single.reminderLeadDays, {30, 7, 1});
    expect(saved.single.imageName, isNotNull);

    // Back on the capture screen, with the save confirmed.
    expect(find.byType(CaptureBillScreen), findsOneWidget);
    expect(find.textContaining('Nudges 30, 7, 1 days before'), findsOneWidget);
  });

  testWidgets('document mode asks for an expiry, not a warranty', (
    tester,
  ) async {
    await pumpCapture(tester);

    await tester.tap(find.text('Document'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Take photo'));
    await tester.pumpAndSettle();

    expect(find.text('Expires on'), findsOneWidget);
    expect(find.text('Warranty ends'), findsNothing);
    expect(find.text('Passport'), findsOneWidget);

    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect((await items.readAll()).single.kind, ItemKind.document);
  });

  testWidgets('typing it in by hand opens an empty form that needs a title', (
    tester,
  ) async {
    await pumpCapture(tester);

    await tester.tap(find.bySemanticsLabel('Add details without a photo'));
    await tester.pumpAndSettle();

    expect(find.text('Add item'), findsOneWidget);
    expect(find.text('read from bill'), findsNothing);
    expect(find.text('Pick a date above to set reminders.'), findsOneWidget);

    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(find.text('Give the item a name'), findsOneWidget);
    expect(await items.readAll(), isEmpty);

    await tester.enterText(find.byType(TextFormField).first, 'Rent agreement');
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    final saved = await items.readAll();
    expect(saved.single.title, 'Rent agreement');
    expect(saved.single.expiryDate, isNull);
    expect(find.textContaining('Rent agreement saved.'), findsOneWidget);
  });

  testWidgets('clear all empties what the photo filled in', (tester) async {
    await pumpCapture(tester);

    await tester.tap(find.bySemanticsLabel('Take photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Clear all'));
    await tester.pumpAndSettle();

    expect(find.text('Samsung 1.5T Split AC'), findsNothing);
    expect(find.text('Pick a date'), findsNWidgets(2));
  });

  testWidgets('a bill with an amount is also logged as spending', (
    tester,
  ) async {
    await pumpCapture(tester);

    await tester.tap(find.bySemanticsLabel('Take photo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Also log ₹39,699 as spending'), findsOneWidget);

    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    final logged = await expenses.readAll();
    expect(logged, hasLength(1));
    expect(logged.single.amount, 39699);
    // "Appliances" is not a spending category, so it is mapped to one.
    expect(logged.single.category, 'Shopping');
    expect(logged.single.note, 'Samsung 1.5T Split AC');
    expect(logged.single.linkedItemId, (await items.readAll()).single.id);
    expect(find.textContaining('₹39,699 added to spending'), findsOneWidget);
  });

  testWidgets('unticking the box keeps the bill out of spending', (
    tester,
  ) async {
    await pumpCapture(tester);

    await tester.tap(find.bySemanticsLabel('Take photo'));
    await tester.pumpAndSettle();
    // The tile sits below the fold on a phone, so scroll to it first.
    final box = find.textContaining('Also log ₹39,699 as spending');
    await tester.ensureVisible(box);
    await tester.pumpAndSettle();
    await tester.tap(box);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(await items.readAll(), hasLength(1));
    expect(await expenses.readAll(), isEmpty);
  });

  testWidgets('a bill with no amount never offers the spending box', (
    tester,
  ) async {
    await pumpCapture(tester);

    await tester.tap(find.bySemanticsLabel('Add details without a photo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('as spending'), findsNothing);
  });
}
