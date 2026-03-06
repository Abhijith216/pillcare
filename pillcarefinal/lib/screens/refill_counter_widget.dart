import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../models/medication.dart';
import '../services/medication_store.dart';

// ───────────────────────────────────────────────────────────────────
//  FUTURISTIC REFILL COUNTER WIDGET
//  A neon-glowing, animated refill tracker for the PillCare home.
// ───────────────────────────────────────────────────────────────────

class RefillCounterWidget extends StatefulWidget {
  const RefillCounterWidget({super.key});

  @override
  State<RefillCounterWidget> createState() => _RefillCounterWidgetState();
}

class _RefillCounterWidgetState extends State<RefillCounterWidget>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _ringPulseController;
  late final AnimationController _bottleBobController;
  AnimationController? _sparkController;

  // Track previous refill counts to detect changes
  Map<String, int> _prevRefillCounts = {};
  String? _lastRefillMedId;

  // Undo snapshot (stores counts before a Refill All)
  Map<String, int>? _undoSnapshot;

  @override
  void initState() {
    super.initState();

    // Slow neon glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Ring pulse (breathing effect on progress arcs)
    _ringPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Gentle bottle bobbing
    _bottleBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // Cache initial refill counts
    final store = MedicationStore();
    for (final m in store.medications) {
      _prevRefillCounts[m.id] = m.refillCount;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _ringPulseController.dispose();
    _bottleBobController.dispose();
    _sparkController?.dispose();
    super.dispose();
  }

  void _triggerSpark(String medId) {
    _sparkController?.dispose();
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    setState(() => _lastRefillMedId = medId);
    _sparkController!.forward().then((_) {
      if (mounted) setState(() => _lastRefillMedId = null);
    });
  }

  void _logRefill(Medication med) {
    final store = MedicationStore();
    final newCount = math.min(med.refillCount + 5, med.refillTotal);
    store.updateRefillCount(med.id, newCount);
    _triggerSpark(med.id);
    _prevRefillCounts[med.id] = newCount;
  }

  void _refillAll() {
    final store = MedicationStore();
    final meds = store.medications;
    // Save snapshot for undo
    _undoSnapshot = { for (final m in meds) m.id: m.refillCount };
    for (final m in meds) {
      store.updateRefillCount(m.id, m.refillTotal);
      _prevRefillCounts[m.id] = m.refillTotal;
    }
    if (meds.isNotEmpty) _triggerSpark(meds.first.id);
  }

  void _undoRefillAll() {
    if (_undoSnapshot == null) return;
    final store = MedicationStore();
    for (final entry in _undoSnapshot!.entries) {
      store.updateRefillCount(entry.key, entry.value);
      _prevRefillCounts[entry.key] = entry.value;
    }
    setState(() => _undoSnapshot = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MedicationStore(),
      builder: (context, _) {
        final store = MedicationStore();
        final meds = store.medications;

        // Overall refill health
        int totalPills = 0;
        int totalCapacity = 0;
        for (final m in meds) {
          totalPills += m.refillCount;
          totalCapacity += m.refillTotal;
        }
        final overallPct =
            totalCapacity > 0 ? totalPills / totalCapacity : 0.0;
        final lowCount = meds.where((m) => m.isLowRefill).length;

        return AnimatedBuilder(
          animation: Listenable.merge(
              [_glowController, _ringPulseController, _bottleBobController]),
          builder: (context, _) {
            final glowVal = _glowController.value;
            final ringVal = _ringPulseController.value;
            final bobVal = _bottleBobController.value;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                // Dark glassmorphic card
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0E27),
                    Color(0xFF0F1638),
                    Color(0xFF0D1230),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xFF1E3A8A),
                    const Color(0xFF7C3AED),
                    glowVal,
                  )!
                      .withValues(alpha: 0.4 + glowVal * 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF135BEC)
                        .withValues(alpha: 0.08 + glowVal * 0.06),
                    blurRadius: 28 + glowVal * 12,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF7C3AED)
                        .withValues(alpha: 0.06 + glowVal * 0.04),
                    blurRadius: 20 + glowVal * 8,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Background ambient particles
                    ..._buildAmbientDots(glowVal),

                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          _buildHeader(glowVal, overallPct, ringVal),
                          const SizedBox(height: 14),

                          // Refill All button
                          _buildRefillAllButton(glowVal),
                          const SizedBox(height: 16),

                          // Overall progress ring + stats
                          _buildOverallRing(
                              overallPct, totalPills, totalCapacity,
                              ringVal, glowVal),
                          const SizedBox(height: 24),

                          // Individual medication bottles
                          ...meds.asMap().entries.map((entry) {
                            final i = entry.key;
                            final m = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: i < meds.length - 1 ? 14 : 0),
                              child: _buildMedBottleRow(
                                  m, glowVal, bobVal, ringVal),
                            );
                          }),

                          if (lowCount > 0) ...[
                            const SizedBox(height: 16),
                            _buildLowRefillAlert(lowCount, glowVal),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── HEADER ───
  Widget _buildHeader(double glowVal, double overallPct, double ringVal) {
    return Row(
      children: [
        // Neon icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFF135BEC), const Color(0xFF7C3AED),
                    glowVal)!,
                Color.lerp(const Color(0xFF7C3AED), const Color(0xFF06B6D4),
                    glowVal)!,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED)
                    .withValues(alpha: 0.3 + glowVal * 0.2),
                blurRadius: 12 + glowVal * 6,
                spreadRadius: -1,
              ),
            ],
          ),
          child: const Icon(Icons.local_pharmacy_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REFILL TRACKER',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color.lerp(
                    const Color(0xFF93C5FD),
                    const Color(0xFFC4B5FD),
                    glowVal,
                  ),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Medication Supply',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Overall percentage badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _pctBadgeColor(overallPct).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _pctBadgeColor(overallPct).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '${(overallPct * 100).round()}%',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _pctBadgeColor(overallPct),
            ),
          ),
        ),
      ],
    );
  }

  Color _pctBadgeColor(double pct) {
    if (pct > 0.6) return const Color(0xFF34D399);
    if (pct > 0.3) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  // ─── REFILL ALL BUTTON ───
  Widget _buildRefillAllButton(double glowVal) {
    return Row(
      children: [
        // Refill All
        Expanded(
          child: GestureDetector(
            onTap: _refillAll,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.lerp(const Color(0xFF06B6D4), const Color(0xFF135BEC), glowVal)!
                        .withValues(alpha: 0.18),
                    Color.lerp(const Color(0xFF7C3AED), const Color(0xFF06B6D4), glowVal)!
                        .withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xFF06B6D4),
                    const Color(0xFF7C3AED),
                    glowVal,
                  )!.withValues(alpha: 0.3 + glowVal * 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4)
                        .withValues(alpha: 0.08 + glowVal * 0.06),
                    blurRadius: 10 + glowVal * 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Color.lerp(
                      const Color(0xFF06B6D4),
                      const Color(0xFFC4B5FD),
                      glowVal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Refill All',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Undo button (visible only after Refill All)
        if (_undoSnapshot != null) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _undoRefillAll,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.12 + glowVal * 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.3 + glowVal * 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.undo_rounded,
                    size: 15,
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.8 + glowVal * 0.2),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Undo',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.85 + glowVal * 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── OVERALL RING ───
  Widget _buildOverallRing(
      double pct, int pills, int capacity, double ringVal, double glowVal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Animated ring
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _NeonRingPainter(
                progress: pct,
                glowIntensity: glowVal,
                pulseValue: ringVal,
                strokeWidth: 6,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pills',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'pills',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Stats column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _miniStat(
                    'Total Capacity', '$capacity pills', const Color(0xFF93C5FD)),
                const SizedBox(height: 10),
                _miniStat(
                    'Remaining', '$pills pills', const Color(0xFF34D399)),
                const SizedBox(height: 10),
                _miniStat('Consumed', '${capacity - pills} pills',
                    const Color(0xFFFBBF24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.45))),
            Text(value,
                style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9))),
          ],
        ),
      ],
    );
  }

  // ─── INDIVIDUAL MEDICATION BOTTLE ROW ───
  Widget _buildMedBottleRow(
      Medication med, double glowVal, double bobVal, double ringVal) {
    final pct = med.refillPercent;
    final isLow = med.isLowRefill;
    final isSparking = _lastRefillMedId == med.id;

    // Neon accent color per medication
    final neonColor = _neonForMed(med);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLow
                  ? const Color(0xFFF87171).withValues(alpha: 0.25 + glowVal * 0.15)
                  : neonColor.withValues(alpha: 0.12 + glowVal * 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Pill bottle visual
              _buildPillBottle(med, pct, bobVal, neonColor, glowVal),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      med.dosage,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Mini progress bar
                    _buildNeonProgressBar(pct, neonColor, glowVal, ringVal),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${med.refillCount}/${med.refillTotal}',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: neonColor.withValues(alpha: 0.8 + glowVal * 0.2),
                          ),
                        ),
                        const Spacer(),
                        if (isLow)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 12,
                                  color: const Color(0xFFF87171)
                                      .withValues(alpha: 0.7 + glowVal * 0.3)),
                              const SizedBox(width: 3),
                              Text(
                                'Low',
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF87171),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Refill button
              _buildRefillButton(med, neonColor, glowVal),
            ],
          ),
        ),

        // Spark overlay
        if (isSparking && _sparkController != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _sparkController!,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SparkPainter(
                    progress: _sparkController!.value,
                    color: neonColor,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ─── PILL BOTTLE VISUAL ───
  Widget _buildPillBottle(
      Medication med, double fillPct, double bobVal, Color neonColor, double glowVal) {
    final yOff = math.sin(bobVal * math.pi) * 2;
    return Transform.translate(
      offset: Offset(0, yOff),
      child: SizedBox(
        width: 44,
        height: 56,
        child: CustomPaint(
          painter: _PillBottlePainter(
            fillPercent: fillPct,
            neonColor: neonColor,
            glowIntensity: glowVal,
            isLow: med.isLowRefill,
          ),
        ),
      ),
    );
  }

  // ─── NEON PROGRESS BAR ───
  Widget _buildNeonProgressBar(
      double pct, Color neonColor, double glowVal, double ringVal) {
    final barWidth = pct.clamp(0.0, 1.0);
    // subtle pulse on the bar width
    final pulseWidth = barWidth + math.sin(ringVal * math.pi) * 0.01;

    return SizedBox(
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Background track
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Filled portion
            FractionallySizedBox(
              widthFactor: pulseWidth.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      neonColor,
                      neonColor.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: neonColor.withValues(alpha: 0.4 + glowVal * 0.2),
                      blurRadius: 6 + glowVal * 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── REFILL BUTTON ───
  Widget _buildRefillButton(Medication med, Color neonColor, double glowVal) {
    return GestureDetector(
      onTap: () => _logRefill(med),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              neonColor.withValues(alpha: 0.25),
              neonColor.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: neonColor.withValues(alpha: 0.3 + glowVal * 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: neonColor.withValues(alpha: 0.15 + glowVal * 0.1),
              blurRadius: 8 + glowVal * 4,
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: neonColor,
          size: 20,
        ),
      ),
    );
  }

  // ─── LOW REFILL ALERT BANNER ───
  Widget _buildLowRefillAlert(int count, double glowVal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF87171).withValues(alpha: 0.08 + glowVal * 0.04),
            const Color(0xFFFBBF24).withValues(alpha: 0.05 + glowVal * 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF87171).withValues(alpha: 0.2 + glowVal * 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notification_important_rounded,
            color: const Color(0xFFF87171).withValues(alpha: 0.7 + glowVal * 0.3),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count medication${count > 1 ? 's' : ''} running low — tap + to refill',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFCA5A5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── AMBIENT DOTS ───
  List<Widget> _buildAmbientDots(double glowVal) {
    return [
      Positioned(
        top: 12,
        right: 30,
        child: _dot(3, const Color(0xFF06B6D4), 0.15 + glowVal * 0.2),
      ),
      Positioned(
        top: 60,
        right: 14,
        child: _dot(2, const Color(0xFF7C3AED), 0.1 + glowVal * 0.15),
      ),
      Positioned(
        bottom: 20,
        left: 16,
        child: _dot(2.5, const Color(0xFF135BEC), 0.12 + glowVal * 0.18),
      ),
      Positioned(
        top: 100,
        left: 40,
        child: _dot(1.8, const Color(0xFF34D399), 0.1 + glowVal * 0.12),
      ),
      Positioned(
        bottom: 60,
        right: 50,
        child: _dot(2.2, const Color(0xFFFBBF24), 0.08 + glowVal * 0.1),
      ),
    ];
  }

  Widget _dot(double radius, Color color, double opacity) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: opacity * 0.6), blurRadius: 8),
        ],
      ),
    );
  }

  Color _neonForMed(Medication med) {
    // Map the medication color to a neon version
    final hsl = HSLColor.fromColor(med.color);
    return hsl
        .withSaturation(math.min(hsl.saturation + 0.3, 1.0))
        .withLightness(0.62)
        .toColor();
  }
}

