/// Finding "hey billbox" in a running transcript.
///
/// This is the hands-free half of voice entry: while the app is open and
/// listening, every reading from the recogniser is checked for the phrase,
/// and whatever follows it is what the user wants logged.
///
/// Matching is deliberately loose. On-device recognisers mangle an invented
/// word like "billbox" in predictable ways — "bill box", "bilbox", "build
/// box" — so the spellings below are all treated as the same thing. A false
/// start costs the user one tap on "Discard"; a missed wake word makes the
/// feature feel broken, so this errs towards hearing it.
library;

/// The spellings the recogniser is known to produce, longest first so
/// "hey bill box" is preferred over the bare "bill box" inside it.
const List<String> wakeSpellings = <String>[
  'hey billbox',
  'hey bill box',
  'hey bilbox',
  'hey bill box',
  'hey build box',
  'hey billboks',
  'ok billbox',
  'ok bill box',
  'billbox',
  'bill box',
  'bilbox',
];

/// What a transcript turned out to contain.
class WakeMatch {
  const WakeMatch({required this.phrase, required this.rest});

  /// The spelling that was actually heard, for logging and for tests.
  final String phrase;

  /// Everything said after the wake phrase — the command to parse. Empty
  /// when the user has only said the name so far and is still talking.
  final String rest;

  bool get hasCommand => rest.trim().isNotEmpty;
}

/// Looks for the wake phrase in [transcript].
///
/// Returns null when it is not there. The search is on a normalised copy but
/// [WakeMatch.rest] is cut from the original, so the command keeps the words
/// the user actually said for the parser and the read-back.
WakeMatch? findWakePhrase(String transcript) {
  final text = transcript.toLowerCase();

  // The earliest match wins, so a second "hey billbox" later in a long
  // reading does not throw away the command in between. Among matches at the
  // same spot, the longest spelling wins.
  int? bestStart;
  String? bestPhrase;

  for (final spelling in wakeSpellings) {
    final at = text.indexOf(spelling);
    if (at < 0) continue;
    if (bestStart == null ||
        at < bestStart ||
        (at == bestStart && spelling.length > bestPhrase!.length)) {
      bestStart = at;
      bestPhrase = spelling;
    }
  }

  if (bestStart == null) return null;

  final after = bestStart + bestPhrase!.length;
  return WakeMatch(
    phrase: bestPhrase,
    rest: after >= transcript.length ? '' : transcript.substring(after).trim(),
  );
}

/// True when [transcript] contains the wake phrase at all.
bool hasWakePhrase(String transcript) => findWakePhrase(transcript) != null;
