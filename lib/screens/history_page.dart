import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/scan_history_service.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  static const _gold = Color(0xFFC9A84C);
  static const _dark = Color(0xFF0D0D0D);
  static const _dark3 = Color(0xFF1E1E1E);
  static const _text2 = Color(0xFFA89878);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, color: _gold, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('ประวัติการสแกน',
                      style: TextStyle(color: _gold, fontSize: 16,
                          fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const Spacer(),
                  const Text('90 วันล่าสุด',
                      style: TextStyle(color: _text2, fontSize: 11)),
                ],
              ),
            ),

            // List
            Expanded(
              child: StreamBuilder<List<ScanRecord>>(
                stream: ScanHistoryService.historyStream(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _gold));
                  }
                  if (snap.hasError) {
                    return Center(
                        child: Text('โหลดไม่ได้: ${snap.error}',
                            style: const TextStyle(color: Colors.redAccent)));
                  }

                  final records = snap.data ?? [];

                  if (records.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🔍', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('ยังไม่มีประวัติการสแกน',
                              style: TextStyle(color: _text2, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _HistoryCard(record: records[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ScanRecord record;
  const _HistoryCard({required this.record});

  static const _dark3 = Color(0xFF1E1E1E);
  static const _gold = Color(0xFFC9A84C);
  static const _text2 = Color(0xFFA89878);

  Color _confColor(double c) {
    if (c >= 0.75) return const Color(0xFF2ECC71);
    if (c >= 0.50) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  String _emoji(String cls) {
    const map = {
      'somdej': '🪬', 'luang_pu_thuat': '🔮', 'thuat': '🔮',
      'sothorn': '✨', 'luang_pho_sothorn': '✨',
      'khun': '🙏', 'luang_pho_khun': '🙏',
      'ruay': '💫', 'luang_pho_ruay': '💫',
      'phra_pidta': '🧿', 'pidta': '🧿',
      'phra_khun_pan': '🌟', 'khun_pan': '🌟',
      'nang_phaya': '🏆',
    };
    return map[cls.toLowerCase()] ?? '🪬';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy  HH:mm', 'th').format(record.scannedAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _dark3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Row(
        children: [
          Text(_emoji(record.className), style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.thaiName,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(dateStr,
                    style: const TextStyle(color: _text2, fontSize: 11)),
                if (record.priceRange != null) ...[
                  const SizedBox(height: 2),
                  Text(record.priceRange!,
                      style: const TextStyle(color: _gold, fontSize: 11)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(record.confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: _confColor(record.confidence),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('confidence',
                  style: TextStyle(color: _text2.withOpacity(0.6), fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}