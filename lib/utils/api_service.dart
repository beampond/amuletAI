import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AmuletAnalysis {
  final String thaiName;
  final String englishName;
  final String generation;
  final double confidence;
  final double authenticPercent;
  final String priceRange;
  final String authenticityNote;
  final String details;

  const AmuletAnalysis({
    required this.thaiName,
    required this.englishName,
    required this.generation,
    required this.confidence,
    required this.authenticPercent,
    required this.priceRange,
    required this.authenticityNote,
    required this.details,
  });

  factory AmuletAnalysis.fromJson(Map<String, dynamic> json) {
    return AmuletAnalysis(
      thaiName: json['thai_name'] as String? ?? 'ไม่ทราบ',
      englishName: json['english_name'] as String? ?? 'Unknown',
      generation: json['generation'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      authenticPercent: (json['authentic_percent'] as num?)?.toDouble() ?? 0.0,
      priceRange: json['price_range'] as String? ?? 'ไม่ทราบ',
      authenticityNote: json['authenticity_note'] as String? ?? '',
      details: json['details'] as String? ?? '',
    );
  }
}

class ApiService {
  static String get _apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  static const _systemPrompt = '''
คุณคือผู้เชี่ยวชาญด้านพระเครื่องไทย วิเคราะห์รูปภาพพระเครื่องและตอบใน JSON เท่านั้น
ตอบด้วย JSON รูปแบบนี้เท่านั้น ไม่มีข้อความอื่น:
{
  "thai_name": "ชื่อพระภาษาไทย",
  "english_name": "ชื่อภาษาอังกฤษ",
  "generation": "ยุคสมัย / วัด / ปีที่สร้าง",
  "confidence": 0.85,
  "authentic_percent": 75.0,
  "price_range": "5,000 - 15,000 บาท",
  "authenticity_note": "คำอธิบายความแท้",
  "details": "ข้อมูลเพิ่มเติมเกี่ยวกับพระ"
}
ถ้าไม่ใช่พระเครื่อง ให้ตั้งชื่อว่า "ไม่พบพระในภาพ" และ confidence เป็น 0.
''';

  static Future<AmuletAnalysis> scanAmulet(String base64Image) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-opus-4-5',
        'max_tokens': 1024,
        'system': _systemPrompt,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': base64Image,
                },
              },
              {
                'type': 'text',
                'text': 'วิเคราะห์พระเครื่องในภาพนี้',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (data['content'] as List).first as Map<String, dynamic>;
    final text = content['text'] as String;

    // Strip markdown fences if present
    final cleaned = text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    return AmuletAnalysis.fromJson(parsed);
  }
}
