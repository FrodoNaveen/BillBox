import '../../../core/utils/formatting.dart';
import 'bill_item.dart';

/// The catalogue the app shows until the first real item is saved.
///
/// These are ordinary [BillItem]s, not a separate shape, so every screen —
/// the dashboard, search, reminders, the detail view — works on a fresh
/// install exactly as it will with real data. Their dates are worked out from
/// "now", so "6 days left" stays true whenever the app is opened, and their
/// ids are prefixed, which is how [BillItem.isSample] tells them apart.
List<BillItem> buildSampleItems({DateTime? now}) {
  final today = dayOf(now ?? DateTime.now());

  BillItem sample({
    required String id,
    required String title,
    required String category,
    required int daysLeft,
    required int boughtDaysAgo,
    required String scannedText,
    ItemKind kind = ItemKind.bill,
    String? store,
    double? amount,
    String? imageName,
  }) {
    final purchased = today.subtract(Duration(days: boughtDaysAgo));
    return BillItem(
      id: 'sample_$id',
      title: title,
      category: category,
      kind: kind,
      savedAt: purchased,
      store: store,
      amount: amount,
      purchaseDate: purchased,
      expiryDate: today.add(Duration(days: daysLeft)),
      scannedText: scannedText,
      reminderLeadDays: const <int>{30, 7, 1},
      imageName: imageName,
    );
  }

  return <BillItem>[
    sample(
      id: 'ac',
      title: 'Samsung 1.5T Split AC',
      category: 'Appliances',
      daysLeft: 6,
      boughtDaysAgo: 724,
      store: 'Sri Electronics, Coimbatore',
      amount: 39699,
      scannedText: 'Extended insurance plan not opted',
      imageName: 'bill_split_ac.jpg',
    ),
    sample(
      id: 'purifier',
      title: 'Water purifier AMC',
      category: 'Appliances',
      daysLeft: 7,
      boughtDaysAgo: 358,
      store: 'AquaCare Services',
      amount: 4200,
      scannedText: 'AMC 2 services remaining, ticket 7781',
    ),
    sample(
      id: 'rent',
      title: 'Flat rental agreement',
      category: 'Home / Rent',
      kind: ItemKind.document,
      daysLeft: 15,
      boughtDaysAgo: 320,
      store: 'Lake View Residency',
      scannedText: 'Rent 18,500 per month, deposit 1,00,000, 11 months',
      imageName: 'rent_agreement.jpg',
    ),
    sample(
      id: 'twowheeler',
      title: 'Two-wheeler insurance',
      category: 'Insurance',
      daysLeft: 21,
      boughtDaysAgo: 344,
      store: 'Star General Insurance',
      amount: 3180,
      scannedText: 'Policy no. 4471, insured declared value 62,400',
    ),
    sample(
      id: 'macbook',
      title: 'MacBook Air M2',
      category: 'Electronics',
      daysLeft: 48,
      boughtDaysAgo: 682,
      store: 'Apple Store',
      amount: 114900,
      scannedText: 'Serial C02XK, AppleCare cover till next January',
      imageName: 'bill_macbook.jpg',
    ),
    sample(
      id: 'health',
      title: 'Family health insurance',
      category: 'Insurance',
      daysLeft: 124,
      boughtDaysAgo: 241,
      store: 'CareFirst Health',
      amount: 21400,
      scannedText: 'Sum insured 5,00,000, floater plan',
    ),
    sample(
      id: 'fridge',
      title: 'LG 190L refrigerator',
      category: 'Appliances',
      daysLeft: 270,
      boughtDaysAgo: 460,
      store: 'Vasanth & Co',
      amount: 18490,
      scannedText: 'Invoice 8821, compressor cover 10 years',
    ),
    sample(
      id: 'activa',
      title: 'Honda Activa registration',
      category: 'Vehicle',
      kind: ItemKind.document,
      daysLeft: 941,
      boughtDaysAgo: 1884,
      scannedText: 'Registration TN 22, chassis ME4JF501',
      imageName: 'rc_book.jpg',
    ),
    sample(
      id: 'passport',
      title: 'Passport',
      category: 'Identity',
      kind: ItemKind.document,
      daysLeft: 1541,
      boughtDaysAgo: 1109,
      store: 'Regional Passport Office, Chennai',
      scannedText: 'Passport no. Z21, place of issue Chennai',
      imageName: 'passport_front.jpg',
    ),
  ];
}

/// Worked out once per run, so the dashboard and search agree on the dates.
final List<BillItem> sampleBillItems = buildSampleItems();
