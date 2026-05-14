import 'package:flutter/material.dart';

class AmuletData {
  final String emoji;
  final String thaiName;
  final String englishName;

  const AmuletData(this.emoji, this.thaiName, this.englishName);
}

const _amulets = [
  AmuletData('🪬', 'พระสมเด็จ', 'Somdej'),
  AmuletData('🔮', 'หลวงปู่ทวด', 'Luang Pu Thuat'),
  AmuletData('✨', 'หลวงพ่อโสธร', 'Luang Pho Sothorn'),
  AmuletData('🙏', 'หลวงพ่อคูณ', 'Luang Pho Khun'),
  AmuletData('💫', 'หลวงพ่อรวย', 'Luang Pho Ruay'),
  AmuletData('🧿', 'พระปิดตา', 'Phra Pidta'),
  AmuletData('⭐', 'พระปานพิมพ์ครุฑ', 'Phra Phan Khrut'),
  AmuletData('🌟', 'พระขุนแผน', 'Phra Khun Pan'),
  AmuletData('🏆', 'พระนางพญา', 'Phra Nang Phaya'),
  AmuletData('🌺', 'หลวงพ่อเงิน', 'Luang Pho Ngern'),
];

class AmuletsPage extends StatefulWidget {
  const AmuletsPage({super.key});

  @override
  State<AmuletsPage> createState() => _AmuletsPageState();
}

class _AmuletsPageState extends State<AmuletsPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _gold = Color(0xFFC9A84C);
  static const _dark = Color(0xFF0D0D0D);
  static const _dark3 = Color(0xFF1E1E1E);
  static const _text2 = Color(0xFFA89878);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _amulets
        .where((a) =>
            a.thaiName.contains(_query) ||
            a.englishName.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Text('คลังพระ',
                      style: TextStyle(
                          color: _gold,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1)),
                  const Spacer(),
                  Icon(Icons.filter_list, color: Colors.grey[700], size: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'ค้นหาพระ...',
                    hintStyle: TextStyle(color: Color(0xFF555555), fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF555555), size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _AmuletCard(amulet: filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmuletCard extends StatelessWidget {
  final AmuletData amulet;
  const _AmuletCard({required this.amulet});

  static const _dark3 = Color(0xFF1E1E1E);
  static const _text2 = Color(0xFFA89878);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _dark3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(bottom: BorderSide(color: Color(0xFF222222), width: 0.5)),
              ),
              child: Center(
                child: Text(amulet.emoji, style: const TextStyle(fontSize: 40)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(amulet.thaiName,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(amulet.englishName,
                    style: const TextStyle(color: _text2, fontSize: 10)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2A1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A3A2A), width: 0.5),
                  ),
                  child: const Text('สแกนได้',
                      style: TextStyle(color: Color(0xFF2ECC71), fontSize: 9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}