import 'dart:convert';

import 'package:flutter/material.dart';

import 'scanner_page.dart'; // AmuletPrediction
import '../utils/api_service.dart'; // AmuletAnalysis, ApiService
import '../utils/scan_history_service.dart';
import '../utils/market_price_service.dart';
import '../utils/auth_service.dart';

class AmuletDetailPage extends StatefulWidget {
  final AmuletPrediction prediction;
  final List<AmuletPrediction> allPredictions;
  final String capturedImageBase64;

  const AmuletDetailPage({
    super.key,
    required this.prediction,
    required this.allPredictions,
    required this.capturedImageBase64,
  });

  @override
  State<AmuletDetailPage> createState() => _AmuletDetailPageState();
}

class _AmuletDetailPageState extends State<AmuletDetailPage> {
  AmuletAnalysis? _analysis;
  bool _loadingAnalysis = true;
  String? _analysisError;
  bool _saved = false;

  static const _gold = Color(0xFFC9A84C);
  static const _dark = Color(0xFF0D0D0D);
  static const _dark3 = Color(0xFF1E1E1E);
  static const _textMuted = Color(0xFFA89878);

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    try {
      final result = await ApiService.scanAmulet(widget.capturedImageBase64);
      if (mounted) {
        setState(() => _analysis = result);
        _saveToHistory(result);
      }
    } catch (e) {
      if (mounted) setState(() => _analysisError = e.toString());
      _saveToHistory(null);
    } finally {
      if (mounted) setState(() => _loadingAnalysis = false);
    }
  }

  Future<void> _saveToHistory(AmuletAnalysis? analysis) async {
    if (_saved || AuthService.currentUser == null) return;
    _saved = true;

    final price = MarketPriceService.getPrice(widget.prediction.className);
    await ScanHistoryService.saveScan(ScanRecord(
      id: '',
      className: widget.prediction.className,
      thaiName: widget.prediction.thaiName,
      confidence: widget.prediction.confidence,
      priceRange: analysis?.priceRange ?? price?.rangeText,
      generation: analysis?.generation,
      authenticityNote: analysis?.authenticityNote,
      scannedAt: DateTime.now(),
    ));
  }

  Color _confidenceColor(double c) {
    if (c >= 0.75) return const Color(0xFF2ECC71);
    if (c >= 0.50) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  String _confidenceLabel(double c) {
    if (c >= 0.75) return '✓ น่าเชื่อถือ';
    if (c >= 0.50) return '~ ปานกลาง';
    return '✗ ต่ำ';
  }

  @override
  Widget build(BuildContext context) {
    final pred = widget.prediction;
    final others = widget.allPredictions.skip(1).take(3).toList();
    final marketPrice = MarketPriceService.getPrice(pred.className);

    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _dark3,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10, width: 0.5),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: _gold, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('ผลการสแกน',
                      style: TextStyle(color: _gold, fontSize: 16,
                          fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _gold.withOpacity(0.3), width: 0.5),
                      ),
                      child: const Row(children: [
                        Icon(Icons.document_scanner_outlined, color: _gold, size: 13),
                        SizedBox(width: 5),
                        Text('สแกนใหม่', style: TextStyle(color: _gold, fontSize: 11)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Captured image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.memory(
                            base64Decode(widget.capturedImageBase64),
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 12, right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _confidenceColor(pred.confidence)
                                        .withOpacity(0.5),
                                    width: 0.8),
                              ),
                              child: Text(
                                '${(pred.confidence * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                    color: _confidenceColor(pred.confidence),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _dark3,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _gold.withOpacity(0.2), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Text(pred.emoji, style: const TextStyle(fontSize: 42)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pred.thaiName,
                                    style: const TextStyle(
                                        color: _gold, fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(pred.className,
                                    style: const TextStyle(
                                        color: _textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Market Price card
                    if (marketPrice != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _dark3,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _gold.withOpacity(0.15), width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.monetization_on_outlined,
                                  color: _gold, size: 13),
                              SizedBox(width: 6),
                              Text('ราคาตลาด',
                                  style: TextStyle(color: _gold, fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ]),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _priceBox('ราคาต่ำสุด', marketPrice.minText,
                                    const Color(0xFF2ECC71)),
                                _priceBox('ราคาสูงสุด', marketPrice.maxText,
                                    const Color(0xFFF39C12)),
                                _priceBox('ช่วงราคา', marketPrice.rangeText,
                                    _textMuted),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Confidence bar
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _dark3,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10, width: 0.5),
                      ),
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ความมั่นใจในการระบุ',
                                style: TextStyle(color: _textMuted, fontSize: 12)),
                            Text(_confidenceLabel(pred.confidence),
                                style: TextStyle(
                                    color: _confidenceColor(pred.confidence),
                                    fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pred.confidence,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(
                                _confidenceColor(pred.confidence)),
                            minHeight: 7,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),

                    // AI Analysis
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _dark3,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10, width: 0.5),
                      ),
                      child: _loadingAnalysis
                          ? const _LoadingAnalysis()
                          : _analysisError != null
                              ? Text('ไม่สามารถโหลดข้อมูลเพิ่มเติมได้',
                                  style: TextStyle(
                                      color: Colors.redAccent.withOpacity(0.7),
                                      fontSize: 12))
                              : _analysis != null
                                  ? _AnalysisContent(analysis: _analysis!)
                                  : const SizedBox(),
                    ),

                    // Other candidates
                    if (others.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('ผลลัพธ์อื่น ๆ',
                          style: TextStyle(color: _textMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      ...others.map((p) => _CandidateRow(
                            prediction: p,
                            confidenceColor: _confidenceColor(p.confidence),
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceBox(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: _textMuted, fontSize: 9)),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LoadingAnalysis extends StatelessWidget {
  const _LoadingAnalysis();
  static const _gold = Color(0xFFC9A84C);
  static const _textMuted = Color(0xFFA89878);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 14, height: 14,
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: _gold.withOpacity(0.6))),
      const SizedBox(width: 10),
      const Text('กำลังโหลดข้อมูลจาก AI...',
          style: TextStyle(color: _textMuted, fontSize: 12)),
    ]);
  }
}

class _AnalysisContent extends StatelessWidget {
  final AmuletAnalysis analysis;
  const _AnalysisContent({required this.analysis});
  static const _gold = Color(0xFFC9A84C);
  static const _textMuted = Color(0xFFA89878);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.auto_awesome, color: _gold, size: 13),
          SizedBox(width: 6),
          Text('ข้อมูลจาก AI',
              style: TextStyle(color: _gold, fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 10),
        if (analysis.generation.isNotEmpty) _row('ยุคสมัย', analysis.generation),
        if (analysis.priceRange.isNotEmpty) _row('ราคาอ้างอิง', analysis.priceRange),
        if (analysis.authenticPercent > 0)
          _row('ประเมินความแท้',
              '${analysis.authenticPercent.toStringAsFixed(0)}%'),
        if (analysis.authenticityNote.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(analysis.authenticityNote,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12, height: 1.5)),
        ],
        if (analysis.details.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(analysis.details,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11, height: 1.5)),
        ],
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100,
            child: Text(label,
                style: const TextStyle(color: _textMuted, fontSize: 11))),
        Expanded(child: Text(value,
            style: const TextStyle(color: Colors.white70, fontSize: 11))),
      ]),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  final AmuletPrediction prediction;
  final Color confidenceColor;
  const _CandidateRow({required this.prediction, required this.confidenceColor});
  static const _dark3 = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _dark3, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10, width: 0.5),
        ),
        child: Row(children: [
          Text(prediction.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(prediction.thaiName,
              style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text('${(prediction.confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: confidenceColor, fontSize: 12)),
        ]),
      ),
    );
  }
}