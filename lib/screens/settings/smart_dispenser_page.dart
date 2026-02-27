import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class SmartDispenserPage extends StatefulWidget {
  const SmartDispenserPage({super.key});

  @override
  State<SmartDispenserPage> createState() => _SmartDispenserPageState();
}

class _SmartDispenserPageState extends State<SmartDispenserPage>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _batteryCtrl;

  bool _isConnected = true;
  int _batteryLevel = 78;
  String _lastSync = '2 minutes ago';
  bool _isReconnecting = false;
  bool _isCalibrating = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _batteryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  @override
  void dispose() { _glowCtrl.dispose(); _batteryCtrl.dispose(); super.dispose(); }

  Future<void> _reconnect() async {
    setState(() => _isReconnecting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() { _isReconnecting = false; _isConnected = true; _lastSync = 'Just now'; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.bluetooth_connected, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('Dispenser reconnected', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _calibrate() async {
    setState(() => _isCalibrating = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isCalibrating = false);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
        const SizedBox(width: 8),
        Text('Calibration Complete', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800)),
      ]),
      content: Text('Your dispenser has been calibrated successfully.',
        style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF64748B))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx),
        child: Text('OK', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: const Color(0xFF135BEC))))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnimatedBuilder(
        animation: Listenable.merge([_glowCtrl, _batteryCtrl]),
        builder: (context, _) {
          final glow = _glowCtrl.value;
          return SafeArea(child: Column(children: [
            _buildAppBar(),
            Expanded(child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildStatusCard(glow),
                const SizedBox(height: 20),
                _buildBatteryCard(glow),
                const SizedBox(height: 20),
                _buildSyncCard(glow),
                const SizedBox(height: 28),
                _buildActionButtons(glow),
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
      Text('Smart Dispenser', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
    ]),
  );

  Widget _buildStatusCard(double glow) {
    final color = _isConnected ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15 + glow * 0.1), blurRadius: 10 + glow * 5)],
          ),
          child: Icon(_isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, size: 26, color: color),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Connection Status', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Row(children: [
            Container(width: 10, height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3 + glow * 0.2), blurRadius: 6 + glow * 3)])),
            const SizedBox(width: 8),
            Text(_isConnected ? 'Connected' : 'Disconnected',
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ]),
        ]),
      ]),
    );
  }

  Widget _buildBatteryCard(double glow) {
    final pct = _batteryLevel / 100;
    final animPct = pct * _batteryCtrl.value;
    Color batColor;
    if (pct > 0.5) batColor = const Color(0xFF16A34A);
    else if (pct > 0.2) batColor = const Color(0xFFF59E0B);
    else batColor = const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BATTERY LEVEL', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 16),
        Center(child: SizedBox(
          width: 120, height: 120,
          child: CustomPaint(
            painter: _BatteryRingPainter(progress: animPct, color: batColor, glow: glow),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.battery_std_rounded, size: 24, color: batColor),
              const SizedBox(height: 4),
              Text('$_batteryLevel%', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            ])),
          ),
        )),
        const SizedBox(height: 12),
        Center(child: Text(
          _batteryLevel > 50 ? 'Battery is healthy' : _batteryLevel > 20 ? 'Consider charging soon' : 'Low battery!',
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: batColor))),
      ]),
    );
  }

  Widget _buildSyncCard(double glow) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.sync_rounded, size: 22, color: Color(0xFF135BEC)),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Last Synced', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(_lastSync, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        ]),
      ]),
    );
  }

  Widget _buildActionButtons(double glow) {
    return Column(children: [
      // Reconnect
      GestureDetector(
        onTap: _isReconnecting ? null : _reconnect,
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.2 + glow * 0.1),
              blurRadius: 12 + glow * 4, offset: const Offset(0, 4))],
          ),
          child: Center(child: _isReconnecting
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.bluetooth_searching_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Reconnect', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ])),
        ),
      ),
      const SizedBox(height: 12),
      // Calibrate
      GestureDetector(
        onTap: _isCalibrating ? null : _calibrate,
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(child: _isCalibrating
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: const Color(0xFF135BEC).withValues(alpha: 0.6)))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
                const SizedBox(width: 8),
                Text('Calibrate Dispenser', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
              ])),
        ),
      ),
    ]);
  }
}

class _BatteryRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glow;
  _BatteryRingPainter({required this.progress, required this.color, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Track
    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 10..color = const Color(0xFFF1F5F9));

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0, endAngle: 2 * math.pi,
          colors: [color.withValues(alpha: 0.6), color],
        ).createShader(rect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + glow * 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
