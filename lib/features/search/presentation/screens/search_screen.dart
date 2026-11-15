import 'package:flutter/material.dart';

import '../../../../core/widgets/coming_soon_view.dart';

/// Placeholder for the search tab.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: const ComingSoonView(
        icon: Icons.search_rounded,
        title: 'Search',
        message:
            'Find any bill, warranty or document by name, category or the '
            'text read from the photo.',
      ),
    );
  }
}
