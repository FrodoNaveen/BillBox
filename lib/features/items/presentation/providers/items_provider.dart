import 'package:flutter/foundation.dart';

import '../../../home/data/home_sample_data.dart';
import '../../../search/data/search_sample_data.dart';
import '../../data/bill_item.dart';
import '../../data/item_category_catalog.dart';
import '../../data/items_repository.dart';

/// The saved items, plus the shapes the dashboard and search already read.
///
/// Until the first item is saved there is nothing to show, so the view-model
/// getters fall back to the sample catalogue and [isShowingSamples] is true —
/// the dashboard says so out loud rather than passing samples off as real.
class ItemsProvider extends ChangeNotifier {
  ItemsProvider({required ItemsRepository repository})
    : _repository = repository;

  final ItemsRepository _repository;

  List<BillItem> _items = <BillItem>[];
  bool _isLoaded = false;

  /// Newest first.
  List<BillItem> get items => List<BillItem>.unmodifiable(_items);

  bool get isLoaded => _isLoaded;

  bool get isShowingSamples => _items.isEmpty;

  Future<void> load() async {
    _items = await _repository.readAll();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> add(BillItem item) async {
    _items = await _repository.add(item);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items = await _repository.delete(id);
    notifyListeners();
  }

  int get savedCount => _items.isEmpty ? sampleSavedItems : _items.length;

  /// Anything due within a month, which is what the dashboard counts.
  int get expiringSoonCount {
    if (_items.isEmpty) return sampleExpiringSoon;
    return _items.where((item) {
      final days = item.daysLeft();
      return days != null && days <= 30;
    }).length;
  }

  /// The soonest three items that have a date, for "Expiring soon".
  List<ExpiringItem> get expiringItems {
    if (_items.isEmpty) return sampleExpiringItems;
    final dated = _items.where((item) => item.expiryDate != null).toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    return dated.take(3).map((item) => item.toExpiringItem()).toList();
  }

  /// Every category with how many saved items sit in it.
  List<ItemCategory> get categories {
    if (_items.isEmpty) return sampleCategories;
    return <ItemCategory>[
      for (final name in itemCategories)
        ItemCategory(
          name: name,
          icon: iconForCategory(name),
          count: _items.where((item) => item.category == name).length,
        ),
    ];
  }

  List<SearchableItem> get searchItems {
    if (_items.isEmpty) return sampleSearchItems;
    return _items.map((item) => item.toSearchableItem()).toList();
  }
}
