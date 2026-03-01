import 'dart:math';
import 'package:flutter/material.dart';
import '../models/medication.dart';

enum MedicationStatus { taken, missed, scheduled, skipped }

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
}

class HistoryStore extends ChangeNotifier {
  static final HistoryStore _instance = HistoryStore._();
  factory HistoryStore() => _instance;

  late List<HistoryEvent> _events;
  late double _weeklyAdherence;
  late double _lastWeeklyAdherence;

  HistoryStore._() {
    _generateMockData();
  }

  List<HistoryEvent> get allEvents => List.unmodifiable(_events);
  double get weeklyAdherence => _weeklyAdherence;
  double get adherenceDifference => _weeklyAdherence - _lastWeeklyAdherence;

  /// Returns adherence data points for the past 7 days (including today).
  /// [0] is 6 days ago, [6] is today. Values are 0.0 to 1.0.
  List<double> get weeklyChartData {
    final now = DateTime.now();
    final data = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final dayEvents = _events.where((e) =>
          e.scheduledTime.year == date.year &&
          e.scheduledTime.month == date.month &&
          e.scheduledTime.day == date.day);

      if (dayEvents.isEmpty) {
        data[i] = 0.0;
        continue;
      }

      int taken = dayEvents.where((e) => e.status == MedicationStatus.taken).length;
      int totalScorable = dayEvents.where((e) =>
          e.status == MedicationStatus.taken || e.status == MedicationStatus.missed).length;

      data[i] = totalScorable == 0 ? 0.0 : taken / totalScorable;
    }
    return data;
  }

  void _generateMockData() {
    _events = [];
    final now = DateTime.now();
    final rng = Random();

    // Past 7 days of events
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));

      // Morning Med (Metformin) - 8:00 AM
      bool takenMorning = rng.nextDouble() > 0.15; // 85% chance
      _events.add(HistoryEvent(
        id: 'evt_${i}_m',
        medicationId: 'm1',
        medicationName: 'Metformin',
        dosage: '500mg • After Breakfast',
        scheduledTime: DateTime(date.year, date.month, date.day, 8, 0),
        actualTime: takenMorning ? DateTime(date.year, date.month, date.day, 8, rng.nextInt(30)) : null,
        status: i == 0 && now.hour < 8 ? MedicationStatus.scheduled : (takenMorning ? MedicationStatus.taken : MedicationStatus.missed),
        preset: medPresets[0], // Pill
        refillCount: 42 - i,
        refillTotal: 60,
      ));

      // Afternoon Med (Lisinopril) - 2:00 PM
      bool takenAft = rng.nextDouble() > 0.25; // 75% chance
      _events.add(HistoryEvent(
        id: 'evt_${i}_a',
        medicationId: 'm2',
        medicationName: 'Lisinopril',
        dosage: '10mg • With Food',
        scheduledTime: DateTime(date.year, date.month, date.day, 14, 0),
        actualTime: takenAft ? DateTime(date.year, date.month, date.day, 14, rng.nextInt(45)) : null,
        status: i == 0 && now.hour < 14 ? MedicationStatus.scheduled : (takenAft ? MedicationStatus.taken : MedicationStatus.missed),
        preset: medPresets[3], // Tablet
        refillCount: 12 - i,
        refillTotal: 30,
      ));

      // Evening Med (Atorvastatin) - 8:00 PM
      bool takenEve = rng.nextDouble() > 0.1; // 90% chance
      bool skipped = rng.nextDouble() < 0.05; // 5% chance skipped
      _events.add(HistoryEvent(
        id: 'evt_${i}_e',
        medicationId: 'm3',
        medicationName: 'Atorvastatin',
        dosage: '20mg • Before Sleep',
        scheduledTime: DateTime(date.year, date.month, date.day, 20, 0),
        actualTime: takenEve && !skipped ? DateTime(date.year, date.month, date.day, 20, rng.nextInt(20)) : null,
        status: i == 0 && now.hour < 20 
            ? MedicationStatus.scheduled 
            : (skipped ? MedicationStatus.skipped : (takenEve ? MedicationStatus.taken : MedicationStatus.missed)),
        preset: medPresets[1], // Capsule
        refillCount: 20 - i,
        refillTotal: 30,
      ));
    }

    // Sort descending by time
    _events.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    // Calculate mock adherence stats
    _weeklyAdherence = 0.825; // 82.5%
    _lastWeeklyAdherence = 0.70; // 70% (difference is +12.5%)
  }

  // Real app would have:
  // Future<void> fetchEvents() async { ... }
}
