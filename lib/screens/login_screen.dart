import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool _isPatient = true;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();

  // Animation controllers
  late final AnimationController _bgController;
  late final AnimationController _fadeController;
  late final AnimationController _glowController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _glowAnim;

  // Floating particles
  late final List<_FloatingPill> _pills;

  @override
  void initState() {
    super.initState();

    // Background particle animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Staggered fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // Button glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Generate floating pills
    final rng = Random();
    _pills = List.generate(18, (_) => _FloatingPill(rng));

    // Start fade-in
    _fadeController.forward();

    // Load saved credentials
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final creds = await _auth.loadCredentials();
    if (creds != null && mounted) {
      setState(() {
        _emailController.text = creds['email'] ?? '';
        _passwordController.text = creds['password'] ?? '';
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final role = await _auth.signIn(email, password);

      // Save or clear credentials
      if (_rememberMe) {
        await _auth.saveCredentials(email, password);
      } else {
        await _auth.clearCredentials();
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        role == 'caregiver' ? '/caregiver' : '/home',
      );
    } on Exception catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      debugPrint('Sign in error: $errorMsg');
      _showError(errorMsg.isNotEmpty ? errorMsg : 'Failed to sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _biometricSignIn() async {
    if (!_auth.isBiometricAvailable) {
      _showError('Biometric auth is only available on mobile devices.');
      return;
    }
    final success = await _auth.attemptBiometric();
    if (success && mounted) {
      Navigator.pushReplacementNamed(
        context,
        _isPatient ? '/home' : '/caregiver',
      );
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
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
          // Animated gradient background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                painter: _BackgroundPainter(_bgController.value, _pills),
                size: Size.infinite,
              );
            },
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAnimatedLogo(),
                            const SizedBox(height: 6),
                            Text(
                              'Your Health, Our Priority',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9CA3AF),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildRoleToggle(),
                            const SizedBox(height: 24),
                            _buildWelcomeText(),
                            const SizedBox(height: 28),
                            _buildEmailField(),
                            const SizedBox(height: 16),
                            _buildPasswordField(),
                            const SizedBox(height: 14),
                            _buildRememberForgotRow(),
                            const SizedBox(height: 24),
                            _buildSignInButton(),
                            const SizedBox(height: 16),
                            _buildBiometricButton(),
                            const SizedBox(height: 12),
                            _buildDivider(),
                            const SizedBox(height: 12),
                            _buildCreateAccountLink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Animated Logo ---
  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF135BEC).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.medical_services, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Text(
            'PillCare',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1F36),
            ),
          ),
        ],
      ),
    );
  }

  // --- Role Toggle ---
  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _roleTab('Patient', true),
          _roleTab('Caregiver', false),
        ],
      ),
    );
  }

  Widget _roleTab(String label, bool isPatientTab) {
    final active = _isPatient == isPatientTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isPatient = isPatientTab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              Icon(
                isPatientTab ? Icons.person_rounded : Icons.people_rounded,
                size: 16,
                color: active ? const Color(0xFF135BEC) : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
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

  // --- Welcome Text ---
  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1F36),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isPatient
                ? 'Sign in to manage your medication'
                : 'Sign in to manage your patients\' care',
            key: ValueKey(_isPatient),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // --- Email Field ---
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1F36)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EBF0)),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1F36)),
            decoration: InputDecoration(
              hintText: 'patient@demo.com',
              hintStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFB0B7C3)),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.email_outlined, color: Color(0xFFB0B7C3), size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  // --- Password Field ---
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1F36)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EBF0)),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1F36)),
            decoration: InputDecoration(
              hintText: 'demo123',
              hintStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFB0B7C3)),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.lock_outline, color: Color(0xFFB0B7C3), size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFFB0B7C3),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  // --- Remember Me + Forgot Password ---
  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _rememberMe ? const Color(0xFF135BEC) : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _rememberMe ? const Color(0xFF135BEC) : const Color(0xFFD1D5DB),
                    width: 1.5,
                  ),
                ),
                child: _rememberMe
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Remember me',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const ForgotPasswordScreen(),
              transitionsBuilder: (_, anim, __, child) {
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 350),
            ),
          ),
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF135BEC)),
          ),
        ),
      ],
    );
  }

  // --- Sign In Button with Glow ---
  Widget _buildSignInButton() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF135BEC).withValues(alpha: 0.2 + _glowAnim.value * 0.2),
                blurRadius: 12 + _glowAnim.value * 8,
                spreadRadius: _glowAnim.value * 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'Sign In',
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
        ),
      ),
    );
  }

  // --- Biometric Button ---
  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _biometricSignIn,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint_rounded, size: 22, color: const Color(0xFF135BEC)),
            const SizedBox(width: 8),
            Text(
              'Sign in with Biometrics',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF135BEC)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Divider ---
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFE8EBF0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF9CA3AF)),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFE8EBF0))),
      ],
    );
  }

  // --- Create Account ---
  Widget _buildCreateAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?  ",
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFF9CA3AF)),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const SignUpScreen(),
              transitionsBuilder: (_, anim, __, child) {
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          ),
          child: Text(
            'Create account',
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF135BEC)),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Floating pill particle for animated background
// ============================================================
class _FloatingPill {
  late double x, y, radius, speed, opacity;
  late int type; // 0 = circle, 1 = pill shape

  _FloatingPill(Random rng) {
    x = rng.nextDouble();
    y = rng.nextDouble();
    radius = 4 + rng.nextDouble() * 18;
    speed = 0.15 + rng.nextDouble() * 0.4;
    opacity = 0.04 + rng.nextDouble() * 0.08;
    type = rng.nextInt(2);
  }
}

class _BackgroundPainter extends CustomPainter {
  final double t;
  final List<_FloatingPill> pills;

  _BackgroundPainter(this.t, this.pills);

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0E3FBE), Color(0xFF5B21B6), Color(0xFF1E1B4B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Gradient wave overlay
    final wavePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          -0.5 + sin(t * 2 * pi) * 0.3,
          -0.3 + cos(t * 2 * pi) * 0.3,
        ),
        radius: 1.2,
        colors: [
          const Color(0xFF135BEC).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), wavePaint);

    // Second wave
    final wave2Paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          0.5 + cos(t * 2 * pi * 0.7) * 0.4,
          0.5 + sin(t * 2 * pi * 0.7) * 0.4,
        ),
        radius: 0.9,
        colors: [
          const Color(0xFF7C3AED).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), wave2Paint);

    // Floating pills / particles
    for (final pill in pills) {
      final px = ((pill.x + t * pill.speed) % 1.2 - 0.1) * size.width;
      final py = ((pill.y + sin(t * 2 * pi + pill.x * 10) * 0.03) % 1.0) * size.height;
      final paint = Paint()..color = Colors.white.withValues(alpha: pill.opacity);

      if (pill.type == 0) {
        canvas.drawCircle(Offset(px, py), pill.radius, paint);
      } else {
        // Pill capsule shape
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(px, py), width: pill.radius * 2.2, height: pill.radius),
          Radius.circular(pill.radius / 2),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => true;
}
