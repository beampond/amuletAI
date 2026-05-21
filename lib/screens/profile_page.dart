import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/auth_service.dart';
import 'login_page.dart';
import 'history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  static const _gold = Color(0xFFC9A84C);
  static const _dark = Color(0xFF0D0D0D);
  static const _dark3 = Color(0xFF1E1E1E);
  static const _text2 = Color(0xFFA89878);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await AuthService.getUserProfile();
    if (mounted) setState(() { _profile = p; _loading = false; });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('ออกจากระบบ',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('ต้องการออกจากระบบใช่หรือไม่?',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('ออกจากระบบ',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm != true) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final displayName = _profile?['displayName'] as String?
        ?? user?.displayName ?? 'ผู้ใช้งาน';
    final email = user?.email ?? '';
    final scanCount = _profile?['scanCount'] as int? ?? 0;
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _gold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Avatar
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _gold, width: 1.5),
                        color: const Color(0xFF1A1A1A),
                      ),
                      child: photoUrl != null
                          ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover))
                          : const Center(
                              child: Text('👤', style: TextStyle(fontSize: 36))),
                    ),
                    const SizedBox(height: 12),
                    Text(displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(email,
                        style: const TextStyle(color: _text2, fontSize: 12)),
                    const SizedBox(height: 32),

                    // Stats
                    Row(children: [
                      _statCard('$scanCount', 'สแกนทั้งหมด'),
                    ]),
                    const SizedBox(height: 24),

                    // Menu
                    _menuItem(Icons.history, 'ประวัติการสแกน', onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HistoryPage()));
                    }),
                    _menuItem(Icons.notifications_outlined, 'การแจ้งเตือน'),
                    _menuItem(Icons.help_outline, 'ช่วยเหลือ'),
                    _menuItem(Icons.info_outline, 'เกี่ยวกับแอป'),
                    const SizedBox(height: 16),

                    // Logout
                    GestureDetector(
                      onTap: _logout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.3), width: 0.5),
                          color: Colors.red.withOpacity(0.05),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.redAccent, size: 16),
                            SizedBox(width: 8),
                            Text('ออกจากระบบ',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _dark3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10, width: 0.5),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(
              color: _gold, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _text2, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _dark3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10, width: 0.5),
        ),
        child: Row(children: [
          Icon(icon, color: _text2, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
        ]),
      ),
    );
  }
}