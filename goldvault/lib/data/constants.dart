/// Fixed option lists used across the app. Codes are stored in the database;
/// labels are localised through `strings.dart` using the `opt.` prefix.
class Opt {
  Opt._();

  static const banks = [
    'SBI',
    'HDFC',
    'ICICI',
    'Axis',
    'Canara',
    'Union Bank',
    'Bank of Baroda',
    'Karnataka Bank',
    'Other',
  ];

  static const lockerSizes = ['Small', 'Medium', 'Large', 'Extra Large'];

  static const categories = ['Gold', 'Silver', 'Diamond', 'Platinum', 'Other'];

  static const itemTypes = [
    'Necklace',
    'Long chain (Haram)',
    'Chain',
    'Mangalsutra',
    'Bangle',
    'Bracelet',
    'Ring',
    'Earrings',
    'Jhumka',
    'Nose pin',
    'Anklet',
    'Toe ring',
    'Waist belt (Vaddanam)',
    'Pendant',
    'Coin',
    'Bar',
    'Idol',
    'Utensil',
    'Pooja item',
    'Watch',
    'Other',
  ];

  static const purities = {
    'Gold': ['24K', '22K', '20K', '18K', '14K'],
    'Silver': ['999 silver', '925 silver', '900 silver', '800 silver'],
    'Diamond': ['18K', '22K', '14K', 'PT950'],
    'Platinum': ['PT950', 'PT900'],
    'Other': ['—'],
  };

  // Item statuses
  static const inLocker = 'in_locker';
  static const atHome = 'at_home';
  static const worn = 'worn';
  static const repair = 'repair';
  static const lent = 'lent';
  static const pledged = 'pledged';
  static const sold = 'sold';
  static const exchanged = 'exchanged';
  static const gifted = 'gifted';

  static const statuses = [
    inLocker,
    atHome,
    worn,
    repair,
    lent,
    pledged,
    sold,
    exchanged,
    gifted,
  ];

  /// Item is still owned by the family.
  static const activeStatuses = [inLocker, atHome, worn, repair, lent, pledged];

  /// Item has left the family (kept for history, never deleted).
  static const disposedStatuses = [sold, exchanged, gifted];

  /// Statuses that mean "physically stored somewhere we track".
  static const placedStatuses = [inLocker, atHome];

  /// Out of the house/locker: these trigger "not returned" reminders.
  static const outStatuses = [worn, repair, lent, pledged];

  // Location kinds
  static const kindLocker = 'locker';
  static const kindHome = 'home';
  static const kindPlace = 'place';

  /// Calendar / chart colours handed out to new lockers in order.
  static const palette = <int>[
    0xFFE0B04B, // gold
    0xFF4FC3F7, // sky
    0xFFEF6C6C, // coral
    0xFF81C784, // green
    0xFFBA68C8, // violet
    0xFFFFB74D, // orange
    0xFF4DB6AC, // teal
    0xFFF06292, // pink
    0xFF9FA8DA, // indigo
    0xFFAED581, // lime
    0xFFFF8A65, // deep orange
    0xFF90A4AE, // slate
  ];

  /// Fraction of pure metal for a purity code (used for value estimates).
  static double purityFactor(String? purity) {
    final p = (purity ?? '').toUpperCase();
    final k = RegExp(r'(\d+)\s*K').firstMatch(p);
    if (k != null) return (int.parse(k.group(1)!) / 24).clamp(0, 1).toDouble();
    final pt = RegExp(r'PT\s*(\d{3})').firstMatch(p);
    if (pt != null) return int.parse(pt.group(1)!) / 1000;
    final fine = RegExp(r'(\d{3})').firstMatch(p);
    if (fine != null) return int.parse(fine.group(1)!) / 1000;
    return 1;
  }
}

/// The precious metal an item's weight should be counted under.
enum Metal { gold, silver, platinum, none }

Metal metalOf(String category, String? purity) {
  final p = (purity ?? '').toUpperCase();
  switch (category) {
    case 'Gold':
      return Metal.gold;
    case 'Silver':
      return Metal.silver;
    case 'Platinum':
      return Metal.platinum;
    case 'Diamond':
      if (p.contains('PT')) return Metal.platinum;
      return Metal.gold;
    default:
      if (p.contains('K')) return Metal.gold;
      if (p.contains('SILVER')) return Metal.silver;
      return Metal.none;
  }
}
