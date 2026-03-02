import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../models/medication.dart';
import '../services/medication_store.dart';

// ═══════════════════════════════════════════════════════════════════════
//  SCHEDULE SCREEN — Futuristic Health Management Interface
//  Monthly calendar · Medication timeline · Animated refill counter
// ═══════════════════════════════════════════════════════════════════════

class ScheduleScreen extends StatefulWidget {
  final bool scrollToRefill;
  const ScheduleScreen({super.key, this.scrollToRefill = false});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  // ─── State ───
  late DateTime _currentMonth;
  late int _selectedDay;
  late AnimationController _dotPulseController;
  late AnimationController _glowController;
  late AnimationController _slideController;
  AnimationController? _sparkController;
  String? _sparkMedId;

  // For calendar month navigation transition
  bool _isMonthTransitioning = false;
  final ScrollController _scrollController = ScrollController();

  // Track low stock alerts sent to Caregiver this session
  final Set<String> _lowStockAlertSentList = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime(2026, 2, 28); // Current date per system
    _currentMonth = DateTime(now.year, now.month);
    _selectedDay = now.day;

    _dotPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideController.value = 1.0; // start fully visible

    if (widget.scrollToRefill) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Wait a bit for animations to settle
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
            );
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _dotPulseController.dispose();
    _glowController.dispose();
    _slideController.dispose();
    _sparkController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Calendar helpers ───
  int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  int _firstWeekday(DateTime month) =>
      DateTime(month.year, month.month, 1).weekday; // 1=Mon..7=Sun

  String get _monthYearLabel {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_currentMonth.month]} ${_currentMonth.year}';
  }

  String get _selectedDateLabel {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Feb $_selectedDay';
  }

  void _previousMonth() {
    setState(() {
      _isMonthTransitioning = true;
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = 1;
    });
    _slideController.forward(from: 0).then((_) {
      if (mounted) setState(() => _isMonthTransitioning = false);
    });
  }

  void _nextMonth() {
    setState(() {
      _isMonthTransitioning = true;
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay = 1;
    });
    _slideController.forward(from: 0).then((_) {
      if (mounted) setState(() => _isMonthTransitioning = false);
    });
  }

  void _selectDay(int day) {
    setState(() => _selectedDay = day);
    _slideController.forward(from: 0);
  }

  // Dates that have "events" (we mark all days that have medications)
  Set<int> _eventDays() {
    // All days have medication schedules in a demo; highlight a few
    return {3, 5, 7, 10, 14, 17, 18, 19, 21, 25, 27, 28};
  }

  bool get _isCurrentMonth =>
      _currentMonth.year == 2026 && _currentMonth.month == 2;

  int _parseHour(String time) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      if (time.contains('PM') && hour != 12) hour += 12;
      if (time.contains('AM') && hour == 12) hour = 0;
      return hour;
    } catch (_) {
      return 0;
    }
  }

  void _triggerSpark(String medId) {
    _sparkController?.dispose();
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    setState(() => _sparkMedId = medId);
    _sparkController!.forward().then((_) {
      if (mounted) setState(() => _sparkMedId = null);
    });
  }

  Future<void> _requestRefill(Medication med) async {
    // 1. Notify user that request is sent
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Refill request for ${med.name} sent to caregiver.'),
        backgroundColor: const Color(0xFF135BEC),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // 2. Simulate caregiver receiving and approving request (e.g. 3 seconds)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 3. Show Approval Dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Text('Request Approved', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF1E293B))),
          ],
        ),
        content: Text(
          'Your caregiver has approved the refill for ${med.name}. The stock will now be updated automatically.',
          style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final store = MedicationStore();
              final newCount = math.min(med.refillCount + 15, med.refillTotal); // Giving 15 pills per refill request
              store.updateRefillCount(med.id, newCount);
              _triggerSpark(med.id);
            },
            child: Text('OKAY', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: const Color(0xFF135BEC))),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MedicationStore(),
      builder: (context, _) {
        final store = MedicationStore();
        final meds = store.medications;

        // Sort medications by time
        final sorted = List<Medication>.from(meds)
          ..sort((a, b) => _parseHour(a.time).compareTo(_parseHour(b.time)));

        return AnimatedBuilder(
          animation: Listenable.merge([_dotPulseController, _glowController]),
          builder: (context, _) {
            final pulse = _dotPulseController.value;
            final glow = _glowController.value;

            return SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // ── Title ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task Calendar',
                            style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PLAN YOUR HEALTH SCHEDULE',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Monthly Calendar Card ──
                    _buildCalendarCard(pulse, glow),
                    const SizedBox(height: 28),

                    // ── Schedule for selected day ──
                    _buildScheduleSection(sorted, pulse),
                    const SizedBox(height: 32),

                    // ── Refill Counter ──
                    _buildRefillSection(sorted, glow, pulse),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  CALENDAR CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCalendarCard(double pulse, double glow) {
    final daysInMonth = _daysInMonth(_currentMonth);
    final firstWeekday = _firstWeekday(_currentMonth); // 1=Mon
    final eventDays = _eventDays();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF135BEC).withValues(alpha: 0.04 + glow * 0.02),
            blurRadius: 20 + glow * 8,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _previousMonth,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Color(0xFF64748B), size: 22),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _monthYearLabel,
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _nextMonth,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF64748B), size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Weekday headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Calendar grid
          _buildCalendarGrid(daysInMonth, firstWeekday, eventDays, pulse),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
      int daysInMonth, int firstWeekday, Set<int> eventDays, double pulse) {
    // Convert firstWeekday (1=Mon) to Sunday-start index (Sun=0)
    int startOffset = firstWeekday % 7; // Sun=0, Mon=1, ...

    final cells = <Widget>[];

    // Empty cells for offset
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final isSelected = day == _selectedDay;
      final isToday = _isCurrentMonth && day == 28;
      final hasEvent = eventDays.contains(day);

      cells.add(
        GestureDetector(
          onTap: () => _selectDay(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Day number
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF135BEC)
                        : isToday
                            ? const Color(0xFFEFF6FF)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF135BEC)
                                  .withValues(alpha: 0.3 + pulse * 0.15),
                              blurRadius: 8 + pulse * 4,
                              spreadRadius: -1,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight:
                            isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? const Color(0xFF135BEC)
                                : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Event dot
                if (hasEvent)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 5 + (isSelected ? pulse * 1.5 : 0),
                    height: 5 + (isSelected ? pulse * 1.5 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFF135BEC)
                          : _dotColor(day),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF135BEC)
                                    .withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                  )
                else
                  const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      );
    }

    // Build rows of 7
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final rowCells = <Widget>[];
      for (int j = i; j < i + 7; j++) {
        rowCells.add(
          Expanded(child: j < cells.length ? cells[j] : const SizedBox()),
        );
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SizedBox(height: 48, child: Row(children: rowCells)),
        ),
      );
    }

    return Column(children: rows);
  }

  Color _dotColor(int day) {
    // Varied dot colors for visual interest
    if (day % 4 == 0) return const Color(0xFF7C3AED);
    if (day % 3 == 0) return const Color(0xFF16A34A);
    if (day % 2 == 0) return const Color(0xFF0891B2);
    return const Color(0xFF135BEC);
  }

  // ═══════════════════════════════════════════════════════════════
  //  SCHEDULE SECTION (Medication Timeline)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildScheduleSection(List<Medication> meds, double pulse) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCHEDULE FOR ${_selectedDateLabel.toUpperCase()}',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Daily View',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF135BEC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Medication timeline cards
          ...meds.asMap().entries.map((entry) {
            final i = entry.key;
            final med = entry.value;
            final isLast = i == meds.length - 1;

            return TweenAnimationBuilder<double>(
              key: ValueKey('sched_${med.id}_$_selectedDay'),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 350 + i * 100),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return Transform.translate(
                  offset: Offset(30 * (1 - val), 0),
                  child: Opacity(opacity: val, child: child),
                );
              },
              child: _buildMedTimelineCard(med, pulse, isLast),
            );
          }),

          if (meds.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.event_available_rounded,
                      size: 48, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 12),
                  Text('No medications for this day',
                      style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedTimelineCard(Medication med, double pulse, bool isLast) {
    // Progress towards dose time
    final currentHour = TimeOfDay.now().hour + (TimeOfDay.now().minute / 60);
    final medHour = _parseHour(med.time).toDouble();
    final progress = med.takenToday
        ? 1.0
        : (currentHour >= medHour ? 1.0 : (currentHour / medHour).clamp(0.0, 1.0));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical Timeline Connector
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 24),
                  decoration: BoxDecoration(
                    color: med.takenToday ? const Color(0xFF16A34A) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: med.takenToday ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: med.takenToday ? const Color(0xFF16A34A).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          // Info card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: med.takenToday
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFF1F5F9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
          // Pill icon with colored background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: med.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(med.icon, color: med.color, size: 24),
          ),
          const SizedBox(width: 14),
          // Info + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    decoration:
                        med.takenToday ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${med.dosage} • ${med.time}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                // Dynamic progress bar
                SizedBox(
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(
                          color: const Color(0xFFF1F5F9),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: med.takenToday
                                    ? [
                                        const Color(0xFF34D399),
                                        const Color(0xFF16A34A),
                                      ]
                                    : [
                                        med.color.withValues(alpha: 0.7),
                                        med.color,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Status indicator
          if (med.takenToday)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF16A34A), size: 18),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: med.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.schedule_rounded,
                  color: med.color.withValues(alpha: 0.6), size: 16),
            ),
        ],
      ),
    ),
  ),
],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  REFILL COUNTER SECTION
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRefillSection(
      List<Medication> meds, double glow, double pulse) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_rounded,
                    color: Color(0xFF7C3AED), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Refill Counter',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Track remaining pills & refill needs',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Refill cards for each medication
          ...meds.asMap().entries.map((entry) {
            final i = entry.key;
            final med = entry.value;

            return TweenAnimationBuilder<double>(
              key: ValueKey('refill_${med.id}'),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + i * 120),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - val)),
                  child: Opacity(opacity: val, child: child),
                );
              },
              child: _buildRefillCard(med, glow, pulse),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRefillCard(Medication med, double glow, double pulse) {
    final pct = med.refillPercent;
    final daysLeft = (med.refillCount * 1.0).round(); // 1 pill/day estimate
    final isSparking = _sparkMedId == med.id;

    // Status color
    Color statusColor;
    String statusLabel;
    if (pct > 0.5) {
      statusColor = const Color(0xFF16A34A);
      statusLabel = '$daysLeft DAYS LEFT';
    } else if (pct > 0.15) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = '$daysLeft DAYS LEFT';
    } else {
      statusColor = const Color(0xFFDC2626);
      statusLabel = '⚠ $daysLeft DAYS LEFT';
    }

    // Automated low stock alert to caregiver if <= 5
    if (med.refillCount <= 5 && !_lowStockAlertSentList.contains(med.id)) {
      _lowStockAlertSentList.add(med.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Caregiver Alerted: ${med.name} stock is critically low (${med.refillCount} pills left).')),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626), // red warning
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: pct <= 0.15
                  ? const Color(0xFFFECACA)
                  : const Color(0xFFF1F5F9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top row: icon + info + radial chart
              Row(
                children: [
                  // Med icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: med.bgColor,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(med.icon, color: med.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  // Name + dosage
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          med.dosage,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Pills remaining text
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${med.refillCount} PILLS REMAINING',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Stock progress bar with labels
              _buildStockBar(med, pct, glow),
              const SizedBox(height: 16),

              // Action buttons row
              Row(
                children: [
                  // Update Stock button (Manual increment)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Allow a simple manual +1 increment locally without caregiver for minor tracking
                        final store = MedicationStore();
                        store.updateRefillCount(med.id, math.min(med.refillCount + 1, med.refillTotal));
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded,
                                size: 18, color: Color(0xFF475569)),
                            const SizedBox(width: 6),
                            Text(
                              'UPDATE STOCK',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF475569),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _requestRefill(med),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF135BEC),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF135BEC)
                                .withValues(alpha: 0.3 + glow * 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'REQUEST REFILL',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Spark overlay
        if (isSparking && _sparkController != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _sparkController!,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SparkBurstPainter(
                      progress: _sparkController!.value,
                      color: med.color,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStockBar(Medication med, double pct, double glow) {
    Color barColor;
    if (pct > 0.5) {
      barColor = const Color(0xFF16A34A);
    } else if (pct > 0.15) {
      barColor = const Color(0xFFF59E0B);
    } else {
      barColor = const Color(0xFFDC2626);
    }

    return Column(
      children: [
        // Labels row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EMPTY',
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFCBD5E1),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${(pct * 100).round()}% STOCK',
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: barColor.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'FULL',
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFCBD5E1),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Bar
        SizedBox(
          height: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(color: const Color(0xFFF1F5F9)),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, animPct, _) {
                    return FractionallySizedBox(
                      widthFactor: animPct.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              barColor.withValues(alpha: 0.7),
                              barColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: barColor
                                  .withValues(alpha: 0.3 + glow * 0.15),
                              blurRadius: 6 + glow * 3,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SPARKLE BURST PAINTER (on refill)
// ═══════════════════════════════════════════════════════════════
class _SparkBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  static final _rng = math.Random(42);

  _SparkBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const count = 16;

    for (int i = 0; i < count; i++) {
      final angle =
          (i / count) * 2 * math.pi + _rng.nextDouble() * 0.6;
      final maxR = 30.0 + _rng.nextDouble() * 50;
      final r = maxR * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final pSize = (3.0 + _rng.nextDouble() * 3) * (1 - progress * 0.5);

      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);

      final c = i.isEven
          ? color.withValues(alpha: opacity * 0.8)
          : Colors.white.withValues(alpha: opacity * 0.7);

      canvas.drawCircle(
        Offset(x, y),
        pSize,
        Paint()
          ..color = c
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
