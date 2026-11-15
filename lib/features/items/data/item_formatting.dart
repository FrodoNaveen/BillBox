/// Small formatters shared by the capture form, the dashboard and search.
///
/// The app ships without the intl package, so dates and rupees are formatted
/// here — plainly, and the same way everywhere.
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
