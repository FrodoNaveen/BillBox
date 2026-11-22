import 'package:speech_to_text/speech_to_text.dart';

/// Listening to the user and handing back words.
///
/// The seam exists for the same reason [BillScanner] does: the screens drive
/// an interface, so the sheet can be tested without a microphone and the
/// engine underneath can be swapped without touching any UI.

/// Why listening could not start.
enum SpeechProblem {
  /// The device has no recogniser, or none that works offline.
  unavailable,

  /// The user said no to the microphone or to speech recognition.
  denied,
}

/// What came back from asking to listen.
sealed class SpeechReadiness {
  const SpeechReadiness();
}

class SpeechReady extends SpeechReadiness {
  const SpeechReady();
}

class SpeechUnavailable extends SpeechReadiness {
  const SpeechUnavailable(this.problem);

  final SpeechProblem problem;
}

abstract class SpeechRecogniser {
  /// Sets up the engine and asks for permission. Called before listening,
  /// and cheap to call again.
  Future<SpeechReadiness> prepare();

  /// Starts listening. [onWords] fires as the user speaks, with [isFinal]
  /// true on the last reading. [onDone] fires when the engine stops on its
  /// own, which it does after a pause.
  Future<void> start({
    required void Function(String words, bool isFinal) onWords,
    required void Function() onDone,
  });

  /// Stops listening but keeps what was heard.
  Future<void> stop();

  /// Stops listening and throws away what was heard.
  Future<void> cancel();
}

/// The real thing, over the platform recognisers.
///
/// On-device recognition is asked for explicitly: the app promises that
/// nothing leaves the phone, and a cloud transcript would break that. Where
/// a device cannot do it offline the engine refuses, which is reported as
/// [SpeechProblem.unavailable] rather than quietly going to a server.
class DeviceSpeechRecogniser implements SpeechRecogniser {
  DeviceSpeechRecogniser({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _isReady = false;

  /// Long enough to say a sentence, short enough not to sit on the mic.
  static const Duration _listenFor = Duration(seconds: 10);
  static const Duration _pauseFor = Duration(seconds: 3);

  @override
  Future<SpeechReadiness> prepare() async {
    if (_isReady) return const SpeechReady();

    var denied = false;
    _isReady = await _speech.initialize(
      onError: (error) => denied = error.errorMsg.contains('permission'),
    );
    if (_isReady) return const SpeechReady();

    return SpeechUnavailable(
      denied || !await _speech.hasPermission
          ? SpeechProblem.denied
          : SpeechProblem.unavailable,
    );
  }

  @override
  Future<void> start({
    required void Function(String words, bool isFinal) onWords,
    required void Function() onDone,
  }) async {
    await _speech.listen(
      onResult: (result) => onWords(result.recognizedWords, result.finalResult),
      listenOptions: SpeechListenOptions(
        // The privacy promise in the app's own copy depends on this.
        onDevice: true,
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: _listenFor,
        pauseFor: _pauseFor,
      ),
    );

    _speech.statusListener = (status) {
      if (status == 'notListening' || status == 'done') onDone();
    };
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}
