import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/caregiver_store.dart';

class CaregiverProfileTab extends StatefulWidget {
  const CaregiverProfileTab({super.key});

  @override
  State<CaregiverProfileTab> createState() => _CaregiverProfileTabState();
}

class _CaregiverProfileTabState extends State<CaregiverProfileTab> {
  final _store = CaregiverStore();

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 24),

            // Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF135BEC).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _store.caregiverName,
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _store.caregiverEmail,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Caregiver',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Notification Preferences
            _sectionTitle('Notification Preferences'),
            const SizedBox(height: 12),
            _toggleTile(
              icon: Icons.warning_rounded,
              iconColor: const Color(0xFFDC2626),
              title: 'Missed Dose Alerts',
              subtitle: 'Get notified when a patient misses a dose',
              value: _store.notifyMissedDose,
              onChanged: (v) => setState(() => _store.notifyMissedDose = v),
            ),
            _toggleTile(
              icon: Icons.medication_rounded,
              iconColor: const Color(0xFFEA580C),
              title: 'Refill Reminders',
              subtitle: 'Alerts when medication supply is low',
              value: _store.notifyRefill,
              onChanged: (v) => setState(() => _store.notifyRefill = v),
            ),
            _toggleTile(
              icon: Icons.settings_remote_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: 'Dispenser Errors',
              subtitle: 'Device connectivity and hardware issues',
              value: _store.notifyDispenser,
              onChanged: (v) => setState(() => _store.notifyDispenser = v),
            ),
            const SizedBox(height: 24),

            // Linked Dispensers
            _sectionTitle('Linked Dispensers'),
            const SizedBox(height: 12),
            _dispenserTile('Dispenser A — Living Room', 'Online', true),
            _dispenserTile('Dispenser B — Bedroom', 'Offline', false),
            const SizedBox(height: 24),

            // Privacy & Security
            _sectionTitle('Privacy & Security'),
            const SizedBox(height: 12),
            _toggleTile(
              icon: Icons.pin_rounded,
              iconColor: const Color(0xFF135BEC),
              title: 'PIN Lock',
              subtitle: 'Require a PIN to access the app',
              value: _store.pinEnabled,
              onChanged: (v) => setState(() => _store.pinEnabled = v),
            ),
            _toggleTile(
              icon: Icons.fingerprint_rounded,
              iconColor: const Color(0xFF16A34A),
              title: 'Biometric Login',
              subtitle: 'Use fingerprint or face recognition',
              value: _store.biometricEnabled,
              onChanged: (v) => setState(() => _store.biometricEnabled = v),
            ),
            const SizedBox(height: 28),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                label: Text(
                  'Log Out',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1F36),
        ),
      );

  Widget _toggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1F36))),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF135BEC),
          ),
        ],
      ),
    );
  }

  Widget _dispenserTile(String name, String status, bool online) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (online ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.settings_remote_rounded,
              color: online ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1F36))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: online ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(status, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
