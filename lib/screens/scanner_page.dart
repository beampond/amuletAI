import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ── Model ─────────────────────────────────────────────────────────────────────

class AmuletPrediction {
  final String className;
  final double confidence;

  const AmuletPrediction({required this.className, required this.confidence});

  factory AmuletPrediction.fromJson(Map<String, dynamic> json) {
    return AmuletPrediction(
      className: json['class'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get thaiName {
    const map = {
      'somdej': 'พระสมเด็จ',
      'luang_pu_thuat': 'หลวงปู่ทวด',
      'luang_pho_sothorn': 'หลวงพ่อโสธร',
      'luang_pho_khun': 'หลวงพ่อคูณ',
      'luang_pho_ruay': 'หลวงพ่อรวย',
      'phra_pidta': 'พระปิดตา',
      'phra_khun_pan': 'พระขุนแผน',
      'nang_phaya': 'พระนางพญา',
    };
    return map[className.toLowerCase()] ?? className;
  }
}

// ── Roboflow Service ──────────────────────────────────────────────────────────

class RoboflowService {
  static const _modelUrl = 'https://classify.roboflow.com/gg-nrhrh/2';

  static String get _apiKey => dotenv.env['ROBOFLOW_API_KEY'] ?? '';

  static Future<List<AmuletPrediction>> detect(String base64Image) async {
    if (_apiKey.isEmpty) {
      throw Exception('ROBOFLOW_API_KEY is missing in .env');
    }

    final response = await http
        .post(
          Uri.parse('$_modelUrl?api_key=$_apiKey'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: base64Image,
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Roboflow error ${response.statusCode}: ${response.body}',
      );
    }

    // DEBUG — ดูใน Chrome DevTools Console
    debugPrint('=== ROBOFLOW RAW ===\n${response.body}\n====================');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawPreds = _extractPredictions(data);

    debugPrint('=== PARSED: ${rawPreds.length} predictions ===');

    final preds = rawPreds
        .whereType<Map<String, dynamic>>()
        .map(AmuletPrediction.fromJson)
        .toList();
    preds.sort((a, b) => b.confidence.compareTo(a.confidence));
    return preds;
  }

  static List<dynamic> _extractPredictions(Map<String, dynamic> data) {
    final top = data['predictions'];
    if (top is List) return top;
    if (top is Map<String, dynamic>) {
      final nested = top['predictions'];
      if (nested is List) return nested;
    }

    final outputs = data['outputs'];
    if (outputs is List && outputs.isNotEmpty) {
      final first = outputs.first;
      if (first is Map<String, dynamic>) {
        final output = first['output'];
        if (output is List) return output;

        final predictions = first['predictions'];
        if (predictions is List) return predictions;
        if (predictions is Map<String, dynamic>) {
          final nested = predictions['predictions'];
          if (nested is List) return nested;
        }
      }
    }

    return const [];
  }
}

// ── Scanner Page ──────────────────────────────────────────────────────────────

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  bool _cameraReady = false;
  bool _cameraError = false;
  String _cameraErrorMsg = '';
  bool _isScanning = false;

  List<AmuletPrediction> _predictions = [];
  bool _hasResult = false;
  String? _scanError;

  Timer? _timer;

  final String _viewId = 'webcam-${DateTime.now().millisecondsSinceEpoch}';
  static const int _captureMaxSide = 416;
  static const Duration _scanInterval = Duration(seconds: 2);

  static const _gold = Color(0xFFC9A84C);
  static const _dark = Color(0xFF0D0D0D);
  static const _dark2 = Color(0xFF161616);
  static const _dark3 = Color(0xFF1E1E1E);
  static const _textMuted = Color(0xFFA89878);

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) => _videoElement!,
    );

