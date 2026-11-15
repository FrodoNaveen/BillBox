import 'dart:convert';

import '../../items/data/bill_item.dart';

/// Builds the export the settings tab puts on the clipboard.
///
/// A clipboard copy is all v1 can offer — writing a file needs a plugin that
/// is not in the project yet — but the shape below is the one a file export
/// will use, so nothing about the format has to change later.
String buildExportJson({
  required List<BillItem> items,
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
          'kind': item.kind.name,
          'date': item.dateLabel(),
          'expiryDate': item.expiryDate?.toIso8601String(),
          'purchaseDate': item.purchaseDate?.toIso8601String(),
          'amount': item.amount,
          'store': item.store,
          'scannedText': item.scannedText,
        },
    ],
  };

  return const JsonEncoder.withIndent('  ').convert(payload);
}
