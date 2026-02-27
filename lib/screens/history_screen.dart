import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/medication_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Taken', 'Missed', 'Skipped'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MedicationStore(),
      builder: (context, _) {
        final store = MedicationStore();
        final meds = store.medications;
        final takenCount = meds.where((m) => m.takenToday).length;
        final missedCount = meds.where((m) => !m.takenToday).length;

        return Column(
          children: [
            _buildHeader(takenCount, missedCount),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildLogTab(), _buildStatsTab(takenCount, meds.length)],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int taken, int missed) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF135BEC), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('History', style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.file_download_outlined, color: Colors.white, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Track your medication adherence', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFBFD4FF))),
              const SizedBox(height: 20),
              Row(children: [
                _chip(Icons.check_circle, '$taken', 'Taken', const Color(0xFF86EFAC)),
                const SizedBox(width: 10),
                _chip(Icons.cancel, '$missed', 'Pending', const Color(0xFFFCA5A5)),
                const SizedBox(width: 10),
                _chip(Icons.skip_next, '0', 'Skipped', const Color(0xFFFDE68A)),
              ]),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF135BEC), unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                  labelStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
                  tabs: const [Tab(text: 'Log', height: 40), Tab(text: 'Statistics', height: 40)],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 16), const SizedBox(width: 6),
          Text(count, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(width: 4),
          Flexible(child: Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.6)), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _buildLogTab() {
    final store = MedicationStore();
    final meds = store.medications;
    
    // Build today's entries from actual medications
    final todayEntries = meds.map((m) {
      return {
        'name': m.name,
        'dose': m.dosage,
        'time': m.takenToday ? m.time : '—',
        'status': m.takenToday ? 'taken' : 'missed',
        'icon': m.icon,
        'color': m.color.toARGB32(),
        'bg': m.bgColor.toARGB32(),
      };
    }).toList();

    final takenCount = meds.where((m) => m.takenToday).length;
    final pct = meds.isEmpty ? 0 : (takenCount / meds.length * 100).round();

    final days = [
      {'date': 'Today, Feb 25', 'pct': pct, 'entries': todayEntries},
      {'date': 'Yesterday, Feb 24', 'pct': 100, 'entries': [
        {'name': 'Amoxicillin', 'dose': '500mg', 'time': '07:55 AM', 'status': 'taken', 'icon': Icons.medication, 'color': 0xFF135BEC, 'bg': 0xFFEFF6FF},
        {'name': 'Vitamin D', 'dose': '1000 IU', 'time': '01:03 PM', 'status': 'taken', 'icon': Icons.water_drop, 'color': 0xFF7C3AED, 'bg': 0xFFF5F3FF},
        {'name': 'Ibuprofen', 'dose': '200mg', 'time': '09:30 PM', 'status': 'taken', 'icon': Icons.medication, 'color': 0xFF16A34A, 'bg': 0xFFF0FDF4},
      ]},
      {'date': 'Sun, Feb 23', 'pct': 67, 'entries': [
        {'name': 'Amoxicillin', 'dose': '500mg', 'time': '08:20 AM', 'status': 'late', 'icon': Icons.medication, 'color': 0xFF135BEC, 'bg': 0xFFEFF6FF},
        {'name': 'Vitamin D', 'dose': '1000 IU', 'time': '—', 'status': 'skipped', 'icon': Icons.water_drop, 'color': 0xFF7C3AED, 'bg': 0xFFF5F3FF},
      ]},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: SizedBox(height: 36, child: ListView.separated(
            scrollDirection: Axis.horizontal, itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final sel = _selectedFilter == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF135BEC) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? const Color(0xFF135BEC) : const Color(0xFFE2E8F0)),
                  ),
                  child: Center(child: Text(_filters[i], style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF64748B)))),
                ),
              );
            },
          )),
        ),
        ...days.map((day) {
          final dayPct = day['pct'] as int;
          final entries = day['entries'] as List;
          
          // Filter entries based on selected filter
          final filteredEntries = _selectedFilter == 0 
            ? entries 
            : entries.where((e) {
                final status = (e as Map)['status'] as String;
                switch (_selectedFilter) {
                  case 1: return status == 'taken';
                  case 2: return status == 'missed';
                  case 3: return status == 'skipped';
                  default: return true;
                }
              }).toList();

          if (filteredEntries.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(day['date'] as String, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: dayPct == 100 ? const Color(0xFFF0FDF4) : dayPct >= 80 ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                  child: Text('$dayPct%', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: dayPct == 100 ? const Color(0xFF16A34A) : dayPct >= 80 ? const Color(0xFFD97706) : const Color(0xFFDC2626))),
                ),
              ]),
              const SizedBox(height: 12),
              ...filteredEntries.map((e) {
                final m = e as Map<String, dynamic>;
                return _entryCard(m['name'], m['dose'], m['time'], m['status'], m['icon'] as IconData, Color(m['color'] as int), Color(m['bg'] as int));
              }),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _entryCard(String name, String dose, String time, String status, IconData icon, Color color, Color bg) {
    final Map<String, List<dynamic>> s = {
      'taken': [const Color(0xFFF0FDF4), const Color(0xFF16A34A), 'Taken', Icons.check_circle],
      'late': [const Color(0xFFFFFBEB), const Color(0xFFD97706), 'Late', Icons.schedule],
      'missed': [const Color(0xFFFEF2F2), const Color(0xFFDC2626), 'Missed', Icons.cancel],
      'skipped': [const Color(0xFFF8FAFC), const Color(0xFF94A3B8), 'Skipped', Icons.skip_next],
    };
    final st = s[status]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text('$dose • $time', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF94A3B8))),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: st[0] as Color, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(st[3] as IconData, color: st[1] as Color, size: 13), const SizedBox(width: 4),
            Text(st[2] as String, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: st[1] as Color)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatsTab(int takenToday, int totalToday) {
    final adherence = totalToday == 0 ? 0 : (takenToday / totalToday * 100).round();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(children: [
        _weeklyChart(),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _statCard('Avg Adherence', '$adherence%', Icons.trending_up, const Color(0xFF16A34A), const Color(0xFFF0FDF4))),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Streak', '5 days', Icons.local_fire_department, const Color(0xFFEA580C), const Color(0xFFFFF7ED))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statCard('On Time', '92%', Icons.schedule, const Color(0xFF135BEC), const Color(0xFFEFF6FF))),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Best Streak', '14 days', Icons.emoji_events, const Color(0xFFD97706), const Color(0xFFFFFBEB))),
        ]),
        const SizedBox(height: 16),
        _breakdownCard(takenToday, totalToday),
      ]),
    );
  }

  Widget _weeklyChart() {
    final data = [['Mon',0.75],['Tue',0.9],['Wed',1.0],['Thu',0.67],['Fri',0.85],['Sat',1.0],['Sun',0.85]];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Weekly Adherence', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
        const SizedBox(height: 4),
        Text('Feb 19 - Feb 25', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF94A3B8))),
        const SizedBox(height: 24),
        SizedBox(height: 140, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children:
          data.asMap().entries.map((e) {
            final isToday = e.key == data.length - 1;
            return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('${((e.value[1] as double) * 100).toInt()}%', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 4),
              Expanded(child: FractionallySizedBox(heightFactor: e.value[1] as double, alignment: Alignment.bottomCenter, child: Container(decoration: BoxDecoration(
                gradient: isToday ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF135BEC), Color(0xFF7C3AED)]) : null,
                color: isToday ? null : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(6))))),
              const SizedBox(height: 8),
              Text(e.value[0] as String, style: GoogleFonts.manrope(fontSize: 10, fontWeight: isToday ? FontWeight.w700 : FontWeight.w500, color: isToday ? const Color(0xFF135BEC) : const Color(0xFF94A3B8))),
            ])));
          }).toList()
        )),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 16)),
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
      ]),
    );
  }

  Widget _breakdownCard(int taken, int total) {
    final missed = total - taken;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Today\'s Breakdown', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
        const SizedBox(height: 20),
        _breakRow('Taken on time', taken, total, const Color(0xFF16A34A)),
        const SizedBox(height: 12),
        _breakRow('Pending', missed, total, const Color(0xFFD97706)),
      ]),
    );
  }

  Widget _breakRow(String label, int count, int total, Color color) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
        ]),
        Text('$count / $total', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: total > 0 ? count / total : 0, minHeight: 6, backgroundColor: const Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation(color))),
    ]);
  }
}
