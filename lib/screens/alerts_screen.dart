import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/patient_alerts_store.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  final _store = PatientAlertsStore();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Missed', 'Delayed', 'Scheduled'];

  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    // Restart stagger animation when filter changes
    _staggerController.reset();
    _staggerController.forward();
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
            Text('Recent Alerts', style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            Text('Notifications for your medication events', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter, style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700, 
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    )),
                    selected: isSelected,
                    onSelected: (_) => _onFilterChanged(filter),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF135BEC),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Alerts Feed
          Expanded(
            child: ListenableBuilder(
              listenable: _store,
              builder: (context, _) {
                // Filter the alerts
                final allAlerts = _store.activeAlerts;
                final alerts = allAlerts.where((a) {
                  if (_selectedFilter == 'All') return true;
                  return a.status.name.toLowerCase() == _selectedFilter.toLowerCase();
                }).toList();
                
                if (alerts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: const Color(0xFF16A34A).withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('All Caught Up!', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                        const SizedBox(height: 8),
                        Text('No active $_selectedFilter alerts.', style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF64748B))),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    // Calculate staggered animation
                    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _staggerController,
                        curve: Interval(
                          (index / alerts.length).clamp(0.0, 1.0) * 0.5,
                          ((index / alerts.length) + 0.5).clamp(0.0, 1.0),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    );

                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - animation.value)),
                          child: Opacity(
                            opacity: animation.value,
                            child: child,
                          ),
                        );
                      },
                      child: _AlertCard(
                        key: ValueKey(alerts[index].id),
                        alert: alerts[index], 
                        store: _store,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatefulWidget {
  final PatientAlert alert;
  final PatientAlertsStore store;

  const _AlertCard({super.key, required this.alert, required this.store});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.alert.status == AlertStatus.missed) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      )..repeat(reverse: true);
      
      _pulseAnimation = Tween<double>(begin: 1.0, end: 3.5).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOutSine),
      );
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = widget.alert.baseColor;
    Color lightBgColor = primaryColor.withValues(alpha: 0.1);
    String statusLabel = widget.alert.status.name.toUpperCase();
    String dayLabel = widget.alert.isToday ? 'Today' : 'Yesterday';

    final cardContent = Container(
      padding: const EdgeInsets.all(20),
      // Set background color so dismissible background is hidden under it
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lightBgColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lightBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.medication, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: primaryColor, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.alert.title,
                      style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF451A03)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: const Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          widget.alert.message,
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Text(
                  dayLabel,
                  style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.store.resolveAlert(widget.alert.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Resolve Now', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.store.snoozeAlert(widget.alert.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Snooze', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Apply pulsing border shadow if it's a missed alert
    Widget animatedCard = cardContent;
    if (_pulseController != null) {
      animatedCard = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: _pulseAnimation.value,
                ),
              ],
            ),
            child: child,
          );
        },
        child: cardContent,
      );
    } else {
      animatedCard = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: cardContent,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(widget.alert.id),
        direction: DismissDirection.horizontal,
        onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {
            widget.store.resolveAlert(widget.alert.id);
          } else {
            widget.store.snoozeAlert(widget.alert.id);
          }
        },
        background: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 30),
          child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 36),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFB0B7C3),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 30),
          child: const Icon(Icons.snooze, color: Colors.white, size: 36),
        ),
        child: animatedCard,
      ),
    );
  }
}
