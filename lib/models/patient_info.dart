import 'package:flutter/material.dart';
import 'medication.dart';

class PatientInfo {
  final String id;
  String linkedPatientId; // User-facing patient ID for caregiver-patient linking
  String name;
  int age;
  String photoUrl;
  double adherencePercent;
  List<Medication> medications;
  int missedDoses;
  int refillAlerts;
  String email;
  String phone;

  PatientInfo({
    required this.id,
    this.linkedPatientId = '',
    required this.name,
    required this.age,
    this.photoUrl = '',
    this.adherencePercent = 0.0,
    List<Medication>? medications,
    this.missedDoses = 0,
    this.refillAlerts = 0,
    this.email = '',
    this.phone = '',
  }) : medications = medications ?? [];

  PatientInfo copy() => PatientInfo(
        id: id,
        linkedPatientId: linkedPatientId,
        name: name,
        age: age,
        photoUrl: photoUrl,
        adherencePercent: adherencePercent,
        medications: medications.map((m) => m.copy()).toList(),
        missedDoses: missedDoses,
        refillAlerts: refillAlerts,
        email: email,
        phone: phone,
      );
}

class CaregiverAlert {
  final String id;
  final String patientId;
  final String patientName;
  final AlertType type;
  final String message;
  final DateTime timestamp;
  bool resolved;

  CaregiverAlert({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.type,
    required this.message,
    required this.timestamp,
    this.resolved = false,
  });
}

enum AlertType { missedDose, dispenserError, refillNeeded }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final bool isFromCaregiver;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    this.senderName = '',
    required this.text,
    required this.isFromCaregiver,
    required this.timestamp,
  });
}
