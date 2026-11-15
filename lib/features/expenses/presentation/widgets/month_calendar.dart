import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';

/// A Monday-first month grid, built by hand so it matches the app's palette.
///
/// Days with spending carry a dot; the dot grows with the amount against the
/// busiest day of the month. The exact figure is never left to the dot alone —
/// selecting a day shows it in full underneath, and each cell says it out loud
/// for a screen reader.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.dailyTotals,
    required this.onSelectDay,
    required this.onChangeMonth,
    this.today,
  });

  /// Any date inside the month being shown.
  final DateTime month;

  final DateTime selectedDay;

  /// Day (at midnight) -> amount spent that day.
  final Map<DateTime, double> dailyTotals;

  final ValueChanged<DateTime> onSelectDay;

  /// Called with the first day of the month to move to.
  final ValueChanged<DateTime> onChangeMonth;

  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = today ?? DateTime.now();
    final first = startOfMonth(month);
    final peak = dailyTotals.values.fold<double>(
      0,
      (high, total) => total > high ? total : high,
    );
    final blanks = leadingBlanks(first);
    final total = daysInMonth(first);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _MonthHeader(
            month: first,
            onPrevious: () =>
                onChangeMonth(DateTime(first.year, first.month - 1)),
            onNext: () => onChangeMonth(DateTime(first.year, first.month + 1)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final initial in weekdayInitials)
                Expanded(
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (int row = 0; row < ((blanks + total + 6) ~/ 7); row++)
            Row(
              children: [
                for (int column = 0; column < 7; column++)
                  Expanded(
                    child: _cellFor(
                      dayNumber: row * 7 + column + 1 - blanks,
                      month: first,
                      now: now,
                      peak: peak,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cellFor({
    required int dayNumber,
    required DateTime month,
    required DateTime now,
    required double peak,
  }) {
    if (dayNumber < 1 || dayNumber > daysInMonth(month)) {
      return const SizedBox(height: 44);
    }
    final day = DateTime(month.year, month.month, dayNumber);
    return _DayCell(
      day: day,
      spent: dailyTotals[day] ?? 0,
      peak: peak,
      selected: isSameDay(day, selectedDay),
      isToday: isSameDay(day, now),
      inFuture: day.isAfter(dayOf(now)),
      onTap: () => onSelectDay(day),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Previous month',
          color: scheme.onSurfaceVariant,
        ),
        Expanded(
          child: Text(
            formatMonthYear(month),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Next month',
          color: scheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.spent,
    required this.peak,
    required this.selected,
    required this.isToday,
    required this.inFuture,
    required this.onTap,
  });

  final DateTime day;
  final double spent;
  final double peak;
  final bool selected;
  final bool isToday;
  final bool inFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color foreground;
    if (selected) {
      foreground = scheme.onPrimary;
    } else if (inFuture) {
      foreground = scheme.onSurfaceVariant.withValues(alpha: 0.55);
    } else {
      foreground = scheme.onSurface;
    }

    // 4px with any spending at all, up to 8px on the month's busiest day.
    final double dotSize = spent == 0
        ? 0
        : 4 + (peak == 0 ? 0 : (spent / peak).clamp(0.0, 1.0) * 4);

    return Semantics(
      button: true,
      selected: selected,
      label: spent == 0
          ? '${day.day} ${formatMonthYear(day).split(' ').first}, nothing spent'
          : '${day.day} ${formatMonthYear(day).split(' ').first}, '
                '${formatRupees(spent)} spent',
      child: SizedBox(
        height: 44,
        child: Center(
          child: Material(
            color: selected ? scheme.primary : Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isToday && !selected
                      ? Border.all(color: scheme.primary, width: 1.4)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected || isToday
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 8,
                      child: dotSize == 0
                          ? null
                          : Container(
                              width: dotSize,
                              height: dotSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? scheme.onPrimary
                                    : scheme.primary,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
