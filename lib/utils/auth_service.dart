import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn();

  // ── Current user ────────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email / Password login ───────────────────────────────────────────────────
  static Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── Email / Password register ────────────────────────────────────────────────
  static Future<UserCredential> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // บันทึก profile ใน Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'email': email.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'displayName': '${firstName.trim()} ${lastName.trim()}',
      'role': 'user',
      'scanCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });

    await cred.user!.updateDisplayName('${firstName.trim()} ${lastName.trim()}');
    return cred;
  }

  // ── Google OAuth ─────────────────────────────────────────────────────────────
  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user ยกเลิก

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);

    // upsert: สร้างใหม่หรืออัปเดต doc ที่มีอยู่แล้วก็ได้ (merge: true)
    final userRef = _db.collection('users').doc(cred.user!.uid);
    final isNew = cred.additionalUserInfo?.isNewUser == true;

    await userRef.set(
      {
        'uid': cred.user!.uid,
        'email': cred.user!.email ?? '',
        'displayName': cred.user!.displayName ?? '',
        'photoUrl': cred.user!.photoURL ?? '',
        if (isNew) 'role': 'user',
        if (isNew) 'scanCount': 0,
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true), // ไม่ทับ field เดิม เช่น role, scanCount
    );

    return cred;
  }

  // ── Logout ────────────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Get user profile ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ── Check admin role ──────────────────────────────────────────────────────────
  static Future<bool> isAdmin() async {
    final profile = await getUserProfile();
    return profile?['role'] == 'admin';
  }

  // ── Update last login ─────────────────────────────────────────────────────────
  static Future<void> updateLastLogin() async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set(
      {'lastLogin': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}