import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;

  bool _masterEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _quietHoursEnabled = false;
  int _frequencyIndex = 0; // 0=Daily, 1=Weekly, 2=Custom
  int _customIntervalHours = 4;

  final _frequencies = ['Daily', 'Weekly', 'Custom'];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _glowCtrl.dispose(); super.dispose(); }

  void _showSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Preferences saved', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (context, _) {
          final glow = _glowCtrl.value;
          return SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Master toggle
                        _buildToggleCard(
                          Icons.notifications_active_rounded,
                          'Enable Notifications',
                          'Receive medication reminders',
                          _masterEnabled,
                          (v) => setState(() => _masterEnabled = v),
                          glow,
                          accentColor: const Color(0xFF135BEC),
                        ),
                        const SizedBox(height: 24),

                        _sectionLabel('ALERT OPTIONS'),
                        const SizedBox(height: 12),
                        _buildToggleCard(
                          Icons.volume_up_rounded,
                          'Sound',
                          'Play alert sound for reminders',
                          _soundEnabled,
                          (v) => setState(() => _soundEnabled = v),
                          glow,
                        ),
                        const SizedBox(height: 10),
                        _buildToggleCard(
                          Icons.vibration_rounded,
                          'Vibration',
                          'Vibrate on notification',
                          _vibrationEnabled,
                          (v) => setState(() => _vibrationEnabled = v),
                          glow,
                        ),
                        const SizedBox(height: 10),
                        _buildToggleCard(
                          Icons.do_not_disturb_on_rounded,
                          'Quiet Hours',
                          'Mute alerts 10 PM – 7 AM',
                          _quietHoursEnabled,
                          (v) => setState(() => _quietHoursEnabled = v),
                          glow,
                        ),
                        const SizedBox(height: 24),

                        _sectionLabel('REMINDER FREQUENCY'),
                        const SizedBox(height: 12),
                        _buildFrequencySelector(glow),

                        if (_frequencyIndex == 2) ...[
                          const SizedBox(height: 16),
                          _buildCustomInterval(glow),
                        ],

                        const SizedBox(height: 32),
                        _buildSaveButton(glow),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text('Notifications', style: GoogleFonts.manrope(
            fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: GoogleFonts.manrope(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: const Color(0xFF94A3B8), letterSpacing: 1));
  }

  Widget _buildToggleCard(IconData icon, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged, double glow,
      {Color accentColor = const Color(0xFF64748B)}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF94A3B8))),
            ],
          )),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52, height: 30, padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: value ? const Color(0xFF135BEC) : const Color(0xFFE2E8F0),
                boxShadow: value ? [BoxShadow(
                  color: const Color(0xFF135BEC).withValues(alpha: 0.25 + glow * 0.15),
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
        ],
      ),
    );
  }

  Widget _buildFrequencySelector(double glow) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: _frequencies.asMap().entries.map((e) {
          final selected = e.key == _frequencyIndex;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _frequencyIndex = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF135BEC) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected ? [BoxShadow(
                  color: const Color(0xFF135BEC).withValues(alpha: 0.2 + glow * 0.1),
                  blurRadius: 8 + glow * 3)] : [],
              ),
              child: Center(child: Text(e.value, style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF64748B)))),
            ),
          ));
        }).toList(),
      ),
    );
  }

  Widget _buildCustomInterval(double glow) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Custom Interval', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('Remind every $_customIntervalHours hours', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF135BEC),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: const Color(0xFF135BEC),
              overlayColor: const Color(0xFF135BEC).withValues(alpha: 0.1),
            ),
            child: Slider(
              min: 1, max: 24, divisions: 23,
              value: _customIntervalHours.toDouble(),
              onChanged: (v) => setState(() => _customIntervalHours = v.round()),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('1 hr', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFFCBD5E1))),
            Text('24 hrs', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFFCBD5E1))),
          ]),
        ],
      ),
    );
  }

  Widget _buildSaveButton(double glow) {
    return GestureDetector(
      onTap: _showSaved,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: const Color(0xFF135BEC).withValues(alpha: 0.2 + glow * 0.1),
            blurRadius: 12 + glow * 4, offset: const Offset(0, 4))],
        ),
        child: Center(child: Text('Save Preferences', style: GoogleFonts.manrope(
          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
      ),
    );
  }
}
