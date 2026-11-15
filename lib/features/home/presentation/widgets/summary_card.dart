import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One of the two counters at the top of the dashboard: a big number over a
/// short label. [highlight] paints the warm "needs attention" variant.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final int value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = highlight
        ? scheme.onTertiaryContainer
        : scheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.tertiaryContainer
            : scheme.surfaceContainerLowest,
        border: highlight ? null : Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? foreground : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
