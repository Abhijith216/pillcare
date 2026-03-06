import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _submitted = false;

  final _faqs = [
    _FAQ('How do I add a new medication?',
      'Tap the + button on the home screen to open the medication form. Fill in the name, dosage, time, and instructions, then tap Save.'),
    _FAQ('How do refill counters work?',
      'Each medication tracks remaining pills. When you log a dose, the count decreases. Tap the Refill button to add pills when you get a new prescription.'),
    _FAQ('Can I set multiple reminders?',
      'Yes! Go to Settings → Notifications → Custom frequency to set intervals, or add the same medication with different times.'),
    _FAQ('How do I connect the Smart Dispenser?',
      'Go to Settings → Smart Dispenser, ensure Bluetooth is on, and tap Reconnect. The app will search for nearby dispensers.'),
    _FAQ('Is my health data secure?',
      'Absolutely. All data is stored locally on your device with optional encryption. Go to Privacy & Security to enable additional protections.'),
    _FAQ('How to export my medication history?',
      'Navigate to Settings → Privacy & Security → Export Data. Your records will be saved as a downloadable file.'),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose(); _msgCtrl.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _msgCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _submitted = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() { _submitted = false; _nameCtrl.clear(); _emailCtrl.clear(); _msgCtrl.clear(); });
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
                // Quick links
                _sectionLabel('QUICK LINKS'),
                const SizedBox(height: 12),
                _buildQuickLinks(glow),
                const SizedBox(height: 28),

                // FAQs
                _sectionLabel('FREQUENTLY ASKED QUESTIONS'),
                const SizedBox(height: 12),
                ..._faqs.asMap().entries.map((e) => _buildFaqCard(e.value, e.key)),
                const SizedBox(height: 28),

                // Contact form
                _sectionLabel('CONTACT SUPPORT'),
                const SizedBox(height: 12),
                _buildContactForm(glow),
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
      Text('Help & Support', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
    ]),
  );

  Widget _sectionLabel(String text) => Text(text, style: GoogleFonts.manrope(
    fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 1));

  Widget _buildQuickLinks(double glow) {
    final links = [
      _QL(Icons.build_circle_outlined, 'Troubleshooting', const Color(0xFFF59E0B)),
      _QL(Icons.menu_book_rounded, 'User Guide', const Color(0xFF135BEC)),
      _QL(Icons.groups_rounded, 'Community', const Color(0xFF7C3AED)),
    ];
    return Row(children: links.map((l) => Expanded(child: Padding(
      padding: EdgeInsets.only(right: l == links.last ? 0 : 10),
      child: GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Opening ${l.label}...', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
          backgroundColor: l.color, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 1),
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
          ),
          child: Column(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: l.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(l.icon, size: 20, color: l.color)),
            const SizedBox(height: 8),
            Text(l.label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          ]),
        ),
      ),
    ))).toList());
  }

  Widget _buildFaqCard(_FAQ faq, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (ctx, val, child) => Transform.translate(
        offset: Offset(20 * (1 - val), 0),
        child: Opacity(opacity: val, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            iconColor: const Color(0xFF135BEC),
            collapsedIconColor: const Color(0xFFCBD5E1),
            title: Text(faq.q, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
            children: [
              Text(faq.a, style: GoogleFonts.manrope(fontSize: 13, height: 1.5, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactForm(double glow) {
    if (_submitted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Column(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4), shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.2 + glow * 0.1), blurRadius: 12 + glow * 4)],
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 28),
          ),
          const SizedBox(height: 16),
          Text('Message Sent!', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A))),
          const SizedBox(height: 4),
          Text('We\'ll get back to you within 24 hours.', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B))),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _formField('Your Name', _nameCtrl, Icons.person_outline),
        const SizedBox(height: 14),
        _formField('Email Address', _emailCtrl, Icons.email_outlined),
        const SizedBox(height: 14),
        _formField('Message', _msgCtrl, Icons.message_outlined, maxLines: 4),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _submitForm,
          child: Container(
            width: double.infinity, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.2 + glow * 0.1),
                blurRadius: 12 + glow * 4, offset: const Offset(0, 4))],
            ),
            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Send Message', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ])),
          ),
        ),
      ]),
    );
  }

  Widget _formField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.3)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextField(
          controller: ctrl, maxLines: maxLines,
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1 ? Icon(icon, size: 18, color: const Color(0xFF94A3B8)) : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 12),
            border: InputBorder.none,
            hintText: label,
            hintStyle: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFFCBD5E1)),
          ),
        ),
      ),
    ]);
  }
}

class _FAQ { final String q, a; _FAQ(this.q, this.a); }
class _QL { final IconData icon; final String label; final Color color; _QL(this.icon, this.label, this.color); }
