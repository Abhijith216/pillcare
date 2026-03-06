import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/patient_info.dart';
import 'firestore_service.dart';
import 'medication_store.dart';

enum AlertStatus { missed, delayed, scheduled, resolved, snoozed }

// ──────────────────────────────────────────────────────────────────────────────
// PatientAlert model
// ──────────────────────────────────────────────────────────────────────────────

class PatientAlert {
  /// Mutable so it can be updated after Firestore assigns a real document id.
  String id;
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

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'message': message,
    'scheduledTime': Timestamp.fromDate(scheduledTime),
    'actionTime': actionTime != null ? Timestamp.fromDate(actionTime!) : null,
    'status': status.name,
    'baseColorValue': baseColor.value,
  };

  static PatientAlert fromFirestore(Map<String, dynamic> m) {
    final scheduledTS = m['scheduledTime'] as Timestamp?;
    final actionTS = m['actionTime'] as Timestamp?;
    final statusStr = m['status'] as String? ?? 'scheduled';
    return PatientAlert(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? '',
      message: m['message'] as String? ?? '',
      scheduledTime: scheduledTS?.toDate() ?? DateTime.now(),
      actionTime: actionTS?.toDate(),
      status: AlertStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => AlertStatus.scheduled,
      ),
      baseColor: Color(m['baseColorValue'] as int? ?? 0xFF135BEC),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PatientAlertsStore
// ────────────────────────────────────────────────────────────────────────────

class PatientAlertsStore extends ChangeNotifier {
  static final PatientAlertsStore _instance = PatientAlertsStore._();
  factory PatientAlertsStore() => _instance;

  final FirestoreService _fs = FirestoreService();
  final MedicationStore _medStore = MedicationStore();

  List<PatientAlert> _alerts = [];
  List<ChatMessage> _messages = [];

  Timer? _checkTimer;
  StreamSubscription<List<Map<String, dynamic>>>? _alertsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<DatabaseEvent>? _rtdbSub;

  PatientAlertsStore._() {
    _init();
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  List<PatientAlert> get allAlerts => List.unmodifiable(_alerts);
  List<ChatMessage> get chatMessages => List.unmodifiable(_messages);

  List<PatientAlert> get activeAlerts => _alerts
      .where((a) =>
          a.status == AlertStatus.missed ||
          a.status == AlertStatus.delayed ||
          a.status == AlertStatus.scheduled)
      .toList()
    ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

  List<PatientAlert> get resolvedAlerts => _alerts
      .where((a) =>
          a.status == AlertStatus.resolved || a.status == AlertStatus.snoozed)
      .toList();

  // ── Initialisation ─────────────────────────────────────────────────────────

  void _init() {
    _startStreams();
    _checkTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkMedicationSchedules();
    });
    Future.delayed(const Duration(seconds: 3), _checkMedicationSchedules);
  }

  /// Re-subscribes all streams. Call after sign-in.
  void refresh() {
    _startStreams();
    _checkMedicationSchedules();
  }

  void _startStreams() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Firestore: persisted alerts
    _alertsSub?.cancel();
    _alertsSub = _fs.streamPatientAlerts().listen(
      (maps) {
        final persisted = maps.map(PatientAlert.fromFirestore).toList();
        final persistedIds = persisted.map((a) => a.id).toSet();
        final localOnly = _alerts
            .where((a) =>
                a.id.startsWith('auto_') && !persistedIds.contains(a.id))
            .toList();
        _alerts = [...persisted, ...localOnly];
        notifyListeners();
      },
      onError: (_) {},
    );

    // Firestore: caregiver ↔ patient messages
    _messagesSub?.cancel();
    _messagesSub = _fs.streamPatientMessages().listen(
      (maps) {
        _messages = maps.map((m) {
          final ts = m['timestamp'] as Timestamp?;
          return ChatMessage(
            id: m['id'] as String? ?? '',
            senderId: m['senderId'] as String? ?? '',
            senderName: m['senderName'] as String? ?? 'Caregiver',
            text: m['text'] as String? ?? '',
            timestamp: ts?.toDate() ?? DateTime.now(),
            isFromCaregiver: m['isFromCaregiver'] as bool? ?? true,
          );
        }).toList();
        notifyListeners();
      },
      onError: (_) {},
    );

    // RTDB: react to hardware status changes immediately.
    // Wrapped in try-catch — RTDB requires a databaseURL on web;
    // if it is not configured the app falls back to Firestore-only mode.
    _rtdbSub?.cancel();
    try {
      final rtdbRef = FirebaseDatabase.instance.ref('users/$uid/status');
      _rtdbSub = rtdbRef.onValue.listen((_) => _checkMedicationSchedules());
    } catch (_) {}
  }

  // ── Schedule check ─────────────────────────────────────────────────────────

  void _checkMedicationSchedules() async {
    final meds = _medStore.medications;
    if (meds.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    Map<String, bool> rtdbStatus = {};
    if (uid != null) {
      try {
        final db = FirebaseDatabase.instance;
        final snap = await db.ref('users/$uid/status').get();
        if (snap.exists && snap.value != null) {
          rtdbStatus = Map<String, dynamic>.from(snap.value as Map)
              .map((k, v) => MapEntry(k, v == true));
        }
      } catch (_) {
        // RTDB not configured or unreachable — use Firestore takenToday flag.
      }
    }

    final now = DateTime.now();
    bool changed = false;

    for (final med in meds) {
      final scheduledTime = _parseMedTime(med.time, now);
      if (scheduledTime == null) continue;

      final alertId = 'auto_${med.id}_${now.year}${now.month}${now.day}';
      if (_alerts.any((a) => a.id == alertId)) continue;

      final slot = _timeToSlot(med.time);
      final isTaken = rtdbStatus[slot] ?? med.takenToday;
      final diffMinutes = now.difference(scheduledTime).inMinutes;

      PatientAlert? newAlert;

      if (!isTaken && diffMinutes > 5) {
        newAlert = PatientAlert(
          id: alertId,
          title: '${med.name} ${med.dosage}',
          message: 'Scheduled: ${med.time} — Not taken yet',
          scheduledTime: scheduledTime,
          status: AlertStatus.missed,
          baseColor: const Color(0xFFDC2626),
        );
      } else if (isTaken && diffMinutes > 15) {
        newAlert = PatientAlert(
          id: alertId,
          title: '${med.name} ${med.dosage}',
          message: 'Scheduled: ${med.time} — Taken late',
          scheduledTime: scheduledTime,
          status: AlertStatus.delayed,
          baseColor: const Color(0xFFD97706),
        );
      } else if (!isTaken && diffMinutes >= -30 && diffMinutes <= 0) {
        newAlert = PatientAlert(
          id: alertId,
          title: '${med.name} ${med.dosage}',
          message: 'Coming up at ${med.time}',
          scheduledTime: scheduledTime,
          status: AlertStatus.scheduled,
          baseColor: const Color(0xFF135BEC),
        );
      }

      if (newAlert != null) {
        _alerts.add(newAlert);
        changed = true;
        _fs.addPatientAlert(newAlert.toFirestore()).then((docId) {
          if (docId != null) newAlert!.id = docId;
        }).catchError((_) {});
      }
    }

    if (changed) notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _timeToSlot(String timeStr) {
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

  // ── Public actions ─────────────────────────────────────────────────────────

  void refreshAlerts() => _checkMedicationSchedules();

  Future<void> resolveAlert(String id) async {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      _alerts[idx].status = AlertStatus.resolved;
      notifyListeners();
      await _fs
          .updatePatientAlertStatus(id, AlertStatus.resolved.name)
          .catchError((_) {});
    }
  }

  Future<void> snoozeAlert(String id) async {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      _alerts[idx].status = AlertStatus.snoozed;
      notifyListeners();
      await _fs
          .updatePatientAlertStatus(id, AlertStatus.snoozed.name)
          .catchError((_) {});
    }
  }

  Future<void> sendMessage(String text) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    _messages.insert(
      0,
      ChatMessage(
        id: now.millisecondsSinceEpoch.toString(),
        senderId: uid,
        senderName: 'You',
        text: text,
        timestamp: now,
        isFromCaregiver: false,
      ),
    );
    notifyListeners();
    await _fs.addPatientMessage({
      'senderId': uid,
      'senderName': 'Patient',
      'text': text,
      'timestamp': Timestamp.fromDate(now),
      'isFromCaregiver': false,
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _alertsSub?.cancel();
    _messagesSub?.cancel();
    _rtdbSub?.cancel();
    super.dispose();
  }
}

