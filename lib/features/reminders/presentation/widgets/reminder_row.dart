import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';
import '../../../items/data/bill_item.dart';

/// One deadline: the date on a tinted block, what it is, and how long is
/// left. Red inside a week, amber inside a month, quiet after that.
class ReminderRow extends StatelessWidget {
  const ReminderRow({super.key, required this.item, this.onTap});

  final BillItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = item.expiryDate!;
    final days = item.daysLeft() ?? 0;

    final (Color block, Color onBlock) = days < 0 || days <= 7
        ? (scheme.errorContainer, scheme.onErrorContainer)
        : days <= 30
        ? (scheme.tertiaryContainer, scheme.onTertiaryContainer)
        : (scheme.surfaceContainer, scheme.onSurfaceVariant);

    final badge = days < 0
        ? '${-days} ${-days == 1 ? 'day' : 'days'} ago'
        : days == 0
        ? 'today'
        : '$days ${days == 1 ? 'day' : 'days'}';

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
            children: [
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: block,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      date.day.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: onBlock,
                      ),
                    ),
                    Text(
                      formatItemDate(date).split(' ')[1].toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: onBlock,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.kind.datePrefix} · ${item.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: block,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: onBlock,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
