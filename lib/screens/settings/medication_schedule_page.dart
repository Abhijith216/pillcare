import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/medication.dart';
import '../../services/medication_store.dart';
import '../add_medication_sheet.dart';

class MedicationSchedulePage extends StatefulWidget {
  const MedicationSchedulePage({super.key});

  @override
  State<MedicationSchedulePage> createState() => _MedicationSchedulePageState();
}

class _MedicationSchedulePageState extends State<MedicationSchedulePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  }

  @override
  void dispose() { _glowCtrl.dispose(); super.dispose(); }

  void _addMedication() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMedicationSheet(),
    );
  }

  void _editMedication(Medication med) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMedicationSheet(existing: med),
    );
  }

  void _deleteMedication(Medication med) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Delete Medication?', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800)),
      content: Text('Are you sure you want to remove ${med.name} from your schedule?',
        style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF64748B))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
        TextButton(onPressed: () {
          MedicationStore().remove(med.id);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${med.name} removed', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }, child: Text('Delete', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedication,
        backgroundColor: const Color(0xFF135BEC),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: MedicationStore(),
        builder: (context, _) {
          final meds = MedicationStore().medications;
          return AnimatedBuilder(
            animation: _glowCtrl,
            builder: (context, _) {
              final glow = _glowCtrl.value;
              return SafeArea(child: Column(children: [
                _buildAppBar(),
                Expanded(
                  child: meds.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: meds.length,
                        itemBuilder: (ctx, i) => _buildMedCard(meds[i], i, glow),
                      ),
                ),
              ]));
            },
          );
        },
      ),
    );
  }

  Widget _buildAppBar() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      Text('Medication Schedule', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
    ]),
  );

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.medication_outlined, size: 56, color: Color(0xFFCBD5E1)),
    const SizedBox(height: 16),
    Text('No medications yet', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
    const SizedBox(height: 4),
    Text('Tap + to add one', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFFCBD5E1))),
  ]));

  Widget _buildMedCard(Medication med, int index, double glow) {
    final pct = med.refillPercent;
    Color barColor;
    if (pct > 0.5) barColor = const Color(0xFF16A34A);
    else if (pct > 0.15) barColor = const Color(0xFFF59E0B);
    else barColor = const Color(0xFFDC2626);

    return TweenAnimationBuilder<double>(
      key: ValueKey('med_${med.id}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (ctx, val, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - val)),
        child: Opacity(opacity: val, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: med.isLowRefill ? const Color(0xFFFECACA) : const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          // Top row
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: med.bgColor, borderRadius: BorderRadius.circular(14)),
              child: Icon(med.icon, color: med.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(med.name, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text('${med.dosage} · ${med.time}', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF94A3B8))),
            ])),
            // Edit
            GestureDetector(
              onTap: () => _editMedication(med),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
                child: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 6),
            // Delete
            GestureDetector(
              onTap: () => _deleteMedication(med),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA))),
                child: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFDC2626)),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          // Instruction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: med.bgColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
            child: Text(med.instruction, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: med.color)),
          ),
          const SizedBox(height: 14),
          // Refill bar
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Refill: ${med.refillCount}/${med.refillTotal}',
                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                Text('${(pct * 100).round()}%',
                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: barColor)),
              ]),
              const SizedBox(height: 6),
              SizedBox(height: 8, child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: [
                  Container(color: const Color(0xFFF1F5F9)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (ctx, v, _) => FractionallySizedBox(
                      widthFactor: v.clamp(0.0, 1.0),
                      child: Container(decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [barColor.withValues(alpha: 0.6), barColor]),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [BoxShadow(color: barColor.withValues(alpha: 0.3 + glow * 0.15), blurRadius: 6 + glow * 3)],
                      )),
                    ),
                  ),
                ]),
              )),
            ])),
          ]),
        ]),
      ),
    );
  }
}
