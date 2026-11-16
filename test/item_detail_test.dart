import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/core/theme/app_theme.dart';
import 'package:billbox/core/utils/formatting.dart';
import 'package:billbox/features/expenses/data/expense.dart';
import 'package:billbox/features/expenses/data/expenses_repository.dart';
import 'package:billbox/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:billbox/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/items_repository.dart';
import 'package:billbox/features/items/presentation/providers/items_provider.dart';
import 'package:billbox/features/items/presentation/screens/add_item_screen.dart';
import 'package:billbox/features/items/presentation/screens/item_detail_screen.dart';
import 'package:billbox/features/settings/data/settings_repository.dart';
import 'package:billbox/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late InMemoryStore store;
  late ItemsRepository items;
  late ExpensesRepository expenses;
  late ItemsProvider itemsProvider;
  late ExpensesProvider expensesProvider;

  final today = dayOf(DateTime.now());

  setUp(() {
    store = InMemoryStore();
    items = ItemsRepository(store);
    expenses = ExpensesRepository(store);
    itemsProvider = ItemsProvider(repository: items);
    expensesProvider = ExpensesProvider(repository: expenses);
  });

  BillItem ac({int daysLeft = 6}) {
    return BillItem(
      id: 'i_ac',
      title: 'Samsung 1.5T Split AC',
      category: 'Appliances',
      kind: ItemKind.bill,
      savedAt: today,
      store: 'Sri Electronics, Coimbatore',
      amount: 39699,
      purchaseDate: today.subtract(const Duration(days: 724)),
      expiryDate: today.add(Duration(days: daysLeft)),
      scannedText: 'TOTAL 39,699.00 · Warranty 24 months',
      reminderLeadDays: const {30, 7, 1},
      imageName: 'bill_split_ac.jpg',
    );
  }

  Future<void> pumpDetail(WidgetTester tester, String itemId) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await itemsProvider.load();
    await expensesProvider.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ItemsProvider>.value(value: itemsProvider),
          ChangeNotifierProvider<ExpensesProvider>.value(
            value: expensesProvider,
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) =>
                SettingsProvider(repository: SettingsRepository(store))..load(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: ItemDetailScreen(itemId: itemId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows what is kept about the item', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(ac());
    await pumpDetail(tester, 'i_ac');

    expect(find.text('Samsung 1.5T Split AC'), findsOneWidget);
    expect(find.text('Appliances'), findsOneWidget);
    expect(find.text('Sri Electronics, Coimbatore'), findsWidgets);
    expect(find.text('Warranty ends in 6 days'), findsOneWidget);
    expect(find.textContaining('claim before this date'), findsOneWidget);
    expect(find.text('Amount paid'), findsOneWidget);
    expect(find.text('₹39,699'), findsWidgets);
    expect(find.text('30 · 7 · 1 days before'), findsOneWidget);
    expect(find.text('bill_split_ac.jpg'), findsWidgets);
  });

  testWidgets('a deadline that has passed is reported as such', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(ac(daysLeft: -3));
    await pumpDetail(tester, 'i_ac');

    expect(find.text('Warranty ended 3 days ago'), findsOneWidget);
  });

  testWidgets('the text read from the bill opens on demand', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(ac());
    await pumpDetail(tester, 'i_ac');

    expect(find.text('TOTAL 39,699.00 · Warranty 24 months'), findsNothing);

    await tester.tap(find.text('Text read from this bill'));
    await tester.pumpAndSettle();

    expect(find.text('TOTAL 39,699.00 · Warranty 24 months'), findsOneWidget);
  });

  testWidgets('editing from here writes the change back', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(ac());
    await pumpDetail(tester, 'i_ac');

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.byType(AddItemScreen), findsOneWidget);
    expect(find.text('Edit item'), findsOneWidget);
    // The form opens on the saved values, not on a blank sheet.
    expect(find.text('Samsung 1.5T Split AC'), findsOneWidget);
    expect(find.text('39699'), findsOneWidget);
    expect(find.text('Clear all'), findsNothing);
    expect(find.textContaining('as spending'), findsNothing);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Samsung Split AC (bedroom)',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect((await items.readAll()).single.title, 'Samsung Split AC (bedroom)');
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.text('Samsung Split AC (bedroom)'), findsOneWidget);
  });

  testWidgets('deleting asks first, then removes the item', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(ac());
    await pumpDetail(tester, 'i_ac');

    await tester.tap(find.byTooltip('Delete item'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this item?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await items.readAll(), hasLength(1));

    await tester.tap(find.byTooltip('Delete item'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(await items.readAll(), isEmpty);
  });

  testWidgets('a bill logged as spending links to that day', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(ac());
    await expensesProvider.load();
    await expensesProvider.add(
      Expense(
        id: 'e_1',
        amount: 39699,
        category: 'Shopping',
        date: today,
        note: 'Samsung 1.5T Split AC',
        linkedItemId: 'i_ac',
      ),
    );
    await pumpDetail(tester, 'i_ac');

    expect(find.text('Logged as spending'), findsOneWidget);

    await tester.tap(find.text('Logged as spending'));
    await tester.pumpAndSettle();

    expect(find.byType(ExpensesScreen), findsOneWidget);
  });

  testWidgets('an item that is gone says so instead of going blank', (
    tester,
  ) async {
    await pumpDetail(tester, 'i_nothing');

    expect(find.text('This item is no longer saved.'), findsOneWidget);
  });

  testWidgets('lays out on a real phone surface without overflowing', (
    tester,
  ) async {
    await itemsProvider.load();
    await itemsProvider.add(ac());
    await expensesProvider.load();
    await expensesProvider.add(
      Expense(
        id: 'e_1',
        amount: 39699,
        category: 'Shopping',
        date: today,
        note: 'Samsung 1.5T Split AC',
        linkedItemId: 'i_ac',
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ItemsProvider>.value(value: itemsProvider),
          ChangeNotifierProvider<ExpensesProvider>.value(
            value: expensesProvider,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ItemDetailScreen(itemId: 'i_ac'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Samsung 1.5T Split AC'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Logged as spending'), findsOneWidget);
  });
}
