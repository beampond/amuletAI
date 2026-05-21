import 'package:flutter/material.dart';
import 'scanner_page.dart';
import 'amulets_page.dart';
import 'profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 1});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  static const _gold = Color(0xFFC9A84C);
  static const _dark = Color(0xFF0D0D0D);

  // ใช้ GlobalKey เพื่อเรียก method ของ ScannerPage โดยตรง
  final _scannerKey = GlobalKey<ScannerPageState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;

    // ออกจากหน้าสแกน → หยุดสแกน
    if (_currentIndex == 1) {
      _scannerKey.currentState?.pauseScanning();
    }
    // กลับมาหน้าสแกน → เริ่มสแกนใหม่
    if (index == 1) {
      _scannerKey.currentState?.resumeScanning();
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const AmuletsPage(),
          ScannerPage(key: _scannerKey),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: _dark,
          border: Border(
            top: BorderSide(color: Color(0xFF222222), width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.auto_stories_outlined,
                  activeIcon: Icons.auto_stories,
                  label: 'คลัง',
                  active: _currentIndex == 0,
                  onTap: () => _onTabChanged(0),
                ),
                _NavItem(
                  icon: Icons.document_scanner_outlined,
                  activeIcon: Icons.document_scanner,
                  label: 'สแกน',
                  active: _currentIndex == 1,
                  onTap: () => _onTabChanged(1),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'บัญชี',
                  active: _currentIndex == 2,
                  onTap: () => _onTabChanged(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  static const _gold = Color(0xFFC9A84C);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? _gold : const Color(0xFF555555),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? _gold : const Color(0xFF555555),
                fontSize: 10,
                fontWeight: active ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}