import 'dart:convert';

import '../../search/data/search_sample_data.dart';

/// Builds the export the settings tab puts on the clipboard.
///
/// A clipboard copy is all v1 can offer — writing a file needs a plugin that
/// is not in the project yet — but the shape below is the one a file export
/// will use, so nothing about the format has to change later.
String buildExportJson({
  required List<SearchableItem> items,
  required DateTime at,
  String? accountEmail,
}) {
  final payload = <String, dynamic>{
    'app': 'BillBox',
    'exportedAt': at.toIso8601String(),
    if (accountEmail != null) 'account': accountEmail,
    'itemCount': items.length,
    'items': [
      for (final item in items)
        <String, dynamic>{
          'title': item.title,
          'category': item.category,
          'date': item.dateLabel,
          'daysLeft': item.daysLeft,
          'scannedText': item.scannedText,
        },
    ],
  };

  return const JsonEncoder.withIndent('  ').convert(payload);
}
