import 'package:flutter/material.dart';

/// The categories BillBox sorts everything into, in the order the dashboard
/// grid and the filter chips show them. One list so the capture form, the
/// dashboard and search can never drift apart.
const List<String> itemCategories = <String>[
  'Electronics',
  'Appliances',
  'Vehicle',
  'Identity',
  'Insurance',
  'Home / Rent',
];

const String fallbackCategory = 'Electronics';

const Map<String, IconData> _categoryIcons = <String, IconData>{
  'Electronics': Icons.desktop_windows_outlined,
  'Appliances': Icons.kitchen_outlined,
  'Vehicle': Icons.directions_car_outlined,
  'Identity': Icons.badge_outlined,
  'Insurance': Icons.shield_outlined,
  'Home / Rent': Icons.home_work_outlined,
};

IconData iconForCategory(String category) =>
    _categoryIcons[category] ?? Icons.receipt_long_outlined;

/// Keeps a category read from a photo — or from older storage — inside the
/// list above.
String normaliseCategory(String? category) {
  if (category == null) return fallbackCategory;
  for (final known in itemCategories) {
    if (known.toLowerCase() == category.trim().toLowerCase()) return known;
  }
  return fallbackCategory;
}
