import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../items/presentation/providers/items_provider.dart';
import '../../../items/presentation/screens/item_detail_screen.dart';
import '../../../items/presentation/widgets/swipeable_item_row.dart';
import '../../data/item_search.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/search_pill_field.dart';
import '../widgets/search_result_tile.dart';

/// The search tab: a query, a category chip, an expiry window, and the rows
/// that match. Everything filters as the user types, over the items
/// [ItemsProvider] holds — only what has actually been saved.
///
/// Each result swipes right to edit and left to delete, so a bill entered
/// wrongly can be put right from the list.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  String _query = '';
  String? _category;
  ExpiryWindow _window = ExpiryWindow.any;
  SearchSort _sort = SearchSort.date;

  bool get _hasFilters =>
      _query.trim().isNotEmpty ||
      _category != null ||
      _window != ExpiryWindow.any;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetFilters() {
    _controller.clear();
    setState(() {
      _query = '';
      _category = null;
      _window = ExpiryWindow.any;
    });
  }

  void _showNotReady(String what) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$what is not built yet.')));
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ItemsProvider>();
    final results = searchItems(
      source: items.searchItems,
      query: _query,
      category: _category,
      window: _window,
      sort: _sort,
    );
    final fromScannedText = countScannedTextOnlyMatches(results, _query);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SearchPillField(
                controller: _controller,
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _controller.clear();
                  setState(() => _query = '');
                },
                onScan: () => _showNotReady('Scan to search'),
              ),
            ),
            const SizedBox(height: 14),
            SearchFilterBar(
              category: _category,
              window: _window,
              onCategoryChanged: (value) => setState(() => _category = value),
              onWindowChanged: (value) => setState(() => _window = value),
            ),
            _ResultsHeader(
              count: results.length,
              fromScannedText: fromScannedText,
              sort: _sort,
              onToggleSort: () => setState(() => _sort = _sort.next),
            ),
            Expanded(
              child: results.isEmpty
                  ? _EmptyResults(
                      query: _query,
                      onClearFilters: _hasFilters ? _resetFilters : null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: results.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == results.length) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: _ScannedTextNote(),
                          );
                        }
                        final item = results[index];
                        final saved = items.itemById(item.itemId);
                        final tile = SearchResultTile(
                          item: item,
                          query: _query,
                          onTap: saved == null
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ItemDetailScreen(itemId: saved.id),
                                  ),
                                ),
                        );
                        if (saved == null) return tile;
                        return SwipeableItemRow(item: saved, child: tile);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How many rows matched, and the button that flips date / name order.
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.count,
    required this.fromScannedText,
    required this.sort,
    required this.onToggleSort,
  });

  final int count;
  final int fromScannedText;
  final SearchSort sort;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = StringBuffer('$count ${count == 1 ? 'result' : 'results'}');
    if (fromScannedText > 0) {
      label.write(' · including scanned text');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toString(),
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
          TextButton.icon(
            onPressed: count > 1 ? onToggleSort : null,
            icon: const Icon(Icons.swap_vert_rounded, size: 18),
            label: Text(sort.label, style: const TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reminder that the query also runs over the text read from each photo.
class _ScannedTextNote extends StatelessWidget {
  const _ScannedTextNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search also looks inside the text scanned from each bill.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query, this.onClearFilters});

  final String query;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmed = query.trim();

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 46, color: scheme.outline),
            const SizedBox(height: 14),
            Text(
              trimmed.isEmpty
                  ? 'Nothing matches these filters'
                  : 'No match for “$trimmed”',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a shorter word, or widen the category and date filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (onClearFilters != null) ...[
              const SizedBox(height: 18),
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
