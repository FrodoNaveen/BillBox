import 'package:billbox/core/storage/key_value_store.dart';
import 'package:billbox/core/theme/app_theme.dart';
import 'package:billbox/features/expenses/data/expenses_repository.dart';
import 'package:billbox/features/expenses/data/speech_recogniser.dart';
import 'package:billbox/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:billbox/features/expenses/presentation/widgets/voice_expense_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Stands in for the microphone: says what it was told to say, instantly.
class _StubRecogniser implements SpeechRecogniser {
  _StubRecogniser({
    this.words = 'add 50 rupees for medicines',
    this.readiness = const SpeechReady(),
    this.finishOnItsOwn = true,
  });

  final String words;
  final SpeechReadiness readiness;

  /// False to leave the mic "open", for testing the listening state.
  final bool finishOnItsOwn;

  var stopped = false;
  var cancelled = false;
  void Function(String, bool)? _onWords;

  @override
  Future<SpeechReadiness> prepare() async => readiness;

  @override
  Future<void> start({
    required void Function(String words, bool isFinal) onWords,
    required void Function() onDone,
  }) async {
    _onWords = onWords;
    // A partial reading first, as a real recogniser does.
    onWords(words, false);
    if (finishOnItsOwn) onWords(words, true);
  }

  @override
  Future<void> stop() async {
    stopped = true;
    _onWords?.call(words, true);
  }

  @override
  Future<void> cancel() async => cancelled = true;
}

void main() {
  late InMemoryStore store;
  late ExpensesRepository expenses;
  late ExpensesProvider provider;

  setUp(() {
    store = InMemoryStore();
    expenses = ExpensesRepository(store);
    provider = ExpensesProvider(repository: expenses);
  });

  /// A screen with a button that opens the sheet, which is how it is reached.
  Future<void> pumpSheet(
    WidgetTester tester,
    _StubRecogniser recogniser,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await provider.load();
    await tester.pumpWidget(
      ChangeNotifierProvider<ExpensesProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showVoiceExpenseSheet(context, recogniser: recogniser),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('what was heard is read back before anything is saved', (
    tester,
  ) async {
    await pumpSheet(tester, _StubRecogniser());

    expect(find.text('“add 50 rupees for medicines”'), findsOneWidget);
    expect(find.text('₹50'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Medicines'), findsOneWidget);
    expect(find.text('Save ₹50'), findsOneWidget);

    // Nothing is written until it is confirmed.
    expect(await expenses.readAll(), isEmpty);
  });

  testWidgets('confirming saves the expense and says so', (tester) async {
    await pumpSheet(tester, _StubRecogniser());

    await tester.tap(find.text('Save ₹50'));
    await tester.pumpAndSettle();

    final saved = await expenses.readAll();
    expect(saved, hasLength(1));
    expect(saved.single.amount, 50);
    expect(saved.single.category, 'Health');
    expect(saved.single.note, 'Medicines');
    expect(saved.single.linkedItemId, isNull);

    expect(find.text('₹50 added to spending.'), findsOneWidget);
  });

  testWidgets('a default the user did not say is marked as assumed', (
    tester,
  ) async {
    // No category word and no day, so both are the app's assumption.
    await pumpSheet(tester, _StubRecogniser(words: 'add 90 rupees'));

    expect(find.text('₹90'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('assumed'), findsNWidgets(2));
  });

  testWidgets('a category actually spoken is not marked assumed', (
    tester,
  ) async {
    await pumpSheet(tester, _StubRecogniser(words: 'add 60 for the auto'));

    expect(find.text('Travel'), findsOneWidget);
    // Only the date is assumed now.
    expect(find.text('assumed'), findsOneWidget);
  });

  testWidgets('a phrase with no amount is not saved, it offers the form', (
    tester,
  ) async {
    await pumpSheet(tester, _StubRecogniser(words: 'add something for tea'));

    expect(find.textContaining('No amount in'), findsOneWidget);
    expect(find.text('Fill it in'), findsOneWidget);
    expect(find.textContaining('Save'), findsNothing);
    expect(await expenses.readAll(), isEmpty);
  });

  testWidgets('nothing heard at all says so', (tester) async {
    await pumpSheet(tester, _StubRecogniser(words: ''));

    expect(find.text('Nothing was heard'), findsOneWidget);
    expect(find.text('Fill it in'), findsOneWidget);
  });

  testWidgets('the words show as they are spoken, and Done settles them', (
    tester,
  ) async {
    final recogniser = _StubRecogniser(finishOnItsOwn: false);
    await pumpSheet(tester, recogniser);

    // Still listening: the partial reading is on screen.
    expect(find.text('add 50 rupees for medicines'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.textContaining('never uploaded'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(recogniser.stopped, isTrue);
    expect(find.text('Save ₹50'), findsOneWidget);
  });

  testWidgets('a refused microphone is explained, not swallowed', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      _StubRecogniser(readiness: const SpeechUnavailable(SpeechProblem.denied)),
    );

    expect(find.text('BillBox cannot hear you'), findsOneWidget);
    expect(find.textContaining('Allow the microphone'), findsOneWidget);
    expect(find.text('Type it instead'), findsOneWidget);
  });

  testWidgets('a phone with no offline speech says why', (tester) async {
    await pumpSheet(
      tester,
      _StubRecogniser(
        readiness: const SpeechUnavailable(SpeechProblem.unavailable),
      ),
    );

    expect(find.text('No offline speech on this phone'), findsOneWidget);
    expect(find.textContaining('nothing is uploaded'), findsOneWidget);
  });

  testWidgets('"say again" listens afresh', (tester) async {
    await pumpSheet(tester, _StubRecogniser());

    expect(find.text('Save ₹50'), findsOneWidget);

    await tester.tap(find.text('Say again'));
    await tester.pumpAndSettle();

    // Heard the same thing again, and still nothing saved on its own.
    expect(find.text('Save ₹50'), findsOneWidget);
    expect(await expenses.readAll(), isEmpty);
  });

  testWidgets('"change details" hands what was heard to the typed sheet', (
    tester,
  ) async {
    await pumpSheet(tester, _StubRecogniser());

    await tester.tap(find.text('Change details'));
    await tester.pumpAndSettle();

    // The typed sheet opens already filled in from the speech.
    expect(find.widgetWithText(TextFormField, '50'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Medicines'), findsOneWidget);
    // Still nothing saved — the typed sheet has its own save.
    expect(await expenses.readAll(), isEmpty);
  });

  testWidgets('a phrase with no amount opens the form to be filled in', (
    tester,
  ) async {
    await pumpSheet(tester, _StubRecogniser(words: 'paid for the auto'));

    await tester.tap(find.text('Fill it in'));
    await tester.pumpAndSettle();

    // No amount to carry over, but what it did understand is kept.
    expect(find.widgetWithText(TextFormField, 'Auto'), findsOneWidget);
    expect(find.text('Travel'), findsWidgets);
  });

  testWidgets('closing the sheet lets go of the microphone', (tester) async {
    final recogniser = _StubRecogniser(finishOnItsOwn: false);
    await pumpSheet(tester, recogniser);

    // Dismiss the sheet.
    await tester.tapAt(const Offset(195, 60));
    await tester.pumpAndSettle();

    expect(recogniser.cancelled, isTrue);
  });
}
