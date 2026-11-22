import '../../../core/utils/formatting.dart';
import 'expense.dart';

/// Turns a spoken sentence into the fields of an expense.
///
/// "add spending amount of 50 rs for medicines" becomes ₹50, Health,
/// "medicines". The shape follows [ScannedBill]: every field is optional,
/// and [VoiceExpenseDraft.heardFields] records which ones actually came from
/// the speech so the sheet can mark them and the rest can be left to the
/// user. Nothing is saved from here — a draft is always confirmed first,
/// because a misheard amount is worse than a second tap.
///
/// Pure Dart on purpose: it is the one piece of this feature that is the same
/// on both platforms, so it carries no plugin and is tested on its own.

/// A field of the sheet that a spoken phrase can fill.
enum VoiceField { amount, category, note, date }

class VoiceExpenseDraft {
  const VoiceExpenseDraft({
    required this.transcript,
    required this.date,
    this.amount,
    this.category = fallbackExpenseCategory,
    this.note,
    this.heardFields = const <VoiceField>{},
  });

  /// Nothing useful was said: the sheet opens as it would from the + button.
  VoiceExpenseDraft.empty(this.transcript, {DateTime? now})
    : amount = null,
      category = fallbackExpenseCategory,
      note = null,
      date = dayOf(now ?? DateTime.now()),
      heardFields = const <VoiceField>{};

  /// Exactly what was heard, kept so the user can check a wrong reading
  /// against their own words.
  final String transcript;

  final double? amount;

  /// Always one of [expenseCategories]; falls back rather than inventing one.
  final String category;

  final String? note;

  /// Midnight on the day the spending is filed under. Today unless the
  /// sentence said otherwise.
  final DateTime date;

  final Set<VoiceField> heardFields;

  bool wasHeard(VoiceField field) => heardFields.contains(field);

  /// True when there is an amount to save. Without one there is no expense,
  /// however much else was understood.
  bool get isUsable => amount != null && amount! > 0;
}

/// Reads [transcript] into a draft. Never throws: anything it cannot make
/// sense of is simply not filled in.
VoiceExpenseDraft parseVoiceExpense(String transcript, {DateTime? now}) {
  final today = dayOf(now ?? DateTime.now());
  final text = _normalise(transcript);
  if (text.isEmpty) return VoiceExpenseDraft.empty(transcript, now: now);

  final heard = <VoiceField>{};

  final amount = _findAmount(text);
  if (amount != null) heard.add(VoiceField.amount);

  final date = _findDate(text, today);
  if (date != null) heard.add(VoiceField.date);

  final note = _findNote(text);
  if (note != null) heard.add(VoiceField.note);

  // The category is worked out from the whole sentence, not just the note, so
  // "paid 200 for the electricity bill" still lands in Bills.
  final category = _findCategory(text);
  if (category != null) heard.add(VoiceField.category);

  return VoiceExpenseDraft(
    transcript: transcript.trim(),
    amount: amount,
    category: category ?? fallbackExpenseCategory,
    note: note,
    date: date ?? today,
    heardFields: heard,
  );
}

