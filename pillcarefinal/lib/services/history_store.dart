import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'firestore_service.dart';
import 'medication_store.dart';

enum MedicationStatus { taken, missed, scheduled, skipped }

// ──────────────────────────────────────────────────────────────────────────────
// HistoryEvent model
// ──────────────────────────────────────────────────────────────────────────────

class HistoryEvent {
  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final DateTime scheduledTime;
  final DateTime? actualTime;
  final MedicationStatus status;
  final MedPreset preset;
  final int refillCount;
  final int refillTotal;

  HistoryEvent({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTime,
    this.actualTime,
    required this.status,
    required this.preset,
    required this.refillCount,
    required this.refillTotal,
  });

  bool get isToday {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }

  /// Serialises this event so it can be written to Firestore history collection.
  Map<String, dynamic> toFirestore() => {
    'medicationId': medicationId,
    'medicationName': medicationName,
    'dosage': dosage,
    'scheduledTime': Timestamp.fromDate(scheduledTime),
    'actualTime': actualTime != null ? Timestamp.fromDate(actualTime!) : null,
    'status': status.name,
    'presetLabel': preset.label,
    'refillCount': refillCount,
    'refillTotal': refillTotal,
  };
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

/// Maps a time string ("08:00 AM") to the hardware RTDB slot name.
/// Hardware has three slots: morning, evening, night.
String _timeToHardwareSlot(String timeStr) {
  try {
    final parts = timeStr.trim().split(':');
    int hour = int.parse(parts[0].trim());
    final rest = parts[1].trim().toUpperCase();
    if (rest.contains('PM') && hour != 12) hour += 12;
    if (rest.contains('AM') && hour == 12) hour = 0;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 20) return 'evening';
    return 'night';
  } catch (_) {
    return 'morning';
  }
}

