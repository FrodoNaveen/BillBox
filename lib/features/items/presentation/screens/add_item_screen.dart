import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/choice_pill.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/bill_item.dart';
import '../../data/bill_scanner.dart';
import '../../data/item_category_catalog.dart';
import '../providers/items_provider.dart';
import '../widgets/review_form_fields.dart';

/// Review and save what was read from the photo.
///
/// Everything the reader filled in is editable and tagged "read from bill";
/// anything it missed is simply empty. Only a title is required — a bill with
/// no readable date is still worth keeping.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({
    super.key,
    this.scanned = const ScannedBill.empty(),
    this.kind = ItemKind.bill,
  });

  final ScannedBill scanned;
  final ItemKind kind;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _store;

  late String _category;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  late Set<int> _leadDays;
  bool _leadDaysTakenFromSettings = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final scanned = widget.scanned;
    _title = TextEditingController(text: scanned.title ?? '');
    _amount = TextEditingController(
      text: scanned.amount == null ? '' : scanned.amount!.round().toString(),
    );
    _store = TextEditingController(text: scanned.store ?? '');
    _category = normaliseCategory(scanned.category);
    _purchaseDate = scanned.purchaseDate;
    _expiryDate = scanned.expiryDate;
    // Replaced with the user's own lead times once the settings provider is
    // reachable, in didChangeDependencies below.
    _leadDays = AppSettings.defaultLeadDays.toSet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_leadDaysTakenFromSettings) {
      _leadDays = context.read<SettingsProvider>().settings.leadDays.toSet();
      _leadDaysTakenFromSettings = true;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _store.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _title.clear();
      _amount.clear();
      _store.clear();
      _category = fallbackCategory;
      _purchaseDate = null;
      _expiryDate = null;
    });
  }

  Future<void> _pickCategory() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final name in itemCategories)
              ListTile(
                leading: Icon(iconForCategory(name)),
                title: Text(name),
                trailing: name == _category
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(name),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickDate({required bool expiry}) async {
    final now = DateTime.now();
    final initial = (expiry ? _expiryDate : _purchaseDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 30),
      helpText: expiry ? widget.kind.dateFieldLabel : 'Purchase date',
    );
    if (picked == null) return;
    setState(() {
      if (expiry) {
        _expiryDate = picked;
      } else {
        _purchaseDate = picked;
      }
    });
  }

  double? _parsedAmount() {
    final digits = _amount.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final item = BillItem(
      id: 'i_${DateTime.now().microsecondsSinceEpoch}',
      title: _title.text.trim(),
      category: _category,
      kind: widget.kind,
      savedAt: DateTime.now(),
      store: _store.text.trim().isEmpty ? null : _store.text.trim(),
      amount: _parsedAmount(),
      purchaseDate: _purchaseDate,
      expiryDate: _expiryDate,
      scannedText: widget.scanned.rawText,
      reminderLeadDays: _leadDays,
      imageName: widget.scanned.imageName,
    );

    await context.read<ItemsProvider>().add(item);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    messenger.showSnackBar(SnackBar(content: Text(_savedMessage(item))));
  }

  String _savedMessage(BillItem item) {
    if (item.expiryDate == null) return '${item.title} saved.';
    if (_leadDays.isEmpty) {
      return '${item.title} saved. No reminder set.';
    }
    final days = _leadDays.toList()..sort((a, b) => b.compareTo(a));
    return '${item.title} saved. Nudges ${days.join(', ')} days before.';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scanned = widget.scanned;

    return Scaffold(
      appBar: AppBar(
        title: Text(scanned.isEmpty ? 'Add item' : 'Check the details'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _clearAll,
            child: const Text('Clear all'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (!scanned.isEmpty) ...[
              const ScanReviewBanner(
                text:
                    'Read from the photo on your phone. Check the details '
                    'before saving.',
              ),
              const SizedBox(height: 14),
            ],
            if (scanned.imageName != null) ...[
              CapturedPhotoRow(
                imageName: scanned.imageName!,
                sourceLabel: scanned.source.label,
                onRetake: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 16),
            ],
            AppTextField(
              label: 'Title',
              controller: _title,
              hint: 'Split AC, passport, policy…',
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Give the item a name' : null,
            ),
            if (scanned.wasRead(ScannedField.title)) const ReadFromBillChip(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PickerField(
                    label: 'Category',
                    value: _category,
                    icon: Icons.expand_more_rounded,
                    onTap: _pickCategory,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 138,
                  child: AppTextField(
                    label: 'Amount',
                    controller: _amount,
                    hint: '39,699',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                    prefix: const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text('₹', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
            if (scanned.wasRead(ScannedField.amount)) const ReadFromBillChip(),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Store or issuer',
              controller: _store,
              hint: 'Sri Electronics, Coimbatore',
              optional: true,
              textCapitalization: TextCapitalization.words,
            ),
            if (scanned.wasRead(ScannedField.store)) const ReadFromBillChip(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PickerField(
                    label: 'Purchase date',
                    value: pickerDateLabel(_purchaseDate),
                    placeholder: 'Pick a date',
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _pickDate(expiry: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PickerField(
                    label: widget.kind.dateFieldLabel,
                    value: pickerDateLabel(_expiryDate),
                    placeholder: 'Pick a date',
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _pickDate(expiry: true),
                  ),
                ),
              ],
            ),
            if (scanned.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  '${scanned.note} · you can change this',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _ReminderChips(
              leadDays: _leadDays,
              enabled: _expiryDate != null,
              onToggle: (days) => setState(() {
                if (!_leadDays.remove(days)) _leadDays.add(days);
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SaveBar(
        isSaving: _isSaving,
        onCancel: () => Navigator.of(context).maybePop(),
        onSave: _save,
      ),
    );
  }
}

/// How long before the date to be nudged, starting from the saved settings.
class _ReminderChips extends StatelessWidget {
  const _ReminderChips({
    required this.leadDays,
    required this.enabled,
    required this.onToggle,
  });

  final Set<int> leadDays;
  final bool enabled;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Remind me before'),
        if (!enabled)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Pick a date above to set reminders.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final days in AppSettings.leadDayOptions)
              ChoicePill(
                label: days == 1 ? '1 day' : '$days days',
                semanticLabel: 'Remind me $days days before',
                selected: leadDays.contains(days),
                onTap: enabled ? () => onToggle(days) : null,
              ),
          ],
        ),
      ],
    );
  }
}

/// Cancel and save, pinned under the form.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: isSaving ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 20),
                  label: const Text('Save item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
