import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/core/theme/app_theme.dart';
import 'package:billbox/core/utils/formatting.dart';
import 'package:billbox/features/expenses/data/expense.dart';
import 'package:billbox/features/expenses/data/expenses_repository.dart';
import 'package:billbox/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:billbox/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:billbox/features/expenses/presentation/widgets/expense_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late ExpensesRepository repository;
  late ExpensesProvider provider;

  final today = dayOf(DateTime.now());

  /// Another day in the same month, so the test works whatever today is.
  final otherDay = today.day == 1
      ? DateTime(today.year, today.month, 2)
      : DateTime(today.year, today.month, 1);

  /// A day in the month with nothing on it.
  final quietDay = DateTime(
    today.year,
    today.month,
    List<int>.generate(
      28,
      (i) => i + 1,
    ).firstWhere((d) => d != today.day && d != otherDay.day),
  );

  setUp(() {
    repository = ExpensesRepository(InMemoryStore());
    provider = ExpensesProvider(repository: repository);
  });

  Future<void> seed() async {
    await provider.load();
    await provider.add(
      Expense(id: 'a', amount: 520, category: 'Groceries', date: today),
    );
    await provider.add(
      Expense(
        id: 'b',
        amount: 320,
        category: 'Travel',
        date: today,
        note: 'Auto to station',
      ),
    );
    await provider.add(
      Expense(id: 'c', amount: 1000, category: 'Bills', date: otherDay),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    // Phone width, but taller than a phone: the screen is a ListView, so a
    // tall surface puts the calendar and the day's rows on screen together
    // instead of every assertion having to scroll.
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider<ExpensesProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ExpensesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on today with the month total and the breakdown', (
    tester,
  ) async {
    await seed();
    await pumpScreen(tester);

    expect(find.text(formatMonthYear(today)), findsNWidgets(2));
    expect(find.text('₹1,840'), findsOneWidget); // the month
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('₹840'), findsOneWidget); // the day
    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('62%'), findsOneWidget);
    expect(find.text('38%'), findsOneWidget);
    expect(find.byType(ExpenseRow), findsNWidgets(2));
    expect(find.text('Auto to station'), findsOneWidget);
  });

  testWidgets('picking another day shows what was spent on it', (tester) async {
    await seed();
    await pumpScreen(tester);

    await tester.tap(find.text('${otherDay.day}'));
    await tester.pumpAndSettle();

    expect(find.text('₹1,000'), findsWidgets);
    expect(find.text(formatItemDate(otherDay)), findsOneWidget);
    expect(find.byType(ExpenseRow), findsOneWidget);
    expect(find.text('Auto to station'), findsNothing);
  });

  testWidgets('a day with nothing on it says so', (tester) async {
    await seed();
    await pumpScreen(tester);

    await tester.tap(find.text('${quietDay.day}'));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseRow), findsNothing);
    expect(find.textContaining('Nothing'), findsOneWidget);
  });

  testWidgets('an expense can be logged from the screen', (tester) async {
    await seed();
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add expense'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '200');
    await tester.tap(find.text('Food'));
    await tester.enterText(find.byType(TextFormField).at(1), 'Tea and snacks');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(provider.totalOnDay(today), 1040);
    expect(find.text('₹1,040'), findsOneWidget);
    expect(find.text('Tea and snacks'), findsOneWidget);
    expect(find.byType(ExpenseRow), findsNWidgets(3));
  });

  testWidgets('nothing is logged without an amount', (tester) async {
    await provider.load();
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Enter how much you spent'), findsOneWidget);
    expect(provider.isEmpty, isTrue);
  });

  testWidgets('tapping a row edits it, and it can be deleted', (tester) async {
    await seed();
    await pumpScreen(tester);

    await tester.tap(find.text('Auto to station'));
    await tester.pumpAndSettle();
    expect(find.text('Edit expense'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '400');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(provider.totalOnDay(today), 920);

    await tester.tap(find.text('Auto to station'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete expense'));
    await tester.pumpAndSettle();

    expect(provider.onDay(today), hasLength(1));
    expect(find.text('Auto to station'), findsNothing);
  });

  testWidgets('the month can be paged back and forward', (tester) async {
    await seed();
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();

    // Both the month card and the calendar header name the month.
    final previous = DateTime(today.year, today.month - 1);
    expect(find.text(formatMonthYear(previous)), findsNWidgets(2));
    expect(find.byType(ExpenseRow), findsNothing);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();

    expect(find.text(formatMonthYear(today)), findsNWidgets(2));
  });

  testWidgets('lays out on a real phone surface without overflowing', (
    tester,
  ) async {
    await seed();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider<ExpensesProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ExpensesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The calendar and the month card fit above the fold; the rest scrolls.
    expect(find.text('₹1,840'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseRow), findsNWidgets(2));
  });
}
