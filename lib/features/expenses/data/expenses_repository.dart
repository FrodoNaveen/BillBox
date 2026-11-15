import 'dart:convert';

import '../../../core/storage/key_value_store.dart';
import 'expense.dart';

/// The logged expenses, as one JSON list in local storage.
class ExpensesRepository {
  ExpensesRepository(this._store);

  static const String expensesKey = 'billbox.expenses';

  final KeyValueStore _store;

  /// Most recent day first, and within a day the largest amount first.
  Future<List<Expense>> readAll() async {
    final raw = await _store.read(expensesKey);
    if (raw == null || raw.isEmpty) return <Expense>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Expense>[];
      final expenses = decoded
          .whereType<Map>()
          .map((e) => Expense.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      expenses.sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.amount.compareTo(a.amount);
      });
      return expenses;
    } on FormatException {
      return <Expense>[];
    }
  }

  Future<void> writeAll(List<Expense> expenses) => _store.write(
    expensesKey,
    jsonEncode(expenses.map((expense) => expense.toJson()).toList()),
  );

  Future<List<Expense>> add(Expense expense) async {
    final next = <Expense>[expense, ...await readAll()];
    await writeAll(next);
    return readAll();
  }

  Future<List<Expense>> update(Expense expense) async {
    final expenses = await readAll();
    final index = expenses.indexWhere((saved) => saved.id == expense.id);
    if (index < 0) return expenses;
    final next = <Expense>[...expenses]..[index] = expense;
    await writeAll(next);
    return readAll();
  }

  Future<List<Expense>> delete(String id) async {
    final next = (await readAll()).where((e) => e.id != id).toList();
    await writeAll(next);
    return next;
  }
}
