/// ราคาตลาด Min-Max ของพระ 8 ประเภท
/// Phase 1: hardcode จากราคาตลาดจริง
/// Phase 2: ดึงจาก API ภายนอก (upgrade ในอนาคต)

class AmuletPrice {
  final String className;
  final String thaiName;
  final int minPrice;
  final int maxPrice;
  final String unit;
  final DateTime updatedAt;

  const AmuletPrice({
    required this.className,
    required this.thaiName,
    required this.minPrice,
    required this.maxPrice,
    this.unit = 'บาท',
    required this.updatedAt,
  });

  String get rangeText =>
      '${_fmt(minPrice)} – ${_fmt(maxPrice)} $unit';

  String get minText => '${_fmt(minPrice)} $unit';
  String get maxText => '${_fmt(maxPrice)} $unit';

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }
}

class MarketPriceService {
  // ── ราคาอ้างอิง (อัปเดต 2567) ────────────────────────────────────────────
  static final Map<String, AmuletPrice> _prices = {
    'somdej': AmuletPrice(
      className: 'somdej',
      thaiName: 'พระสมเด็จ',
      minPrice: 5000,
      maxPrice: 10000000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'luang_pu_thuat': AmuletPrice(
      className: 'luang_pu_thuat',
      thaiName: 'หลวงปู่ทวด',
      minPrice: 3000,
      maxPrice: 500000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'sothorn': AmuletPrice(
      className: 'sothorn',
      thaiName: 'หลวงพ่อโสธร',
      minPrice: 2000,
      maxPrice: 200000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'luang_pho_sothorn': AmuletPrice(
      className: 'luang_pho_sothorn',
      thaiName: 'หลวงพ่อโสธร',
      minPrice: 2000,
      maxPrice: 200000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'luang_pho_khun': AmuletPrice(
      className: 'luang_pho_khun',
      thaiName: 'หลวงพ่อคูณ',
      minPrice: 1500,
      maxPrice: 300000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'khun': AmuletPrice(
      className: 'khun',
      thaiName: 'หลวงพ่อคูณ',
      minPrice: 1500,
      maxPrice: 300000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'luang_pho_ruay': AmuletPrice(
      className: 'luang_pho_ruay',
      thaiName: 'หลวงพ่อรวย',
      minPrice: 500,
      maxPrice: 50000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'ruay': AmuletPrice(
      className: 'ruay',
      thaiName: 'หลวงพ่อรวย',
      minPrice: 500,
      maxPrice: 50000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'phra_pidta': AmuletPrice(
      className: 'phra_pidta',
      thaiName: 'พระปิดตา',
      minPrice: 2000,
      maxPrice: 1000000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'pidta': AmuletPrice(
      className: 'pidta',
      thaiName: 'พระปิดตา',
      minPrice: 2000,
      maxPrice: 1000000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'phra_khun_pan': AmuletPrice(
      className: 'phra_khun_pan',
      thaiName: 'พระขุนแผน',
      minPrice: 3000,
      maxPrice: 800000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'khun_pan': AmuletPrice(
      className: 'khun_pan',
      thaiName: 'พระขุนแผน',
      minPrice: 3000,
      maxPrice: 800000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'nang_phaya': AmuletPrice(
      className: 'nang_phaya',
      thaiName: 'พระนางพญา',
      minPrice: 5000,
      maxPrice: 2000000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'luang_pu_thuat': AmuletPrice(
      className: 'luang_pu_thuat',
      thaiName: 'หลวงปู่ทวด',
      minPrice: 3000,
      maxPrice: 500000,
      updatedAt: DateTime(2024, 1, 1),
    ),
    'thuat': AmuletPrice(
      className: 'thuat',
      thaiName: 'หลวงปู่ทวด',
      minPrice: 3000,
      maxPrice: 500000,
      updatedAt: DateTime(2024, 1, 1),
    ),
  };

  static AmuletPrice? getPrice(String className) =>
      _prices[className.toLowerCase()];

  static List<AmuletPrice> getAllPrices() => _prices.values
      .toSet()
      .toList()
    ..sort((a, b) => a.thaiName.compareTo(b.thaiName));
}