import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medication.dart';
import '../services/ai_service.dart';

class AddMedicationSheet extends StatefulWidget {
  final Medication? existing;
  const AddMedicationSheet({super.key, this.existing});

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _instructionCtrl = TextEditingController();
  final _refillCtrl = TextEditingController();
  final _refillTotalCtrl = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _selectedPreset = 0;
  String? _interactionNote;
  bool _checkingInteraction = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final m = widget.existing!;
      _nameCtrl.text = m.name;
      _dosageCtrl.text = m.dosage;
      _instructionCtrl.text = m.instruction;
      _refillCtrl.text = m.refillCount.toString();
      _refillTotalCtrl.text = m.refillTotal.toString();
      _selectedPreset = medPresets.indexWhere((p) => p.icon == m.icon);
      if (_selectedPreset < 0) _selectedPreset = 0;
      // Parse time
      final parts = m.time.split(':');
      if (parts.length == 2) {
        final hourPart = parts[0];
        final minPart = parts[1].split(' ');
        var hour = int.tryParse(hourPart) ?? 8;
        final min = int.tryParse(minPart[0]) ?? 0;
        if (minPart.length > 1 && minPart[1] == 'PM' && hour != 12) hour += 12;
        if (minPart.length > 1 && minPart[1] == 'AM' && hour == 12) hour = 0;
        _selectedTime = TimeOfDay(hour: hour, minute: min);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _instructionCtrl.dispose();
    _refillCtrl.dispose();
    _refillTotalCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkInteractions() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || isEditing) return;
    setState(() { _checkingInteraction = true; _interactionNote = null; });
    final note = await AiService().checkInteractions(name);
    if (mounted) setState(() { _interactionNote = note; _checkingInteraction = false; });
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${h.toString().padLeft(2, '0')}:$m $p';
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty || _dosageCtrl.text.trim().isEmpty) return;
    final preset = medPresets[_selectedPreset];
    final med = Medication(
      id: isEditing ? widget.existing!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      instruction: _instructionCtrl.text.trim().isEmpty ? 'As directed' : _instructionCtrl.text.trim(),
      time: _formatTime(_selectedTime),
      icon: preset.icon,
      color: preset.color,
      bgColor: preset.bgColor,
      refillCount: int.tryParse(_refillCtrl.text) ?? 30,
      refillTotal: int.tryParse(_refillTotalCtrl.text) ?? 30,
      takenToday: isEditing ? widget.existing!.takenToday : false,
    );
    Navigator.pop(context, med);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle bar
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(isEditing ? 'Edit Medication' : 'Add New Medication',
            style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(isEditing ? 'Update your medication details' : 'Enter your medication details',
            style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 24),

          // Medication Type
          Text('Type', style: _labelStyle()),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: medPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final p = medPresets[i];
                final sel = _selectedPreset == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPreset = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    decoration: BoxDecoration(
                      color: sel ? p.bgColor : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sel ? p.color : const Color(0xFFE2E8F0), width: sel ? 2 : 1),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(p.icon, color: sel ? p.color : const Color(0xFF94A3B8), size: 24),
                      const SizedBox(height: 4),
                      Text(p.label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: sel ? p.color : const Color(0xFF94A3B8))),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Name
          Text('Medicine Name', style: _labelStyle()),
          const SizedBox(height: 8),
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) _checkInteractions();
            },
            child: _field(_nameCtrl, 'e.g. Amoxicillin', Icons.medication_outlined),
          ),
          // AI Interaction Check
          if (_checkingInteraction)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF135BEC)))),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Checking interactions with AI...', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF135BEC)))),
                ]),
              ),
            ),
          if (_interactionNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Text('AI Interaction Check', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFD97706))),
                  ]),
                  const SizedBox(height: 8),
                  Text(_interactionNote!, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF92400E), height: 1.5)),
                ]),
              ),
            ),

          const SizedBox(height: 16),
          // Dosage + Instruction row
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Dosage', style: _labelStyle()),
              const SizedBox(height: 8),
              _field(_dosageCtrl, 'e.g. 500mg', Icons.straighten),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Instruction', style: _labelStyle()),
              const SizedBox(height: 8),
              _field(_instructionCtrl, 'e.g. After meal', Icons.info_outline),
            ])),
          ]),
          const SizedBox(height: 16),

          // Time
          Text('Scheduled Time', style: _labelStyle()),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _selectedTime);
              if (t != null) setState(() => _selectedTime = t);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.schedule, color: Color(0xFFB0B7C3), size: 20),
                const SizedBox(width: 12),
                Text(_formatTime(_selectedTime), style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFFB0B7C3)),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Refill
          Text('Refill Tracking', style: _labelStyle()),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pills Remaining', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 6),
              _field(_refillCtrl, '30', Icons.inventory_2_outlined, isNumber: true),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total in Box', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 6),
              _field(_refillTotalCtrl, '30', Icons.all_inbox_outlined, isNumber: true),
            ])),
          ]),
          const SizedBox(height: 28),

          // Submit button
          SizedBox(
            width: double.infinity, height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(isEditing ? 'Update Medication' : 'Add Medication', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B));

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFFB0B7C3)),
          prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: Icon(icon, color: const Color(0xFFB0B7C3), size: 20)),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
