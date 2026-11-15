import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';
import '../../data/expense_summary.dart';

/// The dashboard's spending card: this month's total, today's total, and a
/// week of bars. Tapping it opens the calendar.
class SpendingCard extends StatelessWidget {
  const SpendingCard({
    super.key,
    required this.monthTotal,
    required this.todayTotal,
    required this.week,
    required this.onTap,
  });

  final double monthTotal;
  final double todayTotal;

  /// Seven days, oldest first.
  final List<DayTotal> week;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nothingYet = monthTotal == 0;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending this month',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupees(monthTotal),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nothingYet
                          ? 'Nothing logged yet — tap to add'
                          : 'today ${formatRupees(todayTotal)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _WeekBars(week: week),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seven bars, each day's total against the busiest day of the week. A flat
/// row of stubs means a week with no spending, which is the honest picture.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.week});

  final List<DayTotal> week;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final peak = week.fold<double>(
      0,
      (high, day) => day.total > high ? day.total : high,
    );
    final total = week.fold<double>(0, (sum, day) => sum + day.total);

    return Semantics(
      label: 'Last seven days, ${formatRupees(total)} in total',
      child: SizedBox(
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final day in week) ...[
              _Bar(
                fraction: peak == 0 ? 0 : day.total / peak,
                today: isSameDay(day.day, DateTime.now()),
                color: scheme.primary,
                emptyColor: AppColors.outlineVariant,
              ),
              if (day != week.last) const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.today,
    required this.color,
    required this.emptyColor,
  });

  final double fraction;
  final bool today;
  final Color color;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    // A day with nothing spent still shows a stub, so the week reads as seven
    // days rather than a gap.
    const minHeight = 4.0;
    final height = minHeight + (48 - minHeight) * fraction.clamp(0, 1);

    return Container(
      width: 7,
      height: height,
      decoration: BoxDecoration(
        color: fraction == 0
            ? emptyColor
            : color.withValues(alpha: today ? 1 : 0.75),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
