import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class ScanRecord {
  final String id;
  final String className;
  final String thaiName;
  final double confidence;
  final String? priceRange;
  final String? generation;
  final String? authenticityNote;
  final DateTime scannedAt;
  final String? imageBase64; // เก็บแค่ thumbnail เล็กๆ

  const ScanRecord({
    required this.id,
    required this.className,
    required this.thaiName,
    required this.confidence,
    this.priceRange,
    this.generation,
    this.authenticityNote,
    required this.scannedAt,
    this.imageBase64,
  });

  factory ScanRecord.fromFirestore(Map<String, dynamic> data, String id) {
    return ScanRecord(
      id: id,
      className: data['className'] as String? ?? '',
      thaiName: data['thaiName'] as String? ?? '',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      priceRange: data['priceRange'] as String?,
      generation: data['generation'] as String?,
      authenticityNote: data['authenticityNote'] as String?,
      scannedAt: (data['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageBase64: data['imageBase64'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'className': className,
        'thaiName': thaiName,
        'confidence': confidence,
        'priceRange': priceRange,
        'generation': generation,
        'authenticityNote': authenticityNote,
        'scannedAt': FieldValue.serverTimestamp(),
        'imageBase64': imageBase64,
      };
}

class ScanHistoryService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _userScans() {
    final uid = AuthService.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('scans');
  }

  // ── บันทึกผลสแกน ──────────────────────────────────────────────────────────
  static Future<void> saveScan(ScanRecord record) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    await _userScans().add(record.toFirestore());

    // อัปเดต scan count
    await _db.collection('users').doc(uid).update({
      'scanCount': FieldValue.increment(1),
    });
  }

  // ── ดึงประวัติ 90 วัน ─────────────────────────────────────────────────────
  static Future<List<ScanRecord>> getHistory({int days = 90}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _userScans()
        .where('scannedAt', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('scannedAt', descending: true)
        .limit(100)
        .get();

    return snapshot.docs
        .map((d) => ScanRecord.fromFirestore(d.data(), d.id))
        .toList();
  }

  // ── Stream realtime (สำหรับ history page) ─────────────────────────────────
  static Stream<List<ScanRecord>> historyStream({int days = 90}) {
    final since = DateTime.now().subtract(Duration(days: days));
    return _userScans()
        .where('scannedAt', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('scannedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ScanRecord.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ── ลบประวัติ ─────────────────────────────────────────────────────────────
  static Future<void> deleteScan(String scanId) async {
    await _userScans().doc(scanId).delete();
  }
}