// ═════════════════════════════════════════════════════════════════════
//  CUSTOM PAINTERS
// ═════════════════════════════════════════════════════════════════════

/// Neon progress ring with gradient + glow
class _NeonRingPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;
  final double pulseValue;
  final double strokeWidth;

  _NeonRingPainter({
    required this.progress,
    required this.glowIntensity,
    required this.pulseValue,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth * 2) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sw = strokeWidth + pulseValue * 1.5;
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: const [
        Color(0xFF06B6D4),
        Color(0xFF135BEC),
        Color(0xFF7C3AED),
        Color(0xFF34D399),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);

    // Glow halo at the leading edge
    final angle = -math.pi / 2 + 2 * math.pi * progress;
    final tipX = center.dx + radius * math.cos(angle);
    final tipY = center.dy + radius * math.sin(angle);
    final glowPaint = Paint()
      ..color =
          const Color(0xFF7C3AED).withValues(alpha: 0.25 + glowIntensity * 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + glowIntensity * 6);
    canvas.drawCircle(Offset(tipX, tipY), 4 + glowIntensity * 2, glowPaint);

    // White dot at the tip
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(tipX, tipY), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Animated pill bottle
class _PillBottlePainter extends CustomPainter {
  final double fillPercent;
  final Color neonColor;
  final double glowIntensity;
  final bool isLow;

  _PillBottlePainter({
    required this.fillPercent,
    required this.neonColor,
    required this.glowIntensity,
    required this.isLow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bottle cap
    final capRect =
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, 0, w * 0.5, h * 0.16), const Radius.circular(3));
    final capPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.6 + glowIntensity * 0.2);
    canvas.drawRRect(capRect, capPaint);

    // Bottle body outline
    final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.18, w * 0.8, h * 0.78),
        const Radius.circular(8));
    final bodyOutlinePaint = Paint()
      ..color = neonColor.withValues(alpha: 0.3 + glowIntensity * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(bodyRect, bodyOutlinePaint);

    // Bottle body interior (glass-like)
    final bodyFillPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.06);
    canvas.drawRRect(bodyRect, bodyFillPaint);

    // Liquid fill
    final bodyInner = Rect.fromLTWH(w * 0.1, h * 0.18, w * 0.8, h * 0.78);
    final fillHeight = bodyInner.height * fillPercent;
    final fillTop = bodyInner.bottom - fillHeight;

    canvas.save();
    canvas.clipRRect(bodyRect);

    final fillRect = Rect.fromLTRB(
        bodyInner.left, fillTop, bodyInner.right, bodyInner.bottom);
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        neonColor.withValues(alpha: 0.35 + glowIntensity * 0.15),
        neonColor.withValues(alpha: 0.55 + glowIntensity * 0.2),
      ],
    );
    final fillPaint = Paint()..shader = fillGradient.createShader(fillRect);
    canvas.drawRect(fillRect, fillPaint);

    // Liquid surface shimmer line
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15 + glowIntensity * 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(bodyInner.left + 4, fillTop),
      Offset(bodyInner.right - 4, fillTop),
      shimmerPaint,
    );

    canvas.restore();

    // Neon glow around bottle when low
    if (isLow) {
      final glowPaint = Paint()
        ..color = const Color(0xFFF87171).withValues(alpha: 0.12 + glowIntensity * 0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + glowIntensity * 6);
      canvas.drawRRect(bodyRect, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Sparkle / confetti burst on refill
class _SparkPainter extends CustomPainter {
  final double progress;
  final Color color;
  static final _rng = math.Random(42);

  _SparkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const particleCount = 14;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi + _rng.nextDouble() * 0.5;
      final maxRadius = 30.0 + _rng.nextDouble() * 40;
      final radius = maxRadius * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final particleSize = (3.0 + _rng.nextDouble() * 3) * (1 - progress * 0.6);

      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);

      final sparkColor = i.isEven
          ? color.withValues(alpha: opacity * 0.8)
          : Colors.white.withValues(alpha: opacity * 0.7);

      final paint = Paint()
        ..color = sparkColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
