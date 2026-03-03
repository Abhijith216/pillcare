import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
<<<<<<< Updated upstream
=======
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/theme_provider.dart';
>>>>>>> Stashed changes
import '../services/medication_store.dart';
import '../services/firestore_service.dart';
import 'settings/notifications_page.dart';
import 'settings/smart_dispenser_page.dart';
import 'settings/medication_schedule_page.dart';
import 'settings/privacy_security_page.dart';
import 'settings/help_support_page.dart';
import 'settings/about_page.dart';

// ═══════════════════════════════════════════════════════════════════════
//  SETTINGS / PROFILE SCREEN — Futuristic Healthcare Profile
//  Animated avatar · Editable details · Neon toggles · Sparkle effects
// ═══════════════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class CaregiverContact {
  String name;
  String relation;
  String phone;
  CaregiverContact(this.name, this.relation, this.phone);
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  // ─── Animation controllers ───
  late final AnimationController _glowController;
  late final AnimationController _avatarBounceController;
  AnimationController? _sparkController;
  bool _showSaveSparkle = false;

  // ─── User data (editable) ───
  String _name = '';
  String _email = '';
  String _phone = '';
  String _age = '--';
  String _weight = '--';
  String _height = '--';
<<<<<<< Updated upstream
  String _patientId = 'PC-...';
  String _role = 'patient';
  bool _dataLoading = true;
=======
  String _patientId = 'PC-GUEST';
  bool _isLoadingProfile = true;
>>>>>>> Stashed changes

  // ─── Caregiver Data ───
  List<CaregiverContact> _caregivers = [];

  // ─── BMI Data ───
  double _bmiValue = 0.0;
  String _bmiStatus = '--';

  // ─── Preferences ───
  bool _notificationsOn = true;
  bool _smartDispenserActive = true;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _avatarBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

