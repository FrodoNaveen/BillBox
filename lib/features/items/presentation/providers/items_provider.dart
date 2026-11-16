import 'package:flutter/foundation.dart';

import '../../../home/data/home_sample_data.dart';
import '../../../search/data/search_sample_data.dart';
import '../../data/bill_item.dart';
import '../../data/item_category_catalog.dart';
import '../../data/items_repository.dart';

/// The saved items, plus the shapes the dashboard and search read.
///
/// Nothing is stood in: until the first item is saved every list here is
/// empty and every count is zero, which is what the screens show.
class ItemsProvider extends ChangeNotifier {
  ItemsProvider({required ItemsRepository repository})
    : _repository = repository;

  final ItemsRepository _repository;

  List<BillItem> _items = <BillItem>[];
  bool _isLoaded = false;

  /// What has actually been saved, newest first.
  List<BillItem> get items => List<BillItem>.unmodifiable(_items);

  bool get isLoaded => _isLoaded;

  bool get isEmpty => _items.isEmpty;

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

  /// The item behind a row; null once it has been deleted.
  BillItem? itemById(String? id) {
    if (id == null) return null;
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  int get savedCount => _items.length;

  /// Anything due within a month, which is what the dashboard counts.
  int get expiringSoonCount => _items.where((item) {
    final days = item.daysLeft();
    return days != null && days <= 30;
  }).length;

  /// The soonest three items that have a date, for "Expiring soon".
  List<ExpiringItem> get expiringItems {
    final dated = _items.where((item) => item.expiryDate != null).toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    return dated.take(3).map((item) => item.toExpiringItem()).toList();
  }

  /// Every category with how many items sit in it.
  List<ItemCategory> get categories => <ItemCategory>[
    for (final name in itemCategories)
      ItemCategory(
        name: name,
        icon: iconForCategory(name),
        count: _items.where((item) => item.category == name).length,
      ),
  ];

  List<SearchableItem> get searchItems =>
      _items.map((item) => item.toSearchableItem()).toList();
}
