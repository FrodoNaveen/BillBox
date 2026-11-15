import 'dart:convert';

import '../../../core/storage/key_value_store.dart';
import 'bill_item.dart';

/// The saved items, as one JSON list in local storage.
///
/// Photos themselves are not handled here — the capture flow only keeps the
/// file name until there is a plugin to write the image with.
class ItemsRepository {
  ItemsRepository(this._store);

  static const String itemsKey = 'billbox.items';

  final KeyValueStore _store;

  /// Newest first. Rows that cannot be read are skipped, not fatal.
  Future<List<BillItem>> readAll() async {
    final raw = await _store.read(itemsKey);
    if (raw == null || raw.isEmpty) return <BillItem>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <BillItem>[];
      final items = decoded
          .whereType<Map>()
          .map((e) => BillItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return items;
    } on FormatException {
      return <BillItem>[];
    }
  }

  Future<void> writeAll(List<BillItem> items) => _store.write(
    itemsKey,
    jsonEncode(items.map((item) => item.toJson()).toList()),
  );

  Future<List<BillItem>> add(BillItem item) async {
    final items = await readAll();
    final next = <BillItem>[item, ...items];
    await writeAll(next);
    return next;
  }

  /// Replaces the item with the same id, or does nothing if it is gone.
  Future<List<BillItem>> update(BillItem item) async {
    final items = await readAll();
    final index = items.indexWhere((saved) => saved.id == item.id);
    if (index < 0) return items;
    final next = <BillItem>[...items]..[index] = item;
    await writeAll(next);
    return next;
  }

  Future<List<BillItem>> delete(String id) async {
    final items = await readAll();
    final next = items.where((item) => item.id != id).toList();
    await writeAll(next);
    return next;
  }
}
