import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../items/presentation/providers/items_provider.dart';
import '../widgets/category_tile.dart';
import '../widgets/expiring_item_tile.dart';
import '../widgets/summary_card.dart';

/// The dashboard: what is saved, what expires next, and the categories to
/// browse. The numbers and rows come from [ItemsProvider], which stands in
/// the sample catalogue until the first item is saved and says so on screen.
///
/// It is one tab of the app shell, so the search and bell actions hand control
/// back to the shell instead of pushing a route.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenSearch,
    required this.onOpenReminders,
  });

  final VoidCallback onOpenSearch;
  final VoidCallback onOpenReminders;

  void _showNotReady(BuildContext context, String what) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$what is not built yet.')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = context.watch<ItemsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('BillBox'),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        actions: [
          IconButton(
            onPressed: onOpenSearch,
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search items',
          ),
          _BellButton(
            count: items.expiringSoonCount,
            onPressed: onOpenReminders,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  value: items.savedCount,
                  label: 'items saved',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryCard(
                  value: items.expiringSoonCount,
                  label: 'expiring soon',
                  highlight: true,
                ),
              ),
            ],
          ),
          if (items.isShowingSamples) const _SampleDataNote(),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Expiring soon',
            actionLabel: 'See all',
            onAction: onOpenReminders,
          ),
          const SizedBox(height: 10),
          for (final item in items.expiringItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpiringItemTile(
                item: item,
                onTap: () => _showNotReady(context, 'Item details'),
              ),
            ),
          const SizedBox(height: 8),
          const _SectionHeader(title: 'Categories'),
          const SizedBox(height: 10),
          for (int i = 0; i < items.categories.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: CategoryTile(
                      category: items.categories[i],
                      onTap: onOpenSearch,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (i + 1 < items.categories.length)
                    Expanded(
                      child: CategoryTile(
                        category: items.categories[i + 1],
                        onTap: onOpenSearch,
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Said plainly while the dashboard is still showing the sample catalogue,
/// so the numbers above are never mistaken for the user's own.
class _SampleDataNote extends StatelessWidget {
  const _SampleDataNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Sample items — add your first bill with the + button.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}

/// Reminder bell carrying the count of items that need attention.
class _BellButton extends StatelessWidget {
  const _BellButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      tooltip: count > 0 ? 'Reminders, $count due' : 'Reminders',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded),
          if (count > 0)
            Positioned(
              top: -3,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: scheme.onError,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
