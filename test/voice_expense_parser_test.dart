import 'package:billbox/features/expenses/data/voice_expense_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A Sunday, so the weekday rules have somewhere unambiguous to land.
  final now = DateTime(2026, 11, 15);
  final today = DateTime(2026, 11, 15);

  VoiceExpenseDraft parse(String said) => parseVoiceExpense(said, now: now);

  group('the phrase the feature was asked for', () {
    test('"add spending amount of 50 rs for medicines"', () {
      final draft = parse('add spending amount of 50 rs for medicines');

      expect(draft.amount, 50);
      expect(draft.category, 'Health');
      expect(draft.note, 'Medicines');
      expect(draft.date, today);
      expect(draft.isUsable, isTrue);
      expect(draft.wasHeard(VoiceField.amount), isTrue);
      expect(draft.wasHeard(VoiceField.category), isTrue);
      expect(draft.wasHeard(VoiceField.note), isTrue);
      // The date was not spoken, so today is a default, not something heard.
      expect(draft.wasHeard(VoiceField.date), isFalse);
    });

    test('the words spoken are kept for checking', () {
      final draft = parse('Add spending amount of 50 rs for medicines');

      expect(draft.transcript, 'Add spending amount of 50 rs for medicines');
    });
  });

  group('amounts', () {
    final cases = <String, double>{
      'add 50 for medicines': 50,
      'spent 200 on groceries': 200,
      'add rs 75 for lunch': 75,
      'add 75 rs for lunch': 75,
      'paid 120 rupees for auto': 120,
      '₹90 for coffee': 90,
      'add 50rs for tea': 50,
      'add 1.5k for clothes': 1500,
      'add 2k for shopping': 2000,
      'spent 99.5 on snacks': 99.5,
      'add fifty rupees for medicines': 50,
      'add twenty five for tea': 25,
      'spent two hundred on groceries': 200,
      'paid three thousand for rent': 3000,
      'add one hundred fifty for dinner': 150,
      'add ninety nine for a book': 99,
    };

    cases.forEach((said, expected) {
      test('"$said" reads $expected', () {
        expect(parse(said).amount, expected);
      });
    });

    test('a number marked as money beats a bare count', () {
      // "2 teas" is a quantity; the 80 is what was spent.
      expect(parse('2 teas for 80 rupees').amount, 80);
      expect(parse('bought 3 tablets 250 rs').amount, 250);
    });

    test('with nothing marked, the first number is taken', () {
      expect(parse('add 50 for 2 medicines').amount, 50);
    });

    test('a phrase with no number is not usable', () {
      final draft = parse('add spending for medicines');

      expect(draft.amount, isNull);
      expect(draft.isUsable, isFalse);
      expect(draft.wasHeard(VoiceField.amount), isFalse);
      // What it did understand is still offered.
      expect(draft.category, 'Health');
    });

    test('a zero amount is not usable either', () {
      expect(parse('add 0 for nothing').isUsable, isFalse);
    });
  });

  group('categories', () {
    final cases = <String, String>{
      'add 50 for medicines': 'Health',
      'paid 300 at the pharmacy': 'Health',
      'add 40 for tea': 'Food',
      'spent 250 on swiggy': 'Food',
      'add 800 for vegetables': 'Groceries',
      'paid 60 for the auto': 'Travel',
      'spent 500 on petrol': 'Travel',
      'paid 1200 for the electricity bill': 'Bills',
      'add 399 for mobile recharge': 'Bills',
      'spent 2000 on clothes': 'Shopping',
      'add 150 for flipkart': 'Shopping',
    };

    cases.forEach((said, expected) {
      test('"$said" files under $expected', () {
        expect(parse(said).category, expected);
      });
    });

    test('an unknown thing falls back rather than guessing', () {
      final draft = parse('add 70 for something odd');

      expect(draft.category, 'Other');
      expect(draft.wasHeard(VoiceField.category), isFalse);
      expect(draft.note, 'Something odd');
    });

    test('a category said outright is taken at its word', () {
      expect(parse('add 500 under travel').category, 'Travel');
      expect(parse('add 500 category shopping').category, 'Shopping');
    });

    test('a named category wins over a keyword', () {
      // The tea is incidental; they asked for Bills.
      expect(parse('add 40 for tea under bills').category, 'Bills');
    });
  });

  group('dates', () {
    test('today unless the phrase says otherwise', () {
      expect(parse('add 50 for medicines').date, today);
    });

    test('"yesterday" goes back a day', () {
      final draft = parse('add 50 for medicines yesterday');

      expect(draft.date, DateTime(2026, 11, 14));
      expect(draft.wasHeard(VoiceField.date), isTrue);
    });

    test('"today" counts as heard', () {
      final draft = parse('add 50 for tea today');

      expect(draft.date, today);
      expect(draft.wasHeard(VoiceField.date), isTrue);
    });

    test('a weekday means the most recent one', () {
      // The 15th is a Sunday, so the Friday before is the 13th.
      expect(
        parse('spent 300 on friday for dinner').date,
        DateTime(2026, 11, 13),
      );
    });

    test('naming today\'s own weekday means a week ago, not today', () {
      // Saying "on Sunday" on a Sunday is about last Sunday.
      expect(parse('spent 300 on sunday').date, DateTime(2026, 11, 8));
    });
  });

  group('notes', () {
    test('the plumbing words are stripped out', () {
      expect(
        parse('please add an expense of 50 rupees for medicines').note,
        'Medicines',
      );
    });

    test('a longer description survives whole', () {
      expect(
        parse('add 250 for lunch at the office canteen').note,
        'Lunch at the office canteen',
      );
    });

    test('a phrase with nothing to describe gets no note', () {
      final draft = parse('add 50 rupees');

      expect(draft.note, isNull);
      expect(draft.wasHeard(VoiceField.note), isFalse);
      expect(draft.isUsable, isTrue);
    });

    test('the wake phrase is not mistaken for a description', () {
      expect(parse('hey billbox add 50 for medicines').note, 'Medicines');
    });
  });

  group('nothing useful said', () {
    test('an empty transcript gives an empty draft', () {
      final draft = parseVoiceExpense('', now: now);

      expect(draft.isUsable, isFalse);
      expect(draft.amount, isNull);
      expect(draft.note, isNull);
      expect(draft.category, 'Other');
      expect(draft.heardFields, isEmpty);
      expect(draft.date, today);
    });

    test('a shrug of a phrase does not throw', () {
      expect(() => parse('umm what'), returnsNormally);
      expect(parse('umm what').isUsable, isFalse);
    });

    test('punctuation and casing make no difference', () {
      final plain = parse('add 50 rs for medicines');
      final messy = parse('Add 50 Rs, for medicines!');

      expect(messy.amount, plain.amount);
      expect(messy.category, plain.category);
      expect(messy.note, plain.note);
    });
  });
}
