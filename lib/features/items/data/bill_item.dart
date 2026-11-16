import 'package:flutter/material.dart';

import '../../home/data/home_sample_data.dart';
import '../../search/data/search_sample_data.dart';
import 'item_category_catalog.dart';
import '../../../core/utils/formatting.dart';

/// What was captured: a bill with a warranty, or a document that expires.
/// It only changes the wording and which date is asked for.
enum ItemKind {
  bill('Bill', 'Warranty ends', 'Warranty'),
  document('Document', 'Expires on', 'Expires');

  const ItemKind(this.label, this.dateFieldLabel, this.datePrefix);

  final String label;

  /// Label over the expiry date field on the add-item form.
  final String dateFieldLabel;

  /// How the date reads on a list row: "Warranty 20 Nov 2026".
  final String datePrefix;
}

/// One saved bill, warranty or document.
///
/// Everything except [id], [title], [category] and [kind] is optional: a photo
/// may be unreadable, and the form lets any field be left blank.
class BillItem {
  const BillItem({
    required this.id,
    required this.title,
    required this.category,
    required this.kind,
    required this.savedAt,
    this.store,
    this.amount,
    this.purchaseDate,
    this.expiryDate,
    this.scannedText = '',
    this.reminderLeadDays = const <int>{},
    this.imageName,
  });

  final String id;
  final String title;
  final String category;
  final ItemKind kind;
  final DateTime savedAt;

  final String? store;
  final double? amount;
  final DateTime? purchaseDate;

  /// When the warranty runs out, or the document expires.
  final DateTime? expiryDate;

  /// The text read from the photo, which search looks inside.
  final String scannedText;

  /// How many days before [expiryDate] to be nudged.
  final Set<int> reminderLeadDays;

  /// File name of the photo kept on the device, when there is one.
  final String? imageName;

  IconData get icon => iconForCategory(category);

  /// Days until [expiryDate]; null when the item has no date. Negative once
  /// the date has passed.
  int? daysLeft({DateTime? now}) {
    final date = expiryDate;
    if (date == null) return null;
    return daysBetween(now ?? DateTime.now(), date);
  }

  /// "Warranty 20 Nov 2026", or the store when there is no date at all.
  String dateLabel({DateTime? now}) {
    final date = expiryDate;
    if (date == null) {
      return store?.trim().isNotEmpty == true ? store! : 'No date saved';
    }
    return '${kind.datePrefix} ${formatItemDate(date)}';
  }

  ExpiryUrgency get urgency {
    final days = daysLeft();
    return days != null && days <= 7
        ? ExpiryUrgency.urgent
        : ExpiryUrgency.soon;
  }

  /// The dashboard row for this item.
  ExpiringItem toExpiringItem({DateTime? now}) {
    final days = daysLeft(now: now) ?? 0;
    return ExpiringItem(
      itemId: id,
      title: title,
      subtitle: dateLabel(now: now),
      icon: icon,
      daysLeft: days,
      urgency: days <= 7 ? ExpiryUrgency.urgent : ExpiryUrgency.soon,
    );
  }

  /// The search result row for this item. Items with no date sort last, which
  /// is what a very large number of days left gives.
  SearchableItem toSearchableItem({DateTime? now}) {
    return SearchableItem(
      itemId: id,
      title: title,
      category: category,
      dateLabel: dateLabel(now: now),
      scannedText: scannedText.isEmpty
          ? [
              if (store != null) store!,
              if (amount != null) formatRupees(amount!),
            ].join(' · ')
          : scannedText,
      daysLeft: daysLeft(now: now) ?? 100000,
      icon: icon,
    );
  }

  BillItem copyWith({
    String? title,
    String? category,
    ItemKind? kind,
    String? store,
    double? amount,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? scannedText,
    Set<int>? reminderLeadDays,
    String? imageName,
  }) {
    return BillItem(
      id: id,
      savedAt: savedAt,
      title: title ?? this.title,
      category: category ?? this.category,
      kind: kind ?? this.kind,
      store: store ?? this.store,
      amount: amount ?? this.amount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      scannedText: scannedText ?? this.scannedText,
      reminderLeadDays: reminderLeadDays ?? this.reminderLeadDays,
      imageName: imageName ?? this.imageName,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'category': category,
    'kind': kind.name,
    'savedAt': savedAt.toIso8601String(),
    'store': store,
    'amount': amount,
    'purchaseDate': purchaseDate?.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'scannedText': scannedText,
    'reminderLeadDays': reminderLeadDays.toList(),
    'imageName': imageName,
  };

  /// Anything unreadable falls back rather than throwing: one bad row must not
  /// cost the user every other item.
  factory BillItem.fromJson(Map<String, dynamic> json) {
    final days = json['reminderLeadDays'];
    return BillItem(
      id: json['id'] as String? ?? 'i_${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Untitled item',
      category: normaliseCategory(json['category'] as String?),
      kind: ItemKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => ItemKind.bill,
      ),
      savedAt: _date(json['savedAt']) ?? DateTime.now(),
      store: json['store'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      purchaseDate: _date(json['purchaseDate']),
      expiryDate: _date(json['expiryDate']),
      scannedText: json['scannedText'] as String? ?? '',
      reminderLeadDays: days is List
          ? days.whereType<num>().map((d) => d.toInt()).toSet()
          : const <int>{},
      imageName: json['imageName'] as String?,
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
