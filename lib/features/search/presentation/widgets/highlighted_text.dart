import 'package:flutter/material.dart';

/// Text with every occurrence of [query] tinted, so a row shows why it
/// matched. Falls back to plain text when the query is empty.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    this.maxLines = 1,
  });

  final String text;
  final String query;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final needle = query.trim().toLowerCase();

    if (needle.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final haystack = text.toLowerCase();
    final spans = <TextSpan>[];
    final match = style.copyWith(
      backgroundColor: scheme.primaryContainer,
      color: scheme.onPrimaryContainer,
    );

    var start = 0;
    while (true) {
      final at = haystack.indexOf(needle, start);
      if (at < 0) break;
      if (at > start) {
        spans.add(TextSpan(text: text.substring(start, at)));
      }
      spans.add(
        TextSpan(text: text.substring(at, at + needle.length), style: match),
      );
      start = at + needle.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
