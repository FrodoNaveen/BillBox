import '../../../core/utils/formatting.dart';
import 'expense.dart';

/// Totals the dashboard card and the calendar read.
///
/// All pure functions over a list of expenses: no storage, no widgets, so the
/// arithmetic can be read and tested on its own.

/// One category's share of a day or a month.
class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.total,
    required this.count,
  });

  final String category;
  final double total;
  final int count;
}

/// One day's total, for the seven-day bars on the dashboard.
class DayTotal {
  const DayTotal({required this.day, required this.total});

  final DateTime day;
  final double total;
}

List<Expense> expensesOn(List<Expense> expenses, DateTime day) {
  final wanted = dayOf(day);
  return expenses.where((e) => e.date == wanted).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
}

double totalOn(List<Expense> expenses, DateTime day) =>
    _sum(expensesOn(expenses, day));

List<Expense> expensesInMonth(List<Expense> expenses, DateTime month) {
  return expenses
      .where((e) => e.date.year == month.year && e.date.month == month.month)
      .toList();
}

double totalInMonth(List<Expense> expenses, DateTime month) =>
    _sum(expensesInMonth(expenses, month));

/// Day -> total, for every day of [month] that has spending. The calendar
/// sizes its dots from this.
Map<DateTime, double> dailyTotals(List<Expense> expenses, DateTime month) {
  final totals = <DateTime, double>{};
  for (final expense in expensesInMonth(expenses, month)) {
    totals.update(
      expense.date,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
  }
  return totals;
}

/// Where the money went, largest first.
List<CategoryTotal> byCategory(List<Expense> expenses) {
  final totals = <String, CategoryTotal>{};
  for (final expense in expenses) {
    final current = totals[expense.category];
    totals[expense.category] = CategoryTotal(
      category: expense.category,
      total: (current?.total ?? 0) + expense.amount,
      count: (current?.count ?? 0) + 1,
    );
  }
  final list = totals.values.toList()
    ..sort((a, b) => b.total.compareTo(a.total));
  return list;
}

/// The last seven days ending today, oldest first, with zeroes for the days
/// nothing was spent — the bars need a slot for every day.
List<DayTotal> lastSevenDays(List<Expense> expenses, {DateTime? today}) {
  final end = dayOf(today ?? DateTime.now());
  return <DayTotal>[
    for (int back = 6; back >= 0; back--)
      () {
        final day = end.subtract(Duration(days: back));
        return DayTotal(day: day, total: totalOn(expenses, day));
      }(),
  ];
}

double _sum(List<Expense> expenses) =>
    expenses.fold<double>(0, (running, e) => running + e.amount);
