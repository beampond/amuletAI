import 'package:flutter/material.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _gold = Color(0xFFC9A84C);
  static const _dark = Color(0xFF0D0D0D);
  static const _dark3 = Color(0xFF1E1E1E);
  static const _text2 = Color(0xFFA89878);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold, width: 1.5),
                  color: const Color(0xFF1A1A1A),
                ),
                child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ผู้ใช้งาน',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              const Text(
                'user@example.com',
                style: TextStyle(color: _text2, fontSize: 12),
              ),
              const SizedBox(height: 32),

              // Stats
              Row(
                children: [
                  _statCard('12', 'สแกนทั้งหมด'),
                  const SizedBox(width: 10),
                  _statCard('8', 'แท้'),
                  const SizedBox(width: 10),
                  _statCard('4', 'ไม่แน่ใจ'),
                ],
              ),
              const SizedBox(height: 24),

              // Menu items
              _menuItem(Icons.history, 'ประวัติการสแกน'),
              _menuItem(Icons.notifications_outlined, 'การแจ้งเตือน'),
              _menuItem(Icons.help_outline, 'ช่วยเหลือ'),
              _menuItem(Icons.info_outline, 'เกี่ยวกับแอป'),
              const SizedBox(height: 16),
              // Logout
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                        width: 0.5),
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
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: _gold, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: _text2, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _dark3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: _text2, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          const Icon(Icons.chevron_right,
              color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}
