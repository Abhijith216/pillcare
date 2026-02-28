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

class _AnalyticsTabState extends State<AnalyticsTab> {
  final _store = CaregiverStore();
  String _selectedPatientId = 'p1';

  @override
  Widget build(BuildContext context) {
    final patient = _store.getPatient(_selectedPatientId);
    final weeklyData = _store.getWeeklyAdherence(_selectedPatientId);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Analytics',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1F36),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: _mockExport,
                    icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 22),
                    tooltip: 'Export Report',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Patient selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPatientId,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF6B7280)),
                  style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1F36)),
                  items: _store.patients
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPatientId = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Adherence summary card
            if (patient != null) _adherenceSummaryCard(patient),
            const SizedBox(height: 20),

            // Bar chart title
            Text(
              'Weekly Adherence',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 16),

            // Bar chart
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  barGroups: _barGroups(weeklyData),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 25,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}%',
                          style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF9CA3AF)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[v.toInt()],
                              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: const Color(0xFFF1F3F8),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()}%',
                          GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Line chart title
            Text(
              'Adherence Trend',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 16),

            // Line chart
            Container(
              height: 200,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: const Color(0xFF135BEC),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: const Color(0xFF135BEC),
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF135BEC).withValues(alpha: 0.15),
                            const Color(0xFF135BEC).withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 25,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}%',
                          style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF9CA3AF)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[v.toInt()],
                              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: const Color(0xFFF1F3F8),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map((s) => LineTooltipItem(
                                '${s.y.toInt()}%',
                                GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adherenceSummaryCard(PatientInfo patient) {
    final adherenceColor = patient.adherencePercent >= 80
        ? const Color(0xFF16A34A)
        : patient.adherencePercent >= 60
            ? const Color(0xFFEA580C)
            : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            adherenceColor.withValues(alpha: 0.08),
            adherenceColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: adherenceColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: patient.adherencePercent / 100,
                    strokeWidth: 6,
                    backgroundColor: const Color(0xFFF1F3F8),
                    valueColor: AlwaysStoppedAnimation(adherenceColor),
                  ),
                ),
                Text(
                  '${patient.adherencePercent.toInt()}%',
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: adherenceColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1A1F36)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${patient.medications.length} medications • ${patient.missedDoses} missed this week',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Text(
                  patient.adherencePercent >= 80
                      ? '🎉 Great adherence!'
                      : patient.adherencePercent >= 60
                          ? '⚠️ Needs attention'
                          : '🚨 Critical — follow up required',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: adherenceColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _barGroups(List<double> data) {
    return data.asMap().entries.map((e) {
      final color = e.value >= 80
          ? const Color(0xFF16A34A)
          : e.value >= 60
              ? const Color(0xFFEA580C)
              : const Color(0xFFDC2626);
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.6)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    }).toList();
  }

  void _mockExport() {
    final patient = _store.getPatient(_selectedPatientId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📄 Report for ${patient?.name ?? 'patient'} exported as CSV',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF135BEC),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
