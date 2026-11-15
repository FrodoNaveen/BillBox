import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/bill_scanner.dart';
import 'package:billbox/features/items/data/items_repository.dart';
import 'package:billbox/features/items/data/sample_items.dart';
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
    test(
      'falls back to the sample catalogue until something is saved',
      () async {
        final provider = ItemsProvider(repository: repository);
        await provider.load();

        expect(provider.isShowingSamples, isTrue);
        expect(provider.savedCount, sampleBillItems.length);
        expect(provider.searchItems, isNotEmpty);
        expect(provider.categories.length, 6);
      },
    );

    test('a saved item takes over the dashboard numbers', () async {
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

      expect(provider.isShowingSamples, isFalse);
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

  group('SampleBillScanner', () {
    test('a photo is read into the fields the form tags', () async {
      final scanned = await SampleBillScanner(
        delay: Duration.zero,
        now: DateTime(2026, 11, 15),
      ).scan(kind: ItemKind.bill, source: CaptureSource.camera);

      expect(scanned.title, 'Samsung 1.5T Split AC');
      expect(scanned.category, 'Appliances');
      expect(scanned.amount, 39699);
      expect(scanned.expiryDate, DateTime(2028, 11, 15));
      expect(scanned.wasRead(ScannedField.amount), isTrue);
      expect(scanned.rawText, contains('Warranty 24 months'));
      expect(scanned.isEmpty, isFalse);
    });

    test('a document is read with its own expiry', () async {
      final scanned = await SampleBillScanner(
        delay: Duration.zero,
        now: DateTime(2026, 11, 15),
      ).scan(kind: ItemKind.document, source: CaptureSource.gallery);

      expect(scanned.title, 'Passport');
      expect(scanned.category, 'Identity');
      expect(scanned.wasRead(ScannedField.amount), isFalse);
      expect(scanned.expiryDate, DateTime(2032, 2, 3));
    });

    test('typing it in by hand reads nothing', () async {
      final scanned = await SampleBillScanner(
        delay: Duration.zero,
      ).scan(kind: ItemKind.bill, source: CaptureSource.manual);

      expect(scanned.isEmpty, isTrue);
      expect(scanned.title, isNull);
      expect(scanned.imageName, isNull);
    });
  });
}
