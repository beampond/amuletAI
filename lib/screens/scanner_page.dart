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

import 'Amulet_detail_page.dart';

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
      // ชื่อเต็ม
      'somdej': 'พระสมเด็จ',
      'luang_pu_thuat': 'หลวงปู่ทวด',
      'luang_pho_sothorn': 'หลวงพ่อโสธร',
      'luang_pho_khun': 'หลวงพ่อคูณ',
      'luang_pho_ruay': 'หลวงพ่อรวย',
      'phra_pidta': 'พระปิดตา',
      'phra_khun_pan': 'พระขุนแผน',
      'nang_phaya': 'พระนางพญา',
      // ชื่อย่อที่ model อาจส่งมา
      'sothorn': 'หลวงพ่อโสธร',
      'khun': 'หลวงพ่อคูณ',
      'ruay': 'หลวงพ่อรวย',
      'pidta': 'พระปิดตา',
      'khun_pan': 'พระขุนแผน',
      'thuat': 'หลวงปู่ทวด',
      'phra_somdej': 'พระสมเด็จ',
    };
    return map[className.toLowerCase()] ?? className;
  }

  String get emoji {
    const map = {
      'somdej': '🪬',
      'luang_pu_thuat': '🔮',
      'luang_pho_sothorn': '✨',
      'luang_pho_khun': '🙏',
      'luang_pho_ruay': '💫',
      'phra_pidta': '🧿',
      'phra_khun_pan': '🌟',
      'nang_phaya': '🏆',
      // ชื่อย่อ
      'sothorn': '✨',
      'khun': '🙏',
      'ruay': '💫',
      'pidta': '🧿',
      'khun_pan': '🌟',
      'thuat': '🔮',
      'phra_somdej': '🪬',
    };
    return map[className.toLowerCase()] ?? '🪬';
  }
}

// ── Roboflow Service ──────────────────────────────────────────────────────────

class RoboflowService {
  // ✅ อัปเดต URL เป็น model ใหม่: amulet-detection version 2
  static const _modelUrl =
      'https://detect.roboflow.com/amulet-detection/2';

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
    debugPrint('=== EXTRACT keys: ${data.keys.toList()} ===');

    final predsField = data['predictions'];

    // Format A: standard hosted API → predictions is a flat List
    // {"predictions":[{"class":"phra_pidta","confidence":0.98,...}]}
    if (predsField is List) {
      debugPrint('=== Format A: List length=${predsField.length} ===');
      return predsField;
    }

    // Format B: workflow / test-UI → predictions is a Map with nested list
    // {"predictions":{"image":{...},"predictions":[{"class":"phra_pidta",...}]}}
    if (predsField is Map<String, dynamic>) {
      final nested = predsField['predictions'];
      if (nested is List) {
        debugPrint('=== Format B nested List length=${nested.length} ===');
        return nested;
      }
      // classification map: {"somdej": 0.92, ...}
      final classMap = predsField.entries
          .where((e) => e.value is num)
          .map((e) => {'class': e.key, 'confidence': (e.value as num).toDouble()})
          .toList();
      if (classMap.isNotEmpty) {
        debugPrint('=== Format B-class map length=${classMap.length} ===');
        return classMap;
      }
    }

    // Format C: outputs wrapper
    final outputs = data['outputs'];
    if (outputs is List && outputs.isNotEmpty) {
      final first = outputs.first;
      if (first is Map<String, dynamic>) {
        final p = first['predictions'];
        if (p is List) return p;
        if (p is Map<String, dynamic>) {
          final n = p['predictions'];
          if (n is List) return n;
        }
      }
    }

    debugPrint('=== No predictions found ===');
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

  // threshold สูงขึ้นเป็น 75% และต้องเจอ class เดิม 2 ครั้งติดกัน (debounce)
  static const double _detectThreshold = 0.75;
  static const int _requiredConsecutive = 2;
  String _lastDetectedClass = '';
  int _consecutiveCount = 0;

  Timer? _timer;

  final String _viewId = 'webcam-${DateTime.now().millisecondsSinceEpoch}';
  static const int _captureMaxSide = 640;
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
        'video': {'facingMode': 'environment', 'width': 1280, 'height': 720},
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

  // ✅ เมื่อสแกนเจอพระ confidence สูงพอ → หยุด timer → navigate ไป detail page
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
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.90);
      final base64Image = dataUrl.split(',').last;

      final preds = await RoboflowService.detect(base64Image);

      if (!mounted) return;

      // DEBUG: แสดงผลทุก prediction ที่ได้รับ
      debugPrint('=== ALL PREDICTIONS (${preds.length}) ===');
      for (final p in preds) {
        debugPrint('  class: ${p.className}  conf: ${(p.confidence * 100).toStringAsFixed(1)}%');
      }

      // debounce: ต้องเจอ class เดิมติดกัน _requiredConsecutive ครั้ง จึง navigate
      if (preds.isNotEmpty && preds.first.confidence >= _detectThreshold) {
        final detectedClass = preds.first.className;
        if (detectedClass == _lastDetectedClass) {
          _consecutiveCount++;
        } else {
          _lastDetectedClass = detectedClass;
          _consecutiveCount = 1;
        }
        debugPrint('Detected: $detectedClass x$_consecutiveCount (conf: ${preds.first.confidence})');
      } else {
        _lastDetectedClass = '';
        _consecutiveCount = 0;
      }

      if (_consecutiveCount >= _requiredConsecutive) {
        _consecutiveCount = 0;
        _lastDetectedClass = '';
        final preds2 = preds; // snapshot
        _stopScanning();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AmuletDetailPage(
              prediction: preds2.first,
              allPredictions: preds2,
              capturedImageBase64: base64Image,
            ),
          ),
        );
        // กลับมาจากหน้า detail → เริ่มสแกนใหม่
        _resumeScanning();
      }
    } catch (e) {
      debugPrint('Scan error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _stopScanning() {
    _timer?.cancel();
    _timer = null;
  }

  void _resumeScanning() {
    if (!mounted) return;
    _timer = Timer.periodic(_scanInterval, (_) => _scanFrame());
    unawaited(_scanFrame());
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
                const Text('ไม่สามารถเปิดกล้องได้',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
                Text(_cameraErrorMsg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _dark,
      body: Column(
        children: [
          // ── Camera view ──────────────────────────────────────────────────
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_cameraReady)
                  HtmlElementView(viewType: _viewId)
                else
                  Container(
                    color: _dark2,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFC9A84C)),
                    ),
                  ),

                // dim overlay
                Container(color: Colors.black.withOpacity(0.25)),

                // corner guides
                _corner(top: 80, left: 40, topLeft: true),
                _corner(top: 80, right: 40, topRight: true),
                _corner(bottom: 80, left: 40, bottomLeft: true),
                _corner(bottom: 80, right: 40, bottomRight: true),

                // scanning line
                if (_isScanning)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: 220,
                        height: 2,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          color: _gold,
                        ),
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

          // ── Status bar (แทน result panel เดิม) ───────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: _dark2,
              border: Border(
                  top: BorderSide(
                      color: _gold.withOpacity(0.3), width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isScanning
                      ? Icons.radar
                      : Icons.document_scanner_outlined,
                  color: _isScanning ? _gold : Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isScanning
                      ? 'กำลังสแกน...'
                      : 'พร้อมสแกน — วางพระให้เห็นชัดเจน',
                  style: TextStyle(
                    color: _isScanning ? _gold : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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