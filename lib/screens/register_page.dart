import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/auth_service.dart';
import 'main_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  static const _gold = Color(0xFFC9A84C);
  static const _dark = Color(0xFF0D0D0D);
  static const _dark2 = Color(0xFF1A1A1A);
  static const _text2 = Color(0xFFA89878);

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (first.isEmpty || last.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMsg = 'รหัสผ่านไม่ตรงกัน');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMsg = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }

    setState(() { _loading = true; _errorMsg = null; });

    try {
      await AuthService.register(
        email: email,
        password: pass,
        firstName: first,
        lastName: last,
      );
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

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'invalid-email': return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password': return 'รหัสผ่านไม่แข็งแรงพอ';
      default: return 'เกิดข้อผิดพลาด ($code)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.arrow_back_ios, color: _gold, size: 14),
                  SizedBox(width: 4),
                  Text('กลับ', style: TextStyle(color: _gold, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 20),
              const Text('สมัครสมาชิก',
                  style: TextStyle(color: _gold, fontSize: 20,
                      fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 4),
              const Text('สร้างบัญชีเพื่อเริ่มใช้งาน',
                  style: TextStyle(color: _text2, fontSize: 12)),
              const SizedBox(height: 24),

              // Error
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

              Row(children: [
                Expanded(child: _inputGroup(label: 'ชื่อ', controller: _firstCtrl, hint: 'สมชาย')),
                const SizedBox(width: 10),
                Expanded(child: _inputGroup(label: 'นามสกุล', controller: _lastCtrl, hint: 'ใจดี')),
              ]),
              const SizedBox(height: 10),
              _inputGroup(label: 'อีเมล', controller: _emailCtrl,
                  hint: 'email@example.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _inputGroup(label: 'รหัสผ่าน', controller: _passCtrl,
                  hint: '••••••••', obscure: true),
              const SizedBox(height: 10),
              _inputGroup(label: 'ยืนยันรหัสผ่าน', controller: _confirmCtrl,
                  hint: '••••••••', obscure: true),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
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
                      : const Text('สร้างบัญชี',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputGroup({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _text2, fontSize: 11)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF555555)),
            filled: true, fillColor: _dark2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF333333), width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF333333), width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _gold, width: 0.8)),
          ),
        ),
      ],
    );
  }
}