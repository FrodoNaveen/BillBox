import 'bill_item.dart';

/// Where the photo came from.
enum CaptureSource {
  camera('Photo'),
  gallery('From gallery'),
  manual('Typed in');

  const CaptureSource(this.label);

  final String label;
}

/// A field on the add-item form that can be filled from a photo. The form
/// puts a "read from bill" chip on each one it was given.
enum ScannedField { title, category, store, amount, purchaseDate, expiryDate }

/// What reading a photo produced. Every field is optional — OCR misses things,
/// and manual entry produces an empty result.
class ScannedBill {
  const ScannedBill({
    this.title,
    this.category,
    this.store,
    this.amount,
    this.purchaseDate,
    this.expiryDate,
    this.rawText = '',
    this.note,
    this.imageName,
    this.source = CaptureSource.manual,
    this.readFields = const <ScannedField>{},
  });

  /// Nothing was read: the form opens blank.
  const ScannedBill.empty({CaptureSource source = CaptureSource.manual})
    : this(source: source);

  final String? title;
  final String? category;
  final String? store;
  final double? amount;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;

  /// Everything the reader saw, kept with the item so search can look inside.
  final String rawText;

  /// The line the expiry date was worked out from, shown under the dates:
  /// "Warranty 24 months on the bill".
  final String? note;

  final String? imageName;
  final CaptureSource source;
  final Set<ScannedField> readFields;

  bool wasRead(ScannedField field) => readFields.contains(field);

  bool get isEmpty => readFields.isEmpty;
}

/// Reads a photo of a bill.
///
/// The camera and on-device OCR are not in the project yet, so this is the
/// seam they slot behind: a real implementation does the same job with
/// image_picker plus an on-device text recogniser, and no screen changes.
abstract class BillScanner {
  Future<ScannedBill> scan({
    required ItemKind kind,
    required CaptureSource source,
  });
}

/// The reader in place until the camera and on-device OCR land.
///
/// It reads nothing, whatever the source, so the review form always opens
/// blank and every field on a saved item is one the user typed. Keeping the
/// seam means the real recogniser drops in here and no screen changes.
class EmptyBillScanner implements BillScanner {
  EmptyBillScanner({this.delay = Duration.zero});

  /// How long the "reading the bill" state is held for.
  final Duration delay;

  @override
  Future<ScannedBill> scan({
    required ItemKind kind,
    required CaptureSource source,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return ScannedBill.empty(source: source);
  }
}
