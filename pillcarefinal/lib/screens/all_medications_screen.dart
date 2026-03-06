import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medication.dart';
import '../services/medication_store.dart';
import 'add_medication_sheet.dart';

class AllMedicationsScreen extends StatelessWidget {
  const AllMedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MedicationStore(),
      builder: (context, _) {
        final meds = MedicationStore().medications;
        return Scaffold(
          backgroundColor: const Color(0xFFF6F6F8),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'All Medications',
              style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
            ),
          ),
          body: meds.isEmpty 
              ? Center(child: Text('No medications added yet.', style: GoogleFonts.manrope(color: Colors.grey)))
              : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: meds.length,
            itemBuilder: (context, index) {
              final m = meds[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
                child: Row(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: m.bgColor, borderRadius: BorderRadius.circular(14)), child: Icon(m.icon, color: m.color, size: 24)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('${m.dosage} • ${m.time}', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF94A3B8))),
                  ])),
                  IconButton(
                    onPressed: () async {
                      final result = await showModalBottomSheet<Medication>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddMedicationSheet(existing: m),
                      );
                      if (result != null) {
                        MedicationStore().update(m.id, result);
                      }
                    },
                    icon: const Icon(Icons.edit, size: 20, color: Color(0xFF94A3B8)),
                  ),
                ]),
              );
            },
          ),
        );
      },
    );
  }
}
