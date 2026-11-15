import 'package:flutter/material.dart';

/// Stand-in dashboard data.
///
/// The items feature does not exist yet, so the home screen reads these
/// constants instead of a repository. The widgets only ever see these models,
/// so wiring a real data source later is a change in this file alone.

/// How close an item is to its expiry date, which picks the badge colour.
enum ExpiryUrgency { urgent, soon }

class ExpiringItem {
  const ExpiringItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.daysLeft,
    required this.urgency,
  });

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

const int sampleSavedItems = 12;
const int sampleExpiringSoon = 3;

const List<ExpiringItem> sampleExpiringItems = <ExpiringItem>[
  ExpiringItem(
    title: 'Samsung 1.5T Split AC',
    subtitle: 'Warranty ends 20 Nov 2026',
    icon: Icons.ac_unit_rounded,
    daysLeft: 6,
    urgency: ExpiryUrgency.urgent,
  ),
  ExpiringItem(
    title: 'Two-wheeler insurance',
    subtitle: 'Renewal due 5 Dec 2026',
    icon: Icons.shield_outlined,
    daysLeft: 21,
    urgency: ExpiryUrgency.soon,
  ),
];

const List<ItemCategory> sampleCategories = <ItemCategory>[
  ItemCategory(
    name: 'Electronics',
    icon: Icons.desktop_windows_outlined,
    count: 4,
  ),
  ItemCategory(name: 'Appliances', icon: Icons.kitchen_outlined, count: 3),
  ItemCategory(name: 'Vehicle', icon: Icons.directions_car_outlined, count: 2),
  ItemCategory(name: 'Identity', icon: Icons.badge_outlined, count: 5),
  ItemCategory(name: 'Insurance', icon: Icons.shield_outlined, count: 2),
  ItemCategory(name: 'Home / Rent', icon: Icons.home_work_outlined, count: 1),
];
