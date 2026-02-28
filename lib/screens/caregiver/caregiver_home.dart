import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'overview_tab.dart';
import 'patients_tab.dart';
import 'alerts_tab.dart';
import 'analytics_tab.dart';
import 'caregiver_profile_tab.dart';

class CaregiverHome extends StatefulWidget {
  const CaregiverHome({super.key});

  @override
  State<CaregiverHome> createState() => _CaregiverHomeState();
}

class _CaregiverHomeState extends State<CaregiverHome> {
  int _currentIndex = 0;

  final _tabs = const [
    OverviewTab(),
    PatientsTab(),
    AlertsTab(),
    AnalyticsTab(),
    CaregiverProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _tabs[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Overview'),
              _navItem(1, Icons.people_rounded, Icons.people_outlined, 'Patients'),
              _navItem(2, Icons.notifications_active_rounded, Icons.notifications_outlined, 'Alerts'),
              _navItem(3, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Analytics'),
              _navItem(4, Icons.person_rounded, Icons.person_outlined, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData active, IconData inactive, String label) {
    final sel = _currentIndex == i;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF135BEC).withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                sel ? active : inactive,
                size: 22,
                color: sel ? const Color(0xFF135BEC) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? const Color(0xFF135BEC) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
