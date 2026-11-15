import 'package:billbox/core/theme/app_theme.dart';
import 'package:billbox/features/search/presentation/screens/search_screen.dart';
import 'package:billbox/features/search/presentation/widgets/search_result_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpSearch(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: const SearchScreen()),
  );
}

void main() {
  testWidgets('opens with every item, soonest first', (tester) async {
    await _pumpSearch(tester);

    expect(find.text('9 results'), findsOneWidget);
    expect(find.text('Samsung 1.5T Split AC'), findsOneWidget);
  });

  testWidgets('typing narrows the rows and counts scanned-text matches', (
    tester,
  ) async {
    await _pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'insur');
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(SearchResultTile, 'Two-wheeler insurance'),
      findsOneWidget,
    );
    expect(find.text('3 results · including scanned text'), findsOneWidget);
  });

  testWidgets('a category chip filters, and clearing brings the rows back', (
    tester,
  ) async {
    await _pumpSearch(tester);

    await tester.ensureVisible(find.text('Identity'));
    await tester.tap(find.text('Identity'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchResultTile), findsOneWidget);
    expect(find.text('Passport'), findsOneWidget);

    await tester.ensureVisible(find.text('Identity'));
    await tester.tap(find.text('Identity'));
    await tester.pumpAndSettle();

    expect(find.text('9 results'), findsOneWidget);
  });

  testWidgets('the expiry window chip keeps only what is due', (tester) async {
    await _pumpSearch(tester);

    await tester.tap(find.text('Any date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next 30 days').last);
    await tester.pumpAndSettle();

    expect(find.text('Expiring 30 d'), findsOneWidget);
    expect(find.byType(SearchResultTile), findsNWidgets(4));
  });

  testWidgets('no match shows the empty state, and clearing resets it', (
    tester,
  ) async {
    await _pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'tractor');
    await tester.pumpAndSettle();

    expect(find.text('0 results'), findsOneWidget);
    expect(find.text('No match for “tractor”'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('9 results'), findsOneWidget);
  });
}
