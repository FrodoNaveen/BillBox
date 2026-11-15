import 'package:flutter/material.dart';

import '../../../../core/utils/formatting.dart';
import '../../data/bill_item.dart';

/// Backdrop behind the bill on the detail screen's header.
const Color billPaperBackdrop = Color(0xFF1A2726);

/// The header of the item detail screen.
///
/// The photo itself is not on the device yet — that waits for the camera
/// plugin — so the sheet is drawn from what was read off the bill: the store,
/// the lines of scanned text, the amount and the date. Items saved without a
/// photo say so instead.
class BillPaper extends StatelessWidget {
  const BillPaper({super.key, required this.item});

  final BillItem item;

  /// The scanned text, cut into the few lines the sheet has room for.
  List<String> get _lines {
    final text = item.scannedText.trim();
    if (text.isEmpty) return const <String>[];
    return text
        .split(RegExp(r' · |, '))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(4)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (item.imageName == null) {
      return const ColoredBox(color: billPaperBackdrop, child: _NoPhoto());
    }

    return ColoredBox(
      color: billPaperBackdrop,
      child: Padding(
        // Clear of the app bar above and flush with the body below, as the
        // bill does in the design.
        padding: const EdgeInsets.only(left: 92, right: 92, top: 78),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          decoration: const BoxDecoration(
            color: Color(0xFFF2F3EF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Color(0x4D000000),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (item.store ?? item.title).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Color(0xFF262A29),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${item.category} · ${item.kind.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: Color(0xFF5A615F)),
              ),
              const SizedBox(height: 9),
              const _PaperRule(),
              const SizedBox(height: 8),
              for (final line in _lines) ...[
                Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF3C4140),
                  ),
                ),
                const SizedBox(height: 5),
              ],
              const Spacer(),
              if (item.amount != null) ...[
                const _PaperRule(),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF262A29),
                        ),
                      ),
                    ),
                    Text(
                      formatRupees(item.amount!),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF262A29),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Text(
                item.dateLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: Color(0xFF5A615F)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperRule extends StatelessWidget {
  const _PaperRule();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 1, child: ColoredBox(color: Color(0xFFC9CEC9)));
}

class _NoPhoto extends StatelessWidget {
  const _NoPhoto();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          Text(
            'No photo saved for this item',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
