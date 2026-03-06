import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/history_store.dart';
import 'components/history_components.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryStore _store = HistoryStore();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreUpdated);
    _store.fetchEvents();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreUpdated);
    super.dispose();
  }

  void _onStoreUpdated() {
    if (mounted) setState(() => _isLoading = _store.isLoading);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('History', style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            Text('PATIENT MODE', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF135BEC), size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF135BEC)))
          : RefreshIndicator(
              onRefresh: () => _store.fetchEvents(),
              color: const Color(0xFF135BEC),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Selector
                    _buildDateSelector(),
                    const SizedBox(height: 24),

                    // Weekly Consistency Graph
                    Hero(
                      tag: 'history_chart',
                      child: WeeklyConsistencyChart(
                        data: _store.weeklyChartData,
                        adherenceDifference: _store.adherenceDifference,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Adherence Timeline Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ADHERENCE TIMELINE',
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.2),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View All',
                            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF135BEC)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Event Feed
                    if (_store.allEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No history yet.\nMedication events will appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._store.allEvents.map((evt) => HistoryEventCard(event: evt)),
                  ],
                ),
              ),
            ),
    );
  }

  String _currentWeekLabel() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: 6));
    final fmt = DateFormat('MMM d');
    return '${fmt.format(start)} – ${fmt.format(now)}, ${now.year}';
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF94A3B8)),
          onPressed: () {},
          splashRadius: 24,
        ),
        const SizedBox(width: 16),
        Text(
          _currentWeekLabel(),
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          onPressed: () {},
          splashRadius: 24,
        ),
      ],
    );
  }
}
