import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../expenses/presentation/screens/expenses_screen.dart';
import '../../data/bill_item.dart';
import '../providers/items_provider.dart';
import '../widgets/bill_paper.dart';
import 'add_item_screen.dart';

/// Everything kept about one item: the photo it came from, how long is left,
/// the figures and dates, the text read from the bill, and the way to edit or
/// delete it.
///
/// Takes an id rather than the item itself, so an edit made here is reflected
/// the moment it is saved.
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  Future<void> _edit(BuildContext context, BillItem item) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AddItemScreen(existing: item)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, BillItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this item?'),
        content: Text(
          '${item.title} and its reminders are removed from this phone. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!(shouldDelete ?? false) || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await context.read<ItemsProvider>().remove(item.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text('${item.title} deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = context.watch<ItemsProvider>().itemById(itemId);

    // The item can go while this screen is open — a delete from here, or an
    // edit elsewhere. Say so instead of showing a blank screen.
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item')),
        body: const Center(child: Text('This item is no longer saved.')),
      );
    }

    final expense = context.watch<ExpensesProvider>().expenseForItem(item.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 268,
            backgroundColor: billPaperBackdrop,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(background: BillPaper(item: item)),
            actions: [
              if (!item.isSample)
                PopupMenuButton<String>(
                  tooltip: 'More options',
                  onSelected: (choice) => choice == 'edit'
                      ? _edit(context, item)
                      : _confirmDelete(context, item),
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _Heading(item: item),
                const SizedBox(height: 14),
                _StatusBanner(item: item),
                const SizedBox(height: 14),
                _DetailsCard(item: item),
                if (expense != null) ...[
                  const SizedBox(height: 14),
                  _LoggedAsSpending(
                    label:
                        '${formatRupees(expense.amount)} on '
                        '${formatItemDate(expense.date)}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ExpensesScreen(initialDay: expense.date),
                      ),
                    ),
                  ),
                ],
                if (item.scannedText.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ScannedTextPanel(text: item.scannedText),
                ],
                if (item.isSample) ...[
                  const SizedBox(height: 14),
                  Text(
                    'This is one of the sample items BillBox starts with. '
                    'Save a bill of your own and these make way for it.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: item.isSample
          ? null
          : _ActionBar(
              onEdit: () => _edit(context, item),
              onDelete: () => _confirmDelete(context, item),
            ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.item});

  final BillItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                item.category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
            if (item.store != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.store!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// How long is left, in the colour the dashboard uses for the same deadline.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.item});

  final BillItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = item.daysLeft();
    final date = item.expiryDate;

    final (Color background, Color foreground, IconData icon) = switch (days) {
      null => (
        scheme.surfaceContainer,
        scheme.onSurfaceVariant,
        Icons.event_busy_outlined,
      ),
      final d when d < 0 => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
      final d when d <= 7 => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.schedule_rounded,
      ),
      final d when d <= 30 => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.schedule_rounded,
      ),
      _ => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.verified_outlined,
      ),
    };

    final headline = switch (days) {
      null => 'No date saved',
      0 => '${item.kind.datePrefix} ends today',
      final d when d < 0 =>
        '${item.kind.datePrefix} ended ${-d} ${-d == 1 ? 'day' : 'days'} ago',
      final d =>
        '${item.kind.datePrefix} ends in $d ${d == 1 ? 'day' : 'days'}',
    };

    final detail = date == null
        ? 'Add a date to be reminded before it runs out'
        : item.kind == ItemKind.bill
        ? '${formatItemDate(date)} · claim before this date'
        : '${formatItemDate(date)} · renew before this date';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detail, style: TextStyle(fontSize: 12, color: foreground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Amount, dates and reminders, one per row.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.item});

  final BillItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final leadDays = item.reminderLeadDays.toList()
      ..sort((a, b) => b.compareTo(a));

    final rows = <(String, String)>[
      if (item.amount != null) ('Amount paid', formatRupees(item.amount!)),
      (
        item.kind == ItemKind.bill ? 'Purchase date' : 'Issued on',
        item.purchaseDate == null
            ? 'Not saved'
            : formatItemDate(item.purchaseDate!),
      ),
      (
        item.kind.dateFieldLabel,
        item.expiryDate == null
            ? 'Not saved'
            : formatItemDate(item.expiryDate!),
      ),
      (
        'Reminders',
        leadDays.isEmpty
            ? 'None set'
            : '${leadDays.join(' · ')} ${leadDays.last == 1 && leadDays.length == 1 ? 'day' : 'days'} before',
      ),
      if (item.imageName != null) ('Photo', item.imageName!),
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown when the bill was also counted as spending, and opens that day.
class _LoggedAsSpending extends StatelessWidget {
  const _LoggedAsSpending({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                Icons.currency_rupee_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logged as spending',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The text read from the photo, folded away until it is asked for.
class _ScannedTextPanel extends StatelessWidget {
  const _ScannedTextPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // The card already carries the tint, so the tile stays transparent.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            Icons.description_outlined,
            size: 20,
            color: scheme.onSurface,
          ),
          title: Text(
            'Text read from this bill',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SelectableText(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 19),
                label: const Text('Edit'),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: scheme.error),
                  foregroundColor: scheme.error,
                ),
                child: Tooltip(
                  message: 'Delete item',
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: scheme.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
