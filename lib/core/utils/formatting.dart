/// Dates, days and rupees, formatted the same way everywhere.
///
/// The app ships without the intl package, so these few helpers stand in for
/// it. Plain English, Indian rupees, no locale switching in v1.
const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "20 Nov 2026".
String formatItemDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// Rupees with Indian grouping: 39699 -> "₹39,699", 500000 -> "₹5,00,000".
String formatRupees(num amount) {
  final rounded = amount.round().abs();
  final digits = rounded.toString();
  final sign = amount < 0 ? '-' : '';

  if (digits.length <= 3) return '$sign₹$digits';

  // Last three digits, then pairs: 5,00,000.
  final lastThree = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);

  return '$sign₹${groups.join(',')},$lastThree';
}

/// Whole days from [from] to [to], counting part days as a day.
int daysBetween(DateTime from, DateTime to) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  return end.difference(start).inDays;
}

/// "November 2026", for the calendar header.
String formatMonthYear(DateTime month) =>
    '${_longMonths[month.month - 1]} ${month.year}';

/// Monday-first initials for the calendar's column headings.
const List<String> weekdayInitials = <String>[
  'M',
  'T',
  'W',
  'T',
  'F',
  'S',
  'S',
];

const List<String> _longMonths = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// True when both fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Midnight on the given day, which is how a day is keyed in a map.
DateTime dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month);

int daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

/// How many blank cells come before the 1st in a Monday-first grid.
int leadingBlanks(DateTime month) => startOfMonth(month).weekday - 1;

/// "Today", "Yesterday", or "15 Nov 2026".
String formatRelativeDay(DateTime date, {DateTime? now}) {
  final today = dayOf(now ?? DateTime.now());
  final day = dayOf(date);
  final difference = day.difference(today).inDays;
  if (difference == 0) return 'Today';
  if (difference == -1) return 'Yesterday';
  if (difference == 1) return 'Tomorrow';
  return formatItemDate(date);
}
