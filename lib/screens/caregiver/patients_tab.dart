import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/caregiver_store.dart';
import '../../models/patient_info.dart';
import '../../models/medication.dart';
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
    final nameC = TextEditingController();
    final ageC = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.link_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text('Link Patient', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1A1F36))),
              const SizedBox(height: 4),
              Text(
                'Enter the patient\'s unique ID to link them',
                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient ID field — primary linking field
              Text('PATIENT ID', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF135BEC), letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
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
                  style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1F36), letterSpacing: 1),
                  decoration: InputDecoration(
                    hintText: 'e.g. PC-12345',
                    hintStyle: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFFB0B7C3), letterSpacing: 1),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(Icons.fingerprint_rounded, color: const Color(0xFF135BEC), size: 22),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 42),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(errorText!, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Patient Name field
              Text('PATIENT NAME', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF6B7280), letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8EBF0)),
                ),
                child: TextField(
                  controller: nameC,
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1F36)),
                  decoration: InputDecoration(
                    hintText: 'Enter patient name',
                    hintStyle: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFFB0B7C3)),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(Icons.person_outline_rounded, color: const Color(0xFFB0B7C3), size: 20),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 42),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Age field
              Text('AGE', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF6B7280), letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8EBF0)),
                ),
                child: TextField(
                  controller: ageC,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1F36)),
                  decoration: InputDecoration(
                    hintText: 'Enter age',
                    hintStyle: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFFB0B7C3)),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(Icons.cake_outlined, color: const Color(0xFFB0B7C3), size: 20),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 42),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF135BEC).withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: const Color(0xFF135BEC), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The Patient ID is found in the patient\'s profile settings. It links both accounts together.',
                        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF4B7BF5), height: 1.4),
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
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF135BEC).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        final patientId = patientIdC.text.trim().toUpperCase();
                        final name = nameC.text.trim();
                        final age = int.tryParse(ageC.text.trim()) ?? 0;

                        // Validate Patient ID
                        if (patientId.isEmpty) {
                          setDialogState(() => errorText = 'Patient ID is required to link accounts');
                          return;
                        }
                        if (!patientId.startsWith('PC-') || patientId.length < 5) {
                          setDialogState(() => errorText = 'Invalid format. Use PC- followed by numbers');
                          return;
                        }
                        // Check for duplicate
                        final exists = _store.patients.any((p) => p.linkedPatientId == patientId);
                        if (exists) {
                          setDialogState(() => errorText = 'This Patient ID is already linked');
                          return;
                        }
                        if (name.isEmpty) {
                          setDialogState(() => errorText = 'Please enter the patient\'s name');
                          return;
                        }
                        if (age <= 0) {
                          setDialogState(() => errorText = 'Please enter a valid age');
                          return;
                        }

                        _store.addPatient(PatientInfo(
                          id: 'p${DateTime.now().millisecondsSinceEpoch}',
                          linkedPatientId: patientId,
                          name: name,
                          age: age,
                          adherencePercent: 0,
                          medications: [
                            Medication(
                              id: 'new_${DateTime.now().millisecondsSinceEpoch}',
                              name: 'Pending',
                              dosage: '-',
                              instruction: 'To be assigned',
                              time: '-',
                            ),
                          ],
                        ));

                        // Persist the link to Firestore
                        _store.saveLinkToFirestore(patientId);

                        Navigator.pop(ctx);

                        // Show success snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ $name linked successfully with ID $patientId',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: const Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.link_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text('Link Patient', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
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
                    'Age ${p.age} • ${p.medications.length} meds • ${p.adherencePercent.toInt()}% adherence',
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