/// Builds a DateTime for the given calendar date + time string ("08:00 AM").
DateTime _scheduledDateTime(DateTime date, String timeStr) {
  try {
    final parts = timeStr.trim().split(':');
    int hour = int.parse(parts[0].trim());
    final rest = parts[1].trim();
    int minute = int.parse(rest.substring(0, 2));
    final period = rest.length > 2 ? rest.substring(2).trim().toUpperCase() : '';
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  } catch (_) {
    return DateTime(date.year, date.month, date.day, 8, 0);
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

MedPreset _presetFromMed(Medication med) =>
    MedPreset(med.name, med.icon, med.color, med.bgColor);

// ──────────────────────────────────────────────────────────────────────────────
// HistoryStore
// ──────────────────────────────────────────────────────────────────────────────

class HistoryStore extends ChangeNotifier {
  static final HistoryStore _instance = HistoryStore._();
  factory HistoryStore() => _instance;

  final FirestoreService _firestoreService = FirestoreService();
  final MedicationStore _medStore = MedicationStore();

  List<HistoryEvent> _events = [];
  double _weeklyAdherence = 0.0;
  double _lastWeeklyAdherence = 0.0;
  bool _isLoading = true;
  String? _error;

  StreamSubscription<List<Map<String, dynamic>>>? _historySub;

  HistoryStore._();

  List<HistoryEvent> get allEvents => List.unmodifiable(_events);
  double get weeklyAdherence => _weeklyAdherence;
  double get adherenceDifference => _weeklyAdherence - _lastWeeklyAdherence;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Returns adherence data points for the past 7 days (including today).
  /// [0] = 6 days ago, [6] = today, values 0.0–1.0.
  List<double> get weeklyChartData {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final dayEvts = _events.where((e) => _isSameDay(e.scheduledTime, date));
      if (dayEvts.isEmpty) return 0.0;
      final scorable = dayEvts.where((e) =>
          e.status == MedicationStatus.taken ||
          e.status == MedicationStatus.missed);
      if (scorable.isEmpty) return 0.0;
      return scorable.where((e) => e.status == MedicationStatus.taken).length /
          scorable.length;
    });
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Starts listening to real Firestore history + combines with today's
  /// live data from Firebase RTDB (hardware-reported status).
  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _historySub?.cancel();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _events = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get today's RTDB status from the hardware once (non-blocking snapshot).
      final rtdbStatus = await _readRtdbStatus(uid);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Stream Firestore history; on every update rebuild the full list.
      _historySub = _firestoreService.streamHistory(days: 7).listen(
        (historyMaps) {
          final meds = _medStore.medications;

          // ── Today's events: built from real medication list + RTDB status ──
          final List<HistoryEvent> todayEvents = meds.map((med) {
            final slot = _timeToHardwareSlot(med.time);
            // Prefer RTDB (hardware-confirmed), fall back to Firestore takenToday.
            final bool isTaken = rtdbStatus[slot] ?? med.takenToday;
            final scheduledDT = _scheduledDateTime(todayDate, med.time);
            final now = DateTime.now();

            MedicationStatus status;
            if (isTaken) {
              status = MedicationStatus.taken;
            } else if (scheduledDT.isAfter(now)) {
              status = MedicationStatus.scheduled;
            } else {
              status = MedicationStatus.missed;
            }

            return HistoryEvent(
              id: 'today_${med.id}',
              medicationId: med.id,
              medicationName: med.name,
              dosage: med.displayDosage,
              scheduledTime: scheduledDT,
              actualTime: isTaken ? now : null,
              status: status,
              preset: _presetFromMed(med),
              refillCount: med.refillCount,
              refillTotal: med.refillTotal,
            );
          }).toList();

          // ── Past events: from Firestore history collection ─────────────────
          final List<HistoryEvent> pastEvents = historyMaps
              .map(_mapToEvent)
              .whereType<HistoryEvent>()
              .where((e) => !_isSameDay(e.scheduledTime, todayDate))
              .toList();

          _events = [...todayEvents, ...pastEvents]
            ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

          _calculateAdherence();
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persists a dose event to Firestore (call this when you want to record
  /// a taken/missed event that future history loads will show).
  Future<void> recordEvent(HistoryEvent event) async {
    await _firestoreService.addHistoryEvent(event.toFirestore());
  }

  @override
  void dispose() {
    _historySub?.cancel();
    super.dispose();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Reads hardware slot status from Firebase RTDB.
  /// Returns e.g. { 'morning': true, 'evening': false, 'night': false }.
  Future<Map<String, bool>> _readRtdbStatus(String uid) async {
    try {
      final db = FirebaseDatabase.instance;
      final snapshot = await db.ref('users/$uid/status').get();
      if (!snapshot.exists || snapshot.value == null) return {};
      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      return raw.map((k, v) => MapEntry(k, v == true));
    } catch (_) {
      // RTDB not configured or unreachable — fall back to Firestore data.
      return {};
    }
  }

  HistoryEvent? _mapToEvent(Map<String, dynamic> m) {
    try {
      final scheduledTS = m['scheduledTime'] as Timestamp?;
      if (scheduledTS == null) return null;
      final scheduled = scheduledTS.toDate();
      final actualTS = m['actualTime'] as Timestamp?;
      final statusStr = m['status'] as String? ?? 'scheduled';
      final status = MedicationStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => MedicationStatus.scheduled,
      );
      final presetLabel = m['presetLabel'] as String? ?? 'Pill';
      final preset = medPresets.firstWhere(
        (p) => p.label == presetLabel,
        orElse: () => medPresets[0],
      );
      return HistoryEvent(
        id: m['id'] as String? ?? '${scheduled.millisecondsSinceEpoch}',
        medicationId: m['medicationId'] as String? ?? '',
        medicationName: m['medicationName'] as String? ?? 'Unknown',
        dosage: m['dosage'] as String? ?? '',
        scheduledTime: scheduled,
        actualTime: actualTS?.toDate(),
        status: status,
        preset: preset,
        refillCount: (m['refillCount'] as num?)?.toInt() ?? 0,
        refillTotal: (m['refillTotal'] as num?)?.toInt() ?? 30,
      );
    } catch (_) {
      return null;
    }
  }

  void _calculateAdherence() {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(const Duration(days: 7));
    final lastWeekStart = now.subtract(const Duration(days: 14));

    double _rate(DateTime from, DateTime to) {
      final evts = _events.where((e) =>
          e.scheduledTime.isAfter(from) &&
          e.scheduledTime.isBefore(to) &&
          (e.status == MedicationStatus.taken ||
              e.status == MedicationStatus.missed));
      if (evts.isEmpty) return 0.0;
      return evts.where((e) => e.status == MedicationStatus.taken).length /
          evts.length;
    }

    _weeklyAdherence = _rate(thisWeekStart, now);
    _lastWeeklyAdherence = _rate(lastWeekStart, thisWeekStart);
  }
}
