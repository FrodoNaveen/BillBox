import 'package:flutter/material.dart';

import '../../data/bill_item.dart';

/// The capture flow is the one dark screen in the app, so its few shades sit
/// here rather than in the app-wide palette.
const Color captureInk = Color(0xFF10201F);
const Color capturePanel = Color(0xFF1E3433);
const Color captureSurface = Color(0xFF1A2726);
const Color captureOnInk = Color(0xFFC5CFCE);
const Color captureOutline = Color(0xFF45504F);

/// The framed area the bill is lined up in: corner brackets, a stand-in for
/// the camera preview, and the on-device reading note.
class Viewfinder extends StatelessWidget {
  const Viewfinder({super.key, required this.kind, required this.isReading});

  final ItemKind kind;

  /// True while the photo is being read, which replaces the hint with a
  /// progress line.
  final bool isReading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: captureSurface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Center(child: _PreviewStandIn()),
            for (final corner in _corners)
              Align(
                alignment: corner,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _CornerBracket(
                    corner: corner,
                    color: scheme.primaryContainer,
                  ),
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: _HintBanner(
                isReading: isReading,
                kind: kind,
                accent: scheme.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<Alignment> _corners = <Alignment>[
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];
}

/// Stands in for the camera preview until the camera plugin is added, and
/// says as much instead of pretending to be a live feed.
class _PreviewStandIn extends StatelessWidget {
  const _PreviewStandIn();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 70, 34, 86),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 54,
            color: captureOnInk.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 14),
          Text(
            'Camera preview arrives with the camera plugin.\n'
            'Until then the details are typed in on the next screen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: captureOnInk.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({required this.corner, required this.color});

  final Alignment corner;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final top = corner.y < 0;
    final left = corner.x < 0;
    final side = BorderSide(color: color, width: 3);
    const round = Radius.circular(10);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? round : Radius.zero,
          topRight: top && !left ? round : Radius.zero,
          bottomLeft: !top && left ? round : Radius.zero,
          bottomRight: !top && !left ? round : Radius.zero,
        ),
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({
    required this.isReading,
    required this.kind,
    required this.accent,
  });

  final bool isReading;
  final ItemKind kind;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final subject = kind == ItemKind.bill ? 'bill' : 'document';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xD1081817),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: isReading
                ? CircularProgressIndicator(strokeWidth: 2, color: accent)
                : Icon(
                    Icons.document_scanner_outlined,
                    size: 18,
                    color: accent,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isReading
                  ? 'Reading the $subject…'
                  : 'Hold steady — text is read on your phone, nothing is '
                        'uploaded.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFFE3EAE9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
