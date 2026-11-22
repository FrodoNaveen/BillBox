import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/formatting.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/choice_pill.dart';
import '../../data/expense.dart';
import '../../data/voice_expense_parser.dart';
import '../providers/expenses_provider.dart';

/// Opens the log-an-expense sheet. Pass [existing] to edit one instead, or
/// [prefill] to open it on what a spoken phrase was understood to mean.
Future<void> showExpenseSheet(
  BuildContext context, {
  DateTime? day,
  Expense? existing,
  VoiceExpenseDraft? prefill,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      // Lift the sheet above the keyboard, since the amount field takes focus.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _ExpenseSheet(day: day, existing: existing, prefill: prefill),
    ),
  );
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({this.day, this.existing, this.prefill});

  final DateTime? day;
  final Expense? existing;

  /// What was heard, when the sheet was opened to correct a spoken entry.
  final VoiceExpenseDraft? prefill;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;

  late String _category;
  late DateTime _date;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    // An edit wins over a spoken draft, which wins over an empty sheet.
    final spoken = widget.prefill;

    _amount = TextEditingController(
      text: switch ((existing, spoken?.amount)) {
        (final Expense e, _) => e.amount.round().toString(),
        (null, final double amount) => amount.round().toString(),
        _ => '',
      },
    );
    _note = TextEditingController(text: existing?.note ?? spoken?.note ?? '');
    _category =
        existing?.category ?? spoken?.category ?? expenseCategories.first;
    _date = dayOf(
      existing?.date ?? spoken?.date ?? widget.day ?? DateTime.now(),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      helpText: 'Spent on',
    );
    if (picked != null) setState(() => _date = dayOf(picked));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = double.tryParse(
      _amount.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (amount == null || amount <= 0) return;

    setState(() => _isSaving = true);
    final provider = context.read<ExpensesProvider>();
    final note = _note.text.trim();

    if (_isEditing) {
      await provider.edit(
        widget.existing!.copyWith(
          amount: amount,
          category: _category,
          date: _date,
          note: note.isEmpty ? null : note,
          clearNote: note.isEmpty,
        ),
      );
    } else {
      await provider.add(
        Expense(
          id: 'e_${DateTime.now().microsecondsSinceEpoch}',
          amount: amount,
          category: _category,
          date: _date,
          note: note.isEmpty ? null : note,
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final provider = context.read<ExpensesProvider>();
    await provider.remove(widget.existing!.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit expense' : 'Log an expense',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      onPressed: _isSaving ? null : _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Delete expense',
                      color: scheme.error,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Amount',
                controller: _amount,
                hint: '0',
                autofocus: !_isEditing,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                prefix: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Text('₹', style: TextStyle(fontSize: 16)),
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').replaceAll(RegExp(r'[^0-9.]'), ''),
                  );
                  if (amount == null || amount <= 0) {
                    return 'Enter how much you spent';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.primary,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in expenseCategories)
                    ChoicePill(
                      label: category,
                      selected: category == _category,
                      onTap: () => setState(() => _category = category),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'What was it for',
                controller: _note,
                hint: 'Lunch at office',
                optional: true,
                textCapitalization: TextCapitalization.sentences,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text('Spent on ${formatRelativeDay(_date)}'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isEditing ? 'Save changes' : 'Save expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
