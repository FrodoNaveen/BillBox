import 'package:flutter/material.dart';

import '../../data/bill_item.dart';
import '../item_actions.dart';

/// Wraps an item row so a wrong entry can be fixed without opening it.
///
/// Dragging right uncovers an edit panel, dragging left a delete panel, both
/// behind the row itself. Let go past a third of the width and the action
/// fires: edit opens the review form and the row springs back, delete asks
/// first and only then takes the item away.
class SwipeableItemRow extends StatelessWidget {
  const SwipeableItemRow({super.key, required this.item, required this.child});

  final BillItem item;

  /// The row as it looks when nothing is being dragged.
  final Widget child;

  /// Far enough that a careless drag while scrolling cannot delete anything.
  static const double _threshold = 0.33;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey<String>('swipe_${item.id}'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const <DismissDirection, double>{
        DismissDirection.startToEnd: _threshold,
        DismissDirection.endToStart: _threshold,
      },
      background: const _ActionPanel(
        icon: Icons.edit_outlined,
        label: 'Edit',
        alignment: Alignment.centerLeft,
        intent: _Intent.edit,
      ),
      secondaryBackground: const _ActionPanel(
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
        alignment: Alignment.centerRight,
        intent: _Intent.delete,
      ),
      // Neither action removes the row on its own: editing never should, and
      // deleting has to be agreed to first.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await editItem(context, item);
          return false;
        }
        return confirmDeleteItem(context, item);
      },
      // Runs once the row has animated away, so the list is never rebuilt
      // from under the animation.
      onDismissed: (_) => deleteItem(context, item),
      child: child,
    );
  }
}

enum _Intent { edit, delete }

/// What sits behind the row while it is being dragged aside.
class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.icon,
    required this.label,
    required this.alignment,
    required this.intent,
  });

  final IconData icon;
  final String label;
  final Alignment alignment;
  final _Intent intent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color panel, Color onPanel) = switch (intent) {
      _Intent.edit => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _Intent.delete => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: panel,
        // Matches the radius of the rows it sits behind.
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: onPanel),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: onPanel,
            ),
          ),
        ],
      ),
    );
  }
}
