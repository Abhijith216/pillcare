import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/history_store.dart';

// ==========================================================
// Weekly Consistency Chart
// ==========================================================
class WeeklyConsistencyChart extends StatelessWidget {
  final List<double> data; // 7 values (0.0 to 1.0)
  final double adherenceDifference; // e.g., 0.125 for +12.5%

  const WeeklyConsistencyChart({
    super.key,
    required this.data,
    required this.adherenceDifference,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = adherenceDifference >= 0;
    final String diffStr = '${isPositive ? '+' : ''}${(adherenceDifference * 100).toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E75),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E75).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEEKLY CONSISTENCY',
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ADHERENCE RATE',
                    style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF8BA4F9), letterSpacing: 1.0),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFF16A34A).withValues(alpha: 0.2) : const Color(0xFFDC2626).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 14, color: isPositive ? const Color(0xFF4ADE80) : const Color(0xFFF87171)),
                    const SizedBox(width: 4),
                    Text(diffStr, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: isPositive ? const Color(0xFF4ADE80) : const Color(0xFFF87171))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Chart
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Color(0xFF8BA4F9), fontWeight: FontWeight.w700, fontSize: 11);
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(days[value.toInt() % 7], style: style),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF8BA4F9),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF2C3E75),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8BA4F9).withValues(alpha: 0.3),
                          const Color(0xFF8BA4F9).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// Expandable Timeline Card
// ==========================================================
class HistoryEventCard extends StatefulWidget {
  final HistoryEvent event;

  const HistoryEventCard({super.key, required this.event});

  @override
  State<HistoryEventCard> createState() => _HistoryEventCardState();
}

class _HistoryEventCardState extends State<HistoryEventCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('MMM dd, yyyy');

    // Status colors
    Color statusBg, statusText, iconBg, iconColor;
    IconData statusIcon;
    String statusLabel;

    switch (ev.status) {
      case MedicationStatus.taken:
        statusLabel = 'TAKEN';
        statusBg = const Color(0xFFF0FDF4); // Light Green
        statusText = const Color(0xFF16A34A); // Green
        iconBg = const Color(0xFFEFF6FF); // Brand Light
        iconColor = const Color(0xFF135BEC); // Brand
        statusIcon = Icons.check_rounded;
        break;
      case MedicationStatus.missed:
        statusLabel = 'MISSED';
        statusBg = const Color(0xFFFEF2F2); // Light Red
        statusText = const Color(0xFFDC2626); // Red
        iconBg = const Color(0xFFFEF2F2); // Light Red
        iconColor = const Color(0xFFDC2626); // Red
        statusIcon = Icons.close_rounded;
        break;
      case MedicationStatus.scheduled:
        statusLabel = 'SCHEDULED';
        statusBg = const Color(0xFFEFF6FF); // Light Blue
        statusText = const Color(0xFF135BEC); // Blue
        iconBg = const Color(0xFFF1F5F9); // Light Gray
        iconColor = const Color(0xFF94A3B8); // Gray
        statusIcon = Icons.schedule_rounded;
        break;
      case MedicationStatus.skipped:
        statusLabel = 'SKIPPED';
        statusBg = const Color(0xFFF8FAFC); // Light Gray
        statusText = const Color(0xFF64748B); // Gray
        iconBg = const Color(0xFFF8FAFC); // Light Gray
        iconColor = const Color(0xFF94A3B8); // Gray
        statusIcon = Icons.skip_next_rounded;
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: _isExpanded
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))]
              : [],
        ),
        child: Column(
          children: [
            // Header (Always visible)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status Icon (Check/Cross/Time inside rounded box with circular badge)
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(statusIcon, color: iconColor, size: 24),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.change_circle_outlined, size: 14, color: const Color(0xFF9CA3AF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              dateFormat.format(ev.scheduledTime).toUpperCase(),
                              style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), letterSpacing: 0.5),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.circle, size: 3, color: Color(0xFFD1D5DB)),
                            ),
                            Text(
                              timeFormat.format(ev.scheduledTime),
                              style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF135BEC)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ev.medicationName,
                          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A1F36)),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge & Time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: statusText, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ev.actualTime != null ? timeFormat.format(ev.actualTime!) : timeFormat.format(ev.scheduledTime),
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A1F36)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Expanded Area
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dosage row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: ev.preset.bgColor, borderRadius: BorderRadius.circular(10)),
                                    child: Icon(ev.preset.icon, size: 16, color: ev.preset.color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Dosage & Instructions', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF))),
                                        Text(ev.dosage, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1F36))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Refill progress
                              Text('Refill Status', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF))),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: ev.refillCount / ev.refillTotal,
                                        minHeight: 6,
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        valueColor: AlwaysStoppedAnimation(const Color(0xFF135BEC)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${ev.refillCount}/${ev.refillTotal}',
                                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A1F36)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
