import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/formatting.dart';
import '../../data/expense.dart';
import '../../data/speech_recogniser.dart';
import '../../data/voice_expense_parser.dart';
import '../providers/expenses_provider.dart';
import 'expense_sheet.dart';

/// Opens the speak-an-expense sheet: "add 50 rupees for medicines".
///
/// Nothing is ever saved straight from speech. What was heard is read back as
/// a draft and needs one tap to keep, because a misheard amount quietly
/// landing in the month's total is worse than an extra tap.
Future<void> showVoiceExpenseSheet(
  BuildContext context, {
  DateTime? day,
  SpeechRecogniser? recogniser,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _VoiceExpenseSheet(day: day, recogniser: recogniser),
  );
}

enum _Stage { starting, listening, heard, failed }

class _VoiceExpenseSheet extends StatefulWidget {
  const _VoiceExpenseSheet({this.day, this.recogniser});

  final DateTime? day;

  /// Swapped in tests for one that does not need a microphone.
  final SpeechRecogniser? recogniser;

  @override
  State<_VoiceExpenseSheet> createState() => _VoiceExpenseSheetState();
}

class _VoiceExpenseSheetState extends State<_VoiceExpenseSheet> {
  late final SpeechRecogniser _recogniser =
      widget.recogniser ?? DeviceSpeechRecogniser();

  _Stage _stage = _Stage.starting;
  String _words = '';
  SpeechProblem? _problem;
  VoiceExpenseDraft? _draft;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void dispose() {
    _recogniser.cancel();
    super.dispose();
  }

  Future<void> _listen() async {
    setState(() {
      _stage = _Stage.starting;
      _words = '';
      _draft = null;
      _problem = null;
    });

    final readiness = await _recogniser.prepare();
    if (!mounted) return;

    if (readiness is SpeechUnavailable) {
      setState(() {
        _stage = _Stage.failed;
        _problem = readiness.problem;
      });
      return;
    }

    setState(() => _stage = _Stage.listening);
    await _recogniser.start(
      onWords: (words, isFinal) {
        if (!mounted) return;
        setState(() => _words = words);
        if (isFinal) _settle(words);
      },
      onDone: () {
        // The engine stops itself after a pause; whatever was heard by then
        // is what we work with.
        if (mounted && _stage == _Stage.listening) _settle(_words);
      },
    );
  }

  /// Reads what was said into a draft and shows it for checking.
  void _settle(String words) {
    if (!mounted) return;
    setState(() {
      _words = words;
      _draft = parseVoiceExpense(words, now: _referenceNow());
      _stage = _Stage.heard;
    });
  }

  /// The day the sheet was opened on, so "yesterday" means the day before
  /// the one being looked at rather than the day before today.
  DateTime _referenceNow() => widget.day ?? DateTime.now();

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !draft.isUsable || _isSaving) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await context.read<ExpensesProvider>().add(
      Expense(
        id: 'e_${DateTime.now().microsecondsSinceEpoch}',
        amount: draft.amount!,
        category: draft.category,
        date: draft.date,
        note: draft.note,
      ),
    );

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${formatRupees(draft.amount!)} added to spending.'),
      ),
    );
  }

  /// Hands what was understood to the typed sheet, for anything the parser
  /// got wrong or left out.
  Future<void> _openFullSheet() async {
    final draft = _draft;
    final navigator = Navigator.of(context);
    final sheetContext = context;

    navigator.pop();
    if (!sheetContext.mounted) return;
    await showExpenseSheet(
      sheetContext,
      day: draft?.date ?? widget.day,
      prefill: draft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (_stage) {
            _Stage.starting || _Stage.listening => _Listening(words: _words),
            _Stage.failed => _CannotListen(problem: _problem!),
            _Stage.heard => _Heard(draft: _draft!),
          },
          const SizedBox(height: 20),
          ..._actions(),
        ],
      ),
    );
  }

  List<Widget> _actions() {
    switch (_stage) {
      case _Stage.starting:
        return const <Widget>[];

      case _Stage.listening:
        return <Widget>[
          OutlinedButton(
            onPressed: () => _recogniser.stop().then((_) => _settle(_words)),
            child: const Text('Done'),
          ),
        ];

      case _Stage.failed:
        return <Widget>[
          FilledButton(
            onPressed: _openFullSheet,
            child: const Text('Type it instead'),
          ),
        ];

      case _Stage.heard:
        final usable = _draft!.isUsable;
        return <Widget>[
          if (usable)
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(
                _isSaving ? 'Saving…' : 'Save ${formatRupees(_draft!.amount!)}',
              ),
            )
          else
            FilledButton(
              onPressed: _openFullSheet,
              child: const Text('Fill it in'),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _listen,
                  icon: const Icon(Icons.mic_none_rounded, size: 18),
                  label: const Text('Say again'),
                ),
              ),
              if (usable)
                Expanded(
                  child: TextButton(
                    onPressed: _openFullSheet,
                    child: const Text('Change details'),
                  ),
                ),
            ],
          ),
        ];
    }
  }
}

