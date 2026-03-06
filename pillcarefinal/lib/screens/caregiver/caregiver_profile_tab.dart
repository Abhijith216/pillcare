import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/caregiver_store.dart';
import '../../models/patient_info.dart';

class CaregiverProfileTab extends StatefulWidget {
  const CaregiverProfileTab({super.key});
  @override
  State<CaregiverProfileTab> createState() => _CaregiverProfileTabState();
}

class _CaregiverProfileTabState extends State<CaregiverProfileTab> {
  final _store = CaregiverStore();
  bool _editMode = false;
  bool _saving = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _store.addListener(_onUpdate);
    _nameCtrl.text = _store.caregiverName;
    _phoneCtrl.text = _store.caregiverPhone;
  }

  @override
  void dispose() {
    _store.removeListener(_onUpdate);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (!_editMode) { _nameCtrl.text = _store.caregiverName; _phoneCtrl.text = _store.caregiverPhone; }
    setState(() {});
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    setState(() => _saving = true);
    await _store.updateProfile(name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim());
    if (mounted) { setState(() { _saving = false; _editMode = false; }); _showSnack('Profile updated'); }
  }

  void _signOut() async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Sign Out', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      content: Text('Are you sure you want to sign out?', style: GoogleFonts.manrope()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.manrope())),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Sign Out', style: GoogleFonts.manrope(color: const Color(0xFFDC2626), fontWeight: FontWeight.w700))),
      ],
    ));
    if (confirm == true && mounted) {
      await _store.signOut();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: _store.caregiverId));
    _showSnack('Caregiver ID copied!');
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
      backgroundColor: error ? const Color(0xFFDC2626) : const Color(0xFF135BEC),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(isDark),
        const SizedBox(height: 20),
        _profileCard(isDark),
        const SizedBox(height: 16),
        _cgIdCard(isDark),
        const SizedBox(height: 16),
        _connectedPatientsSection(isDark),
        const SizedBox(height: 16),
        _notificationSection(isDark),
        const SizedBox(height: 24),
        _signOutBtn(),
      ]),
    );
  }

  Widget _header(bool isDark) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('My Profile', style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1F36))),
      Text('Manage your account', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF94A3B8))),
    ])),
    if (!_editMode)
      GestureDetector(onTap: () => setState(() => _editMode = true), child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))]),
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20)))
    else
      TextButton(onPressed: () => setState(() { _editMode = false; _nameCtrl.text = _store.caregiverName; _phoneCtrl.text = _store.caregiverPhone; }), child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)))),
  ]);

  Widget _profileCard(bool isDark) {
    final initials = _store.caregiverName.trim().isEmpty ? 'CG' : _store.caregiverName.trim().split(' ').take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDeco(isDark, const Color(0xFF135BEC)),
      child: Column(children: [
        Row(children: [
          Container(
            width: 66, height: 66,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Center(child: Text(initials, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_store.caregiverName.isEmpty ? 'Caregiver' : _store.caregiverName, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1F36)), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(_store.caregiverEmail, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF6B7280))),
          ])),
        ]),
        if (_editMode) ...[
          const SizedBox(height: 20),
          _field('Full Name', _nameCtrl, Icons.person_rounded, isDark),
          const SizedBox(height: 12),
          _field('Phone Number', _phoneCtrl, Icons.phone_rounded, isDark, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            onPressed: _saving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            ).copyWith(backgroundColor: WidgetStateProperty.all(Colors.transparent)),
            child: Ink(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]), borderRadius: BorderRadius.all(Radius.circular(14))),
              child: Center(child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text('Save Changes', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)))),
          )),
        ] else ...[
          const SizedBox(height: 16),
          _infoRow(Icons.phone_rounded, 'Phone', _store.caregiverPhone.isEmpty ? '— not set —' : _store.caregiverPhone, isDark),
          const SizedBox(height: 8),
          _infoRow(Icons.people_rounded, 'Patients', '${_store.patients.length} connected', isDark),
        ],
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData ic, bool isDark, {TextInputType keyboardType = TextInputType.text}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280))),
    const SizedBox(height: 6),
    TextField(controller: ctrl, keyboardType: keyboardType, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1F36)),
      decoration: InputDecoration(
        prefixIcon: Icon(ic, size: 18, color: const Color(0xFF94A3B8)),
        filled: true, fillColor: isDark ? const Color(0xFF162032) : const Color(0xFFF8FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF135BEC), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      )),
  ]);

  Widget _infoRow(IconData ic, String label, String value, bool isDark) => Row(children: [
    Icon(ic, size: 16, color: const Color(0xFF94A3B8)), const SizedBox(width: 8),
    Text('$label: ', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF94A3B8))),
    Expanded(child: Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF374151)), overflow: TextOverflow.ellipsis)),
  ]);

  Widget _cgIdCard(bool isDark) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDeco(isDark, const Color(0xFF7C3AED)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9333EA)]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.badge_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 12),
        Text('Caregiver ID', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1F36))),
        const Spacer(),
        GestureDetector(onTap: _copyId, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9333EA)]), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [const Icon(Icons.copy_rounded, color: Colors.white, size: 14), const SizedBox(width: 4), Text('Copy', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))]))),
      ]),
      const SizedBox(height: 14),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF7C3AED).withValues(alpha: 0.1), const Color(0xFF9333EA).withValues(alpha: 0.05)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.25))),
        child: Center(child: Text(_store.caregiverId.isEmpty ? 'Loading…' : _store.caregiverId, style: GoogleFonts.robotoMono(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED), letterSpacing: 3)))),
      const SizedBox(height: 10),
      Text('Share this ID with your patients. They can enter it in their app to connect with you.', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF))),
    ]),
  );

  Widget _connectedPatientsSection(bool isDark) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDeco(isDark, const Color(0xFF0891B2)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF06B6D4)]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.people_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 12),
        Text('Connected Patients', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1F36))),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF0891B2).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('${_store.patients.length}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0891B2)))),
      ]),
      const SizedBox(height: 14),
      if (_store.patients.isEmpty)
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? const Color(0xFF162032) : const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [Icon(Icons.info_outline_rounded, size: 16, color: const Color(0xFF94A3B8)), const SizedBox(width: 8), Expanded(child: Text('Share your Caregiver ID with patients to connect.', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF))))]))
      else
        Column(children: _store.patients.map((p) => _patientRow(p, isDark)).toList()),
    ]),
  );

  Widget _patientRow(PatientInfo p, bool isDark) {
    final initials = p.name.trim().isEmpty
        ? '?'
        : p.name.trim().split(' ').take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    final adherenceColor = p.adherencePercent >= 80 ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(initials, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1F36)), overflow: TextOverflow.ellipsis),
                  Text('ID: ${p.id}', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF6B7280))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: adherenceColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('${p.adherencePercent.toInt()}%', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: adherenceColor)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _notificationSection(bool isDark) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDeco(isDark, const Color(0xFFEA580C)),
    child: Column(children: [
      Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFF97316)]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 12),
        Text('Notifications', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1F36))),
      ]),
      const SizedBox(height: 14),
      _toggleRow('Missed dose alerts', true, const Color(0xFFEA580C), isDark),
      _toggleRow('Refill reminders', true, const Color(0xFFEA580C), isDark),
      _toggleRow('Hardware events', false, const Color(0xFFEA580C), isDark),
    ]),
  );

  Widget _toggleRow(String label, bool val, Color c, bool isDark) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Expanded(child: Text(label, style: GoogleFonts.manrope(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF374151)))),
      Switch(value: val, activeColor: c, onChanged: (_) {}),
    ]));
  }

  Widget _signOutBtn() => SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
    onPressed: _signOut,
    icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
    label: Text('Sign Out', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFFDC2626))),
    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFDC2626), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
  ));

  BoxDecoration _cardDeco(bool isDark, Color accent) => BoxDecoration(
    color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: accent.withValues(alpha: 0.15), width: 1.5),
    boxShadow: [BoxShadow(color: accent.withValues(alpha: isDark ? 0.06 : 0.05), blurRadius: 16, offset: const Offset(0, 6))],
  );
}
