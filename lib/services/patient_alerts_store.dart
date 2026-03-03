import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/patient_info.dart'; // Re-use ChatMessage
import 'medication_store.dart';

enum AlertStatus { missed, delayed, scheduled, resolved, snoozed }

class PatientAlert {
  final String id;
  final String title;
  final String message;
  final DateTime scheduledTime;
  final DateTime? actionTime;
  AlertStatus status;
  final Color baseColor;

  PatientAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.scheduledTime,
    this.actionTime,
    required this.status,
    required this.baseColor,
  });

  bool get isToday {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }
}

class PatientAlertsStore extends ChangeNotifier {
  static final PatientAlertsStore _instance = PatientAlertsStore._();
  factory PatientAlertsStore() => _instance;

  late List<PatientAlert> _alerts;
  late List<ChatMessage> _messages;
  Timer? _checkTimer;

  PatientAlertsStore._() {
    _generateMockData();
    // Start checking medication schedules every 60 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkMedicationSchedules();
    });
    // Also check immediately on creation (after a short delay for MedicationStore to init)
    Future.delayed(const Duration(seconds: 3), () => _checkMedicationSchedules());
  }

  List<PatientAlert> get allAlerts => List.unmodifiable(_alerts);
  List<ChatMessage> get chatMessages => List.unmodifiable(_messages);

  List<PatientAlert> get activeAlerts => _alerts
      .where((a) => a.status == AlertStatus.missed || a.status == AlertStatus.delayed || a.status == AlertStatus.scheduled)
      .toList()
    ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

  List<PatientAlert> get resolvedAlerts => _alerts
      .where((a) => a.status == AlertStatus.resolved || a.status == AlertStatus.snoozed)
      .toList();

  /// Checks all medications and auto-generates alerts based on schedule vs current time.
  void _checkMedicationSchedules() {
    final meds = MedicationStore().medications;
    if (meds.isEmpty) return;

    final now = DateTime.now();
    bool changed = false;

    for (final med in meds) {
      // Parse the medication time (e.g. "08:00 AM", "02:30 PM")
      final scheduledTime = _parseMedTime(med.time, now);
      if (scheduledTime == null) continue;

      // Create a unique alert ID based on med ID + today's date
      final alertId = 'auto_${med.id}_${now.year}${now.month}${now.day}';

      // Skip if alert already exists for this med today
      if (_alerts.any((a) => a.id == alertId)) continue;

      final diffMinutes = now.difference(scheduledTime).inMinutes;

      if (!med.takenToday && diffMinutes > 5) {
        // Medication time passed by 5+ minutes and not taken → MISSED
        _alerts.add(PatientAlert(
          id: alertId,
          title: '${med.name} ${med.dosage}',
          message: 'Scheduled: ${med.time} — Not taken yet',
          scheduledTime: scheduledTime,
          status: AlertStatus.missed,
          baseColor: const Color(0xFFDC2626),
        ));
        changed = true;
      } else if (med.takenToday && diffMinutes > 15) {
        // Was taken, but more than 15 min after schedule → DELAYED
        _alerts.add(PatientAlert(
          id: alertId,
          title: '${med.name} ${med.dosage}',
          message: 'Scheduled: ${med.time} — Taken late',
          scheduledTime: scheduledTime,
          status: AlertStatus.delayed,
          baseColor: const Color(0xFFD97706),
        ));
        changed = true;
      } else if (!med.takenToday && diffMinutes >= -30 && diffMinutes <= 0) {
        // Coming up within the next 30 minutes → SCHEDULED
        _alerts.add(PatientAlert(
          id: alertId,
          title: '${med.name} ${med.dosage}',
          message: 'Coming up at ${med.time}',
          scheduledTime: scheduledTime,
          status: AlertStatus.scheduled,
          baseColor: const Color(0xFF135BEC),
        ));
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  /// Parses a time string like "08:00 AM" or "02:30 PM" into a DateTime for today.
  DateTime? _parseMedTime(String timeStr, DateTime today) {
    try {
      timeStr = timeStr.trim().toUpperCase();
      final isPM = timeStr.contains('PM');
      final isAM = timeStr.contains('AM');
      final cleaned = timeStr.replaceAll(RegExp(r'[APM\s]'), '');
      final parts = cleaned.split(':');
      if (parts.length < 2) return null;

      var hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      return DateTime(today.year, today.month, today.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Force-check medication schedules (can be called externally)
  void refreshAlerts() {
    _checkMedicationSchedules();
  }

  void _generateMockData() {
    final now = DateTime.now();
    _alerts = [
      PatientAlert(
        id: 'a1',
        title: 'Atorvastatin 20mg',
        message: 'Scheduled: 2:00 PM',
        scheduledTime: DateTime(now.year, now.month, now.day, 14, 0),
        status: AlertStatus.missed,
        baseColor: const Color(0xFFDC2626), // Red
      ),
      PatientAlert(
        id: 'a2',
        title: 'Aspirin 81mg',
        message: 'Scheduled: 8:00 AM   ✓ Taken: 9:15 AM',
        scheduledTime: DateTime(now.year, now.month, now.day, 8, 0),
        status: AlertStatus.delayed,
        baseColor: const Color(0xFFD97706), // Orange
      ),
      PatientAlert(
        id: 'a3',
        title: 'Vitamin D 1000 IU',
        message: 'Scheduled: 1:00 PM',
        scheduledTime: DateTime(now.year, now.month, now.day, 13, 0),
        status: AlertStatus.scheduled,
        baseColor: const Color(0xFF135BEC), // Blue
      ),
      PatientAlert(
        id: 'a4',
        title: 'Metformin 500mg',
        message: 'Scheduled: 8:00 PM',
        scheduledTime: DateTime(now.year, now.month, now.day - 1, 20, 0),
        status: AlertStatus.missed,
        baseColor: const Color(0xFFDC2626), // Red
      ),
    ];

    _messages = [
      ChatMessage(
        id: 'm1',
        senderId: 'caregiver_1',
        senderName: 'Dr. Sarah (Caregiver)',
        text: 'Hi there! I noticed you missed your Atorvastatin yesterday. Everything okay?',
        timestamp: now.subtract(const Duration(minutes: 45)),
        isFromCaregiver: true,
      ),
      ChatMessage(
        id: 'm2',
        senderId: 'patient_1',
        senderName: 'You',
        text: 'Yes, sorry! I fell asleep early. I will make sure to take it on time today.',
        timestamp: now.subtract(const Duration(minutes: 30)),
        isFromCaregiver: false,
      ),
      ChatMessage(
        id: 'm3',
        senderId: 'caregiver_1',
        senderName: 'Dr. Sarah (Caregiver)',
        text: 'Thank you for letting me know. Let\'s aim for a good streak this week! 🌟',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isFromCaregiver: true,
      ),
    ];
  }

  void resolveAlert(String id) {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      _alerts[idx].status = AlertStatus.resolved;
      notifyListeners();
      
      debugPrint('Alert $id RESOLVED — synced to Caregiver Dashboard.');
    }
  }

  void snoozeAlert(String id) {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      _alerts[idx].status = AlertStatus.snoozed;
      notifyListeners();

      debugPrint('Alert $id SNOOZED — synced to Caregiver Dashboard.');
    }
  }

  void sendMessage(String text) {
    _messages.insert(0, ChatMessage(
      id: Random().nextInt(10000).toString(),
      senderId: 'patient_1',
      senderName: 'You',
      text: text,
      timestamp: DateTime.now(),
      isFromCaregiver: false,
    ));
    notifyListeners();

    // Auto-reply mock
    Future.delayed(const Duration(seconds: 2), () {
      _messages.insert(0, ChatMessage(
        id: Random().nextInt(10000).toString(),
        senderId: 'caregiver_1',
        senderName: 'Dr. Sarah (Caregiver)',
        text: 'Got it. I\'ll update your record.', // Simple generic reply
        timestamp: DateTime.now(),
        isFromCaregiver: true,
      ));
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
