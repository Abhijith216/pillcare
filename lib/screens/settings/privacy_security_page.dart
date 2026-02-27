import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;

  bool _pinLockEnabled = false;
  bool _biometricEnabled = false;
  bool _encryptionEnabled = true;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  }

  @override
  void dispose() { _glowCtrl.dispose(); super.dispose(); }

  void _showPinDialog() {
    final pinCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Set PIN', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Enter a 4-digit PIN to lock the app.',
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B))),
        const SizedBox(height: 16),
        TextField(
          controller: pinCtrl, maxLength: 4,
          keyboardType: TextInputType.number, obscureText: true,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: '',
            hintText: '····',
            hintStyle: GoogleFonts.manrope(fontSize: 24, color: const Color(0xFFCBD5E1)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF135BEC), width: 2)),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () { Navigator.pop(ctx); setState(() => _pinLockEnabled = false); },
          child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
        TextButton(onPressed: () {
          Navigator.pop(ctx);
          setState(() => _pinLockEnabled = true);
          _showConfirmSnackbar('PIN lock enabled');
        }, child: Text('Set PIN', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: const Color(0xFF135BEC)))),
      ],
    ));
  }

  void _showConfirmSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _clearData() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
        const SizedBox(width: 8),
        Text('Clear All Data?', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800)),
      ]),
      content: Text('This will remove all local data including medication history. This action cannot be undone.',
        style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
        TextButton(onPressed: () {
          Navigator.pop(ctx);
          _showConfirmSnackbar('All data cleared');
        }, child: Text('Clear', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)))),
      ],
    ));
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        const SizedBox(width: 12),
        Text('Exporting data...', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: const Color(0xFF135BEC),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _showConfirmSnackbar('Data exported successfully');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (context, _) {
          final glow = _glowCtrl.value;
          return SafeArea(child: Column(children: [
            _buildAppBar(),
            Expanded(child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionLabel('AUTHENTICATION'),
                const SizedBox(height: 12),
                _buildToggle(Icons.pin_outlined, 'PIN Lock', 'Require 4-digit PIN on launch',
                  _pinLockEnabled, (v) {
                    if (v) { _showPinDialog(); } else { setState(() => _pinLockEnabled = false); }
                  }, glow),
                const SizedBox(height: 10),
                _buildToggle(Icons.fingerprint_rounded, 'Biometric Auth', 'Use fingerprint or Face ID',
                  _biometricEnabled, (v) {
                    setState(() => _biometricEnabled = v);
                    if (v) _showConfirmSnackbar('Biometric authentication enabled');
                  }, glow),
                const SizedBox(height: 24),

                _sectionLabel('DATA PROTECTION'),
                const SizedBox(height: 12),
                _buildToggle(Icons.enhanced_encryption_outlined, 'Data Encryption', 'Encrypt local health data',
                  _encryptionEnabled, (v) => setState(() => _encryptionEnabled = v), glow),
                const SizedBox(height: 28),

                _sectionLabel('DATA MANAGEMENT'),
                const SizedBox(height: 12),
                _buildActionButton(Icons.delete_outline_rounded, 'Clear All Data',
                  'Remove all local data', const Color(0xFFDC2626), _clearData),
                const SizedBox(height: 10),
                _buildActionButton(Icons.download_rounded, 'Export Data',
                  'Download your health records', const Color(0xFF135BEC), _exportData),
              ]),
            )),
          ]));
        },
      ),
    );
  }

  Widget _buildAppBar() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      Text('Privacy & Security', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
    ]),
  );

  Widget _sectionLabel(String text) => Text(text, style: GoogleFonts.manrope(
    fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 1));

  Widget _buildToggle(IconData icon, String title, String sub, bool value,
      ValueChanged<bool> onChanged, double glow) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: const Color(0xFF64748B))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF94A3B8))),
        ])),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300), width: 52, height: 30, padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: value ? const Color(0xFF135BEC) : const Color(0xFFE2E8F0),
              boxShadow: value ? [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.25 + glow * 0.15),
                blurRadius: 8 + glow * 4, spreadRadius: -1)] : [],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(width: 24, height: 24,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)])),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildActionButton(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: color)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 2),
            Text(sub, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF94A3B8))),
          ])),
          Icon(Icons.chevron_right_rounded, size: 22, color: color.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }
}
