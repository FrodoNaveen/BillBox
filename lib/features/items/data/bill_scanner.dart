import 'bill_item.dart';
import 'item_category_catalog.dart';

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

/// Stand-in reader used until the camera lands.
///
/// Returns the reading of the bill drawn in the design — a split AC with a
/// 24-month warranty — so the review form can be used end to end. Manual
/// entry still returns an empty result, as the real one will.
class SampleBillScanner implements BillScanner {
  SampleBillScanner({
    this.delay = const Duration(milliseconds: 900),
    DateTime? now,
  }) : _now = now;

  /// How long the "reading the bill" state is held for.
  final Duration delay;

  final DateTime? _now;

  @override
  Future<ScannedBill> scan({
    required ItemKind kind,
    required CaptureSource source,
  }) async {
    if (source == CaptureSource.manual) {
      return const ScannedBill.empty();
    }

    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final now = _now ?? DateTime.now();

    if (kind == ItemKind.document) {
      return ScannedBill(
        title: 'Passport',
        category: 'Identity',
        store: 'Regional Passport Office, Chennai',
        purchaseDate: DateTime(now.year - 4, 2, 4),
        expiryDate: DateTime(now.year + 6, 2, 3),
        rawText:
            'Republic of India · Passport no. Z21 · place of issue Chennai · '
            'date of issue 4 Feb ${now.year - 4} · date of expiry 3 Feb '
            '${now.year + 6}',
        note: '"Date of expiry" on the document',
        imageName: 'passport_front.jpg',
        source: source,
        readFields: const <ScannedField>{
          ScannedField.title,
          ScannedField.category,
          ScannedField.store,
          ScannedField.purchaseDate,
          ScannedField.expiryDate,
        },
      );
    }

    final purchase = DateTime(now.year, now.month, now.day);
    return ScannedBill(
      title: 'Samsung 1.5T Split AC',
      category: normaliseCategory('Appliances'),
      store: 'Sri Electronics, Coimbatore',
      amount: 39699,
      purchaseDate: purchase,
      expiryDate: DateTime(purchase.year + 2, purchase.month, purchase.day),
      rawText:
          'SRI ELECTRONICS · GSTIN 33ABCDE1234F1Z5 · Coimbatore · '
          'Split AC 1.5T 38,499.00 · Installation 1,200.00 · TOTAL 39,699.00 · '
          'Invoice dt ${purchase.day}/${purchase.month}/${purchase.year} · '
          'Warranty 24 months',
      note: '"Warranty 24 months" on the bill',
      imageName: 'bill_${purchase.day}${purchase.month}.jpg',
      source: source,
      readFields: const <ScannedField>{
        ScannedField.title,
        ScannedField.category,
        ScannedField.store,
        ScannedField.amount,
        ScannedField.purchaseDate,
        ScannedField.expiryDate,
      },
    );
  }
}