/// Lower case, no punctuation, single spaces — so every rule below can assume
/// clean input. Speech recognisers vary on commas and "₹".
String _normalise(String transcript) {
  return transcript
      .toLowerCase()
      .replaceAll('₹', ' rs ')
      .replaceAll(RegExp(r'[^a-z0-9.\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// ---------------------------------------------------------------- amount

/// Words for numbers, so "fifty rupees" works as well as "50".
const Map<String, int> _units = <String, int>{
  'zero': 0,
  'one': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'eleven': 11,
  'twelve': 12,
  'thirteen': 13,
  'fourteen': 14,
  'fifteen': 15,
  'sixteen': 16,
  'seventeen': 17,
  'eighteen': 18,
  'nineteen': 19,
  'twenty': 20,
  'thirty': 30,
  'forty': 40,
  'fifty': 50,
  'sixty': 60,
  'seventy': 70,
  'eighty': 80,
  'ninety': 90,
};

/// What marks a number as money: "50 rs", "rs 50", "50 rupees", "50 bucks".
const List<String> _currencyWords = <String>[
  'rs',
  'rupee',
  'rupees',
  'buck',
  'bucks',
];

/// Picks the amount out of [text].
///
/// A number next to a currency word wins, so "2 teas for 80 rupees" reads 80
/// rather than 2. With nothing marked, the first number is taken, which is
/// how the phrase almost always runs: "add 50 for medicines".
double? _findAmount(String text) {
  final words = text.split(' ');
  final candidates = <({double value, bool marked})>[];

  for (var i = 0; i < words.length; i++) {
    final value = _numberAt(words, i);
    if (value == null) continue;

    final span = value.wordCount;
    final before = i > 0 ? words[i - 1] : '';
    final after = i + span < words.length ? words[i + span] : '';
    final marked =
        _currencyWords.contains(before) ||
        _currencyWords.contains(after) ||
        value.hadSuffix;

    candidates.add((value: value.amount, marked: marked));
    i += span - 1;
  }

  if (candidates.isEmpty) return null;
  for (final candidate in candidates) {
    if (candidate.marked) return candidate.value;
  }
  return candidates.first.value;
}

/// A number read at [index], however it was spoken.
({double amount, int wordCount, bool hadSuffix})? _numberAt(
  List<String> words,
  int index,
) {
  final word = words[index];

  // "50", "50.5", "50rs", "1.5k", "2k"
  final digits = RegExp(r'^(\d+(?:\.\d+)?)(k|rs)?$').firstMatch(word);
  if (digits != null) {
    final base = double.parse(digits.group(1)!);
    final suffix = digits.group(2);
    return (
      amount: suffix == 'k' ? base * 1000 : base,
      wordCount: 1,
      hadSuffix: suffix != null,
    );
  }

  // "fifty", "twenty five", "two hundred", "three thousand"
  if (!_units.containsKey(word) && word != 'hundred' && word != 'thousand') {
    return null;
  }

  var total = 0;
  var current = 0;
  var used = 0;
  for (var i = index; i < words.length; i++) {
    final part = words[i];
    if (_units.containsKey(part)) {
      current += _units[part]!;
    } else if (part == 'hundred') {
      current = (current == 0 ? 1 : current) * 100;
    } else if (part == 'thousand') {
      total += (current == 0 ? 1 : current) * 1000;
      current = 0;
    } else {
      break;
    }
    used++;
  }

  final value = total + current;
  if (used == 0 || value == 0) return null;
  return (amount: value.toDouble(), wordCount: used, hadSuffix: false);
}

// -------------------------------------------------------------- category

/// Words that place an expense in a category. Indian-English first, since
/// that is how the app's own copy reads.
///
/// The order matters: it is the priority used when a phrase hits two
/// categories at once. Bills sits above Shopping so "mobile recharge" is a
/// bill rather than a gadget.
const Map<String, List<String>> _categoryWords = <String, List<String>>{
  'Health': <String>[
    'medicine',
    'medicines',
    'medical',
    'pharmacy',
    'chemist',
    'doctor',
    'hospital',
    'clinic',
    'tablet',
    'tablets',
    'dentist',
    'checkup',
  ],
  'Food': <String>[
    'food',
    'lunch',
    'dinner',
    'breakfast',
    'tea',
    'coffee',
    'snack',
    'snacks',
    'restaurant',
    'hotel',
    'biryani',
    'meal',
    'meals',
    'juice',
    'swiggy',
    'zomato',
  ],
  'Groceries': <String>[
    'grocery',
    'groceries',
    'vegetables',
    'vegetable',
    'milk',
    'provisions',
    'supermarket',
    'fruits',
    'rice',
    'eggs',
  ],
  'Travel': <String>[
    'auto',
    'uber',
    'ola',
    'bus',
    'train',
    'metro',
    'cab',
    'taxi',
    'petrol',
    'diesel',
    'fuel',
    'ticket',
    'travel',
    'parking',
    'toll',
  ],
  'Bills': <String>[
    'bill',
    'bills',
    'recharge',
    'electricity',
    'current',
    'water',
    'gas',
    'rent',
    'wifi',
    'internet',
    'broadband',
    'dth',
    'emi',
    'insurance',
    'premium',
    'fees',
    'fee',
  ],
  'Shopping': <String>[
    'clothes',
    'shirt',
    'shoes',
    'amazon',
    'flipkart',
    'shopping',
    'dress',
    'bag',
    'gift',
    'phone',
    'mobile',
  ],
};

/// The category [text] belongs in, or null to leave it to the user.
///
/// An explicit "under health" or "category travel" is taken at its word
/// first; otherwise the keywords decide.
String? _findCategory(String text) {
  final words = text.split(' ');

  for (var i = 0; i < words.length - 1; i++) {
    if (words[i] != 'under' && words[i] != 'category') continue;
    final named = normaliseExpenseCategory(words[i + 1]);
    // normalise falls back to Other, which here means "not a category name".
    if (named != fallbackExpenseCategory) return named;
  }

  // Categories outer, words inner: the declared priority above decides, not
  // whichever keyword happens to be said first.
  for (final entry in _categoryWords.entries) {
    for (final word in words) {
      if (entry.value.contains(word)) return entry.key;
    }
  }
  return null;
}

// ------------------------------------------------------------------ date

/// "yesterday" and weekday names, which is as far as speech usually goes.
/// Anything else is today, and the sheet lets them change it.
DateTime? _findDate(String text, DateTime today) {
  if (text.contains('yesterday')) {
    return today.subtract(const Duration(days: 1));
  }
  if (text.contains('today')) return today;

  const weekdays = <String, int>{
    'monday': 1,
    'tuesday': 2,
    'wednesday': 3,
    'thursday': 4,
    'friday': 5,
    'saturday': 6,
    'sunday': 7,
  };
  for (final entry in weekdays.entries) {
    if (!text.contains(entry.key)) continue;
    // The most recent one: spending is logged after the fact, not before.
    final back = (today.weekday - entry.value + 7) % 7;
    return today.subtract(Duration(days: back == 0 ? 7 : back));
  }
  return null;
}

// ------------------------------------------------------------------ note

/// Words that are plumbing rather than description. Only ever trimmed from
/// the ends of the note, never from the middle — "lunch at the office" has to
/// survive whole.
const Set<String> _stopWords = <String>{
  'add',
  'added',
  'log',
  'logged',
  'note',
  'put',
  'save',
  'spent',
  'spend',
  'spending',
  'paid',
  'pay',
  'expense',
  'expenses',
  'amount',
  'of',
  'for',
  'on',
  'a',
  'an',
  'the',
  'to',
  'it',
  'is',
  'was',
  'i',
  'my',
  'me',
  'please',
  'hey',
  'billbox',
  'bill',
  'box',
  'and',
  'under',
  'category',
  'worth',
  'in',
  'at',
  'some',
  'this',
  'that',
  'towards',
  'as',
};

/// Said while naming a day rather than describing the spending.
const Set<String> _dateWords = <String>{
  'today',
  'yesterday',
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
};

bool _isNumberWord(String word) {
  if (RegExp(r'^\d+(\.\d+)?(k|rs)?$').hasMatch(word)) return true;
  return _units.containsKey(word) || word == 'hundred' || word == 'thousand';
}

/// What the money went on, in the user's own words.
///
/// The amount, the currency, the day and an outright "under travel" are
/// taken out wherever they appear, since none of them describe anything.
/// The command is then trimmed off both ends — but nothing is removed from
/// the middle, so "lunch at the office canteen" comes back intact.
String? _findNote(String text) {
  final words = text.split(' ');
  final kept = <String>[];

  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    if (word.isEmpty) continue;
    if (_isNumberWord(word)) continue;
    if (_currencyWords.contains(word)) continue;
    if (_dateWords.contains(word)) continue;

    // "under travel" / "category shopping" named the category, not the thing.
    if ((word == 'under' || word == 'category') && i + 1 < words.length) {
      final named = normaliseExpenseCategory(words[i + 1]);
      if (named != fallbackExpenseCategory) {
        i++;
        continue;
      }
    }

    kept.add(word);
  }

  // Trim the plumbing off the front and back only.
  var start = 0;
  var end = kept.length;
  while (start < end && _stopWords.contains(kept[start])) {
    start++;
  }
  while (end > start && _stopWords.contains(kept[end - 1])) {
    end--;
  }
  if (start >= end) return null;

  final note = kept.sublist(start, end).join(' ');
  return note[0].toUpperCase() + note.substring(1);
}
