import 'package:cloud_firestore/cloud_firestore.dart';
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'photoUrl': photoUrl,
      'adherencePercent': adherencePercent,
      'missedDoses': missedDoses,
      'refillAlerts': refillAlerts,
      'email': email,
      'phone': phone,
    };
  }

  factory PatientInfo.fromMap(Map<String, dynamic> map, String docId) {
    return PatientInfo(
      id: docId,
      name: map['name']?.toString() ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      photoUrl: map['photoUrl']?.toString() ?? '',
      adherencePercent: (map['adherencePercent'] as num?)?.toDouble() ?? 0.0,
      missedDoses: (map['missedDoses'] as num?)?.toInt() ?? 0,
      refillAlerts: (map['refillAlerts'] as num?)?.toInt() ?? 0,
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'type': type.name,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'resolved': resolved,
    };
  }

  factory CaregiverAlert.fromMap(Map<String, dynamic> map, String docId) {
    DateTime ts;
    final raw = map['timestamp'];
    if (raw is Timestamp) {
      ts = raw.toDate();
    } else if (raw is String) {
      ts = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }
    return CaregiverAlert(
      id: docId,
      patientId: map['patientId']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.missedDose,
      ),
      message: map['message']?.toString() ?? '',
      timestamp: ts,
      resolved: map['resolved'] as bool? ?? false,
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'isFromCaregiver': isFromCaregiver,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    DateTime ts;
    final raw = map['timestamp'];
    if (raw is Timestamp) {
      ts = raw.toDate();
    } else {
      ts = DateTime.now();
    }
    return ChatMessage(
      id: docId,
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      isFromCaregiver: map['isFromCaregiver'] as bool? ?? false,
      timestamp: ts,
    );
  }
}
