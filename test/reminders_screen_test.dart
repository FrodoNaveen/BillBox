import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/core/theme/app_theme.dart';
import 'package:billbox/core/utils/formatting.dart';
import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/items_repository.dart';
import 'package:billbox/features/items/presentation/providers/items_provider.dart';
import 'package:billbox/features/items/presentation/screens/item_detail_screen.dart';
import 'package:billbox/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:billbox/features/reminders/presentation/widgets/reminder_row.dart';
import 'package:billbox/features/settings/data/settings_repository.dart';
import 'package:billbox/features/settings/presentation/providers/settings_provider.dart';
import 'package:billbox/features/expenses/data/expenses_repository.dart';
import 'package:billbox/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:billbox/features/settings/presentation/screens/reminder_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late InMemoryStore store;
  late ItemsRepository items;
  late SettingsRepository settings;
  late ItemsProvider itemsProvider;
  late SettingsProvider settingsProvider;

  final today = dayOf(DateTime.now());
  var addPressed = 0;

  setUp(() {
    store = InMemoryStore();
    items = ItemsRepository(store);
    settings = SettingsRepository(store);
    itemsProvider = ItemsProvider(repository: items);
    settingsProvider = SettingsProvider(repository: settings);
    addPressed = 0;
  });

  BillItem item({
    required String id,
    required String title,
    int? daysLeft,
    String category = 'Appliances',
    ItemKind kind = ItemKind.bill,
  }) {
    return BillItem(
      id: id,
      title: title,
      category: category,
      kind: kind,
      savedAt: today,
      expiryDate: daysLeft == null ? null : today.add(Duration(days: daysLeft)),
    );
  }

  Future<void> pumpReminders(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await itemsProvider.load();
    await settingsProvider.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ItemsProvider>.value(value: itemsProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
          ),
          ChangeNotifierProvider<ExpensesProvider>(
            create: (_) =>
                ExpensesProvider(repository: ExpensesRepository(store))..load(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: RemindersScreen(onAddItem: () => addPressed++),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('groups the deadlines and names each band', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(item(id: 'a', title: 'Split AC', daysLeft: 6));
    await itemsProvider.add(
      item(id: 'b', title: 'Two-wheeler insurance', daysLeft: 21),
    );
    await itemsProvider.add(item(id: 'c', title: 'Passport', daysLeft: 400));
    await itemsProvider.add(item(id: 'd', title: 'Old warranty', daysLeft: -5));
    await pumpReminders(tester);

    expect(find.text('ALREADY PASSED'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('NEXT 30 DAYS'), findsOneWidget);
    expect(find.text('LATER'), findsOneWidget);
    expect(find.byType(ReminderRow), findsNWidgets(4));
    expect(find.text('6 days'), findsOneWidget);
    expect(find.text('5 days ago'), findsOneWidget);
    expect(find.text('Warranty · Appliances'), findsWidgets);
  });

  testWidgets('an item with no date is not listed', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(item(id: 'a', title: 'Dateless receipt'));
    await pumpReminders(tester);

    expect(find.byType(ReminderRow), findsNothing);
    expect(find.text('Nothing has a date yet'), findsOneWidget);

    await tester.tap(find.text('Add one now'));
    await tester.pumpAndSettle();
    expect(addPressed, 1);
  });

  testWidgets('the card reports the saved settings and can switch them off', (
    tester,
  ) async {
    await itemsProvider.load();
    await itemsProvider.add(item(id: 'a', title: 'Split AC', daysLeft: 6));
    await pumpReminders(tester);

    expect(find.text('Reminders on'), findsOneWidget);
    expect(
      find.textContaining('Alerts 30 · 7 · 1 days before'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Reminders off'), findsOneWidget);
    expect((await settings.read()).remindersEnabled, isFalse);
  });

  testWidgets('a row opens the item, the gear opens the settings', (
    tester,
  ) async {
    await itemsProvider.load();
    await itemsProvider.add(item(id: 'a', title: 'Split AC', daysLeft: 6));
    await pumpReminders(tester);

    await tester.tap(find.text('Split AC'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Reminder settings'));
    await tester.pumpAndSettle();
    expect(find.byType(ReminderSettingsScreen), findsOneWidget);
  });

  testWidgets('a fresh install has nothing to list', (tester) async {
    await pumpReminders(tester);

    expect(find.byType(ReminderRow), findsNothing);
    expect(find.text('THIS WEEK'), findsNothing);
    expect(find.text('Nothing has a date yet'), findsOneWidget);
  });

  testWidgets('adding a bill is offered under the list', (tester) async {
    await itemsProvider.load();
    await itemsProvider.add(item(id: 'a', title: 'Split AC', daysLeft: 6));
    await pumpReminders(tester);

    await tester.tap(find.text('Add a bill or document'));
    await tester.pumpAndSettle();

    expect(addPressed, 1);
  });

  testWidgets('lays out on a real phone surface without overflowing', (
    tester,
  ) async {
    await itemsProvider.load();
    await itemsProvider.add(
      item(id: 'a', title: 'Samsung 1.5T Split AC', daysLeft: 6),
    );
    await itemsProvider.add(
      item(
        id: 'b',
        title: 'Two-wheeler insurance',
        daysLeft: 21,
        category: 'Insurance',
      ),
    );
    await itemsProvider.add(
      item(
        id: 'c',
        title: 'Passport',
        daysLeft: 400,
        category: 'Identity',
        kind: ItemKind.document,
      ),
    );
    await settingsProvider.load();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ItemsProvider>.value(value: itemsProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const RemindersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The long titles sit in rows that must not overflow at phone width.
    expect(find.byType(ReminderRow), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('LATER'), findsOneWidget);
  });
}
