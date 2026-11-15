import 'package:flutter/material.dart';

import '../../../../core/widgets/choice_pill.dart';
import '../../data/item_search.dart';
import '../../data/search_sample_data.dart';

/// The scrolling chip row under the search field: one category at a time,
/// plus how far ahead to look for expiry dates.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.category,
    required this.window,
    required this.onCategoryChanged,
    required this.onWindowChanged,
  });

  /// Null means every category.
  final String? category;
  final ExpiryWindow window;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<ExpiryWindow> onWindowChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _WindowPill(window: window, onChanged: onWindowChanged),
          const SizedBox(width: 8),
          ChoicePill(
            label: 'All',
            selected: category == null,
            onTap: () => onCategoryChanged(null),
          ),
          for (final name in searchCategories) ...[
            const SizedBox(width: 8),
            ChoicePill(
              label: name,
              selected: category == name,
              // Tapping the selected chip again clears it.
              onTap: () => onCategoryChanged(category == name ? null : name),
            ),
          ],
        ],
      ),
    );
  }
}

/// The expiry chip. Reads as a dropdown because it opens the four windows.
class _WindowPill extends StatelessWidget {
  const _WindowPill({required this.window, required this.onChanged});

  final ExpiryWindow window;
  final ValueChanged<ExpiryWindow> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = window != ExpiryWindow.any;

    return PopupMenuButton<ExpiryWindow>(
      onSelected: onChanged,
      tooltip: 'Expiring within',
      initialValue: window,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final option in ExpiryWindow.values)
          PopupMenuItem<ExpiryWindow>(value: option, child: Text(option.label)),
      ],
      child: ChoicePill(
        label: window.chipLabel,
        selected: selected,
        trailing: Icon(
          Icons.expand_more_rounded,
          size: 16,
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
