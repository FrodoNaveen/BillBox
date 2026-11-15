import 'package:flutter/material.dart';

/// The rounded search field at the top of the search tab. Shows a clear
/// button once something is typed, and the scan-to-search button otherwise.
class SearchPillField extends StatelessWidget {
  const SearchPillField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onScan,
    this.focusNode,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onScan;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 22, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 16, color: scheme.onSurface),
              decoration: const InputDecoration(
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Search bills, text, stores',
              ),
            ),
          ),
          if (hasText)
            IconButton(
              onPressed: onClear,
              tooltip: 'Clear search',
              icon: const Icon(Icons.close_rounded, size: 22),
              color: scheme.onSurfaceVariant,
            )
          else
            IconButton(
              onPressed: onScan,
              tooltip: 'Scan to search',
              icon: const Icon(Icons.document_scanner_outlined, size: 22),
              color: scheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}
