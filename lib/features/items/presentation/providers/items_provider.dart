import 'package:flutter/foundation.dart';

import '../../../home/data/home_sample_data.dart';
import '../../../search/data/search_sample_data.dart';
import '../../data/bill_item.dart';
import '../../data/item_category_catalog.dart';
import '../../data/items_repository.dart';
import '../../data/sample_items.dart';

/// The saved items, plus the shapes the dashboard and search read.
///
/// Until the first item is saved there is nothing to show, so everything here
/// falls back to [sampleBillItems] and [isShowingSamples] is true — the
/// dashboard says so out loud rather than passing samples off as real.
class ItemsProvider extends ChangeNotifier {
  ItemsProvider({required ItemsRepository repository})
    : _repository = repository;

  final ItemsRepository _repository;

  List<BillItem> _items = <BillItem>[];
  bool _isLoaded = false;

  /// What has actually been saved, newest first.
  List<BillItem> get items => List<BillItem>.unmodifiable(_items);

  bool get isLoaded => _isLoaded;

  bool get isShowingSamples => _items.isEmpty;

  /// What every screen should show: the saved items, or the samples.
  List<BillItem> get visibleItems => _items.isEmpty ? sampleBillItems : items;

  Future<void> load() async {
    _items = await _repository.readAll();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> add(BillItem item) async {
    _items = await _repository.add(item);
    notifyListeners();
  }

  Future<void> edit(BillItem item) async {
    _items = await _repository.update(item);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items = await _repository.delete(id);
    notifyListeners();
  }

  /// The item behind a row, saved or sample; null once it has been deleted.
  BillItem? itemById(String? id) {
    if (id == null) return null;
    for (final item in visibleItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  int get savedCount => visibleItems.length;

  /// Anything due within a month, which is what the dashboard counts.
  int get expiringSoonCount => visibleItems.where((item) {
    final days = item.daysLeft();
    return days != null && days <= 30;
  }).length;

  /// The soonest three items that have a date, for "Expiring soon".
  List<ExpiringItem> get expiringItems {
    final dated = visibleItems.where((item) => item.expiryDate != null).toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    return dated.take(3).map((item) => item.toExpiringItem()).toList();
  }

  /// Every category with how many items sit in it.
  List<ItemCategory> get categories => <ItemCategory>[
    for (final name in itemCategories)
      ItemCategory(
        name: name,
        icon: iconForCategory(name),
        count: visibleItems.where((item) => item.category == name).length,
      ),
  ];

  List<SearchableItem> get searchItems =>
      visibleItems.map((item) => item.toSearchableItem()).toList();
}
