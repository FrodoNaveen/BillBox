import 'package:flutter/material.dart';

import '../../../core/utils/formatting.dart';

/// What everyday spending is filed under. Deliberately not the item
/// categories: nobody files lunch under "Appliances".
const List<String> expenseCategories = <String>[
  'Food',
  'Groceries',
  'Travel',
  'Bills',
  'Health',
  'Shopping',
  'Other',
];

const String fallbackExpenseCategory = 'Other';

const Map<String, IconData> _expenseIcons = <String, IconData>{
  'Food': Icons.restaurant_outlined,
  'Groceries': Icons.shopping_basket_outlined,
  'Travel': Icons.directions_bus_outlined,
  'Bills': Icons.receipt_long_outlined,
  'Health': Icons.medical_services_outlined,
  'Shopping': Icons.shopping_bag_outlined,
  'Other': Icons.more_horiz_rounded,
};

IconData iconForExpenseCategory(String category) =>
    _expenseIcons[category] ?? _expenseIcons[fallbackExpenseCategory]!;

String normaliseExpenseCategory(String? category) {
  if (category == null) return fallbackExpenseCategory;
  for (final known in expenseCategories) {
    if (known.toLowerCase() == category.trim().toLowerCase()) return known;
  }
  return fallbackExpenseCategory;
}

/// One thing the user spent money on, on one day.
class Expense {
  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required DateTime date,
    this.note,
    this.linkedItemId,
  }) : date = dayOf(date);

  final String id;
  final double amount;
  final String category;

  /// Always midnight: spending is tracked by day, not by minute.
  final DateTime date;

  /// What it was for — "Lunch at office", "Auto to station".
  final String? note;

  /// Set when the expense came from a captured bill, which is what lets the
  /// row show where it came from.
  final String? linkedItemId;

  bool get isFromBill => linkedItemId != null;

  IconData get icon => iconForExpenseCategory(category);

  /// The note if there is one, otherwise the category stands in as the label.
  String get label => note?.trim().isNotEmpty == true ? note!.trim() : category;

  Expense copyWith({
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    bool clearNote = false,
  }) {
    return Expense(
      id: id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
      linkedItemId: linkedItemId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'note': note,
    'linkedItemId': linkedItemId,
  };

  /// A row that cannot be read is patched rather than dropped, so one bad
  /// entry never costs the user the rest of the month.
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? 'e_${DateTime.now().microsecondsSinceEpoch}',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: normaliseExpenseCategory(json['category'] as String?),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String?,
      linkedItemId: json['linkedItemId'] as String?,
    );
  }
}

/// Which spending category a captured bill belongs in, when the user asks for
/// it to be logged. A rough map by design — they can change it afterwards.
String expenseCategoryForItemCategory(String itemCategory) {
  switch (itemCategory) {
    case 'Electronics':
    case 'Appliances':
      return 'Shopping';
    case 'Vehicle':
      return 'Travel';
    case 'Insurance':
    case 'Home / Rent':
      return 'Bills';
    default:
      return fallbackExpenseCategory;
  }
}
