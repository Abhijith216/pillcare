import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/caregiver_store.dart';
import '../../models/patient_info.dart';
import 'patient_detail_screen.dart';

class PatientsTab extends StatefulWidget {
  const PatientsTab({super.key});

  @override
  State<PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends State<PatientsTab> {
  final _store = CaregiverStore();
  String _search = '';

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

  List<PatientInfo> get _filtered {
    if (_search.isEmpty) return _store.patients;
    final q = _search.toLowerCase();
    return _store.patients.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  void _showAddPatientDialog() {
    final patientIdC = TextEditingController();
    String? errorText;
    Map<String, dynamic>? foundPatient;
    bool searching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.link_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text('Link Patient', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(
                'Enter the patient\'s unique ID to find & link them',
                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PATIENT ID', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF135BEC), letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF135BEC).withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: errorText != null ? const Color(0xFFDC2626).withValues(alpha: 0.5) : const Color(0xFF135BEC).withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: patientIdC,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 1),
                        decoration: InputDecoration(
                          hintText: 'e.g. PC-12345',
                          hintStyle: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFFB0B7C3)),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: Icon(Icons.fingerprint_rounded, color: Color(0xFF135BEC), size: 22),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 42),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                        onChanged: (_) => setDialogState(() { errorText = null; foundPatient = null; }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: searching ? null : () async {
                      final pid = patientIdC.text.trim().toUpperCase();
                      if (pid.isEmpty) {
                        setDialogState(() => errorText = 'Enter a Patient ID first');
                        return;
                      }
                      if (_store.patients.any((p) => p.linkedPatientId == pid)) {
                        setDialogState(() => errorText = 'This patient is already linked');
                        return;
                      }
                      setDialogState(() { searching = true; errorText = null; foundPatient = null; });
                      try {
                        final query = await FirebaseFirestore.instance
                            .collection('users')
                            .where('patientId', isEqualTo: pid)
                            .limit(1)
                            .get();
                        if (query.docs.isEmpty) {
                          setDialogState(() { searching = false; errorText = 'No patient found with ID "$pid". Ask the patient to share their ID from their profile.'; });
                        } else {
                          final doc = query.docs.first;
                          setDialogState(() {
                            searching = false;
                            foundPatient = doc.data();
                          });
                        }
                      } catch (e) {
                        setDialogState(() { searching = false; errorText = 'Search failed. Check your connection.'; });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: searching ? null : const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]),
                        color: searching ? const Color(0xFF135BEC).withValues(alpha: 0.2) : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: searching
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF135BEC)))
                          : const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(errorText!, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626)))),
                  ],
                ),
              ],
              // Found patient preview
              if (foundPatient != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 6),
                        Text('Patient Found', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
                      ]),
                      const SizedBox(height: 10),
                      _infoRow(Icons.person_rounded, 'Name', foundPatient!['name']?.toString() ?? '-'),
                      const SizedBox(height: 6),
                      _infoRow(Icons.cake_rounded, 'Age', foundPatient!['age']?.toString() ?? '-'),
                      const SizedBox(height: 6),
                      _infoRow(Icons.email_rounded, 'Email', foundPatient!['email']?.toString() ?? '-'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF135BEC).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF135BEC), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The Patient ID is displayed in the patient\'s profile. Only registered patients can be linked.',
                        style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF4B7BF5), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Text('Cancel', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: foundPatient != null ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: foundPatient != null
                            ? [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed: foundPatient == null ? null : () async {
                          final pid = patientIdC.text.trim().toUpperCase();
                          await _store.linkPatient(pid);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('âœ… ${foundPatient!['name']} linked successfully', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.link_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text('Link Patient', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text('$label: ', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
        Expanded(child: Text(value, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF1A1F36)), overflow: TextOverflow.ellipsis)),
      ],
    );
  }


  void _confirmRemove(PatientInfo p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Patient', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        content: Text(
          'Remove ${p.name} from your patient list?',
          style: GoogleFonts.manrope(color: const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.manrope(color: const Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              _store.removePatient(p.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Remove', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Patients',
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
                    onPressed: _showAddPatientDialog,
                    icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
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
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: GoogleFonts.manrope(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search patients...',
                  hintStyle: GoogleFonts.manrope(color: const Color(0xFFB0B7C3)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFB0B7C3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_rounded, size: 56, color: const Color(0xFFB0B7C3)),
                        const SizedBox(height: 12),
                        Text(
                          'No patients found',
                          style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final p = _filtered[i];
                      return Dismissible(
                        key: ValueKey(p.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          _confirmRemove(p);
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        child: _buildPatientTile(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientTile(PatientInfo p) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PatientDetailScreen(patient: p)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF135BEC).withValues(alpha: 0.12),
                    const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  p.name.split(' ').map((w) => w[0]).take(2).join(),
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF135BEC)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(p.name, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1F36))),
                      ),
                      if (p.linkedPatientId.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF135BEC).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF135BEC).withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link_rounded, size: 10, color: const Color(0xFF135BEC)),
                              const SizedBox(width: 3),
                              Text(
                                p.linkedPatientId,
                                style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF135BEC), letterSpacing: 0.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Age ${p.age} â€¢ ${p.medications.length} meds â€¢ ${p.adherencePercent.toInt()}% adherence',
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B7C3)),
          ],
        ),
      ),
    );
  }
}
