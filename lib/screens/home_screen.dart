import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_content.dart';
import 'schedule_screen.dart';
import 'history_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import '../models/medication.dart';
import 'add_medication_sheet.dart';
import 'ai_chat_screen.dart';
import '../services/medication_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

// _HomeScreenState class body continues below

  final List<Widget> _screens = [
    const HomeContent(),
    const ScheduleScreen(),
    const HistoryScreen(),
    const AlertsScreen(),
    const ProfileScreen(),
  ];

  void _openAddMedicationSheet() async {
    final result = await showModalBottomSheet<Medication>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMedicationSheet(),
    );
    if (result != null) {
      MedicationStore().add(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: Stack(
        children: [
          // Current screen
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(_currentNavIndex),
              child: _screens[_currentNavIndex],
            ),
          ),

          // FAB (on Home and Schedule)
          if (_currentNavIndex == 0 || _currentNavIndex == 1)
            Positioned(
              bottom: 90,
              right: 20,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF135BEC).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 32),
                  onPressed: _openAddMedicationSheet,
                ),
              ),
            ),

          // Floating AI Chatbot Icon
          Positioned(
            bottom: 90,
            left: 20,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF135BEC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.25 + _pulseAnimation.value * 0.2),
                        blurRadius: 12 + _pulseAnimation.value * 8,
                        spreadRadius: _pulseAnimation.value * 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const AiChatScreen(),
                          transitionsBuilder: (_, anim, __, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 1),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
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
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(1, Icons.calendar_month, Icons.calendar_month_outlined, 'Schedule'),
              _buildNavItem(2, Icons.history_rounded, Icons.history_rounded, 'History'),
              _buildNavItem(3, Icons.notifications_active_rounded, Icons.notifications_none_rounded, 'Alerts'),
              _buildNavItem(4, Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentNavIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentNavIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF135BEC).withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                size: 24,
                color: isActive ? const Color(0xFF135BEC) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF135BEC) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
