import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/firestore_service.dart';

// ════════════════════════════════════════════════════════════════════════════
//  PATIENT REPORT PAGE
//  Add medical conditions → AI generates a clinical summary
// ════════════════════════════════════════════════════════════════════════════

class PatientReportPage extends StatefulWidget {
  const PatientReportPage({super.key});

  @override
  State<PatientReportPage> createState() => _PatientReportPageState();
}

class _PatientReportPageState extends State<PatientReportPage>
    with SingleTickerProviderStateMixin {
  final _firestore = FirestoreService();
  final _conditionCtrl = TextEditingController();

  List<String> _conditions = [];
  String _aiDescription = '';
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isGenerating = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadReport();
  }

  @override
  void dispose() {
    _conditionCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final report = await _firestore.getHealthReport(
        _firestore.currentUserId ?? '',
      );
      if (report != null && mounted) {
        setState(() {
          _conditions = List<String>.from(report['conditions'] as List? ?? []);
          _aiDescription = report['aiDescription'] as String? ?? '';
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward();
    }
  }

  void _addCondition() {
    final text = _conditionCtrl.text.trim();
    if (text.isEmpty) return;
    if (_conditions.contains(text)) return;
    setState(() {
      _conditions.add(text);
      _conditionCtrl.clear();
    });
  }

  void _removeCondition(String c) => setState(() => _conditions.remove(c));

  Future<void> _generateAiDescription() async {
    if (_conditions.isEmpty) {
      _showSnack('Add at least one condition first.', isError: true);
      return;
    }
    setState(() { _isGenerating = true; _aiDescription = ''; });

    const baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
    final apiKey = 'your_groq_api_key_here'; // Uses the env key via ai_service
    // NOTE: In production use AiService; here we call directly for independence
    try {
      final conditionList = _conditions.join(', ');
      final prompt =
          'You are a clinical assistant. Write a concise, easy-to-understand health '
          'summary paragraph (3-5 sentences) for a patient with the following conditions: '
          '$conditionList. '
          'Focus on key health considerations, common medication interactions to watch, '
          'and general lifestyle tips. Do not diagnose or prescribe.';

      final resp = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.6,
          'max_tokens': 300,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final content = data['choices']?[0]?['message']?['content'] as String? ?? '';
        setState(() => _aiDescription = content.trim());
      } else {
        setState(() => _aiDescription =
            'Unable to generate summary. Please check your API key.');
      }
    } catch (e) {
      setState(() => _aiDescription = 'Error generating summary: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _firestore.saveHealthReport(
        conditions: _conditions,
        aiDescription: _aiDescription,
      );
      _showSnack('Health report saved!');
    } catch (e) {
      _showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1117) : const Color(0xFFF6F6F8);
    final cardBg = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF2D3142) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 28),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const Spacer(),
                          Text('Health Report',
                              style: GoogleFonts.manrope(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const Spacer(),
                          if (_isSaving)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          else
                            TextButton(
                              onPressed: _save,
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20))),
                              child: Text('Save',
                                  style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Track your medical conditions and get an AI-powered health summary visible to your caregiver.',
                          style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverFadeTransition(
              opacity: _fadeAnim,
              sliver: SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // — Add condition —
                    Text('YOUR CONDITIONS',
                        style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF135BEC),
                            letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _conditionCtrl,
                              style: GoogleFonts.manrope(
                                  fontSize: 14, color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'e.g. Hypertension, Diabetes',
                                hintStyle: GoogleFonts.manrope(
                                    color: textSecondary, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              onSubmitted: (_) => _addCondition(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _addCondition,
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF135BEC),
                                      Color(0xFF7C3AED)
                                    ]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_conditions.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _conditions
                            .map((c) => _ConditionChip(
                                  label: c,
                                  onRemove: () => _removeCondition(c),
                                  isDark: isDark,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // — Generate AI summary —
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1B4B)
                            : const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3730A3)
                              : const Color(0xFFDDD6FE),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFF135BEC)
                                  ]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('AI Health Summary',
                                        style: GoogleFonts.manrope(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary)),
                                    Text('Powered by Llama 3.3',
                                        style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            color: textSecondary)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _isGenerating
                                    ? null
                                    : _generateAiDescription,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                ),
                                child: _isGenerating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : Text('Generate',
                                        style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          if (_aiDescription.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Divider(color: Color(0xFFDDD6FE)),
                            const SizedBox(height: 10),
                            Text(_aiDescription,
                                style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: textPrimary,
                                    height: 1.6)),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Info note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF93C5FD).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 16, color: Color(0xFF135BEC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This report is visible to your linked caregiver. '
                              'Save after making changes.',
                              style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: const Color(0xFF1D4ED8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final bool isDark;

  const _ConditionChip({
    required this.label,
    required this.onRemove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E3A5F)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2D5A8E)
              : const Color(0xFF93C5FD),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }
}
