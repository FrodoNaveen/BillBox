import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/core/utils/formatting.dart';
import 'package:billbox/features/expenses/data/expense.dart';
import 'package:billbox/features/expenses/data/expense_summary.dart';
import 'package:billbox/features/expenses/data/expenses_repository.dart';
import 'package:billbox/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day1 = DateTime(2026, 11, 15);
  final day2 = DateTime(2026, 11, 12);
  final lastMonth = DateTime(2026, 10, 30);

  Expense expense({
    required String id,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
    String? linkedItemId,
  }) {
    return Expense(
      id: id,
      amount: amount,
      category: category,
      date: date,
      note: note,
      linkedItemId: linkedItemId,
    );
  }

  final expenses = <Expense>[
    expense(id: 'a', amount: 520, category: 'Groceries', date: day1),
    expense(
      id: 'b',
      amount: 320,
      category: 'Travel',
      date: DateTime(2026, 11, 15, 22, 30),
      note: 'Auto to station',
    ),
    expense(id: 'c', amount: 1000, category: 'Bills', date: day2),
    expense(id: 'd', amount: 90, category: 'Food', date: lastMonth),
  ];

  group('Expense', () {
    test('the time of day is dropped — spending is tracked by day', () {
      expect(expenses[1].date, DateTime(2026, 11, 15));
    });

    test('the note stands in as the label, else the category', () {
      expect(expenses[1].label, 'Auto to station');
      expect(expenses[0].label, 'Groceries');
    });

    test('json survives a round trip', () {
      final restored = Expense.fromJson(
        expense(
          id: 'z',
          amount: 39699,
          category: 'Shopping',
          date: day1,
          note: 'Split AC',
          linkedItemId: 'i_1',
        ).toJson(),
      );

      expect(restored.id, 'z');
      expect(restored.amount, 39699);
      expect(restored.category, 'Shopping');
      expect(restored.date, day1);
      expect(restored.note, 'Split AC');
      expect(restored.isFromBill, isTrue);
    });

    test('an unreadable row is patched, not dropped', () {
      final restored = Expense.fromJson(<String, dynamic>{
        'id': 'e_9',
        'category': 'Yachts',
        'date': 'not a date',
      });

      expect(restored.amount, 0);
      expect(restored.category, fallbackExpenseCategory);
      expect(restored.isFromBill, isFalse);
    });

    test('a captured bill lands in a sensible spending category', () {
      expect(expenseCategoryForItemCategory('Appliances'), 'Shopping');
      expect(expenseCategoryForItemCategory('Vehicle'), 'Travel');
      expect(expenseCategoryForItemCategory('Insurance'), 'Bills');
      expect(expenseCategoryForItemCategory('Identity'), 'Other');
    });
  });

  group('summaries', () {
    test('a day totals only that day, whatever the time', () {
      expect(totalOn(expenses, day1), 840);
      expect(totalOn(expenses, DateTime(2026, 11, 15, 6)), 840);
      expect(totalOn(expenses, DateTime(2026, 11, 13)), 0);
    });

    test('a month leaves out the neighbouring months', () {
      expect(totalInMonth(expenses, DateTime(2026, 11, 1)), 1840);
      expect(totalInMonth(expenses, DateTime(2026, 10, 1)), 90);
    });

    test('daily totals key the calendar dots by day', () {
      final totals = dailyTotals(expenses, DateTime(2026, 11, 1));

      expect(totals, {day1: 840.0, day2: 1000.0});
    });

    test('a day breaks down by category, largest first', () {
      final breakdown = byCategory(expensesOn(expenses, day1));

      expect(breakdown.map((c) => c.category), ['Groceries', 'Travel']);
      expect(breakdown.first.total, 520);
      expect(breakdown.first.count, 1);
    });

    test('the day list is largest first', () {
      expect(expensesOn(expenses, day1).map((e) => e.id), ['a', 'b']);
    });

    test('seven days always has seven slots, zeroes included', () {
      final week = lastSevenDays(expenses, today: day1);

      expect(week, hasLength(7));
      expect(week.first.day, DateTime(2026, 11, 9));
      expect(week.last.day, day1);
      expect(week.last.total, 840);
      expect(week.map((d) => d.total).where((t) => t == 0), hasLength(5));
    });
  });

  group('ExpensesRepository', () {
    late InMemoryStore store;
    late ExpensesRepository repository;

    setUp(() {
      store = InMemoryStore();
      repository = ExpensesRepository(store);
    });

    test('newest day first, biggest amount first within a day', () async {
      for (final e in expenses) {
        await repository.add(e);
      }

      expect((await repository.readAll()).map((e) => e.id), [
        'a',
        'b',
        'c',
        'd',
      ]);
    });

    test('an expense can be edited and deleted', () async {
      await repository.add(expenses.first);

      await repository.update(
        expenses.first.copyWith(amount: 600, note: 'Weekly veg'),
      );
      final edited = (await repository.readAll()).single;
      expect(edited.amount, 600);
      expect(edited.note, 'Weekly veg');

      await repository.delete('a');
      expect(await repository.readAll(), isEmpty);
    });

    test('clearing a note is not mistaken for leaving it alone', () async {
      await repository.add(expenses[1]);

      await repository.update(expenses[1].copyWith(clearNote: true));

      expect((await repository.readAll()).single.note, isNull);
    });

    test('corrupt storage reads as nothing logged', () async {
      await store.write(ExpensesRepository.expensesKey, 'not json');

      expect(await repository.readAll(), isEmpty);
    });
  });

  group('ExpensesProvider', () {
    test('an empty month is reported as empty, never as samples', () async {
      final provider = ExpensesProvider(
        repository: ExpensesRepository(InMemoryStore()),
      );
      await provider.load();

      expect(provider.isEmpty, isTrue);
      expect(provider.totalThisMonth(), 0);
      expect(provider.lastSevenDaysSpend, hasLength(7));
    });

    test('adding an expense updates the day and the month', () async {
      final provider = ExpensesProvider(
        repository: ExpensesRepository(InMemoryStore()),
      );
      await provider.load();
      final today = dayOf(DateTime.now());

      await provider.add(
        expense(id: 'a', amount: 240, category: 'Food', date: today),
      );

      expect(provider.isEmpty, isFalse);
      expect(provider.totalOnDay(today), 240);
      expect(provider.totalThisMonth(), 240);
      expect(provider.onDay(today).single.id, 'a');
      expect(provider.categoriesOnDay(today).single.category, 'Food');
      expect(provider.dailyTotalsFor(today)[today], 240);
    });

    test('removing it empties the day again', () async {
      final provider = ExpensesProvider(
        repository: ExpensesRepository(InMemoryStore()),
      );
      await provider.load();
      final today = dayOf(DateTime.now());
      await provider.add(
        expense(id: 'a', amount: 240, category: 'Food', date: today),
      );

      await provider.remove('a');

      expect(provider.isEmpty, isTrue);
      expect(provider.totalOnDay(today), 0);
    });
  });

  group('calendar helpers', () {
    test('a month knows its length and where the 1st sits', () {
      expect(daysInMonth(DateTime(2026, 11)), 30);
      expect(daysInMonth(DateTime(2026, 2)), 28);
      expect(daysInMonth(DateTime(2028, 2)), 29);
      // 1 Nov 2026 is a Sunday, so a Monday-first grid needs 6 blanks.
      expect(leadingBlanks(DateTime(2026, 11)), 6);
      expect(formatMonthYear(DateTime(2026, 11)), 'November 2026');
    });

    test('days near today read in words', () {
      final today = DateTime(2026, 11, 15);

      expect(formatRelativeDay(today, now: today), 'Today');
      expect(
        formatRelativeDay(DateTime(2026, 11, 14), now: today),
        'Yesterday',
      );
      expect(
        formatRelativeDay(DateTime(2026, 11, 10), now: today),
        '10 Nov 2026',
      );
    });
  });
}
