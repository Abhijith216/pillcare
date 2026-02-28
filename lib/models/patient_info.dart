import 'package:flutter/material.dart';
import 'medication.dart';

class PatientInfo {
  final String id;
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
  final String patientId;
  final String text;
  final bool isCaregiver;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.patientId,
    required this.text,
    required this.isCaregiver,
    required this.timestamp,
  });
}
