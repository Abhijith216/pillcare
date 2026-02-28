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
    final nameC = TextEditingController();
    final ageC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Patient', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: InputDecoration(
                labelText: 'Patient Name',
                labelStyle: GoogleFonts.manrope(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageC,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                labelStyle: GoogleFonts.manrope(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.manrope(color: const Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameC.text.trim();
              final age = int.tryParse(ageC.text.trim()) ?? 0;
              if (name.isNotEmpty && age > 0) {
                _store.addPatient(PatientInfo(
                  id: 'p${DateTime.now().millisecondsSinceEpoch}',
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
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135BEC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Add', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
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
                  Text(p.name, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1F36))),
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
