import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatting.dart';
import '../../data/expense.dart';
import '../../data/expense_summary.dart';
import '../providers/expenses_provider.dart';
import '../widgets/expense_row.dart';
import '../widgets/expense_sheet.dart';
import '../widgets/month_calendar.dart';

/// Daily spending: a month at a glance, then everything spent on the day that
/// is picked — how much, and on what.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, this.initialDay});

  final DateTime? initialDay;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late DateTime _selectedDay = dayOf(widget.initialDay ?? DateTime.now());
  late DateTime _month = startOfMonth(_selectedDay);

  void _changeMonth(DateTime month) {
    setState(() {
      _month = startOfMonth(month);
      // Keep the selection inside the month on view, so the panel below
      // always matches what the grid is showing.
      final lastDay = daysInMonth(_month);
      _selectedDay = DateTime(
        _month.year,
        _month.month,
        _selectedDay.day > lastDay ? lastDay : _selectedDay.day,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpensesProvider>();
    final dayExpenses = provider.onDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('Spending')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showExpenseSheet(context, day: _selectedDay),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
        children: [
          _MonthTotal(
            month: _month,
            total: provider.totalForMonth(_month),
            categories: provider.categoriesInMonth(_month),
          ),
          const SizedBox(height: 14),
          MonthCalendar(
            month: _month,
            selectedDay: _selectedDay,
            dailyTotals: provider.dailyTotalsFor(_month),
            onSelectDay: (day) => setState(() => _selectedDay = day),
            onChangeMonth: _changeMonth,
          ),
          const SizedBox(height: 20),
          _DayHeader(
            day: _selectedDay,
            total: provider.totalOnDay(_selectedDay),
          ),
          const SizedBox(height: 10),
          if (dayExpenses.isEmpty)
            _NothingOnThisDay(
              day: _selectedDay,
              onAdd: () => showExpenseSheet(context, day: _selectedDay),
            )
          else ...[
            _CategoryBreakdown(
              categories: provider.categoriesOnDay(_selectedDay),
              dayTotal: provider.totalOnDay(_selectedDay),
            ),
            const SizedBox(height: 12),
            for (final expense in dayExpenses)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ExpenseRow(
                  expense: expense,
                  onTap: () => showExpenseSheet(context, existing: expense),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The month's total, with its biggest category named.
class _MonthTotal extends StatelessWidget {
  const _MonthTotal({
    required this.month,
    required this.total,
    required this.categories,
  });

  final DateTime month;
  final double total;
  final List<CategoryTotal> categories;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final biggest = categories.isEmpty ? null : categories.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatMonthYear(month),
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupees(total),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          if (biggest != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'most on',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      iconForExpenseCategory(biggest.category),
                      size: 16,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      biggest.category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatRupees(biggest.total),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.total});

  final DateTime day;
  final double total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final relative = formatRelativeDay(day);
    final exact = formatItemDate(day);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                relative,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
              if (relative != exact)
                Text(
                  exact,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Text(
          formatRupees(total),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: total == 0 ? scheme.onSurfaceVariant : scheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Where the day's money went, as a share bar plus the figures.
class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.categories, required this.dayTotal});

  final List<CategoryTotal> categories;
  final double dayTotal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (int i = 0; i < categories.length; i++)
                    Expanded(
                      flex: (categories[i].total * 100).round().clamp(
                        1,
                        1 << 30,
                      ),
                      child: ColoredBox(color: _shadeFor(i, scheme.primary)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _shadeFor(
                        categories.indexOf(category),
                        scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category.category,
                      style: TextStyle(fontSize: 13, color: scheme.onSurface),
                    ),
                  ),
                  Text(
                    formatRupees(category.total),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (dayTotal > 0) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 38,
                      child: Text(
                        '${(category.total / dayTotal * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Shades of the one brand colour, so the bar stays legible without
  /// inventing a second palette.
  static Color _shadeFor(int index, Color primary) {
    const alphas = <double>[1, 0.78, 0.58, 0.42, 0.3, 0.22, 0.16];
    return primary.withValues(alpha: alphas[index % alphas.length]);
  }
}

class _NothingOnThisDay extends StatelessWidget {
  const _NothingOnThisDay({required this.day, required this.onAdd});

  final DateTime day;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final future = day.isAfter(dayOf(DateTime.now()));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            future ? Icons.event_outlined : Icons.savings_outlined,
            size: 34,
            color: scheme.outline,
          ),
          const SizedBox(height: 10),
          Text(
            future
                ? 'Nothing logged for this day yet.'
                : 'Nothing spent on this day.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: scheme.onSurface),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onAdd, child: const Text('Add an expense')),
        ],
      ),
    );
  }
}