<<<<<<< Updated upstream
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _dataLoading = false);
      return;
    }
    try {
      final data = await FirestoreService().getUserData();
      if (data != null && mounted) {
        final h = data['height']?.toString() ?? '';
        final w = data['weight']?.toString() ?? '';
        double bmi = 0.0;
        String bmiStatus = '--';
        final hNum = double.tryParse(h);
        final wNum = double.tryParse(w);
        if (hNum != null && wNum != null && hNum > 0) {
          final hm = hNum / 100;
          bmi = wNum / (hm * hm);
          if (bmi < 18.5) bmiStatus = 'Underweight';
          else if (bmi < 25) bmiStatus = 'Normal';
          else if (bmi < 30) bmiStatus = 'Overweight';
          else bmiStatus = 'Obese';
        }
        final cgName = data['caregiverName']?.toString() ?? '';
        final cgEmail = data['caregiverEmail']?.toString() ?? '';
        setState(() {
          _name = data['name']?.toString() ?? '';
          _email = data['email']?.toString() ?? '';
          _phone = data['phone']?.toString() ?? '';
          _height = h.isEmpty ? '--' : h;
          _weight = w.isEmpty ? '--' : w;
          _role = data['role']?.toString() ?? 'patient';
          _patientId = 'PC-${uid.substring(0, 6).toUpperCase()}';
          _bmiValue = bmi;
          _bmiStatus = bmiStatus;
          if (cgName.isNotEmpty) {
            _caregivers = [CaregiverContact(cgName, 'CAREGIVER', cgEmail)];
          }
          _dataLoading = false;
        });
      } else if (mounted) {
        setState(() => _dataLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _dataLoading = false);
=======
    _loadUserProfile();
  }

  /// Fetches the current user's profile data from Firestore
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null && mounted) {
        final data = doc.data()!;
        setState(() {
          _name = (data['name'] as String?)?.isNotEmpty == true
              ? data['name'] as String
              : user.displayName ?? 'Guest User';
          _email = (data['email'] as String?)?.isNotEmpty == true
              ? data['email'] as String
              : user.email ?? 'guest@pillcare.com';
          _phone = (data['phone'] as String?)?.isNotEmpty == true
              ? data['phone'] as String
              : '+1 (555) 000-0000';

          // Height & Weight
          final h = data['height'] as String? ?? '';
          final w = data['weight'] as String? ?? '';
          _height = h.isNotEmpty ? h.replaceAll(RegExp(r'[^0-9.]'), '') : '--';
          _weight = w.isNotEmpty ? w.replaceAll(RegExp(r'[^0-9.]'), '') : '--';

          // Age — could be stored as string or int
          final ageRaw = data['age'];
          if (ageRaw != null) {
            _age = ageRaw.toString();
          }

          // Patient ID — generate from UID if not stored
          final storedPatientId = data['patientId'] as String? ?? '';
          if (storedPatientId.isNotEmpty) {
            _patientId = storedPatientId;
          } else {
            // Generate a patient ID from UID hash
            final hash = user.uid.hashCode.abs() % 100000;
            _patientId = 'PC-${hash.toString().padLeft(5, '0')}';
            // Save it back to Firestore for future use
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'patientId': _patientId}).catchError((_) {});
          }

          // Caregiver details
          final cgName = data['caregiverName'] as String? ?? '';
          final cgEmail = data['caregiverEmail'] as String? ?? '';
          if (cgName.isNotEmpty || cgEmail.isNotEmpty) {
            _caregivers = [
              CaregiverContact(
                cgName.isNotEmpty ? cgName : 'Caregiver',
                'CAREGIVER',
                cgEmail,
              ),
            ];
          }

          // Compute BMI if height and weight are available
          _recalculateBMI();

          _isLoadingProfile = false;
        });
      } else {
        // Fallback to Firebase Auth info
        if (mounted) {
          setState(() {
            _name = user.displayName ?? 'Guest User';
            _email = user.email ?? 'guest@pillcare.com';
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _name = user.displayName ?? 'Guest User';
          _email = user.email ?? 'guest@pillcare.com';
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _recalculateBMI() {
    final weightNum = double.tryParse(_weight);
    final heightNum = double.tryParse(_height);
    if (weightNum != null && heightNum != null && heightNum > 0) {
      final heightM = heightNum / 100;
      _bmiValue = double.parse((weightNum / (heightM * heightM)).toStringAsFixed(1));
      if (_bmiValue < 18.5) {
        _bmiStatus = 'Underweight';
      } else if (_bmiValue < 25) {
        _bmiStatus = 'Normal';
      } else if (_bmiValue < 30) {
        _bmiStatus = 'Overweight';
      } else {
        _bmiStatus = 'Obese';
      }
    } else {
      _bmiValue = 0.0;
      _bmiStatus = '--';
>>>>>>> Stashed changes
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _avatarBounceController.dispose();
    _sparkController?.dispose();
    super.dispose();
  }

  void _triggerSaveSparkle() {
    _sparkController?.dispose();
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    setState(() => _showSaveSparkle = true);
    _sparkController!.forward().then((_) {
      if (mounted) setState(() => _showSaveSparkle = false);
    });
  }

  void _onAvatarTap() {
    _avatarBounceController.forward().then((_) {
      _avatarBounceController.reverse();
    });
    _openEditSheet();
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = _glowController.value;

        return SafeArea(
          bottom: false,
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // ── Title ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Settings',
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Profile Card ──
                    _buildProfileCard(glow),
                    const SizedBox(height: 28),

                    // ── Caregiver Contact Section ──
                    ..._caregivers.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCaregiverCard(e.key, glow),
                      );
                    }),
                    
                    // Add Emergency Contact Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: GestureDetector(
                        onTap: () => _openEditCaregiverSheet(null),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFBFDBFE).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF135BEC), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Add Emergency Contact',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF135BEC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 20),

                    // ── BMI Section ──
                    _buildBMICard(glow),
                    const SizedBox(height: 28),

                    // ── Preferences Section ──
                    _buildSectionHeader('PREFERENCES'),
                    const SizedBox(height: 12),
                    _buildNotificationToggle(glow),
                    const SizedBox(height: 10),
                    _buildDarkModeToggle(glow),
                    const SizedBox(height: 10),
                    _buildSmartDispenserCard(glow),
                    const SizedBox(height: 10),

                    // ── Menu Items ──
                    ..._buildMenuItems(),
                    const SizedBox(height: 28),

                    // ── Logout ──
                    _buildLogoutButton(glow),
                    const SizedBox(height: 24),
                    // Version
                    Center(
                      child: Text(
                        'PillCare v1.0.0',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),

              // ── Floating Support Chat ──
              Positioned(
                bottom: 90,
                right: 20,
                child: _buildSupportFAB(glow),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PROFILE CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProfileCard(double glow) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFFE2E8F0),
                const Color(0xFFBFDBFE),
                glow * 0.3,
              )!,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF135BEC)
                    .withValues(alpha: 0.04 + glow * 0.02),
                blurRadius: 20 + glow * 6,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Edit button top-right
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: _openEditSheet,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: Color(0xFF64748B)),
                  ),
                ),
              ),

              // Avatar with glowing frame
              GestureDetector(
                onTap: _onAvatarTap,
                child: AnimatedBuilder(
                  animation: _avatarBounceController,
                  builder: (context, child) {
                    final scale = 1.0 -
                        _avatarBounceController.value * 0.08 +
                        _avatarBounceController.value * 0.08;
                    return Transform.scale(
                      scale: 1.0 + math.sin(_avatarBounceController.value * math.pi) * 0.05,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(const Color(0xFFBFDBFE),
                              const Color(0xFFC4B5FD), glow)!,
                          Color.lerp(const Color(0xFFC4B5FD),
                              const Color(0xFFBFDBFE), glow)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED)
                              .withValues(alpha: 0.12 + glow * 0.08),
                          blurRadius: 12 + glow * 6,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      backgroundImage: const NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuD-OLmc3MWAgQM2NWdoEk9NNRpMJ2Vt3SEfLDbdaLMXD-SlayR74-IVADTI-nw_5Xt5jMPFyWVLovr38CkL2nikLFxTx3Unqz4ycg10E9LTlOyCn8nM1IxbH9eVP8ywPOrV7NUrsjzs1uZzQBaS-xRXUqUF4QBgNCJIzyi8HKbxdOtMPsLt2pGPALgfxqbjbAZ5e7MOWEeEhPBNaqqgXI4pEOz72LC6LNS2yfIq0xfB39fTdhsUeSA3ajvfsUqseQRdwWayL8qQMKg',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Name
              Text(
                _name,
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),

              // Badges row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PATIENT',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16A34A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Prominent Patient ID Card ──
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _patientId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '📋 Patient ID "$_patientId" copied to clipboard!',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: const Color(0xFF135BEC),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF135BEC).withValues(alpha: 0.06),
                        const Color(0xFF7C3AED).withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF135BEC).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint_rounded,
                              size: 18, color: const Color(0xFF135BEC)),
                          const SizedBox(width: 6),
                          Text(
                            'YOUR PATIENT ID',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF135BEC),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _patientId,
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E293B),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 12, color: const Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to copy',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 10)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showQRCodeDialog(),
                            child: Row(
                              children: [
                                Icon(Icons.qr_code_2_rounded,
                                    size: 12, color: const Color(0xFF135BEC)),
                                const SizedBox(width: 4),
                                Text(
                                  'Show QR Code',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF135BEC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stats chips row (Age, Weight, Height)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatChip(Icons.accessibility_new_rounded, 'AGE',
                      '$_age yrs', const Color(0xFF135BEC)),
                  const SizedBox(width: 12),
                  _buildStatChip(Icons.monitor_weight_outlined, 'WEIGHT',
                      '$_weight kg', const Color(0xFF7C3AED)),
                  const SizedBox(width: 12),
                  _buildStatChip(Icons.height_rounded, 'HEIGHT',
                      '$_height cm', const Color(0xFF0891B2)),
                ],
              ),
              const SizedBox(height: 18),
              // Divider
              Container(
                height: 1,
                color: const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 14),

              // Contact info rows
              _buildContactRow('Email', _email),
              const SizedBox(height: 10),
              _buildContactRow('Phone', _phone),
            ],
          ),
        ),

        // Save sparkle overlay
        if (_showSaveSparkle && _sparkController != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _sparkController!,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SaveSparklePainter(
                      progress: _sparkController!.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  NOTIFICATION TOGGLE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildNotificationToggle(double glow) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_outlined,
                  size: 20, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Notifications',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            // Custom neon toggle
            GestureDetector(
              onTap: () {
                setState(() => _notificationsOn = !_notificationsOn);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 52,
                height: 30,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: _notificationsOn
                      ? const Color(0xFF135BEC)
                      : const Color(0xFFE2E8F0),
                  boxShadow: _notificationsOn
                      ? [
                          BoxShadow(
                            color: const Color(0xFF135BEC)
                                .withValues(alpha: 0.25 + glow * 0.15),
                            blurRadius: 8 + glow * 4,
                            spreadRadius: -1,
                          ),
                        ]
                      : [],
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: _notificationsOn
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ═══════════════════════════════════════════════════════════════
  //  DARK MODE TOGGLE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDarkModeToggle(double glow) {
    final themeProvider = ThemeProvider();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              themeProvider.isDark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              size: 20,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Dark Mode',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              themeProvider.toggleTheme();
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 52,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: themeProvider.isDark
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFFE2E8F0),
                boxShadow: themeProvider.isDark
                    ? [
                        BoxShadow(
                          color: const Color(0xFF7C3AED)
                              .withValues(alpha: 0.25 + glow * 0.15),
                          blurRadius: 8 + glow * 4,
                          spreadRadius: -1,
                        ),
                      ]
                    : [],
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: themeProvider.isDark
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    themeProvider.isDark
                        ? Icons.nightlight_round
                        : Icons.wb_sunny_rounded,
                    size: 14,
                    color: themeProvider.isDark
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SMART DISPENSER CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSmartDispenserCard(double glow) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartDispenserPage())),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bluetooth,
                size: 20, color: Color(0xFF135BEC)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Smart Dispenser',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          // Active badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A)
                          .withValues(alpha: 0.3 + glow * 0.2),
                      blurRadius: 4 + glow * 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Active',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MENU ITEMS
  // ═══════════════════════════════════════════════════════════════
  List<Widget> _buildMenuItems() {
    final items = [
      _MenuItem(Icons.calendar_month_outlined, 'Medication Schedule', const MedicationSchedulePage()),
      _MenuItem(Icons.shield_outlined, 'Privacy & Security', const PrivacySecurityPage()),
      _MenuItem(Icons.help_outline_rounded, 'Help & Support', const HelpSupportPage()),
      _MenuItem(Icons.info_outline_rounded, 'About PillCare', const AboutPage()),
    ];

    return items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;

      return TweenAnimationBuilder<double>(
        key: ValueKey('menu_$i'),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + i * 100),
        curve: Curves.easeOutCubic,
        builder: (context, val, child) {
          return Transform.translate(
            offset: Offset(30 * (1 - val), 0),
            child: Opacity(opacity: val, child: child),
          );
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.page)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon,
                          size: 20, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFCBD5E1), size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOGOUT BUTTON
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLogoutButton(double glow) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFECACA)
                    .withValues(alpha: 0.6 + glow * 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: const Color(0xFFDC2626)
                      .withValues(alpha: 0.8 + glow * 0.2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Logout',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SUPPORT CHAT FAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSupportFAB(double glow) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF7C3AED).withValues(alpha: 0.25 + glow * 0.15),
            blurRadius: 14 + glow * 6,
            spreadRadius: -1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {},
          child: const Center(
            child:
                Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  CAREGIVER CONTACT CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCaregiverCard(int index, double glow) {
    final caregiver = _caregivers[index];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Avatar and edit button
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_border, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caregiver.name,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      caregiver.relation,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _openEditCaregiverSheet(index),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF135BEC)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Contact Phone Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONTACT PHONE',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                caregiver.phone,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Actions: Call & SMS
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling ${caregiver.name}...')));
                  },
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: const Text('CALL', maxLines: 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    textStyle: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert SMS Sent!')));
                  },
                  icon: const Icon(Icons.warning_amber_rounded, size: 16),
                  label: const Text('ALERT SMS', maxLines: 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFDC2626),
                    elevation: 0,
                    textStyle: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BMI CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBMICard(double glow) {
    return GestureDetector(
      onTap: _openEditBMISheet,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCFCE7)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.monitor_heart_outlined, color: Color(0xFF22C55E)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BODY MASS INDEX',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _bmiValue.toStringAsFixed(1),
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'BMI',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
              ),
              child: Text(
                _bmiStatus,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF22C55E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF135BEC).withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'YOUR PATIENT QR CODE',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // QR Code
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: QrImageView(
                  data: _patientId,
                  version: QrVersions.auto,
                  size: 200,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.roundedOuter,
                    color: Color(0xFF135BEC),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.roundedOuter,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Patient ID text
              Text(
                _patientId,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask your caregiver to scan this code',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _patientId));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied $_patientId',
                                style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFF135BEC),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text('Copy ID', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135BEC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Close', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditCaregiverSheet(int? index) {
    bool isNew = index == null;
    final nameCtrl = TextEditingController(text: isNew ? '' : _caregivers[index].name);
    final phoneCtrl = TextEditingController(text: isNew ? '' : _caregivers[index].phone);
    String selectedRelation = isNew ? 'PARENT' : _caregivers[index].relation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            margin: EdgeInsets.only(bottom: bottomInset),
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Text(isNew ? 'Add Caregiver' : 'Edit Caregiver', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: 'Caregiver Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: ['PARENT', 'SPOUSE', 'SIBLING', 'GUARDIAN', 'OTHER'].contains(selectedRelation) ? selectedRelation : 'OTHER',
                    decoration: InputDecoration(labelText: 'Relationship', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: ['PARENT', 'SPOUSE', 'SIBLING', 'GUARDIAN', 'OTHER'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedRelation = val);
                    },
                  ),
                  const SizedBox(height: 28),
                  
                  // Wrap delete button and save button in a row if editing
                  if (!isNew)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _caregivers.removeAt(index);
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF2F2), foregroundColor: const Color(0xFFDC2626),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text('Delete', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _caregivers[index] = CaregiverContact(nameCtrl.text, selectedRelation, phoneCtrl.text);
                              });
                              Navigator.pop(ctx);
                              _triggerSaveSparkle();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF135BEC), foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Save', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                          setState(() {
                            _caregivers.add(CaregiverContact(nameCtrl.text, selectedRelation, phoneCtrl.text));
                          });
                          Navigator.pop(ctx);
                          _triggerSaveSparkle();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135BEC), foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Add Caregiver', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openEditBMISheet() {
    final weightCtrl = TextEditingController(text: _weight == '--' ? '' : _weight);
    final heightCtrl = TextEditingController(text: _height == '--' ? '' : _height);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            margin: EdgeInsets.only(bottom: bottomInset),
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Text('Update BMI Info', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      final h = double.tryParse(heightCtrl.text);
                      final w = double.tryParse(weightCtrl.text);
                      setState(() {
                        _height = heightCtrl.text.isEmpty ? '--' : heightCtrl.text;
                        _weight = weightCtrl.text.isEmpty ? '--' : weightCtrl.text;
                        
                        if (h != null && w != null && h > 0) {
                          final hMeters = h / 100;
                          _bmiValue = w / (hMeters * hMeters);
                          if (_bmiValue < 18.5) {
                            _bmiStatus = 'Underweight';
                          } else if (_bmiValue < 25) {
                            _bmiStatus = 'Normal';
                          } else if (_bmiValue < 30) {
                            _bmiStatus = 'Overweight';
                          } else {
                            _bmiStatus = 'Obese';
                          }
                        }
                      });
                      Navigator.pop(ctx);
                      _triggerSaveSparkle();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Calculate & Save', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EDIT PROFILE BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════
  void _openEditSheet() {
    // Local controllers for editable fields
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phone);
    final ageCtrl = TextEditingController(text: _age == '--' ? '' : _age);
    final weightCtrl =
        TextEditingController(text: _weight == '--' ? '' : _weight);
    final heightCtrl =
        TextEditingController(text: _height == '--' ? '' : _height);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _EditProfileSheet(
          nameCtrl: nameCtrl,
          emailCtrl: emailCtrl,
          phoneCtrl: phoneCtrl,
          ageCtrl: ageCtrl,
          weightCtrl: weightCtrl,
          heightCtrl: heightCtrl,
          onSave: () async {
            final newName = nameCtrl.text.isEmpty ? _name : nameCtrl.text;
            final newEmail = emailCtrl.text.isEmpty ? _email : emailCtrl.text;
            final newPhone = phoneCtrl.text.isEmpty ? _phone : phoneCtrl.text;
            final newAge = ageCtrl.text.isEmpty ? '--' : ageCtrl.text;
            final newWeight = weightCtrl.text.isEmpty ? '--' : weightCtrl.text;
            final newHeight = heightCtrl.text.isEmpty ? '--' : heightCtrl.text;
            setState(() {
<<<<<<< Updated upstream
              _name = newName;
              _email = newEmail;
              _phone = newPhone;
              _age = newAge;
              _weight = newWeight;
              _height = newHeight;
            });
            Navigator.pop(ctx);
            _triggerSaveSparkle();
            try {
              await FirestoreService().updateUserProfile({
                'name': newName,
                'phone': newPhone,
                'height': newHeight == '--' ? '' : newHeight,
                'weight': newWeight == '--' ? '' : newWeight,
              });
            } catch (_) {}
=======
              _name = nameCtrl.text.isEmpty ? 'Guest User' : nameCtrl.text;
              _email = emailCtrl.text.isEmpty
                  ? 'guest@pillcare.com'
                  : emailCtrl.text;
              _phone = phoneCtrl.text.isEmpty
                  ? '+1 (555) 000-0000'
                  : phoneCtrl.text;
              _age = ageCtrl.text.isEmpty ? '--' : ageCtrl.text;
              _weight = weightCtrl.text.isEmpty ? '--' : weightCtrl.text;
              _height = heightCtrl.text.isEmpty ? '--' : heightCtrl.text;
              _recalculateBMI();
            });
            Navigator.pop(ctx);
            _triggerSaveSparkle();

            // Persist changes to Firestore
            _saveProfileToFirestore();
>>>>>>> Stashed changes
          },
          onCancel: () => Navigator.pop(ctx),
        );
      },
    );
  }

  /// Saves the current profile data back to Firestore
  Future<void> _saveProfileToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': _name,
        'email': _email,
        'phone': _phone,
        'age': _age,
        'height': _height,
        'weight': _weight,
      });
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EDIT PROFILE SHEET — Floating inputs with gradient borders
// ═══════════════════════════════════════════════════════════════════
class _EditProfileSheet extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController ageCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController heightCtrl;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditProfileSheet({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.ageCtrl,
    required this.weightCtrl,
    required this.heightCtrl,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _btnPulseController;

  @override
  void initState() {
    super.initState();
    _btnPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _btnPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _btnPulseController,
      builder: (context, _) {
        final pulse = _btnPulseController.value;

        return Container(
          margin: EdgeInsets.only(bottom: bottomInset),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fields
                  _gradientField('Full Name', widget.nameCtrl,
                      Icons.person_outline, pulse),
                  const SizedBox(height: 14),
                  _gradientField('Email Address', widget.emailCtrl,
                      Icons.email_outlined, pulse),
                  const SizedBox(height: 14),
                  _gradientField('Phone Number', widget.phoneCtrl,
                      Icons.phone_outlined, pulse),
                  const SizedBox(height: 14),

                  // Row: Age, Weight, Height
                  Row(
                    children: [
                      Expanded(
                          child: _gradientField(
                              'Age', widget.ageCtrl, null, pulse,
                              suffix: 'yrs')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _gradientField(
                              'Weight', widget.weightCtrl, null, pulse,
                              suffix: 'kg')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _gradientField(
                              'Height', widget.heightCtrl, null, pulse,
                              suffix: 'cm')),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Buttons row
                  Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onCancel,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: widget.onSave,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF135BEC),
                                  Color(0xFF7C3AED)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF135BEC).withValues(
                                      alpha: 0.2 + pulse * 0.1),
                                  blurRadius: 10 + pulse * 4,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Save Changes',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _gradientField(
      String label, TextEditingController ctrl, IconData? icon, double pulse,
      {String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color.lerp(const Color(0xFFE2E8F0),
                  const Color(0xFFBFDBFE), pulse * 0.3)!,
            ),
          ),
          child: TextField(
            controller: ctrl,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              prefixIcon:
                  icon != null ? Icon(icon, size: 18, color: const Color(0xFF94A3B8)) : null,
              suffixText: suffix,
              suffixStyle: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: InputBorder.none,
              hintText: label,
              hintStyle: GoogleFonts.manrope(
                fontSize: 13,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════════
class _MenuItem {
  final IconData icon;
  final String label;
  final Widget page;
  const _MenuItem(this.icon, this.label, this.page);
}

// ═══════════════════════════════════════════════════════════════════
//  SAVE SPARKLE PAINTER
// ═══════════════════════════════════════════════════════════════════
class _SaveSparklePainter extends CustomPainter {
  final double progress;
  static final _rng = math.Random(7);

  _SaveSparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.35;
    const count = 18;

    // Checkmark glow (first half)
    if (progress < 0.5) {
      final glowProgress = progress * 2;
      final paint = Paint()
        ..color = const Color(0xFF16A34A).withValues(alpha: (1 - glowProgress) * 0.3)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, 20 + glowProgress * 20);
      canvas.drawCircle(Offset(cx, cy), 20 + glowProgress * 30, paint);
    }

    // Particles (second half)
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + _rng.nextDouble() * 0.8;
      final maxR = 40.0 + _rng.nextDouble() * 60;
      final r = maxR * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final pSize = (2.5 + _rng.nextDouble() * 2.5) * (1 - progress * 0.5);

      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);

      final colors = [
        const Color(0xFF16A34A),
        const Color(0xFF135BEC),
        const Color(0xFF7C3AED),
        Colors.white,
      ];
      final c = colors[i % colors.length].withValues(alpha: opacity * 0.7);

      canvas.drawCircle(
        Offset(x, y),
        pSize,
        Paint()
          ..color = c
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
