import 'package:flutter/material.dart';

import '../../data/bill_item.dart';
import '../../data/bill_scanner.dart';
import '../widgets/viewfinder.dart';
import 'add_item_screen.dart';

/// The capture screen: pick bill or document, then shoot, choose a photo, or
/// skip the photo and type the details in.
///
/// The live camera preview and the text recogniser need plugins the project
/// does not have yet, so the frame holds a stand-in and nothing is read off
/// the photo — the review form opens blank whichever button is used.
/// Everything else — the modes and handing the result to the form — is the
/// real flow.
class CaptureBillScreen extends StatefulWidget {
  const CaptureBillScreen({super.key, this.scanner});

  /// Swapped in tests for an instant reader.
  final BillScanner? scanner;

  @override
  State<CaptureBillScreen> createState() => _CaptureBillScreenState();
}

class _CaptureBillScreenState extends State<CaptureBillScreen> {
  late final BillScanner _scanner = widget.scanner ?? EmptyBillScanner();

  ItemKind _kind = ItemKind.bill;
  bool _flashOn = false;
  bool _isReading = false;

  Future<void> _capture(CaptureSource source) async {
    if (_isReading) return;
    setState(() => _isReading = true);

    final scanned = await _scanner.scan(kind: _kind, source: source);
    if (!mounted) return;
    setState(() => _isReading = false);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddItemScreen(scanned: scanned, kind: _kind),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: captureInk,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              flashOn: _flashOn,
              onToggleFlash: () => setState(() => _flashOn = !_flashOn),
              onClose: () => Navigator.of(context).maybePop(),
            ),
            _KindToggle(
              kind: _kind,
              onChanged: (kind) => setState(() => _kind = kind),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Viewfinder(kind: _kind, isReading: _isReading),
              ),
            ),
            _CaptureControls(
              busy: _isReading,
              onGallery: () => _capture(CaptureSource.gallery),
              onShutter: () => _capture(CaptureSource.camera),
              onManual: () => _capture(CaptureSource.manual),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.flashOn,
    required this.onToggleFlash,
    required this.onClose,
  });

  final bool flashOn;
  final VoidCallback onToggleFlash;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
            tooltip: 'Cancel',
          ),
          const Expanded(
            child: Text(
              'Scan bill',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onToggleFlash,
            icon: Icon(
              flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            ),
            color: Colors.white,
            tooltip: flashOn ? 'Turn flash off' : 'Turn flash on',
          ),
        ],
      ),
    );
  }
}

/// Bill or document, as a two-up segmented control.
class _KindToggle extends StatelessWidget {
  const _KindToggle({required this.kind, required this.onChanged});

  final ItemKind kind;
  final ValueChanged<ItemKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: capturePanel,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in ItemKind.values)
            Semantics(
              selected: option == kind,
              button: true,
              child: Material(
                color: option == kind
                    ? scheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(19),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onChanged(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 9,
                    ),
                    child: Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: option == kind
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: option == kind
                            ? scheme.onPrimaryContainer
                            : captureOnInk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gallery, shutter, and "no photo, I will type it".
class _CaptureControls extends StatelessWidget {
  const _CaptureControls({
    required this.busy,
    required this.onGallery,
    required this.onShutter,
    required this.onManual,
  });

  final bool busy;
  final VoidCallback onGallery;
  final VoidCallback onShutter;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SquareButton(
            icon: Icons.photo_library_outlined,
            tooltip: 'Pick from gallery',
            onTap: busy ? null : onGallery,
          ),
          Tooltip(
            message: 'Take photo',
            child: Semantics(
              button: true,
              label: 'Take photo',
              child: Material(
                color: scheme.primaryContainer,
                shape: const CircleBorder(
                  side: BorderSide(color: Color(0xFF304746), width: 5),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: busy ? null : onShutter,
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: busy
                        ? Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.photo_camera_outlined,
                            size: 30,
                            color: scheme.onPrimaryContainer,
                          ),
                  ),
                ),
              ),
            ),
          ),
          _SquareButton(
            icon: Icons.edit_note_rounded,
            tooltip: 'Add details without a photo',
            onTap: busy ? null : onManual,
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: capturePanel,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: captureOutline),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 24, color: captureOnInk),
            ),
          ),
        ),
      ),
    );
  }
}
