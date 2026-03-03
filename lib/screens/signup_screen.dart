import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  // Additional fields for patients
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _caregiverNameController = TextEditingController();
  final _caregiverEmailController = TextEditingController();

  // Additional fields for caregiver
  final _phoneController = TextEditingController();
  final _patientIdController = TextEditingController();

  final _auth = AuthService();
  bool _isPatient = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Animations
  late final AnimationController _bgController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    final rng = Random();
    _particles = List.generate(14, (_) => _Particle(rng));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _caregiverNameController.dispose();
    _caregiverEmailController.dispose();
    _phoneController.dispose();
    _patientIdController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    
    final height = _heightController.text.trim();
    final weight = _weightController.text.trim();
    final caregiverName = _caregiverNameController.text.trim();
    final caregiverEmail = _caregiverEmailController.text.trim();
    final phone = _phoneController.text.trim();
    final linkedPatientId = _patientIdController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final role = await _auth.signUp(
        name: name,
        email: email,
        password: password,
        role: _isPatient ? 'patient' : 'caregiver',
        height: _isPatient ? height : null,
        weight: _isPatient ? weight : null,
        caregiverName: _isPatient ? caregiverName : null,
        caregiverEmail: _isPatient ? caregiverEmail : null,
        phone: !_isPatient ? phone : null,
        linkedPatientId: !_isPatient ? linkedPatientId : null,
      );

      if (!mounted) return;

      await _auth.signOut();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Account created! Please sign in.', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } on Exception catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      debugPrint('Sign up error: $errorMsg');
      debugPrint('Sign up error details: ${e.runtimeType}');
      _showError(errorMsg.isNotEmpty && errorMsg != 'Error' ? errorMsg : 'Failed to create account. Please check your email and try a different password.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => CustomPaint(
              painter: _SignUpBgPainter(_bgController.value, _particles),
              size: Size.infinite,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                      const Spacer(),
                      Text(
                        'Create Account',
                        style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.elasticOut,
                                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF135BEC).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 26),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Join PillCare',
                                style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF1A1F36)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Create your account to get started',
                                style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
                              ),
                              const SizedBox(height: 24),

                              // Role toggle
                              _buildRoleToggle(),
                              const SizedBox(height: 20),

                              // Name
                              _buildField(
                                controller: _nameController,
                                label: 'Full Name',
                                hint: 'Enter your name',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 14),

                              // Email
                              _buildField(
                                controller: _emailController,
                                label: 'Account Email',
                                hint: 'Your email address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),

                              if (_isPatient) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildField(
                                        controller: _heightController,
                                        label: 'Height',
                                        hint: 'e.g. 170 cm',
                                        icon: Icons.height,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildField(
                                        controller: _weightController,
                                        label: 'Weight',
                                        hint: 'e.g. 65 kg',
                                        icon: Icons.monitor_weight_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildField(
                                  controller: _caregiverNameController,
                                  label: 'Caregiver Name',
                                  hint: 'Enter caregiver name',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 14),
                                _buildField(
                                  controller: _caregiverEmailController,
                                  label: 'Caregiver Email',
                                  hint: 'Enter caregiver email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                              ] else ...[
                                // Phone
                                _buildField(
                                  controller: _phoneController,
                                  label: 'Your Phone',
                                  hint: 'Your contact number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Password
                              _buildField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Create a password',
                                icon: Icons.lock_outline,
                                obscure: _obscurePassword,
                                toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              const SizedBox(height: 14),
                              // Confirm Password — always shown for both roles
                              _buildField(
                                controller: _confirmController,
                                label: 'Confirm Password',
                                hint: 'Re-enter password',
                                icon: Icons.lock_outline,
                                obscure: _obscureConfirm,
                                toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),

                              if (!_isPatient) ...[
                                const SizedBox(height: 24),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('PATIENT CONNECTION', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF135BEC))),
                                ),
                                const SizedBox(height: 8),
                                _buildDashedField(
                                  controller: _patientIdController,
                                  hint: 'Link Patient ID (e.g. PC-12345)',
                                  icon: Icons.person_add_outlined,
                                ),
                              ],
                              
                              const SizedBox(height: 24),

                              // Sign Up button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF135BEC).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signUp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                        : Text(
                                            'Create Account',
                                            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Sign In link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account?  ',
                                    style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Text(
                                      'Sign In',
                                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF135BEC)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _roleTab('Patient', true, Icons.person_rounded),
          _roleTab('Caregiver', false, Icons.people_rounded),
        ],
      ),
    );
  }

  Widget _roleTab(String label, bool isPatientTab, IconData icon) {
    final active = _isPatient == isPatientTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isPatient = isPatientTab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? const Color(0xFF135BEC) : const Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? const Color(0xFF135BEC) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool? obscure,
    VoidCallback? toggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF6B7280), letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EBF0)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure ?? false,
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1F36)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFFB0B7C3)),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(icon, color: const Color(0xFFB0B7C3), size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44),
              suffixIcon: toggleObscure != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconButton(
                        icon: Icon(
                          obscure! ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFFB0B7C3),
                          size: 20,
                        ),
                        onPressed: toggleObscure,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashedField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF135BEC).withValues(alpha: 0.04), // slight blue tint
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: controller,
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1F36)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFFB0B7C3)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: const Color(0xFF135BEC), size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DashedBorderPainter({this.color = const Color(0xFF135BEC), this.strokeWidth = 1.5, this.gap = 5.0, this.radius = 14.0});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius)));

    var dashPath = Path();
    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashPath.addPath(measurePath.extractPath(distance, distance + gap), Offset.zero);
        distance += gap * 2;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// Background particles (reusable)
// ============================================================
class _Particle {
  late double x, y, r, speed, opacity;
  _Particle(Random rng) {
    x = rng.nextDouble();
    y = rng.nextDouble();
    r = 3 + rng.nextDouble() * 14;
    speed = 0.1 + rng.nextDouble() * 0.3;
    opacity = 0.03 + rng.nextDouble() * 0.06;
  }
}

class _SignUpBgPainter extends CustomPainter {
  final double t;
  final List<_Particle> particles;
  _SignUpBgPainter(this.t, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0E3FBE), Color(0xFF5B21B6), Color(0xFF1E1B4B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Waves
    final wave = Paint()
      ..shader = RadialGradient(
        center: Alignment(sin(t * 2 * pi) * 0.4, cos(t * 2 * pi) * 0.3),
        radius: 1.0,
        colors: [const Color(0xFF7C3AED).withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), wave);

    for (final p in particles) {
      final px = ((p.x + t * p.speed) % 1.1 - 0.05) * size.width;
      final py = ((p.y + sin(t * 2 * pi + p.x * 8) * 0.02) % 1.0) * size.height;
      canvas.drawCircle(Offset(px, py), p.r, Paint()..color = Colors.white.withValues(alpha: p.opacity));
    }
  }

  @override
  bool shouldRepaint(covariant _SignUpBgPainter old) => true;
}
