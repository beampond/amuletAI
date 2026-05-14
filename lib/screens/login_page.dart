import 'package:flutter/material.dart';
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

  void _login() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
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
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1400), Color(0xFF2A2000)],
                    ),
                    border: Border.all(color: _gold, width: 1.5),
                  ),
                  child: const Center(
                    child: Text('🪬', style: TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'AMULET AI',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 24,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ระบบสแกนพระอัจฉริยะ',
                  style: TextStyle(color: _text2, fontSize: 11, letterSpacing: 3),
                ),
                const SizedBox(height: 40),

                // Email
                _buildInput(
                  controller: _emailCtrl,
                  hint: 'อีเมล',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),

                // Password
                _buildInput(
                  controller: _passCtrl,
                  hint: 'รหัสผ่าน',
                  obscure: true,
                ),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1A0E00),
                            ),
                          )
                        : const Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                  ),
                ),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                          child: Divider(color: Colors.white.withOpacity(0.1))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('หรือ',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 12)),
                      ),
                      Expanded(
                          child: Divider(color: Colors.white.withOpacity(0.1))),
                    ],
                  ),
                ),

                // Register link
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: _text2, fontSize: 13),
                      children: [
                        TextSpan(text: 'ยังไม่มีบัญชี? '),
                        TextSpan(
                          text: 'สมัครสมาชิก',
                          style: TextStyle(
                              color: _gold, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                // Skip (dev shortcut)
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainShell()),
                  ),
                  child: const Text(
                    'ข้ามการเข้าสู่ระบบ',
                    style: TextStyle(color: Colors.white24, fontSize: 11),
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
        filled: true,
        fillColor: _dark2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333333), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333333), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold, width: 0.8),
        ),
      ),
    );
  }
}
