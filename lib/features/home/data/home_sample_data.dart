import 'package:flutter/material.dart';

/// What the dashboard widgets are handed.
///
/// These are view models, not data: [ItemsProvider] builds them from the
/// saved items, so the tiles never need to know where a row came from.

/// How close an item is to its expiry date, which picks the badge colour.
enum ExpiryUrgency { urgent, soon }

class ExpiringItem {
  const ExpiringItem({
    required this.title,
    this.itemId,
    required this.subtitle,
    required this.icon,
    required this.daysLeft,
    required this.urgency,
  });

  /// The item this row stands for, so tapping it can open the detail screen.
  final String? itemId;

  final String title;
  final String subtitle;
  final IconData icon;
  final int daysLeft;
  final ExpiryUrgency urgency;
}

class ItemCategory {
  const ItemCategory({
    required this.name,
    required this.icon,
    required this.count,
  });

  final String name;
  final IconData icon;
  final int count;
}
