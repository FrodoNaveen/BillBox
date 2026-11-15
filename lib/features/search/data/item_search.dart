import 'search_sample_data.dart';

/// Querying and filtering for the search tab, kept out of the widgets so the
/// rules can be read — and tested — on their own.

/// How far ahead the "expiring" chip looks.
enum ExpiryWindow {
  any('Any date', null),
  days30('Next 30 days', 30),
  days90('Next 90 days', 90),
  days365('Next 12 months', 365);

  const ExpiryWindow(this.label, this.days);

  final String label;

  /// Null means no upper bound.
  final int? days;

  /// Shorter wording for the chip itself.
  String get chipLabel =>
      this == ExpiryWindow.any ? 'Any date' : 'Expiring $days d';
}

enum SearchSort {
  date('Date'),
  name('Name');

  const SearchSort(this.label);

  final String label;

  SearchSort get next =>
      this == SearchSort.date ? SearchSort.name : SearchSort.date;
}

/// Normalised form used by every comparison below.
String _fold(String value) => value.trim().toLowerCase();

/// True when [query] is found in anything the user can see on the row except
/// the scanned text.
bool matchesVisibleText(SearchableItem item, String query) {
  final needle = _fold(query);
  if (needle.isEmpty) return true;
  return _fold(item.title).contains(needle) ||
      _fold(item.category).contains(needle) ||
      _fold(item.dateLabel).contains(needle);
}

/// True when [query] is found in the text read from the photo.
bool matchesScannedText(SearchableItem item, String query) {
  final needle = _fold(query);
  if (needle.isEmpty) return false;
  return _fold(item.scannedText).contains(needle);
}

bool _matchesQuery(SearchableItem item, String query) =>
    matchesVisibleText(item, query) || matchesScannedText(item, query);

bool _matchesCategory(SearchableItem item, String? category) =>
    category == null || item.category == category;

bool _matchesWindow(SearchableItem item, ExpiryWindow window) {
  final limit = window.days;
  return limit == null || item.daysLeft <= limit;
}

/// The rows to show: everything matching the query and both chips, in the
/// order the sort button asks for.
List<SearchableItem> searchItems({
  required List<SearchableItem> source,
  String query = '',
  String? category,
  ExpiryWindow window = ExpiryWindow.any,
  SearchSort sort = SearchSort.date,
}) {
  final results = source
      .where(
        (item) =>
            _matchesQuery(item, query) &&
            _matchesCategory(item, category) &&
            _matchesWindow(item, window),
      )
      .toList();

  results.sort((a, b) {
    switch (sort) {
      case SearchSort.date:
        return a.daysLeft.compareTo(b.daysLeft);
      case SearchSort.name:
        return _fold(a.title).compareTo(_fold(b.title));
    }
  });

  return results;
}

/// How many of [results] were found only by their scanned text, which is what
/// the "including scanned text" note under the chips reports.
int countScannedTextOnlyMatches(List<SearchableItem> results, String query) {
  return results
      .where(
        (item) =>
            !matchesVisibleText(item, query) && matchesScannedText(item, query),
      )
      .length;
}
