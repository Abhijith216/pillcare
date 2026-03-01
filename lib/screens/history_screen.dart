import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/history_store.dart';
import 'components/history_components.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // We'll simulate fetching from our mock "Firebase" service
  final HistoryStore _store = HistoryStore();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('History', style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            Text('PATIENT MODE', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
              onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
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
                    ..._store.allEvents.map((evt) => HistoryEventCard(event: evt)),
                  ],
                ),
              ),
            ),
    );
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
          'Oct 18 - Oct 24, 2023', // Hardcoded for mockup consistency
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
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
