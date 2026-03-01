import 'dart:math';
import 'package:flutter/material.dart';
import '../models/patient_info.dart'; // Re-use ChatMessage

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

  PatientAlertsStore._() {
    _generateMockData();
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
      
      // Simulate Caregiver Acknowledgment Webhook/Log
      print('Firebase Simulated: Alert $id RESOLVED sent to Caregiver Dashboard.');
    }
  }

  void snoozeAlert(String id) {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      _alerts[idx].status = AlertStatus.snoozed;
      notifyListeners();

      // Simulate Caregiver Acknowledgment Webhook/Log
      print('Firebase Simulated: Alert $id SNOOZED sent to Caregiver Dashboard.');
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
}
