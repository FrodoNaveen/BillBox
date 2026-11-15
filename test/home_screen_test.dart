import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/core/theme/app_theme.dart';
import 'package:billbox/features/home/presentation/screens/home_screen.dart';
import 'package:billbox/features/home/presentation/widgets/summary_card.dart';
import 'package:billbox/features/items/data/bill_item.dart';
import 'package:billbox/features/items/data/items_repository.dart';
import 'package:billbox/features/items/presentation/providers/items_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late ItemsRepository items;
  late ItemsProvider provider;

  setUp(() {
    items = ItemsRepository(InMemoryStore());
    provider = ItemsProvider(repository: items);
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await provider.load();
    await tester.pumpWidget(
      ChangeNotifierProvider<ItemsProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: HomeScreen(onOpenSearch: () {}, onOpenReminders: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says so while it is still showing sample items', (tester) async {
    await pumpDashboard(tester);

    expect(
      find.text('Sample items — add your first bill with the + button.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(SummaryCard, '12'), findsOneWidget);
  });

  testWidgets('a saved item replaces the samples', (tester) async {
    await pumpDashboard(tester);

    await provider.add(
      BillItem(
        id: 'i_1',
        title: 'Split AC',
        category: 'Appliances',
        kind: ItemKind.bill,
        savedAt: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 5)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sample items'), findsNothing);
    expect(find.text('Split AC'), findsOneWidget);
    expect(find.text('5 days'), findsOneWidget);
    // One saved, one expiring soon.
    expect(find.widgetWithText(SummaryCard, '1'), findsNWidgets(2));
  });
}
