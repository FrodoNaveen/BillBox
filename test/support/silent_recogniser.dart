import 'package:billbox/features/expenses/data/speech_recogniser.dart';

/// A recogniser that is ready but never hears anything.
///
/// For harnesses that only need [HandsFreeProvider] to exist — it keeps the
/// microphone and its platform channels out of widget tests entirely.
class SilentRecogniser implements SpeechRecogniser {
  SilentRecogniser({this.readiness = const SpeechReady()});

  final SpeechReadiness readiness;

  var startCount = 0;
  var cancelled = false;

  @override
  Future<SpeechReadiness> prepare() async => readiness;

  @override
  Future<void> start({
    required void Function(String words, bool isFinal) onWords,
    required void Function() onDone,
  }) async {
    startCount++;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async => cancelled = true;
}
