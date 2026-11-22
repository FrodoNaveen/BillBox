import 'package:billbox/features/expenses/data/speech_recogniser.dart';
import 'package:billbox/features/expenses/presentation/providers/hands_free_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// A recogniser the test drives by hand, so the listening loop can be stepped
/// through without a microphone or real time.
class _FakeRecogniser implements SpeechRecogniser {
  _FakeRecogniser({this.readiness = const SpeechReady()});

  final SpeechReadiness readiness;

  var startCount = 0;
  var cancelCount = 0;

  void Function(String, bool)? _onWords;
  void Function()? _onDone;

  @override
  Future<SpeechReadiness> prepare() async => readiness;

  @override
  Future<void> start({
    required void Function(String words, bool isFinal) onWords,
    required void Function() onDone,
  }) async {
    startCount++;
    _onWords = onWords;
    _onDone = onDone;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async => cancelCount++;

  /// What the engine reports back.
  void say(String words, {bool isFinal = true}) =>
      _onWords?.call(words, isFinal);

  /// The engine giving up after a pause, which should restart the loop.
  void finish() => _onDone?.call();
}

void main() {
  late _FakeRecogniser recogniser;
  late HandsFreeProvider provider;

  setUp(() {
    recogniser = _FakeRecogniser();
    provider = HandsFreeProvider(recogniser: recogniser);
  });

  tearDown(() => provider.dispose());

  test('it does nothing until it is switched on', () {
    expect(provider.isEnabled, isFalse);
    expect(provider.isListening, isFalse);
    expect(recogniser.startCount, 0);
  });

  test('switching on opens the microphone', () async {
    await provider.setEnabled(true);

    expect(provider.isEnabled, isTrue);
    expect(provider.isListening, isTrue);
    expect(recogniser.startCount, 1);
  });

  test('the wake phrase with a command is caught', () async {
    await provider.setEnabled(true);

    recogniser.say('hey billbox add 50 rupees for medicines');

    final caught = provider.caught;
    expect(caught, isNotNull);
    expect(caught!.amount, 50);
    expect(caught.category, 'Health');
    expect(caught.note, 'Medicines');
  });

  test('speech without the wake phrase is ignored entirely', () async {
    await provider.setEnabled(true);

    recogniser.say('add 50 rupees for medicines');
    recogniser.say('what did i spend on groceries last week');

    expect(provider.caught, isNull);
  });

  test('a partial reading is not acted on', () async {
    await provider.setEnabled(true);

    // Mid-sentence: "for medicines" has not arrived yet.
    recogniser.say('hey billbox add 50', isFinal: false);
    expect(provider.caught, isNull);

    recogniser.say('hey billbox add 50 for medicines', isFinal: true);
    expect(provider.caught!.note, 'Medicines');
  });

  test('the wake phrase with no amount is not caught', () async {
    await provider.setEnabled(true);

    recogniser.say('hey billbox what did i spend');

    expect(provider.caught, isNull);
  });

  test('the name alone waits for the rest of the sentence', () async {
    await provider.setEnabled(true);

    recogniser.say('hey billbox');

    expect(provider.caught, isNull);
  });

  test('taking a catch clears it, so it is not offered twice', () async {
    await provider.setEnabled(true);
    recogniser.say('hey billbox add 50 for tea');

    expect(provider.takeCaught(), isNotNull);
    expect(provider.caught, isNull);
    expect(provider.takeCaught(), isNull);
  });

  test('the loop listens again when the engine stops itself', () async {
    await provider.setEnabled(true);
    expect(recogniser.startCount, 1);

    recogniser.finish();
    expect(provider.isListening, isFalse);

    // The restart is delayed so a failing engine cannot spin the loop.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(recogniser.startCount, 2);
    expect(provider.isListening, isTrue);
  });

  test('switching off lets go of the microphone and stops the loop', () async {
    await provider.setEnabled(true);
    await provider.setEnabled(false);

    expect(provider.isEnabled, isFalse);
    expect(provider.isListening, isFalse);
    expect(recogniser.cancelCount, greaterThan(0));

    // Nothing restarts it once it is off.
    recogniser.finish();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(recogniser.startCount, 1);
  });

  test('speech after switching off is ignored', () async {
    await provider.setEnabled(true);
    await provider.setEnabled(false);

    recogniser.say('hey billbox add 50 for tea');

    expect(provider.caught, isNull);
  });

  group('leaving the foreground', () {
    test('pausing drops the microphone but stays switched on', () async {
      await provider.setEnabled(true);
      await provider.pause();

      expect(provider.isListening, isFalse);
      // Still on, so coming back does not need the user to ask again.
      expect(provider.isEnabled, isTrue);
      expect(recogniser.cancelCount, greaterThan(0));
    });

    test('resuming listens again', () async {
      await provider.setEnabled(true);
      await provider.pause();
      await provider.resume();

      expect(provider.isListening, isTrue);
      expect(recogniser.startCount, 2);
    });

    test('resuming does nothing when it was never switched on', () async {
      await provider.resume();

      expect(provider.isListening, isFalse);
      expect(recogniser.startCount, 0);
    });
  });

  group('when it cannot listen', () {
    test('a refused microphone switches itself off and says why', () async {
      final refused = HandsFreeProvider(
        recogniser: _FakeRecogniser(
          readiness: const SpeechUnavailable(SpeechProblem.denied),
        ),
      );
      addTearDown(refused.dispose);

      await refused.setEnabled(true);

      // No retry loop: without permission it would spin forever.
      expect(refused.isEnabled, isFalse);
      expect(refused.isListening, isFalse);
      expect(refused.problem, SpeechProblem.denied);
    });

    test('no offline engine is reported as such', () async {
      final none = HandsFreeProvider(
        recogniser: _FakeRecogniser(
          readiness: const SpeechUnavailable(SpeechProblem.unavailable),
        ),
      );
      addTearDown(none.dispose);

      await none.setEnabled(true);

      expect(none.problem, SpeechProblem.unavailable);
      expect(none.isEnabled, isFalse);
    });
  });
}
