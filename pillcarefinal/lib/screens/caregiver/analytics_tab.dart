import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/caregiver_store.dart';
import '../../models/patient_info.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});
  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> with TickerProviderStateMixin {
  final _store = CaregiverStore();
  String? _selectedId;

  late AnimationController _bgCtrl;
  late AnimationController _chartCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _chartAnim;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onUpdate);
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _chartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _chartAnim = CurvedAnimation(parent: _chartCtrl, curve: Curves.easeOutQuart);
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    if (_store.patients.isNotEmpty) { _selectedId = _store.patients.first.id; _chartCtrl.forward(); }
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _chartCtrl.dispose(); _fadeCtrl.dispose();
    _store.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (_selectedId == null && _store.patients.isNotEmpty) _selectedId = _store.patients.first.id;
    setState(() {});
  }

  void _selectPatient(String id) { setState(() => _selectedId = id); _chartCtrl.forward(from: 0); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patient = _selectedId != null ? _store.getPatient(_selectedId!) : null;
    final weeklyData = _selectedId != null ? _store.getWeeklyAdherence(_selectedId!) : List.filled(7, 0.0);
    return Stack(children: [
      AnimatedBuilder(animation: _bgCtrl, builder: (_, __) => CustomPaint(painter: _BlobPainter(_bgCtrl.value, isDark), size: Size.infinite)),
      SafeArea(child: FadeTransition(opacity: _fadeCtrl, child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Analytics', style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1F36))),
              Text('Adherence insights', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF94A3B8))),
            ])),
            GestureDetector(onTap: _export, child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))]),
              child: const Icon(Icons.file_download_outlined, color: Colors.white, size: 22))),
          ]),
          const SizedBox(height: 24),
          if (_store.patients.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 60), child: Center(child: Column(children: [
              Icon(Icons.analytics_outlined, size: 56, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              const SizedBox(height: 16),
              Text('No patients linked', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF))),
              Text('Analytics appear once patients are connected.', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF94A3B8)), textAlign: TextAlign.center),
            ])))
          else ...[
            SizedBox(height: 44, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _store.patients.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = _store.patients[i];
                final sel = p.id == _selectedId;
                return GestureDetector(
                  onTap: () => _selectPatient(p.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: sel ? const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]) : null,
                      color: sel ? null : (isDark ? const Color(0xFF1E2D3D) : Colors.white),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: sel ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      boxShadow: sel ? [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3))] : [],
                    ),
                    child: Center(child: Text(p.name.split(' ').first, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: sel ? Colors.white : const Color(0xFF6B7280)))),
                  ),
                );
              },
            )),
            if (patient != null) ...[
              const SizedBox(height: 24),
              _adherenceCard(patient, isDark),
              const SizedBox(height: 16),
              _statsRow(patient, isDark),
              const SizedBox(height: 24),
              Text('Weekly Adherence', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1F36))),
              const SizedBox(height: 12),
              _barCard(weeklyData, isDark),
              const SizedBox(height: 24),
              Text('7-Day Trend', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1F36))),
              const SizedBox(height: 12),
              _lineCard(weeklyData, isDark),
            ],
          ],
        ]),
      ))),
    ]);
  }

  Widget _adherenceCard(PatientInfo p, bool isDark) {
    final c = p.adherencePercent >= 80 ? const Color(0xFF16A34A) : p.adherencePercent >= 60 ? const Color(0xFFEA580C) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isDark ? [const Color(0xFF1E2D3D), const Color(0xFF162032)] : [Colors.white, const Color(0xFFF8FAFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withValues(alpha: 0.22), width: 1.5),
        boxShadow: [BoxShadow(color: c.withValues(alpha: isDark ? 0.08 : 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        AnimatedBuilder(animation: _chartAnim, builder: (_, __) => SizedBox(width: 72, height: 72, child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 64, height: 64, child: CircularProgressIndicator(value: (p.adherencePercent / 100) * _chartAnim.value, strokeWidth: 7, backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F3F8), valueColor: AlwaysStoppedAnimation(c), strokeCap: StrokeCap.round)),
          Text('${(p.adherencePercent * _chartAnim.value).toInt()}%', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: c)),
        ]))),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1F36))),
          const SizedBox(height: 4),
          Text('${p.medications.length} meds • ${p.missedDoses} missed', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(p.adherencePercent >= 80 ? '🎉 Excellent' : p.adherencePercent >= 60 ? '⚠️ Needs attention' : '🚨 Critical', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: c))),
        ])),
      ]),
    );
  }

  Widget _statsRow(PatientInfo p, bool isDark) => Row(children: [
    _stat('Medications', '${p.medications.length}', Icons.medication_rounded, const Color(0xFF135BEC), isDark),
    const SizedBox(width: 10),
    _stat('Missed', '${p.missedDoses}', Icons.warning_rounded, const Color(0xFFDC2626), isDark),
    const SizedBox(width: 10),
    _stat('Refills', '${p.refillAlerts}', Icons.inventory_2_rounded, const Color(0xFFEA580C), isDark),
  ]);

  Widget _stat(String label, String val, IconData ic, Color c, bool isDark) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1E2D3D) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withValues(alpha: 0.15)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(ic, color: c, size: 20), const SizedBox(height: 8),
      Text(val, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
      Text(label, style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF94A3B8))),
    ]),
  ));

  Widget _barCard(List<double> data, bool isDark) => Container(
    height: 220,
    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1E2D3D) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))]),
    child: AnimatedBuilder(animation: _chartAnim, builder: (_, __) => BarChart(BarChartData(
      maxY: 100,
      barGroups: data.asMap().entries.map((e) {
        final v = e.value * _chartAnim.value;
        final c = v >= 80 ? const Color(0xFF16A34A) : v >= 60 ? const Color(0xFFEA580C) : const Color(0xFFDC2626);
        return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: v, width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)), gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.6)], begin: Alignment.bottomCenter, end: Alignment.topCenter), backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFF1F3F8)))]);
      }).toList(),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 25, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: GoogleFonts.manrope(fontSize: 9, color: const Color(0xFF9CA3AF))))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) { const d = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']; return Padding(padding: const EdgeInsets.only(top: 4), child: Text(d[v.toInt()], style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))); })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25, getDrawingHorizontalLine: (_) => FlLine(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F3F8), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(getTooltipItem: (g, _, r, __) => BarTooltipItem('${r.toY.toInt()}%', GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)))),
    ))),
  );

  Widget _lineCard(List<double> data, bool isDark) => Container(
    height: 200,
    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1E2D3D) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))]),
    child: AnimatedBuilder(animation: _chartAnim, builder: (_, __) => LineChart(LineChartData(
      minY: 0, maxY: 100,
      lineBarsData: [LineChartBarData(
        spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value * _chartAnim.value)).toList(),
        isCurved: true, curveSmoothness: 0.35, color: const Color(0xFF135BEC), barWidth: 3,
        dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2.5, strokeColor: const Color(0xFF135BEC))),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [const Color(0xFF135BEC).withValues(alpha: 0.18), const Color(0xFF135BEC).withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      )],
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 25, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: GoogleFonts.manrope(fontSize: 9, color: const Color(0xFF9CA3AF))))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) { const d = ['M','T','W','T','F','S','S']; return Padding(padding: const EdgeInsets.only(top: 4), child: Text(d[v.toInt()], style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))); })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25, getDrawingHorizontalLine: (_) => FlLine(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F3F8), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipItems: (spots) => spots.map((s) => LineTooltipItem('${s.y.toInt()}%', GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))).toList())),
    ))),
  );

  void _export() {
    final p = _selectedId != null ? _store.getPatient(_selectedId!) : null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Report for ${p?.name ?? "patient"} exported', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFF135BEC), behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

class _BlobPainter extends CustomPainter {
  final double t; final bool isDark;
  _BlobPainter(this.t, this.isDark);
  @override
  void paint(Canvas canvas, Size size) {
    for (final b in [
      _B(Offset(size.width * (0.15 + 0.12 * math.sin(t * math.pi * 2)), size.height * (0.2 + 0.1 * math.cos(t * math.pi * 2))), size.width * 0.38, isDark ? const Color(0xFF135BEC).withValues(alpha: 0.06) : const Color(0xFF135BEC).withValues(alpha: 0.04)),
      _B(Offset(size.width * (0.85 + 0.08 * math.cos(t * math.pi * 2 + 1.0)), size.height * (0.35 + 0.12 * math.sin(t * math.pi * 2 + 1.0))), size.width * 0.32, isDark ? const Color(0xFF7C3AED).withValues(alpha: 0.05) : const Color(0xFF7C3AED).withValues(alpha: 0.04)),
      _B(Offset(size.width * (0.5 + 0.15 * math.sin(t * math.pi * 2 + 2.0)), size.height * (0.75 + 0.08 * math.cos(t * math.pi * 2 + 2.0))), size.width * 0.28, isDark ? const Color(0xFF0891B2).withValues(alpha: 0.04) : const Color(0xFF0891B2).withValues(alpha: 0.03)),
    ]) { canvas.drawCircle(b.c, b.r, Paint()..color = b.color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60)); }
  }
  @override bool shouldRepaint(_BlobPainter o) => o.t != t || o.isDark != isDark;
}

class _B { final Offset c; final double r; final Color color; const _B(this.c, this.r, this.color); }
