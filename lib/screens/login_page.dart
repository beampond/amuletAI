import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/auth_service.dart';
import 'main_shell.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  String? _errorMsg;

  static const _gold = Color(0xFFC9A84C);
  static const _dark = Color(0xFF0D0D0D);
  static const _dark2 = Color(0xFF1A1A1A);
  static const _text2 = Color(0xFFA89878);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Email login ──────────────────────────────────────────────────────────────
  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }

    setState(() { _loading = true; _errorMsg = null; });

    try {
      await AuthService.login(email, pass);
      await AuthService.updateLastLogin();
      if (!mounted) return;
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainShell()));
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMsg = _authError(e.code));
    } catch (e) {
      setState(() => _errorMsg = 'เกิดข้อผิดพลาด กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Google login ─────────────────────────────────────────────────────────────
  Future<void> _googleLogin() async {
    setState(() { _googleLoading = true; _errorMsg = null; });
    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred == null) { // user ยกเลิก
        setState(() => _googleLoading = false);
        return;
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainShell()));
    } catch (e) {
      setState(() => _errorMsg = 'Google Sign-In ล้มเหลว: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found': return 'ไม่พบบัญชีนี้ในระบบ';
      case 'wrong-password': return 'รหัสผ่านไม่ถูกต้อง';
      case 'invalid-email': return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'user-disabled': return 'บัญชีนี้ถูกระงับ';
      case 'too-many-requests': return 'ลองใหม่ภายหลัง (พยายามมากเกินไป)';
      case 'invalid-credential': return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      default: return 'เกิดข้อผิดพลาด ($code)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1400), Color(0xFF2A2000)],
                    ),
                    border: Border.all(color: _gold, width: 1.5),
                  ),
                  child: const Center(child: Text('🪬', style: TextStyle(fontSize: 32))),
                ),
                const SizedBox(height: 14),
                const Text('AMULET AI',
                    style: TextStyle(color: _gold, fontSize: 24,
                        letterSpacing: 6, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('ระบบสแกนพระอัจฉริยะ',
                    style: TextStyle(color: _text2, fontSize: 11, letterSpacing: 3)),
                const SizedBox(height: 40),

                // Error message
                if (_errorMsg != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Text(_errorMsg!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                ],

                // Email
                _buildInput(controller: _emailCtrl, hint: 'อีเมล',
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),

                // Password
                _buildInput(controller: _passCtrl, hint: 'รหัสผ่าน', obscure: true),
                const SizedBox(height: 16),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _gold,
                      foregroundColor: const Color(0xFF1A0E00),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(height: 18, width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF1A0E00)))
                        : const Text('เข้าสู่ระบบ',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),

                // Google Sign-In
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _googleLoading ? null : _googleLogin,
                    icon: _googleLoading
                        ? const SizedBox(height: 16, width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _gold))
                        : const Text('G', style: TextStyle(
                            color: _gold, fontSize: 16, fontWeight: FontWeight.bold)),
                    label: const Text('เข้าสู่ระบบด้วย Google',
                        style: TextStyle(color: _text2, fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: _gold.withOpacity(0.4), width: 0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('หรือ',
                            style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                    ],
                  ),
                ),

                // Register link
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterPage())),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: _text2, fontSize: 13),
                      children: [
                        TextSpan(text: 'ยังไม่มีบัญชี? '),
                        TextSpan(text: 'สมัครสมาชิก',
                            style: TextStyle(color: _gold, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        filled: true, fillColor: _dark2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF333333), width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF333333), width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _gold, width: 0.8)),
      ),
    );
  }
}