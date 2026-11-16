import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/bill_scanner.dart';
import 'package:billbox/features/items/data/items_repository.dart';
import 'package:billbox/features/items/presentation/providers/items_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStore store;
  late ItemsRepository repository;

  setUp(() {
    store = InMemoryStore();
    repository = ItemsRepository(store);
  });

  BillItem item({
    required String id,
    required DateTime savedAt,
    String title = 'Item',
    String category = 'Appliances',
    DateTime? expiry,
  }) {
    return BillItem(
      id: id,
      title: title,
      category: category,
      kind: ItemKind.bill,
      savedAt: savedAt,
      expiryDate: expiry,
    );
  }

  group('ItemsRepository', () {
    test('starts empty and keeps the newest item first', () async {
      expect(await repository.readAll(), isEmpty);

      await repository.add(item(id: 'a', savedAt: DateTime(2026, 11, 1)));
      await repository.add(item(id: 'b', savedAt: DateTime(2026, 11, 14)));

      expect((await repository.readAll()).map((i) => i.id), ['b', 'a']);
    });

    test('an item can be edited and removed', () async {
      await repository.add(item(id: 'a', savedAt: DateTime(2026, 11, 1)));

      final saved = (await repository.readAll()).single;
      await repository.update(saved.copyWith(title: 'Renamed'));
      expect((await repository.readAll()).single.title, 'Renamed');

      await repository.delete('a');
      expect(await repository.readAll(), isEmpty);
    });

    test('editing something already gone changes nothing', () async {
      await repository.add(item(id: 'a', savedAt: DateTime(2026, 11, 1)));

      await repository.update(item(id: 'ghost', savedAt: DateTime.now()));

      expect((await repository.readAll()).single.id, 'a');
    });

    test('corrupt storage reads as no items', () async {
      await store.write(ItemsRepository.itemsKey, '{not a list}');

      expect(await repository.readAll(), isEmpty);
    });
  });

  group('ItemsProvider', () {
    test('reads empty until something is saved', () async {
      final provider = ItemsProvider(repository: repository);
      await provider.load();

      expect(provider.isEmpty, isTrue);
      expect(provider.savedCount, 0);
      expect(provider.expiringSoonCount, 0);
      expect(provider.expiringItems, isEmpty);
      expect(provider.searchItems, isEmpty);
      expect(provider.categories.length, 6);
      expect(provider.categories.every((c) => c.count == 0), isTrue);
    });

    test('a saved item fills the dashboard numbers', () async {
      final provider = ItemsProvider(repository: repository);
      await provider.load();

      await provider.add(
        item(
          id: 'a',
          savedAt: DateTime.now(),
          title: 'Split AC',
          expiry: DateTime.now().add(const Duration(days: 5)),
        ),
      );

      expect(provider.isEmpty, isFalse);
      expect(provider.savedCount, 1);
      expect(provider.expiringSoonCount, 1);
      expect(provider.expiringItems.single.title, 'Split AC');
      expect(provider.searchItems.single.title, 'Split AC');
      expect(
        provider.categories.firstWhere((c) => c.name == 'Appliances').count,
        1,
      );
    });

    test('items with no date are left out of "expiring soon"', () async {
      final provider = ItemsProvider(repository: repository);
      await provider.load();

      await provider.add(item(id: 'a', savedAt: DateTime.now()));

      expect(provider.savedCount, 1);
      expect(provider.expiringSoonCount, 0);
      expect(provider.expiringItems, isEmpty);
    });
  });

  group('EmptyBillScanner', () {
    test('a photo reads nothing, so the form opens blank', () async {
      final scanned = await EmptyBillScanner().scan(
        kind: ItemKind.bill,
        source: CaptureSource.camera,
      );

      expect(scanned.isEmpty, isTrue);
      expect(scanned.title, isNull);
      expect(scanned.amount, isNull);
      expect(scanned.expiryDate, isNull);
      expect(scanned.rawText, isEmpty);
      expect(scanned.imageName, isNull);
      expect(scanned.source, CaptureSource.camera);
    });

    test('a document reads nothing either', () async {
      final scanned = await EmptyBillScanner().scan(
        kind: ItemKind.document,
        source: CaptureSource.gallery,
      );

      expect(scanned.isEmpty, isTrue);
      expect(scanned.title, isNull);
      expect(scanned.source, CaptureSource.gallery);
    });

    test('typing it in by hand reads nothing', () async {
      final scanned = await EmptyBillScanner().scan(
        kind: ItemKind.bill,
        source: CaptureSource.manual,
      );

      expect(scanned.isEmpty, isTrue);
      expect(scanned.title, isNull);
      expect(scanned.imageName, isNull);
    });
  });
}
