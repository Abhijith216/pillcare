import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_content.dart';
import 'schedule_screen.dart';
import 'history_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  bool _scrollToRefill = false;

  // Floating AI button pulse
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Per-nav-item bounce controllers
  late final List<AnimationController> _navBounceControllers;
  late final List<Animation<double>> _navBounceAnimations;

  // Page-slide direction (+1 slide from right side, -1 from left side)
  int _slideDirection = 1;

  static const _navItems = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.calendar_month, Icons.calendar_month_outlined, 'Schedule'),
    (Icons.history_rounded, Icons.history_rounded, 'History'),
    (Icons.notifications_active_rounded, Icons.notifications_none_rounded, 'Alerts'),
    (Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
  ];

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

    _navBounceControllers = List.generate(
      _navItems.length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 380)),
    );

    _navBounceAnimations = _navBounceControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.15), weight: 45),
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    }).toList();

    _navBounceControllers[0].forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    for (final c in _navBounceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    _slideDirection = index > _currentNavIndex ? 1 : -1;
    setState(() {
      _currentNavIndex = index;
      if (index != 1) _scrollToRefill = false;
    });
    _navBounceControllers[index].forward(from: 0);
  }

  Widget _buildCurrentScreen() {
    switch (_currentNavIndex) {
      case 0:
        return HomeContent(
          onNavigateToSchedule: () {
            _onNavTap(1);
            setState(() => _scrollToRefill = true);
          },
        );
      case 1:
        return ScheduleScreen(scrollToRefill: _scrollToRefill);
      case 2:
        return const HistoryScreen();
      case 3:
        return const AlertsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Main content with slide+fade transition
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
              key: ValueKey('$_currentNavIndex-$_scrollToRefill'),
              child: _buildCurrentScreen(),
            ),
          ),

          // Floating AI button
          Positioned(
            bottom: 90,
            right: 20,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => Container(
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
                      color: const Color(0xFF7C3AED)
                          .withValues(alpha: 0.25 + _pulseAnimation.value * 0.2),
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
                        transitionsBuilder: (_, anim, __, child) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                        transitionDuration: const Duration(milliseconds: 380),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom nav bar
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
              (i) => _buildNavItem(
                i,
                _navItems[i].$1,
                _navItems[i].$2,
                _navItems[i].$3,
                isDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    bool isDark,
  ) {
    final isActive = _currentNavIndex == index;
    const activeColor = Color(0xFF135BEC);
    final inactiveColor = isDark ? const Color(0xFF4A5568) : const Color(0xFF94A3B8);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNavTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _navBounceAnimations[index],
              builder: (_, child) => Transform.scale(
                scale: _navBounceAnimations[index].value,
                child: child,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor.withValues(alpha: isDark ? 0.18 : 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    isActive ? activeIcon : inactiveIcon,
                    key: ValueKey('nav-$index-$isActive'),
                    size: 24,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
