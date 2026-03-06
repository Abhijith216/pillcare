import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/patient_info.dart';
import '../../models/medication.dart';
import '../../services/caregiver_store.dart';
import '../../services/firestore_service.dart';
import 'chat_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final PatientInfo patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  Map<String, dynamic>? _healthReport;
  bool _loadingReport = true;

  @override
  void initState() {
    super.initState();
    _fetchHealthReport();
    CaregiverStore().addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    CaregiverStore().removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchHealthReport() async {
    if (!widget.patient.id.startsWith('fb_')) {
      setState(() => _loadingReport = false);
      return;
    }
    final patientUid = widget.patient.id.replaceFirst('fb_', '');
    try {
      final report = await FirestoreService().getHealthReport(patientUid);
      if (mounted) setState(() { _healthReport = report; _loadingReport = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingReport = false);
    }
  }

  Future<void> _approve(Medication med) async {
    await CaregiverStore().approveMedication(widget.patient, med.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${med.name} approved', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _reject(Medication med) async {
    await CaregiverStore().rejectMedication(widget.patient, med.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✗ ${med.name} rejected', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final adherenceColor = patient.adherencePercent >= 80
        ? const Color(0xFF16A34A)
        : patient.adherencePercent >= 60
            ? const Color(0xFFEA580C)
            : const Color(0xFFDC2626);
    final pendingMeds = patient.medications.where((m) => m.isPending).toList();
    final approvedMeds = patient.medications.where((m) => !m.isPending).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 28),
                  child: Column(
                    children: [
                      // Back button row
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          ),
                          const Spacer(),
                          Text(
                            'Patient Details',
                            style: GoogleFonts.manrope(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Avatar & name
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            patient.name.split(' ').map((w) => w[0]).take(2).join(),
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        patient.name,
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age ${patient.age}',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      if (patient.linkedPatientId.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link_rounded, size: 14, color: Colors.white.withValues(alpha: 0.9)),
                              const SizedBox(width: 5),
                              Text(
                                'Linked: ${patient.linkedPatientId}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  _infoChip(Icons.check_circle_rounded, '${patient.adherencePercent.toInt()}%', 'Adherence', adherenceColor),
                  const SizedBox(width: 10),
                  _infoChip(Icons.warning_rounded, '${patient.missedDoses}', 'Missed', const Color(0xFFDC2626)),
                  const SizedBox(width: 10),
                  _infoChip(Icons.medication_rounded, '${patient.refillAlerts}', 'Refills', const Color(0xFFEA580C)),
                ],
              ),
            ),
          ),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  _actionButton(Icons.chat_bubble_rounded, 'Chat', const Color(0xFF135BEC), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CaregiverChatScreen(patient: patient)),
                    );
                  }),
                  const SizedBox(width: 10),
                  _actionButton(Icons.phone_rounded, 'Call', const Color(0xFF16A34A), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📞 Calling ${patient.name}...', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),
                  _actionButton(Icons.email_rounded, 'Email', const Color(0xFF7C3AED), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📧 Opening email to ${patient.email}', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                        backgroundColor: const Color(0xFF7C3AED),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Pending approvals section
          if (pendingMeds.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF9C3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFCA8A04)),
                              const SizedBox(width: 4),
                              Text(
                                'PENDING APPROVAL',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFCA8A04),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${pendingMeds.length} medication${pendingMeds.length > 1 ? 's' : ''}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...pendingMeds.map((med) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE047).withValues(alpha: 0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(color: med.bgColor, borderRadius: BorderRadius.circular(12)),
                                child: Icon(med.icon, color: med.color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(med.name, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1F36))),
                                    Text('${med.dosage} • ${med.instruction} • ${med.time}',
                                      style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _reject(med),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Center(
                                      child: Text('Reject', style: GoogleFonts.manrope(
                                        fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626))),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _approve(med),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                                          blurRadius: 8, offset: const Offset(0, 3)),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text('Approve', style: GoogleFonts.manrope(
                                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),

          // Health report section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Health Report',
                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1A1F36))),
                  const SizedBox(height: 10),
                  _loadingReport
                    ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                    : _healthReport == null
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text('No health report submitted yet.',
                            style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF))),
                        )
                      : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((_healthReport!['conditions'] as List?)?.isNotEmpty == true) ...[
                                Text('CONDITIONS', style: GoogleFonts.manrope(
                                  fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF135BEC), letterSpacing: 0.8)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6, runSpacing: 6,
                                  children: (_healthReport!['conditions'] as List)
                                      .map((c) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(c.toString(),
                                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF135BEC))),
                                      )).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if ((_healthReport!['aiDescription'] as String?)?.isNotEmpty == true) ...[
                                Text('AI SUMMARY', style: GoogleFonts.manrope(
                                  fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF7C3AED), letterSpacing: 0.8)),
                                const SizedBox(height: 8),
                                Text(_healthReport!['aiDescription'] as String,
                                  style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF374151), height: 1.5)),
                              ],
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),

          // Medication schedule title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Medication Schedule',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1F36),
                ),
              ),
            ),
          ),

          // Medication list (approved + rejected only)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final med = approvedMeds[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: med.bgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(med.icon, color: med.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.name,
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1F36),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${med.dosage} • ${med.instruction}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              med.time,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF135BEC),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${med.refillCount}/${med.refillTotal} left',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: med.isLowRefill ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                childCount: approvedMeds.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
