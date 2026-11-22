import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/speech_recogniser.dart';
import '../../data/voice_expense_parser.dart';
import '../../data/wake_phrase.dart';

/// Listens for "hey BillBox …" for as long as the app is on screen.
///
/// This is the no-tap half of voice entry, and it only works while the app is
/// in the foreground: neither platform lets an app hold the microphone once
/// it is backgrounded, so [stop] is called the moment the app is hidden and
/// [start] again when it comes back.
///
/// The recognisers stop themselves after a pause, so listening is a loop:
/// each session is restarted until the feature is switched off. Everything it
/// hears before the wake phrase is thrown away without leaving this object.
class HandsFreeProvider extends ChangeNotifier {
  HandsFreeProvider({required SpeechRecogniser recogniser})
    : _recogniser = recogniser;

  final SpeechRecogniser _recogniser;

  bool _isEnabled = false;
  bool _isListening = false;
  bool _isRestarting = false;

  SpeechProblem? _problem;
  VoiceExpenseDraft? _caught;

  /// How long to wait before listening again, so a failing recogniser cannot
  /// spin the loop flat out.
  static const Duration _restartDelay = Duration(milliseconds: 400);

  Timer? _restartTimer;

  /// True while the feature is meant to be running.
  bool get isEnabled => _isEnabled;

  /// True while the microphone is actually open, which the UI shows.
  bool get isListening => _isListening;

  /// Why listening could not start, for the settings row to explain.
  SpeechProblem? get problem => _problem;

  /// A command heard and understood, waiting to be confirmed. The shell
  /// watches this and opens the read-back sheet.
  VoiceExpenseDraft? get caught => _caught;

  /// Starts or stops listening to match [enabled].
  Future<void> setEnabled(bool enabled) async {
    if (enabled == _isEnabled) return;
    _isEnabled = enabled;
    _problem = null;
    notifyListeners();

    if (enabled) {
      await _listen();
    } else {
      await _halt();
    }
  }

  /// Called when the app leaves the foreground. Keeps [isEnabled] as it was,
  /// so coming back resumes without the user asking again.
  Future<void> pause() async {
    if (!_isListening && !_isRestarting) return;
    await _halt();
  }

  Future<void> resume() async {
    if (!_isEnabled || _isListening) return;
    await _listen();
  }

  /// Taken by the shell once it has shown the sheet, so the same command is
  /// not offered twice.
  VoiceExpenseDraft? takeCaught() {
    final draft = _caught;
    _caught = null;
    return draft;
  }

  Future<void> _listen() async {
    if (!_isEnabled || _isListening) return;

    final readiness = await _recogniser.prepare();
    if (readiness is SpeechUnavailable) {
      // Nothing to retry: without permission or an engine the loop would
      // spin forever, so the feature switches itself off and says why.
      _isEnabled = false;
      _isListening = false;
      _problem = readiness.problem;
      notifyListeners();
      return;
    }

    _isListening = true;
    notifyListeners();

    await _recogniser.start(
      onWords: (words, isFinal) {
        if (!_isEnabled) return;
        final match = findWakePhrase(words);
        if (match == null || !match.hasCommand) return;

        // Only act on a finished reading: a partial one is still growing and
        // "add 50" would be caught before "for medicines" arrives.
        if (isFinal) _catch(match);
      },
      onDone: _restart,
    );
  }

  void _catch(WakeMatch match) {
    final draft = parseVoiceExpense(match.rest);
    if (!draft.isUsable) return;

    _caught = draft;
    notifyListeners();
  }

  /// Listens again after the engine stops itself.
  void _restart() {
    if (!_isEnabled || _isRestarting) return;
    _isListening = false;
    _isRestarting = true;
    notifyListeners();

    _restartTimer?.cancel();
    _restartTimer = Timer(_restartDelay, () async {
      _isRestarting = false;
      await _listen();
    });
  }

  Future<void> _halt() async {
    _restartTimer?.cancel();
    _restartTimer = null;
    _isRestarting = false;
    _isListening = false;
    notifyListeners();
    await _recogniser.cancel();
  }

  @override
  void dispose() {
    _restartTimer?.cancel();
    _recogniser.cancel();
    super.dispose();
  }
}
