import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _fadeCtrl]),
        builder: (context, _) {
          final pulse = _pulseCtrl.value;
          final fade = _fadeCtrl.value;
          return SafeArea(child: Column(children: [
            _buildAppBar(),
            Expanded(child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(children: [
                const SizedBox(height: 20),
                _buildAnimatedLogo(pulse),
                const SizedBox(height: 24),

                // Tagline
                Opacity(opacity: fade,
                  child: Text('Your Health, Simplified.',
                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B)),
                    textAlign: TextAlign.center)),
                const SizedBox(height: 6),
                Opacity(opacity: fade,
                  child: Text('Smart medication management for a healthier tomorrow.',
                    style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF94A3B8)),
                    textAlign: TextAlign.center)),
                const SizedBox(height: 32),

                // App info cards
                _buildInfoCard(Icons.info_outline_rounded, 'App Version', '1.0.0 (Build 2026.02)', 0, fade),
                const SizedBox(height: 10),
                _buildInfoCard(Icons.code_rounded, 'Developer', 'PillCare Team', 1, fade),
                const SizedBox(height: 10),
                _buildInfoCard(Icons.flutter_dash_rounded, 'Built With', 'Flutter & Dart', 2, fade),
                const SizedBox(height: 10),
                _buildInfoCard(Icons.devices_rounded, 'Platform', 'Web, iOS, Android', 3, fade),
                const SizedBox(height: 28),

                // Legal section
                _sectionLabel('LEGAL'),
                const SizedBox(height: 12),
                _buildLegalCard('Terms of Service', Icons.description_outlined, _showTerms),
                const SizedBox(height: 10),
                _buildLegalCard('Privacy Policy', Icons.privacy_tip_outlined, _showPrivacy),
                const SizedBox(height: 10),
                _buildLegalCard('Open Source Licenses', Icons.source_outlined, _showLicenses),
                const SizedBox(height: 32),

                // Footer
                Text('Made with ❤️ for better health',
                  style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFFCBD5E1))),
                const SizedBox(height: 4),
                Text('© 2026 PillCare. All rights reserved.',
                  style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFFE2E8F0))),
              ]),
            )),
          ]));
        },
      ),
    );
  }

  Widget _buildAppBar() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      Text('About PillCare', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
    ]),
  );

  Widget _sectionLabel(String text) => Align(alignment: Alignment.centerLeft,
    child: Text(text, style: GoogleFonts.manrope(
      fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 1)));

  Widget _buildAnimatedLogo(double pulse) {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF135BEC), const Color(0xFF7C3AED), pulse)!,
            Color.lerp(const Color(0xFF7C3AED), const Color(0xFF06B6D4), pulse)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF135BEC).withValues(alpha: 0.2 + pulse * 0.15),
            blurRadius: 20 + pulse * 10, spreadRadius: -2),
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.1 + pulse * 0.1),
            blurRadius: 30 + pulse * 10, spreadRadius: -4),
        ],
      ),
      child: Center(
        child: Transform.scale(
          scale: 1.0 + math.sin(pulse * math.pi) * 0.05,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.medication_rounded, color: Colors.white, size: 36),
            const SizedBox(height: 2),
            Text('PC', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w900,
              color: Colors.white, letterSpacing: 2)),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, int index, double fade) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 100),
      curve: Curves.easeOutCubic,
      builder: (ctx, val, child) => Transform.translate(
        offset: Offset(0, 15 * (1 - val)),
        child: Opacity(opacity: val, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: const Color(0xFF135BEC))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF94A3B8))),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          ])),
        ]),
      ),
    );
  }

  Widget _buildLegalCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)))),
          const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFFCBD5E1)),
        ]),
      ),
    );
  }

  void _showTerms() => _showLegalSheet('Terms of Service',
    'Welcome to PillCare. By using this app, you agree to the following terms:\n\n'
    '1. PillCare is designed as a medication management tool and does not replace professional medical advice.\n\n'
    '2. You are responsible for the accuracy of medication information entered.\n\n'
    '3. We do not guarantee the accuracy of AI-generated health insights.\n\n'
    '4. Your data is stored locally unless you opt in to cloud sync.\n\n'
    '5. We reserve the right to update these terms at any time.\n\n'
    '6. Use of the Smart Dispenser feature requires compatible hardware.');

  void _showPrivacy() => _showLegalSheet('Privacy Policy',
    'PillCare takes your privacy seriously.\n\n'
    '• Data Collection: We collect only the information you provide (medication names, schedules, health notes).\n\n'
    '• Storage: All data is stored locally on your device by default.\n\n'
    '• AI Features: When using AI chat, your messages are sent to our AI provider but are not stored permanently.\n\n'
    '• No Selling: We never sell your personal health data to third parties.\n\n'
    '• Encryption: Optional encryption is available in Settings → Privacy & Security.\n\n'
    '• Deletion: You can clear all data at any time from the Privacy & Security settings.');

  void _showLicenses() => showLicensePage(context: context, applicationName: 'PillCare', applicationVersion: '1.0.0');

  void _showLegalSheet(String title, String content) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Text(content, style: GoogleFonts.manrope(fontSize: 14, height: 1.6, color: const Color(0xFF64748B))),
          )),
        ]),
      ),
    );
  }
}
