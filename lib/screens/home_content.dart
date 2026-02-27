import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../models/medication.dart';
import '../services/medication_store.dart';
import '../services/ai_service.dart';
import 'add_medication_sheet.dart';
import 'ai_chat_screen.dart';
import 'refill_counter_widget.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? _aiInsight;
  bool _loadingInsight = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MedicationStore(),
      builder: (context, _) {
        final store = MedicationStore();
        final meds = store.medications;
        final taken = meds.where((m) => m.takenToday).length;
        final total = meds.isEmpty ? 1 : meds.length;
        final pct = (taken / total * 100).round();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGradientHeader(pct),
              const SizedBox(height: 24),
              _MedicationsSection(),
              const SizedBox(height: 28),
              // ──── Futuristic Refill Counter ────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Refill Status',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF7C3AED)),
                                const SizedBox(width: 4),
                                Text(
                                  'Live',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const RefillCounterWidget(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildStatsGrid(store),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradientHeader(int pct) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Positioned(top: -40, right: -40, child: Container(width: 160, height: 160, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Welcome back', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFBFD4FF))),
                      const SizedBox(height: 4),
                      Text('Good Morning,\nGuest', style: GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15)),
                    ]),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        backgroundImage: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuD-OLmc3MWAgQM2NWdoEk9NNRpMJ2Vt3SEfLDbdaLMXD-SlayR74-IVADTI-nw_5Xt5jMPFyWVLovr38CkL2nikLFxTx3Unqz4ycg10E9LTlOyCn8nM1IxbH9eVP8ywPOrV7NUrsjzs1uZzQBaS-xRXUqUF4QBgNCJIzyi8HKbxdOtMPsLt2pGPALgfxqbjbAZ5e7MOWEeEhPBNaqqgXI4pEOz72LC6LNS2yfIq0xfB39fTdhsUeSA3ajvfsUqseQRdwWayL8qQMKg'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Daily Adherence Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Daily Adherence', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFBFD4FF))),
                        const SizedBox(height: 4),
                        Text('$pct%', style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.trending_up, color: Color(0xFF86EFAC), size: 14),
                          const SizedBox(width: 4),
                          Text('+5% from last week', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF86EFAC))),
                        ]),
                      ]),
                      SizedBox(
                        width: 64, height: 64,
                        child: CustomPaint(
                          painter: _CircularProgressPainter(progress: pct / 100, strokeWidth: 4, backgroundColor: Colors.white.withValues(alpha: 0.2), progressColor: Colors.white),
                          child: const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 24)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // AI Health Trends Card
                GestureDetector(
                  onTap: () async {
                    if (_aiInsight == null && !_loadingInsight) {
                      setState(() => _loadingInsight = true);
                      final insight = await AiService().generateHealthInsights();
                      setState(() {
                        _aiInsight = insight;
                        _loadingInsight = false;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF93C5FD), size: 18),
                        const SizedBox(width: 8),
                        Text('AI HEALTH TRENDS', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFBFD4FF), letterSpacing: 0.5)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                              Text('Chat', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                            ]),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      if (_loadingInsight)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(children: [
                              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))),
                              const SizedBox(height: 8),
                              Text('Generating insights...', style: GoogleFonts.manrope(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                            ]),
                          ),
                        )
                      else if (_aiInsight != null)
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_aiInsight!, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.85), height: 1.6)),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () async {
                              setState(() { _aiInsight = null; _loadingInsight = true; });
                              final insight = await AiService().generateHealthInsights();
                              setState(() { _aiInsight = insight; _loadingInsight = false; });
                            },
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.5), size: 14),
                              const SizedBox(width: 4),
                              Text('Refresh', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5))),
                            ]),
                          ),
                        ])
                      else
                        Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('WEEKLY PROGRESS', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            SizedBox(height: 32, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              _bar(0.4, false), const SizedBox(width: 6),
                              _bar(0.6, false), const SizedBox(width: 6),
                              _bar(0.55, false), const SizedBox(width: 6),
                              _bar(0.8, false), const SizedBox(width: 6),
                              _bar(1.0, true),
                            ])),
                            const SizedBox(height: 6),
                            Text('Tap for AI insights ✨', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          ])),
                          Container(width: 1, height: 60, color: Colors.white.withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 12)),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('PEAK DOSING', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.verified, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text('Consistent', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                            ]),
                            const SizedBox(height: 6),
                            Text('Morning routine stable', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.6))),
                          ])),
                        ]),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bar(double height, bool isActive) {
    return Expanded(
      child: FractionallySizedBox(
        heightFactor: height, alignment: Alignment.bottomCenter,
        child: Container(decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
          boxShadow: isActive ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 8)] : [],
        )),
      ),
    );
  }

  Widget _buildStatsGrid(MedicationStore store) {
    final lowRefills = store.lowRefillCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(child: _statCard('Low Refills', '$lowRefills', 'Meds', Icons.inventory_2, const Color(0xFFDBEAFE), const Color(0xFF135BEC), const Color(0xFFEFF6FF))),
        const SizedBox(width: 16),
        Expanded(child: _statCard('Alerts', 'On', 'Track', Icons.notifications_active, const Color(0xFFEDE9FE), const Color(0xFF7C3AED), const Color(0xFFF5F3FF))),
      ]),
    );
  }

  Widget _statCard(String title, String value, String unit, IconData icon, Color iconBg, Color iconColor, Color decorBg) {
    return Container(
      height: 130, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Stack(children: [
        Positioned(right: -32, top: -32, child: Container(width: 96, height: 96, decoration: BoxDecoration(color: decorBg, shape: BoxShape.circle))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 16)),
            const SizedBox(height: 8),
            Text(title.toUpperCase(), style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
          ]),
          RichText(text: TextSpan(children: [
            TextSpan(text: '$value ', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
            TextSpan(text: unit, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFF94A3B8))),
          ])),
        ]),
      ]),
    );
  }
}

