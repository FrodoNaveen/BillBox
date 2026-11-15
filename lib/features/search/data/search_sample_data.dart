import 'package:flutter/material.dart';

/// Stand-in catalogue for the search tab.
///
/// The items feature does not exist yet, so search reads these constants
/// instead of a repository. [scannedText] is the stand-in for the OCR text
/// kept with each photo, which is what makes searching "inside" a bill work.
/// Swapping in a real data source is a change in this file alone.

/// How close an item is to its date, which picks the badge colour.
enum ExpiryBand { urgent, soon, later }

class SearchableItem {
  const SearchableItem({
    required this.title,
    required this.category,
    required this.dateLabel,
    required this.scannedText,
    required this.daysLeft,
    required this.icon,
  });

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

/// Chip order on the filter bar. Kept the same as the dashboard grid.
const List<String> searchCategories = <String>[
  'Electronics',
  'Appliances',
  'Vehicle',
  'Identity',
  'Insurance',
  'Home / Rent',
];

const List<SearchableItem> sampleSearchItems = <SearchableItem>[
  SearchableItem(
    title: 'Samsung 1.5T Split AC',
    category: 'Appliances',
    dateLabel: 'Warranty 20 Nov 2026',
    scannedText: 'Extended insurance plan not opted',
    daysLeft: 6,
    icon: Icons.ac_unit_rounded,
  ),
  SearchableItem(
    title: 'Water purifier AMC',
    category: 'Appliances',
    dateLabel: 'Service due 22 Nov 2026',
    scannedText: 'AMC 2 services remaining, ticket 7781',
    daysLeft: 7,
    icon: Icons.water_drop_outlined,
  ),
  SearchableItem(
    title: 'Flat rental agreement',
    category: 'Home / Rent',
    dateLabel: 'Ends 30 Nov 2026',
    scannedText: 'Rent 18,500 per month, deposit 1,00,000, 11 months',
    daysLeft: 15,
    icon: Icons.home_work_outlined,
  ),
  SearchableItem(
    title: 'Two-wheeler insurance',
    category: 'Insurance',
    dateLabel: 'Renewal 5 Dec 2026',
    scannedText: 'Policy no. 4471, insured declared value 62,400',
    daysLeft: 21,
    icon: Icons.shield_outlined,
  ),
  SearchableItem(
    title: 'MacBook Air M2',
    category: 'Electronics',
    dateLabel: 'Warranty 2 Jan 2027',
    scannedText: 'Serial C02XK, AppleCare cover till Jan 2027',
    daysLeft: 48,
    icon: Icons.laptop_mac_rounded,
  ),
  SearchableItem(
    title: 'Family health insurance',
    category: 'Insurance',
    dateLabel: 'Renewal 18 Mar 2027',
    scannedText: 'Sum insured 5,00,000, floater plan',
    daysLeft: 124,
    icon: Icons.health_and_safety_outlined,
  ),
  SearchableItem(
    title: 'LG 190L refrigerator',
    category: 'Appliances',
    dateLabel: 'Warranty 12 Aug 2027',
    scannedText: 'Invoice 8821, compressor cover 10 years',
    daysLeft: 270,
    icon: Icons.kitchen_outlined,
  ),
  SearchableItem(
    title: 'Honda Activa registration',
    category: 'Vehicle',
    dateLabel: 'Fitness due 14 Jun 2028',
    scannedText: 'Registration TN 22, chassis ME4JF501',
    daysLeft: 941,
    icon: Icons.two_wheeler_outlined,
  ),
  SearchableItem(
    title: 'Passport',
    category: 'Identity',
    dateLabel: 'Expires 3 Feb 2031',
    scannedText: 'Passport no. Z21, place of issue Chennai',
    daysLeft: 1541,
    icon: Icons.badge_outlined,
  ),
];
