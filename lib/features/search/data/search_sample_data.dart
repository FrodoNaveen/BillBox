import 'package:flutter/material.dart';

/// What the search tab's rows are handed.
///
/// A view model, not data: [ItemsProvider] builds these from the saved items,
/// or from the sample catalogue while nothing is saved. [scannedText] is the
/// text read from the photo, which is what makes searching "inside" a bill
/// work.

/// How close an item is to its date, which picks the badge colour.
enum ExpiryBand { urgent, soon, later }

class SearchableItem {
  const SearchableItem({
    required this.title,
    this.itemId,
    required this.category,
    required this.dateLabel,
    required this.scannedText,
    required this.daysLeft,
    required this.icon,
  });

  /// The item this row stands for, so tapping it can open the detail screen.
  final String? itemId;

  final String title;
  final String category;

  /// What the date means, spelled out: "Warranty 20 Nov 2026".
  final String dateLabel;

  /// A line of the text read from the photo, shown as the match snippet.
  final String scannedText;

  final int daysLeft;
  final IconData icon;

  ExpiryBand get band {
    if (daysLeft <= 7) return ExpiryBand.urgent;
    if (daysLeft <= 30) return ExpiryBand.soon;
    return ExpiryBand.later;
  }
}
