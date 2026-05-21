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
      'somdej': 'พระสมเด็จ',
      'luang_pu_thuat': 'หลวงปู่ทวด',
      'luang_pho_sothorn': 'หลวงพ่อโสธร',
      'luang_pho_khun': 'หลวงพ่อคูณ',
      'luang_pho_ruay': 'หลวงพ่อรวย',
      'phra_pidta': 'พระปิดตา',
      'phra_khun_pan': 'พระขุนแผน',
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
  static const _modelUrl = 'https://detect.roboflow.com/amulet-detection/2';
  static String get _apiKey => dotenv.env['ROBOFLOW_API_KEY'] ?? '';

  static Future<List<AmuletPrediction>> detect(String base64Image) async {
    if (_apiKey.isEmpty) throw Exception('ROBOFLOW_API_KEY is missing in .env');

    final response = await http
        .post(
          Uri.parse('$_modelUrl?api_key=$_apiKey'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: base64Image,
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Roboflow error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawPreds = _extractPredictions(data);
    final preds = rawPreds
        .whereType<Map<String, dynamic>>()
        .map(AmuletPrediction.fromJson)
        .toList();
    preds.sort((a, b) => b.confidence.compareTo(a.confidence));
    return preds;
  }

  static List<dynamic> _extractPredictions(Map<String, dynamic> data) {
    final predsField = data['predictions'];
    if (predsField is List) return predsField;
    if (predsField is Map<String, dynamic>) {
      final nested = predsField['predictions'];
      if (nested is List) return nested;
      final classMap = predsField.entries
          .where((e) => e.value is num)
          .map((e) => {'class': e.key, 'confidence': (e.value as num).toDouble()})
          .toList();
      if (classMap.isNotEmpty) return classMap;
    }
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
    return const [];
  }
}

// ── Scanner Page ──────────────────────────────────────────────────────────────

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  // public state ให้ MainShell เรียกได้
  ScannerPageState createState() => ScannerPageState();
}

class ScannerPageState extends State<ScannerPage> {
  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  bool _cameraReady = false;
  bool _cameraError = false;
  String _cameraErrorMsg = '';
  bool _isScanning = false;
  bool _isNavigating = false;
  bool _isPaused = false; // ← หยุดเมื่อออกจาก tab

  static const double _detectThreshold = 0.65;
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

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  // ── Public API สำหรับ MainShell ───────────────────────────────────────────

  void pauseScanning() {
    _isPaused = true;
    _stopTimer();
    debugPrint('Scanner paused');
  }

  void resumeScanning() {
    if (!_cameraReady) return;
    _isPaused = false;
    _lastDetectedClass = '';
    _consecutiveCount = 0;
    _startTimer();
    debugPrint('Scanner resumed');
  }

  // ── Camera setup ──────────────────────────────────────────────────────────

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

      if (!_isPaused) {
        unawaited(_scanFrame());
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = true;
          _cameraErrorMsg = e.toString();
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_scanInterval, (_) => _scanFrame());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _scanFrame() async {
    if (_isScanning || _isNavigating || _isPaused) return;
    if (_videoElement == null || !_cameraReady) return;
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

      final canvas = html.CanvasElement(width: captureWidth, height: captureHeight);
      canvas.context2D.drawImageScaled(_videoElement!, 0, 0, captureWidth, captureHeight);
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.90);
      final base64Image = dataUrl.split(',').last;

      final preds = await RoboflowService.detect(base64Image);

      if (!mounted || _isPaused) return;

      if (preds.isNotEmpty && preds.first.confidence >= _detectThreshold) {
        final detectedClass = preds.first.className;
        if (detectedClass == _lastDetectedClass) {
          _consecutiveCount++;
        } else {
          _lastDetectedClass = detectedClass;
          _consecutiveCount = 1;
        }
      } else {
        _lastDetectedClass = '';
        _consecutiveCount = 0;
      }

      if (_consecutiveCount >= _requiredConsecutive) {
        _consecutiveCount = 0;
        _lastDetectedClass = '';
        final snapshot = List<AmuletPrediction>.from(preds);

        _stopTimer();
        _isNavigating = true;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AmuletDetailPage(
              prediction: snapshot.first,
              allPredictions: snapshot,
              capturedImageBase64: base64Image,
            ),
          ),
        );

        _isNavigating = false;
        // กลับมาจาก detail — เริ่มใหม่เฉพาะเมื่อยัง active tab อยู่
        if (mounted && !_isPaused) resumeScanning();
      }
    } catch (e) {
      debugPrint('Scan error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
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
                const Icon(Icons.no_photography, color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                const Text('ไม่สามารถเปิดกล้องได้',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
                Text(_cameraErrorMsg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
                      child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
                    ),
                  ),

                Container(color: Colors.black.withOpacity(0.25)),

                _corner(top: 80, left: 40, topLeft: true),
                _corner(top: 80, right: 40, topRight: true),
                _corner(bottom: 80, left: 40, bottomLeft: true),
                _corner(bottom: 80, right: 40, bottomRight: true),

                if (_isScanning && !_isPaused)
                  Positioned(
                    top: 0, bottom: 0, left: 0, right: 0,
                    child: Center(
                      child: SizedBox(
                        width: 220, height: 2,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          color: _gold,
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  bottom: 12, left: 0, right: 0,
                  child: Text(
                    _isPaused
                        ? ''
                        : _isScanning
                            ? 'กำลังวิเคราะห์...'
                            : 'วางพระในกรอบเพื่อสแกน',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isScanning ? _gold : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),

                Positioned(
                  bottom: 36, right: 16,
                  child: GestureDetector(
                    onTap: (_isScanning || _isNavigating || _isPaused)
                        ? null
                        : _scanFrame,
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
                        color: (_isScanning || _isNavigating || _isPaused)
                            ? Colors.white24
                            : _gold,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: _dark2,
              border: Border(
                  top: BorderSide(color: _gold.withOpacity(0.3), width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isScanning ? Icons.radar : Icons.document_scanner_outlined,
                  color: _isScanning && !_isPaused ? _gold : Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isScanning && !_isPaused
                      ? 'กำลังสแกน...'
                      : 'พร้อมสแกน — วางพระให้เห็นชัดเจน',
                  style: TextStyle(
                    color: _isScanning && !_isPaused ? _gold : Colors.white38,
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
    double? top, double? bottom, double? left, double? right,
    bool topLeft = false, bool topRight = false,
    bool bottomLeft = false, bool bottomRight = false,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 24, height: 24,
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
    _stopTimer();
    _stream?.getTracks().forEach((t) => t.stop());
    super.dispose();
  }
}