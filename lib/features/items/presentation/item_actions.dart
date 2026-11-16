import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/bill_item.dart';
import 'providers/items_provider.dart';
import 'screens/add_item_screen.dart';

/// Correcting or removing a saved item, in one place.
///
/// The detail screen and the swipe actions on every item row both go through
/// these, so a bill entered wrongly is fixed the same way wherever it is
/// found, and the wording of the warning never drifts apart.

/// Opens the review form on [item] so its details can be corrected.
Future<void> editItem(BuildContext context, BillItem item) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AddItemScreen(existing: item)),
  );
}

/// Asks before anything is lost. True once the user has said to go ahead.
Future<bool> confirmDeleteItem(BuildContext context, BillItem item) async {
  final confirmed = await showDialog<bool>(
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
  return confirmed ?? false;
}

/// Removes [item] and says so. The caller has already asked.
///
/// The messenger is looked up before the write, so the note still appears if
/// the row that triggered this has gone by the time it finishes.
Future<void> deleteItem(BuildContext context, BillItem item) async {
  final messenger = ScaffoldMessenger.of(context);
  await context.read<ItemsProvider>().remove(item.id);
  messenger.showSnackBar(SnackBar(content: Text('${item.title} deleted.')));
}
