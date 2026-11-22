import 'package:billbox/features/expenses/data/voice_expense_parser.dart';
import 'package:billbox/features/expenses/data/wake_phrase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hearing the name', () {
    final heard = <String>[
      'hey billbox add 50 for medicines',
      'Hey BillBox add 50 for medicines',
      'hey bill box add 50 for medicines',
      'hey bilbox add 50 for medicines',
      'ok billbox add 50 for medicines',
      'billbox add 50 for medicines',
      'bill box add 50 for medicines',
    ];

    for (final transcript in heard) {
      test('"$transcript" is a wake', () {
        final match = findWakePhrase(transcript);

        expect(match, isNotNull);
        expect(match!.hasCommand, isTrue);
        expect(match.rest, 'add 50 for medicines');
      });
    }

    test('an unrelated sentence is not a wake', () {
      expect(findWakePhrase('add 50 for medicines'), isNull);
      expect(hasWakePhrase('what did i spend on groceries'), isFalse);
    });

    test('the name on its own is a wake with nothing to do yet', () {
      final match = findWakePhrase('hey billbox');

      expect(match, isNotNull);
      expect(match!.rest, isEmpty);
      // Still talking: the loop waits rather than acting on nothing.
      expect(match.hasCommand, isFalse);
    });
  });

  group('cutting the command out', () {
    test('words before the name are ignored', () {
      final match = findWakePhrase('umm so hey billbox add 90 for tea');

      expect(match!.rest, 'add 90 for tea');
    });

    test('the earliest name wins, so the command is not thrown away', () {
      // A long reading can pick the name up twice; the command sits after
      // the first one.
      final match = findWakePhrase('hey billbox add 70 for lunch hey billbox');

      expect(match!.rest, 'add 70 for lunch hey billbox');
    });

    test('the longer spelling wins at the same spot', () {
      // "hey bill box" rather than the "bill box" inside it, so "hey" is
      // not left at the front of the command.
      final match = findWakePhrase('hey bill box add 40 for coffee');

      expect(match!.phrase, 'hey bill box');
      expect(match.rest, 'add 40 for coffee');
    });

    test('the command keeps the words as they were said', () {
      // Cut from the original, not the lower-cased copy.
      final match = findWakePhrase('Hey BillBox Add 50 For Medicines');

      expect(match!.rest, 'Add 50 For Medicines');
    });
  });

  group('end to end with the parser', () {
    test('the phrase the feature was asked for', () {
      final match = findWakePhrase('hey billbox add 50 rs for medicine');
      final draft = parseVoiceExpense(match!.rest, now: DateTime(2026, 11, 22));

      expect(draft.amount, 50);
      expect(draft.category, 'Health');
      expect(draft.note, 'Medicine');
      expect(draft.isUsable, isTrue);
    });

    test('a wake with no amount is not something to act on', () {
      final match = findWakePhrase('hey billbox what did i spend');
      final draft = parseVoiceExpense(match!.rest);

      expect(draft.isUsable, isFalse);
    });
  });
}
