import 'package:flutter/foundation.dart';

import '../../data/expense.dart';
import '../../data/expense_summary.dart';
import '../../data/expenses_repository.dart';

/// Holds the logged expenses and the totals the dashboard and calendar show.
///
/// Nothing is stood in: an empty month is a true, and useful, answer.
class ExpensesProvider extends ChangeNotifier {
  ExpensesProvider({required ExpensesRepository repository})
    : _repository = repository;

  final ExpensesRepository _repository;

  List<Expense> _expenses = <Expense>[];
  bool _isLoaded = false;

  List<Expense> get expenses => List<Expense>.unmodifiable(_expenses);

  bool get isLoaded => _isLoaded;

  bool get isEmpty => _expenses.isEmpty;

  Future<void> load() async {
    _expenses = await _repository.readAll();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> add(Expense expense) async {
    _expenses = await _repository.add(expense);
    notifyListeners();
  }

  Future<void> edit(Expense expense) async {
    _expenses = await _repository.update(expense);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _expenses = await _repository.delete(id);
    notifyListeners();
  }

  /// The expense logged from a captured bill, if the user asked for one.
  Expense? expenseForItem(String itemId) {
    for (final expense in _expenses) {
      if (expense.linkedItemId == itemId) return expense;
    }
    return null;
  }

  double totalOnDay(DateTime day) => totalOn(_expenses, day);

  double totalThisMonth({DateTime? now}) =>
      totalInMonth(_expenses, now ?? DateTime.now());

  double totalForMonth(DateTime month) => totalInMonth(_expenses, month);

  List<Expense> onDay(DateTime day) => expensesOn(_expenses, day);

  List<CategoryTotal> categoriesOnDay(DateTime day) =>
      byCategory(expensesOn(_expenses, day));

  List<CategoryTotal> categoriesInMonth(DateTime month) =>
      byCategory(expensesInMonth(_expenses, month));

  Map<DateTime, double> dailyTotalsFor(DateTime month) =>
      dailyTotals(_expenses, month);

  List<DayTotal> get lastSevenDaysSpend => lastSevenDays(_expenses);
}
