import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../services/medication_store.dart';
import 'history_screen.dart';

class DailyAdherenceCard extends StatefulWidget {
  const DailyAdherenceCard({super.key});

  @override
  State<DailyAdherenceCard> createState() => _DailyAdherenceCardState();
}

class _DailyAdherenceCardState extends State<DailyAdherenceCard> with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _glowController;
  late final AnimationController _entryController;
  
  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _glowController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _showWeeklySummary() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart_rounded, color: Color(0xFF93C5FD)),
                    const SizedBox(width: 8),
                    Text('Weekly Summary', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 24),
                // simple mini chart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar('M', 0.8),
                    _buildBar('T', 0.9),
                    _buildBar('W', 0.6),
                    _buildBar('T', 1.0),
                    _buildBar('F', 0.5),
                    _buildBar('S', 0.9),
                    _buildBar('S', 0.7),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      surfaceTintColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Close', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBar(String day, double heightFactor) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 100,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FractionallySizedBox(
            heightFactor: heightFactor,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MedicationStore(),
      builder: (context, _) {
        final store = MedicationStore();
        final meds = store.medications;
        final taken = meds.where((m) => m.takenToday).length;
        final total = meds.isEmpty ? 1 : meds.length;
        final pct = taken / total;
        
        String message;
        Color messageColor;
        if (pct >= 0.8) {
          message = "Great job staying consistent!";
          messageColor = const Color(0xFF34D399); // Green
        } else if (pct >= 0.5) {
          message = "Almost there, keep it up!";
          messageColor = const Color(0xFFFBBF24); // Yellow
        } else {
          message = "Let’s get back on track!";
          messageColor = const Color(0xFFF87171); // Red
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
          },
          onLongPress: _showWeeklySummary,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAILY ADHERENCE', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF93C5FD), letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text('Today\'s Progress', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                    Icon(Icons.touch_app_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
                  ],
                ),
                const SizedBox(height: 38),
                
                // Animated Circular Progress with Orbiting Pills
                AnimatedBuilder(
                  animation: Listenable.merge([_orbitController, _glowController, _entryController]),
                  builder: (context, child) {
                    final orbitObj = _orbitController.value;
                    final glowVal = _glowController.value;
                    final entryVal = CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic).value;
                    final displayPct = pct * entryVal;
                    
                    return SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Glow behind the circle (only pulses intensely if >= 80% or pulses moderately)
                          Container(
                            width: 130 + glowVal * (pct >= 0.8 ? 30 : 10),
                            height: 130 + glowVal * (pct >= 0.8 ? 30 : 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.15 * glowVal),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF135BEC).withValues(alpha: 0.25 * glowVal),
                                  blurRadius: 30,
                                  spreadRadius: pct >= 0.8 ? 10 : 0,
                                ),
                              ],
                            ),
                          ),
                          
                          // Circular Progress
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CustomPaint(
                              painter: _GradientCircularProgressPainter(
                                progress: displayPct,
                                strokeWidth: 14,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF135BEC), Color(0xFF7C3AED), Color(0xFF06B6D4)],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                          
                          // Center Text
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(displayPct * 100).round()}%',
                                style: GoogleFonts.manrope(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Adherence',
                                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                          
                          // Orbiting pill icon 1
                          Positioned(
                            left: 85 + math.cos(orbitObj * 2 * math.pi) * 90 - 15,
                            top: 85 + math.sin(orbitObj * 2 * math.pi) * 90 - 15,
                            child: Transform.rotate(
                              angle: orbitObj * 4 * math.pi,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
                                  boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.4), blurRadius: 10)],
                                ),
                                child: const Icon(Icons.medication_liquid_rounded, size: 16, color: Color(0xFFC4B5FD)),
                              ),
                            ),
                          ),
                          
                          // Orbiting pill icon 2
                          Positioned(
                            left: 85 + math.cos(orbitObj * 2 * math.pi + math.pi) * 90 - 15,
                            top: 85 + math.sin(orbitObj * 2 * math.pi + math.pi) * 90 - 15,
                            child: Transform.rotate(
                              angle: orbitObj * -4 * math.pi,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.5)),
                                  boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.4), blurRadius: 10)],
                                ),
                                child: const Icon(Icons.medication_rounded, size: 16, color: Color(0xFF67E8F9)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 38),
                
                // Dynamic feedback message with fade
                FadeTransition(
                  opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: messageColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: messageColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(pct >= 0.8 ? Icons.celebration_rounded : pct >= 0.5 ? Icons.thumb_up_rounded : Icons.support_rounded, color: messageColor, size: 18),
                        const SizedBox(width: 8),
                        Text(message, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: messageColor)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Gradient gradient;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);
    
    // Gradient outline
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
      
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.gradient != gradient;
  }
}
