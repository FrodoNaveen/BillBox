import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/core/theme/app_theme.dart';
import 'package:billbox/core/utils/formatting.dart';
import 'package:billbox/features/expenses/data/expense.dart';
import 'package:billbox/features/expenses/data/expenses_repository.dart';
import 'package:billbox/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:billbox/features/home/presentation/screens/home_screen.dart';
import 'package:billbox/features/home/presentation/widgets/summary_card.dart';
import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/items_repository.dart';
import 'package:billbox/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:billbox/features/expenses/presentation/widgets/spending_card.dart';
import 'package:billbox/features/items/presentation/providers/items_provider.dart';
import 'package:billbox/features/items/presentation/widgets/swipeable_item_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late ItemsRepository items;
  late ItemsProvider provider;
  late ExpensesProvider expenses;

  setUp(() {
    items = ItemsRepository(InMemoryStore());
    provider = ItemsProvider(repository: items);
    expenses = ExpensesProvider(
      repository: ExpensesRepository(InMemoryStore()),
    );
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await provider.load();
    await expenses.load();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ItemsProvider>.value(value: provider),
          ChangeNotifierProvider<ExpensesProvider>.value(value: expenses),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: HomeScreen(onOpenSearch: () {}, onOpenReminders: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reads zero and says nothing is saved yet', (tester) async {
    await pumpDashboard(tester);

    expect(find.textContaining('Nothing saved yet'), findsOneWidget);
    // Items saved and expiring soon both read zero.
    expect(find.widgetWithText(SummaryCard, '0'), findsNWidgets(2));
  });

  testWidgets('a saved item fills the dashboard', (tester) async {
    await pumpDashboard(tester);

    await provider.add(
      BillItem(
        id: 'i_1',
        title: 'Split AC',
        category: 'Appliances',
        kind: ItemKind.bill,
        savedAt: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 5)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing saved yet'), findsNothing);
    expect(find.text('Split AC'), findsOneWidget);
    // The row swipes right to edit and left to delete.
    expect(find.byType(SwipeableItemRow), findsOneWidget);
    expect(find.text('5 days'), findsOneWidget);
    // One saved, one expiring soon.
    expect(find.widgetWithText(SummaryCard, '1'), findsNWidgets(2));
  });

  testWidgets('the spending card shows the month and opens the calendar', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(
      find.widgetWithText(SpendingCard, 'Nothing logged yet — tap to add'),
      findsOneWidget,
    );

    await expenses.add(
      Expense(
        id: 'e_1',
        amount: 840,
        category: 'Groceries',
        date: dayOf(DateTime.now()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SpendingCard, '₹840'), findsOneWidget);
    expect(find.textContaining('today ₹840'), findsOneWidget);

    await tester.tap(find.byType(SpendingCard));
    await tester.pumpAndSettle();

    expect(find.byType(ExpensesScreen), findsOneWidget);
  });
}
