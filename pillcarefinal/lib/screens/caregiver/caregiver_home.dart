import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/caregiver_store.dart';
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

class _CaregiverHomeState extends State<CaregiverHome> with TickerProviderStateMixin {
  int _currentIndex = 1;  // Default to Patients tab
  int _slideDirection = 1;

  late final List<AnimationController> _bounceControllers;
  late final List<Animation<double>> _bounceAnimations;

  static const _navItems = [
    (Icons.dashboard_rounded, Icons.dashboard_outlined, 'Overview'),
    (Icons.people_rounded, Icons.people_outlined, 'Patients'),
    (Icons.notifications_active_rounded, Icons.notifications_outlined, 'Alerts'),
    (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Analytics'),
    (Icons.person_rounded, Icons.person_outlined, 'Profile'),
  ];

  final _tabs = const [
    OverviewTab(),
    PatientsTab(),
    AlertsTab(),
    AnalyticsTab(),
    CaregiverProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    CaregiverStore().loadFromFirestore();

    _bounceControllers = List.generate(
      _navItems.length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 380)),
    );

    _bounceAnimations = _bounceControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.15), weight: 45),
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    }).toList();

    _bounceControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _bounceControllers) c.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    _slideDirection = index > _currentIndex ? 1 : -1;
    setState(() => _currentIndex = index);
    _bounceControllers[index].forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: Offset(_slideDirection * 0.06, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: _tabs[_currentIndex],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D27) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2D3142) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(
              _navItems.length,
              (i) => _buildNavItem(i, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final isActive = _currentIndex == index;
    const activeColor = Color(0xFF135BEC);
    final inactiveColor = isDark ? const Color(0xFF4A5568) : const Color(0xFF94A3B8);
    final item = _navItems[index];

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNavTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _bounceAnimations[index],
              builder: (_, child) => Transform.scale(
                scale: _bounceAnimations[index].value,
                child: child,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor.withValues(alpha: isDark ? 0.18 : 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    isActive ? item.$1 : item.$2,
                    key: ValueKey('cgnav-$index-$isActive'),
                    size: 22,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
              child: Text(item.$3),
            ),
          ],
        ),
      ),
    );
  }
}
