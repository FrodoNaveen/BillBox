import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/core/theme/app_theme.dart';
import 'package:billbox/core/utils/formatting.dart';
import 'package:billbox/features/expenses/data/expenses_repository.dart';
import 'package:billbox/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/items_repository.dart';
import 'package:billbox/features/items/presentation/providers/items_provider.dart';
import 'package:billbox/features/items/presentation/screens/add_item_screen.dart';
import 'package:billbox/features/items/presentation/widgets/swipeable_item_row.dart';
import 'package:billbox/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:billbox/features/reminders/presentation/widgets/reminder_row.dart';
import 'package:billbox/features/settings/data/settings_repository.dart';
import 'package:billbox/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// The swipe actions are one widget shared by every item row, so the
/// reminders tab stands in for all of them here.
void main() {
  late InMemoryStore store;
  late ItemsRepository items;
  late ItemsProvider itemsProvider;

  final today = dayOf(DateTime.now());

  setUp(() {
    store = InMemoryStore();
    items = ItemsRepository(store);
    itemsProvider = ItemsProvider(repository: items);
  });

  BillItem bill({String id = 'i_ac', String title = 'Split AC'}) {
    return BillItem(
      id: id,
      title: title,
      category: 'Appliances',
      kind: ItemKind.bill,
      savedAt: today,
      amount: 39699,
      expiryDate: today.add(const Duration(days: 6)),
    );
  }

  Future<void> pumpList(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await itemsProvider.load();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ItemsProvider>.value(value: itemsProvider),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) =>
                SettingsProvider(repository: SettingsRepository(store))..load(),
          ),
          ChangeNotifierProvider<ExpensesProvider>(
            create: (_) =>
                ExpensesProvider(repository: ExpensesRepository(store))..load(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const RemindersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Drags the row far enough past the threshold to fire the action.
  Future<void> swipe(WidgetTester tester, double dx) async {
    await tester.drag(find.byType(ReminderRow), Offset(dx, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('every saved row carries the swipe actions', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(bill());
    await pumpList(tester);

    expect(find.byType(SwipeableItemRow), findsOneWidget);
  });

  testWidgets('dragging right uncovers Edit and opens the form', (
    tester,
  ) async {
    await itemsProvider.load();
    await itemsProvider.add(bill());
    await pumpList(tester);

    // Part way across, the edit panel is showing behind the row.
    await tester.drag(find.byType(ReminderRow), const Offset(90, 0));
    await tester.pump();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    await tester.pumpAndSettle();
    await swipe(tester, 400);

    expect(find.byType(AddItemScreen), findsOneWidget);
    expect(find.text('Edit item'), findsOneWidget);
    // The form opens on the item it was swiped from.
    expect(find.text('Split AC'), findsOneWidget);
    expect(find.text('39699'), findsOneWidget);
  });

  testWidgets('editing leaves the row in place', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(bill());
    await pumpList(tester);

    await swipe(tester, 400);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ReminderRow), findsOneWidget);
    expect(await items.readAll(), hasLength(1));
  });

  testWidgets('dragging left uncovers Delete and asks first', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(bill());
    await pumpList(tester);

    await tester.drag(find.byType(ReminderRow), const Offset(-90, 0));
    await tester.pump();
    expect(find.text('Delete'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    await tester.pumpAndSettle();
    await swipe(tester, -400);

    expect(find.text('Delete this item?'), findsOneWidget);
    expect(
      find.textContaining('Split AC and its reminders are removed'),
      findsOneWidget,
    );
    // Nothing has gone yet.
    expect(await items.readAll(), hasLength(1));
  });

  testWidgets('confirming the warning removes the item and says so', (
    tester,
  ) async {
    await itemsProvider.load();
    await itemsProvider.add(bill());
    await pumpList(tester);

    await swipe(tester, -400);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(await items.readAll(), isEmpty);
    expect(find.byType(ReminderRow), findsNothing);
    expect(find.text('Split AC deleted.'), findsOneWidget);
    // The tab falls back to its empty state.
    expect(find.text('Nothing has a date yet'), findsOneWidget);
  });

  testWidgets('cancelling the warning keeps the row', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(bill());
    await pumpList(tester);

    await swipe(tester, -400);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(await items.readAll(), hasLength(1));
    expect(find.byType(ReminderRow), findsOneWidget);
    expect(find.text('Split AC'), findsOneWidget);
  });

  testWidgets('a short drag does nothing at all', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(bill());
    await pumpList(tester);

    // Well short of the third of the width the actions need.
    await swipe(tester, 40);

    expect(find.byType(AddItemScreen), findsNothing);
    expect(find.text('Delete this item?'), findsNothing);
    expect(find.byType(ReminderRow), findsOneWidget);
    expect(await items.readAll(), hasLength(1));
  });

  testWidgets('only the swiped row is deleted', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(bill(id: 'i_ac', title: 'Split AC'));
    await itemsProvider.add(bill(id: 'i_tv', title: 'Sony TV'));
    await pumpList(tester);

    expect(find.byType(ReminderRow), findsNWidgets(2));

    await tester.drag(find.text('Sony TV'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect((await items.readAll()).single.title, 'Split AC');
    expect(find.text('Split AC'), findsOneWidget);
    expect(find.text('Sony TV'), findsNothing);
  });
}
