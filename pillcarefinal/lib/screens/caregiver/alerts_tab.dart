import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/caregiver_store.dart';
import '../../models/patient_info.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});
  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> with SingleTickerProviderStateMixin {
  final _store = CaregiverStore();
  AlertType? _filter;

  List<CaregiverAlert> _firebaseAlerts = [];
  StreamSubscription<QuerySnapshot>? _firestoreSub;
  final List<StreamSubscription> _rtdbSubs = [];
  final Set<String> _subscribedUids = {};
  bool _loading = true;
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _store.addListener(_onStoreUpdate);
    _startListening();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _firestoreSub?.cancel();
    for (final s in _rtdbSubs) s.cancel();
    _store.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (!mounted) return;
    _subscribeRtdbForNewPatients();
    setState(() {});
  }

  void _startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _loading = false); return; }

    _firestoreSub = FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('alerts')
        .orderBy('timestamp', descending: true).limit(100)
        .snapshots().listen((snap) {
          if (!mounted) return;
          final fsAlerts = snap.docs.map((d) => CaregiverAlert.fromMap(d.data(), d.id)).toList();
          final rtdbOnly = _firebaseAlerts.where((a) => a.id.startsWith('rtdb_')).toList();
          setState(() {
            _firebaseAlerts = [...fsAlerts, ...rtdbOnly.where((r) => !fsAlerts.any((f) => f.id == r.id))];
            _loading = false;
          });
          _staggerCtrl.reset(); _staggerCtrl.forward();
        }, onError: (_) { if (mounted) setState(() => _loading = false); });

    _subscribeRtdbForNewPatients();
  }

  void _subscribeRtdbForNewPatients() {
    for (final patient in _store.patients) {
      if (!patient.id.startsWith('fb_')) continue;
      final uid = patient.id.replaceFirst('fb_', '');
      if (_subscribedUids.contains(uid)) continue;
      _subscribedUids.add(uid);
      final sub = FirebaseDatabase.instance.ref('users/$uid/events').onChildAdded.listen((event) {
        final raw = event.snapshot.value;
        if (raw is! Map) return;
        final data = Map<String, dynamic>.from(raw);
        final alertId = 'rtdb_${event.snapshot.key}';
        if (_firebaseAlerts.any((a) => a.id == alertId)) return;
        final t = data['type']?.toString() ?? '';
        final type = t == 'missed' ? AlertType.missedDose : t == 'refill' ? AlertType.refillNeeded : AlertType.dispenserError;
        final tsRaw = data['timestamp'];
        final ts = tsRaw is int ? DateTime.fromMillisecondsSinceEpoch(tsRaw) : DateTime.now();
        if (mounted) setState(() => _firebaseAlerts.add(CaregiverAlert(
          id: alertId, patientId: patient.id, patientName: patient.name,
          type: type, message: data['message']?.toString() ?? 'Hardware event from ${patient.name}\'s dispenser', timestamp: ts,
        )));
      });
      _rtdbSubs.add(sub);
    }
  }

  List<CaregiverAlert> get _displayed {
    var list = List<CaregiverAlert>.from(_firebaseAlerts);
    if (_filter != null) list = list.where((a) => a.type == _filter).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Alerts', style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                Text('Live from hardware & Firebase', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF94A3B8))),
              ])),
              if (_loading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF135BEC))),
            ]),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _chip('All', null, isDark), const SizedBox(width: 8),
              _chip('Missed', AlertType.missedDose, isDark), const SizedBox(width: 8),
              _chip('Refills', AlertType.refillNeeded, isDark), const SizedBox(width: 8),
              _chip('Hardware', AlertType.dispenserError, isDark),
            ]),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _displayed.isEmpty && !_loading
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_outline_rounded, size: 52, color: Color(0xFF16A34A))),
                    const SizedBox(height: 16),
                    Text('No alerts — all clear!', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 6),
                    Text('Hardware alerts appear here in real time.', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF94A3B8))),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _displayed.length,
                    itemBuilder: (_, i) {
                      final delay = (i * 80).clamp(0, 600);
                      return AnimatedBuilder(
                        animation: _staggerCtrl,
                        builder: (ctx, child) {
                          final p = Curves.easeOut.transform(((_staggerCtrl.value * 1000 - delay) / 400).clamp(0.0, 1.0));
                          return Transform.translate(offset: Offset(0, (1 - p) * 20), child: Opacity(opacity: p, child: child));
                        },
                        child: _alertTile(_displayed[i], isDark),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, AlertType? type, bool isDark) {
    final sel = _filter == type;
    return GestureDetector(
      onTap: () { setState(() => _filter = type); _staggerCtrl.reset(); _staggerCtrl.forward(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF135BEC) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? const Color(0xFF135BEC) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          boxShadow: sel ? [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }

  Widget _alertTile(CaregiverAlert alert, bool isDark) {
    final isHw = alert.id.startsWith('rtdb_');
    final icon = alert.type == AlertType.missedDose ? Icons.warning_rounded : alert.type == AlertType.refillNeeded ? Icons.medication_rounded : Icons.router_rounded;
    final color = alert.type == AlertType.missedDose ? const Color(0xFFDC2626) : alert.type == AlertType.refillNeeded ? const Color(0xFFEA580C) : const Color(0xFF7C3AED);
    return AnimatedOpacity(
      opacity: alert.resolved ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: alert.resolved ? null : Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Row(children: [
                Text(alert.patientName, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                if (isHw) ...[
                  const SizedBox(width: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('HW', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF7C3AED)))),
                ],
              ])),
              Text(_timeAgo(alert.timestamp), style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF))),
            ]),
            const SizedBox(height: 4),
            Text(alert.message, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280))),
            const SizedBox(height: 8),
            if (!alert.resolved && !isHw)
              GestureDetector(
                onTap: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) FirebaseFirestore.instance.collection('users').doc(user.uid).collection('alerts').doc(alert.id).update({'resolved': true});
                  setState(() => alert.resolved = true);
                },
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF135BEC).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text('Mark Resolved', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF135BEC)))),
              )
            else if (alert.resolved)
              Row(children: [const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)), const SizedBox(width: 4), Text('Resolved', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A)))]),
          ])),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
