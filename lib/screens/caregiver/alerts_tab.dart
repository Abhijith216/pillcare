import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/caregiver_store.dart';
import '../../models/patient_info.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  final _store = CaregiverStore();
  AlertType? _filter;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _store.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  List<CaregiverAlert> get _displayedAlerts {
    var list = _store.alerts.toList();
    if (_filter != null) list = list.where((a) => a.type == _filter).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Alerts',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1F36),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _chip('All', null),
                const SizedBox(width: 8),
                _chip('Missed', AlertType.missedDose),
                const SizedBox(width: 8),
                _chip('Refills', AlertType.refillNeeded),
                const SizedBox(width: 8),
                _chip('Errors', AlertType.dispenserError),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Alert list
          Expanded(
            child: _displayedAlerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 56, color: const Color(0xFF16A34A)),
                        const SizedBox(height: 12),
                        Text(
                          'All clear — no alerts!',
                          style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _displayedAlerts.length,
                    itemBuilder: (_, i) => _alertTile(_displayedAlerts[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, AlertType? type) {
    final selected = _filter == type;
    return GestureDetector(
      onTap: () => setState(() => _filter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF135BEC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF135BEC) : const Color(0xFFE2E8F0),
          ),
          boxShadow: selected
              ? [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _alertTile(CaregiverAlert alert) {
    final iconData = _alertIcon(alert.type);
    final color = _alertColor(alert.type);
    final timeAgo = _timeAgo(alert.timestamp);

    return AnimatedOpacity(
      opacity: alert.resolved ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: alert.resolved ? null : Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.patientName,
                          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1F36)),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 8),
                  if (!alert.resolved)
                    GestureDetector(
                      onTap: () => _store.resolveAlert(alert.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF135BEC).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Mark Resolved',
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF135BEC)),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          'Resolved',
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _alertIcon(AlertType type) {
    switch (type) {
      case AlertType.missedDose:
        return Icons.warning_rounded;
      case AlertType.refillNeeded:
        return Icons.medication_rounded;
      case AlertType.dispenserError:
        return Icons.error_outline_rounded;
    }
  }

  Color _alertColor(AlertType type) {
    switch (type) {
      case AlertType.missedDose:
        return const Color(0xFFDC2626);
      case AlertType.refillNeeded:
        return const Color(0xFFEA580C);
      case AlertType.dispenserError:
        return const Color(0xFF7C3AED);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