/// The mic is open: show the words as they land so the user can see it is
/// keeping up with them.
class _Listening extends StatelessWidget {
  const _Listening({required this.words});

  final String words;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mic_rounded,
            size: 34,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          words.isEmpty ? 'Listening…' : words,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: words.isEmpty ? 16 : 18,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: words.isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Try "add 50 rupees for medicines".',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        const _PrivacyLine(),
      ],
    );
  }
}

/// What was understood, laid out for checking before anything is kept.
class _Heard extends StatelessWidget {
  const _Heard({required this.draft});

  final VoiceExpenseDraft draft;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!draft.isUsable) {
      return Column(
        children: [
          Icon(Icons.hearing_disabled_rounded, size: 40, color: scheme.outline),
          const SizedBox(height: 14),
          Text(
            draft.transcript.isEmpty
                ? 'Nothing was heard'
                : 'No amount in “${draft.transcript}”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Say the amount too — "add 50 rupees for medicines".',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'You said',
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          '“${draft.transcript}”',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            fontStyle: FontStyle.italic,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatRupees(draft.amount!),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              _HeardRow(
                icon: iconForExpenseCategory(draft.category),
                label: draft.category,
                guessed: !draft.wasHeard(VoiceField.category),
              ),
              if (draft.note != null) ...[
                const SizedBox(height: 8),
                _HeardRow(
                  icon: Icons.notes_rounded,
                  label: draft.note!,
                  guessed: false,
                ),
              ],
              const SizedBox(height: 8),
              _HeardRow(
                icon: Icons.event_rounded,
                label: formatRelativeDay(draft.date),
                guessed: !draft.wasHeard(VoiceField.date),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One line of the draft. Anything not actually spoken says so, so a default
/// is never mistaken for something the user asked for.
class _HeardRow extends StatelessWidget {
  const _HeardRow({
    required this.icon,
    required this.label,
    required this.guessed,
  });

  final IconData icon;
  final String label;
  final bool guessed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.onSecondaryContainer),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: scheme.onSecondaryContainer),
          ),
        ),
        if (guessed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'assumed',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

/// Said plainly when the mic cannot be used, with the reason.
class _CannotListen extends StatelessWidget {
  const _CannotListen({required this.problem});

  final SpeechProblem problem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (String title, String detail) = switch (problem) {
      SpeechProblem.denied => (
        'BillBox cannot hear you',
        'Allow the microphone and speech recognition in Settings to log '
            'spending by voice.',
      ),
      SpeechProblem.unavailable => (
        'No offline speech on this phone',
        'BillBox only uses on-device recognition, so nothing is uploaded. '
            'You can still type the expense in.',
      ),
    };

    return Column(
      children: [
        Icon(Icons.mic_off_rounded, size: 40, color: scheme.outline),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PrivacyLine extends StatelessWidget {
  const _PrivacyLine();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 13, color: scheme.outline),
        const SizedBox(width: 5),
        // Flexible, so a larger text scale wraps instead of overflowing.
        Flexible(
          child: Text(
            'Heard on your phone, never uploaded.',
            style: TextStyle(fontSize: 11, color: scheme.outline),
          ),
        ),
      ],
    );
  }
}
