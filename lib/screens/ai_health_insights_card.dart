import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiHealthInsightsCard extends StatefulWidget {
  const AiHealthInsightsCard({super.key});

  @override
  State<AiHealthInsightsCard> createState() => _AiHealthInsightsCardState();
}

class _AiHealthInsightsCardState extends State<AiHealthInsightsCard> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isCaregiverRequestPending = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Fake TTS state
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    
    // Start entry animation after a slight delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _applyChange() async {
    // Caregiver approval mockup flow
    setState(() => _isCaregiverRequestPending = true);
    
    // Show request sent snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Request sent to Caregiver (ayisha) - Waiting for approval...',
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF7C3AED),
        duration: const Duration(seconds: 3),
      ),
    );

    // Mock waiting for caregiver decision
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      // Mock caregiver approved
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF34D399)),
              const SizedBox(width: 8),
              Text('Change Approved', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'Caregiver ayisha has approved your requested routine change. Your schedule has been updated.',
            style: GoogleFonts.manrope(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: GoogleFonts.manrope(color: const Color(0xFF93C5FD), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      setState(() => _isCaregiverRequestPending = false);
    }
  }

  void _listenToInsights() async {
    if (_isListening) return;
    setState(() => _isListening = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Playing insight audio...', style: GoogleFonts.manrope(fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // fake TTS delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF135BEC)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative background star
              Positioned(
                top: -20,
                right: -20,
                child: Icon(
                  Icons.auto_awesome,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Color(0xFFFDE047), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Health Insights',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Tabs
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: EdgeInsets.zero,
                        labelColor: const Color(0xFF7C3AED),
                        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                        labelStyle: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800),
                        unselectedLabelStyle: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'SUMMARY'),
                          Tab(text: 'INTERACTIONS'),
                          Tab(text: 'ADVICE'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Tab Content
                    SizedBox(
                      height: 80,
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildInsightText(
                            "You are at the start of your daily routine; maintaining consistency with your morning dose improves overall health outcomes.",
                          ),
                          _buildInsightText(
                            "No known negative interactions detected between your current medications. Safe to proceed as prescribed.",
                          ),
                          _buildInsightText(
                            "Take Aspirin with a full glass of water. Consider taking it with food to avoid stomach upset.",
                          ),
                        ],
                      ),
                    ),
                    
                    // View More Link
                    GestureDetector(
                      onTap: () {
                        // In a real app, this would push to a Detailed AI Insights page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening detailed insights...')),
                        );
                      },
                      child: Text(
                        'View More',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        // Listen Button
                        GestureDetector(
                          onTap: _listenToInsights,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isListening ? Icons.graphic_eq : Icons.volume_up, 
                                  color: Colors.white, 
                                  size: 16
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Listen',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Apply Change Button
                        Expanded(
                          child: GestureDetector(
                            onTap: _isCaregiverRequestPending ? null : _applyChange,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isCaregiverRequestPending ? Icons.hourglass_empty : Icons.check,
                                    color: const Color(0xFF7C3AED),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isCaregiverRequestPending ? 'Sending...' : 'Apply Change',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF7C3AED),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightText(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1.5,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