    try {
      _stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'environment', 'width': 480, 'height': 360},
        'audio': false,
      });
      _videoElement!.srcObject = _stream;
      await _videoElement!.play();
      if (mounted) setState(() => _cameraReady = true);

      unawaited(_scanFrame());
      _timer = Timer.periodic(_scanInterval, (_) => _scanFrame());
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = true;
          _cameraErrorMsg = e.toString();
        });
      }
    }
  }

  Future<void> _scanFrame() async {
    if (_isScanning || _videoElement == null || !_cameraReady) return;
    if (mounted) setState(() => _isScanning = true);

    try {
      final videoWidth = _videoElement!.videoWidth;
      final videoHeight = _videoElement!.videoHeight;
      if (videoWidth == 0 || videoHeight == 0) return;

      final longestSide = math.max(videoWidth, videoHeight);
      final scale = _captureMaxSide / longestSide;
      final captureScale = scale < 1 ? scale : 1.0;
      final captureWidth = (videoWidth * captureScale).round();
      final captureHeight = (videoHeight * captureScale).round();

      final canvas = html.CanvasElement(
        width: captureWidth,
        height: captureHeight,
      );
      canvas.context2D.drawImageScaled(
        _videoElement!,
        0,
        0,
        captureWidth,
        captureHeight,
      );
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.70);
      final base64Image = dataUrl.split(',').last;

      final preds = await RoboflowService.detect(base64Image);

      if (mounted) {
        setState(() {
          _predictions = preds;
          _hasResult = true;
          _scanError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _scanError = e.toString());
      debugPrint('Scan error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Color _confidenceColor(double c) {
    if (c >= 0.70) return const Color(0xFF2ECC71);
    if (c >= 0.45) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_cameraError) {
      return Scaffold(
        backgroundColor: _dark,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_photography,
                    color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                const Text('เปิดกล้องไม่ได้',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_cameraErrorMsg,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _cameraError = false;
                      _cameraReady = false;
                    });
                    _setupCamera();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('ลองใหม่'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_cameraReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFC9A84C)),
              SizedBox(height: 16),
              Text('กำลังเปิดกล้อง...',
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _dark,
      body: Column(
        children: [
          // ── Camera ────────────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HtmlElementView(viewType: _viewId),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(children: [
                      _corner(top: 0, left: 0, topLeft: true),
                      _corner(top: 0, right: 0, topRight: true),
                      _corner(bottom: 0, left: 0, bottomLeft: true),
                      _corner(bottom: 0, right: 0, bottomRight: true),
                    ]),
                  ),
                ),
                if (_isScanning)
                  const Center(
                    child: SizedBox(
                      width: 220,
                      height: 2,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        color: _gold,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Text(
                    _isScanning ? 'กำลังวิเคราะห์...' : 'วางพระในกรอบเพื่อสแกน',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isScanning ? _gold : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
                // Manual scan button
                Positioned(
                  bottom: 36,
                  right: 16,
                  child: GestureDetector(
                    onTap: _isScanning ? null : _scanFrame,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _gold.withOpacity(0.4), width: 0.5),
                      ),
                      child: Icon(
                        Icons.center_focus_strong,
                        color: _isScanning ? Colors.white24 : _gold,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Result panel ──────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: 80,
              maxHeight: _hasResult ? 300 : 80,
            ),
            decoration: BoxDecoration(
              color: _dark2,
              border: Border(
                  top: BorderSide(
                      color: _gold.withOpacity(0.3), width: 0.5)),
            ),
            child: _hasResult
                ? _buildResults()
                : Center(
                    child: Text(
                      _scanError != null
                          ? 'เกิดข้อผิดพลาด: $_scanError'
                          : 'ยังไม่มีผลการสแกน',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _scanError != null
                            ? Colors.redAccent.withOpacity(0.7)
                            : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Result content ────────────────────────────────────────────────────────

  Widget _buildResults() {
    if (_predictions.isEmpty) {
      return const Center(
        child: Text('ไม่พบพระในภาพ',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
      );
    }

    final top = _predictions.first;
    final rest = _predictions.skip(1).take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(top.thaiName,
                        style: const TextStyle(
                            color: _gold,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text(top.className,
                        style: const TextStyle(
                            color: _textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      _confidenceColor(top.confidence).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _confidenceColor(top.confidence)
                          .withOpacity(0.3),
                      width: 0.5),
                ),
                child: Text(
                  '${(top.confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: _confidenceColor(top.confidence),
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ความมั่นใจ',
                  style: TextStyle(color: _textMuted, fontSize: 11)),
              Text(
                top.confidence >= 0.70
                    ? '✓ น่าเชื่อถือ'
                    : top.confidence >= 0.45
                        ? '~ ปานกลาง'
                        : '✗ ต่ำ',
                style: TextStyle(
                    color: _confidenceColor(top.confidence),
                    fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: top.confidence,
              backgroundColor: Colors.white10,
              valueColor:
                  AlwaysStoppedAnimation(_confidenceColor(top.confidence)),
              minHeight: 6,
            ),
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('ผลลัพธ์อื่น ๆ',
                style: TextStyle(color: _textMuted, fontSize: 11)),
            const SizedBox(height: 6),
            ...rest.map((p) => _candidateRow(p)),
          ],
        ],
      ),
    );
  }

  Widget _candidateRow(AmuletPrediction p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _dark3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(p.thaiName,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ),
            Text(
              '${(p.confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                  color: _confidenceColor(p.confidence), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: topLeft || topRight
                ? const BorderSide(color: _gold, width: 2)
                : BorderSide.none,
            bottom: bottomLeft || bottomRight
                ? const BorderSide(color: _gold, width: 2)
                : BorderSide.none,
            left: topLeft || bottomLeft
                ? const BorderSide(color: _gold, width: 2)
                : BorderSide.none,
            right: topRight || bottomRight
                ? const BorderSide(color: _gold, width: 2)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stream?.getTracks().forEach((t) => t.stop());
    super.dispose();
  }
}