class _MedicationsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MedicationStore(),
      builder: (context, _) {
        final store = MedicationStore();
        final meds = store.medications;

        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Today's Medications", style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              TextButton(onPressed: () {}, child: Text('See All', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF135BEC)))),
            ]),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: meds.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(children: [
                    Icon(Icons.medication_outlined, size: 48, color: const Color(0xFFCBD5E1)),
                    const SizedBox(height: 12),
                    Text('No medications yet', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    Text('Tap + to add your first medication', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFFCBD5E1))),
                  ]),
                )
              : Column(
                  children: meds.asMap().entries.map((entry) {
                    final i = entry.key;
                    final m = entry.value;
                    String btnStyle;
                    if (m.takenToday) {
                      btnStyle = 'outline';
                    } else if (i == 0 || meds.take(i).every((prev) => prev.takenToday)) {
                      btnStyle = 'primary';
                    } else {
                      btnStyle = 'disabled';
                    }
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < meds.length - 1 ? 16 : 0),
                      child: Opacity(
                        opacity: btnStyle == 'disabled' ? 0.75 : 1.0,
                        child: _medCard(context, m, btnStyle),
                      ),
                    );
                  }).toList(),
                ),
          ),
        ]);
      },
    );
  }

  Widget _medCard(BuildContext context, Medication m, String btnStyle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(children: [
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: m.bgColor, borderRadius: BorderRadius.circular(14)), child: Icon(m.icon, color: m.color, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(m.displayDosage, style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF94A3B8))),
          ])),
          IconButton(
            onPressed: () async {
              final result = await showModalBottomSheet<Medication>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddMedicationSheet(existing: m),
              );
              if (result != null) {
                MedicationStore().update(m.id, result);
              }
            },
            icon: const Icon(Icons.edit, size: 20, color: Color(0xFF94A3B8)),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFF1F5F9), height: 1),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.schedule, size: 20, color: m.color),
            const SizedBox(width: 8),
            Text(m.displayTime, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
          ]),
          _btn(btnStyle, m.id),
        ]),
        // Refill indicator
        if (m.isLowRefill) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
              const SizedBox(width: 4),
              Text('${m.refillCount} pills remaining', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _btn(String style, String medId) {
    final store = MedicationStore();
    if (style == 'primary') {
      return Container(
        decoration: BoxDecoration(color: const Color(0xFF135BEC), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: const Color(0xFF135BEC).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]),
        child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(10), onTap: () => store.toggleTaken(medId), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text('Log Now', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))))),
      );
    } else if (style == 'outline') {
      return Container(
        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBBF7D0))),
        child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(10), onTap: () => store.toggleTaken(medId), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: 6),
          Text('Taken', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
        ])))),
      );
    } else {
      return Container(
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text('Log Now', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)))),
      );
    }
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _CircularProgressPainter({required this.progress, required this.strokeWidth, required this.backgroundColor, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final bgPaint = Paint()..color = backgroundColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);
    final progressPaint = Paint()..color = progressColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
