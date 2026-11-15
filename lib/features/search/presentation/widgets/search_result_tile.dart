import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/search_sample_data.dart';
import 'highlighted_text.dart';

/// One search result: the bill thumbnail, the title and its date line, the
/// matching line of scanned text, and how many days are left.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.item,
    required this.query,
    this.onTap,
  });

  final SearchableItem item;

  /// Highlighted wherever it appears in the title or the scanned text.
  final String query;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 74,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 24, color: scheme.outline),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightedText(
                      text: item.title,
                      query: query,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.category} · ${item.dateLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    HighlightedText(
                      text: '“${item.scannedText}”',
                      query: query,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _DaysBadge(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

/// Days left, coloured red within a week, amber within a month, quiet after.
class _DaysBadge extends StatelessWidget {
  const _DaysBadge({required this.item});

  final SearchableItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (Color background, Color foreground) = switch (item.band) {
      ExpiryBand.urgent => (scheme.errorContainer, scheme.onErrorContainer),
      ExpiryBand.soon => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      ExpiryBand.later => (scheme.surfaceContainer, scheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '${item.daysLeft} d',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }
}
