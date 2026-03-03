import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_info.dart';
import '../models/medication.dart';

class CaregiverStore extends ChangeNotifier {
  static final CaregiverStore _instance = CaregiverStore._();
  factory CaregiverStore() => _instance;
  CaregiverStore._() {
    _patients = _defaultPatients();
    _alerts = _defaultAlerts();
    _messages = _defaultMessages();
  }

  bool _firestoreLoaded = false;
  final Map<String, StreamSubscription> _medSyncSubscriptions = {};

  /// Loads caregiver profile + linked patients from Firestore.
  /// Called once when CaregiverHome mounts.
  Future<void> loadFromFirestore() async {
    if (_firestoreLoaded) return;
    _firestoreLoaded = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Load caregiver's own profile
      final caregiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (caregiverDoc.exists && caregiverDoc.data() != null) {
        final data = caregiverDoc.data()!;
        caregiverName = data['name'] as String? ?? caregiverName;
        caregiverEmail = data['email'] as String? ?? caregiverEmail;

        // 2. Check if caregiver signed up with a linkedPatientId
        final signupLinkedId = data['linkedPatientId'] as String? ?? '';
        if (signupLinkedId.isNotEmpty) {
          await _loadPatientByPatientId(signupLinkedId);
        }

        // 3. Load any additional linked patient IDs stored in a list
        final linkedIds = data['linkedPatientIds'] as List<dynamic>? ?? [];
        for (final id in linkedIds) {
          if (id is String && id.isNotEmpty) {
            await _loadPatientByPatientId(id);
          }
        }
      }
    } catch (e) {
      debugPrint('CaregiverStore: Error loading from Firestore: $e');
    }

    // Start real-time medication sync for all Firestore-loaded patients
    _startMedicationSync();

    notifyListeners();
  }

  /// Queries Firestore for a user whose `patientId` matches, then adds them
  /// along with their actual medications from Firestore.
  Future<void> _loadPatientByPatientId(String patientId) async {
    // Don't add duplicates
    if (_patients.any((p) => p.linkedPatientId == patientId)) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('patientId', isEqualTo: patientId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final patientUid = query.docs.first.id;
        final data = query.docs.first.data();
        final name = data['name'] as String? ?? 'Unknown Patient';
        final email = data['email'] as String? ?? '';
        final phone = data['phone'] as String? ?? '';
        final ageRaw = data['age'];
        final age = ageRaw is int ? ageRaw : int.tryParse(ageRaw?.toString() ?? '') ?? 0;

        // Load the patient's medications from Firestore
        final medsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(patientUid)
            .collection('medications')
            .get();

        final medications = medsSnapshot.docs.isNotEmpty
            ? medsSnapshot.docs
                .map((doc) => Medication.fromMap(doc.data(), doc.id))
                .toList()
            : <Medication>[];

        // Calculate adherence from meds
        final totalMeds = medications.length;
        final takenMeds = medications.where((m) => m.takenToday).length;
        final adherence = totalMeds > 0 ? (takenMeds / totalMeds * 100) : 0.0;
        final missed = totalMeds - takenMeds;
        final lowRefills = medications.where((m) => m.isLowRefill).length;

        _patients.add(PatientInfo(
          id: 'fb_$patientUid',
          linkedPatientId: patientId,
          name: name,
          age: age,
          email: email,
          phone: phone,
          adherencePercent: adherence,
          missedDoses: missed,
          refillAlerts: lowRefills,
          medications: medications.isEmpty
              ? [Medication(id: 'none', name: 'No medications yet', dosage: '-', instruction: '-', time: '-')]
              : medications,
        ));
      }
    } catch (e) {
      debugPrint('CaregiverStore: Error loading patient $patientId: $e');
    }
  }

  /// Sets up real-time Firestore listeners on each linked patient's medications.
  /// When a patient adds/updates/removes a medication, the caregiver sees it live.
  void _startMedicationSync() {
    for (final patient in _patients) {
      // Only sync Firestore-loaded patients (id starts with 'fb_')
      if (!patient.id.startsWith('fb_')) continue;
      final patientUid = patient.id.replaceFirst('fb_', '');

      // Skip if already subscribed
      if (_medSyncSubscriptions.containsKey(patientUid)) continue;

      final sub = FirebaseFirestore.instance
          .collection('users')
          .doc(patientUid)
          .collection('medications')
          .snapshots()
          .listen((snapshot) {
        final meds = snapshot.docs
            .map((doc) => Medication.fromMap(doc.data(), doc.id))
            .toList();

        final idx = _patients.indexWhere((p) => p.id == 'fb_$patientUid');
        if (idx >= 0) {
          final totalMeds = meds.length;
          final takenMeds = meds.where((m) => m.takenToday).length;
          final adherence = totalMeds > 0 ? (takenMeds / totalMeds * 100) : 0.0;

          _patients[idx] = _patients[idx].copy()
            ..medications.clear();
          _patients[idx].medications.addAll(
            meds.isEmpty
                ? [Medication(id: 'none', name: 'No medications yet', dosage: '-', instruction: '-', time: '-')]
                : meds,
          );
          // Update stats
          _patients[idx] = PatientInfo(
            id: _patients[idx].id,
            linkedPatientId: _patients[idx].linkedPatientId,
            name: _patients[idx].name,
            age: _patients[idx].age,
            email: _patients[idx].email,
            phone: _patients[idx].phone,
            adherencePercent: adherence,
            missedDoses: totalMeds - takenMeds,
            refillAlerts: meds.where((m) => m.isLowRefill).length,
            medications: meds.isEmpty
                ? [Medication(id: 'none', name: 'No medications yet', dosage: '-', instruction: '-', time: '-')]
                : meds,
          );
          notifyListeners();
        }
      });

      _medSyncSubscriptions[patientUid] = sub;
    }
  }

  /// Saves a newly linked patient ID to the caregiver's Firestore doc
  Future<void> saveLinkToFirestore(String patientId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'linkedPatientIds': FieldValue.arrayUnion([patientId]),
      });
    } catch (e) {
      debugPrint('CaregiverStore: Error saving link: $e');
    }
  }

  late List<PatientInfo> _patients;
  late List<CaregiverAlert> _alerts;
  late List<ChatMessage> _messages;

  // --- Caregiver profile ---
  String caregiverName = 'Dr. Sarah Chen';
  String caregiverEmail = 'sarah.chen@pillcare.com';
  bool notifyMissedDose = true;
  bool notifyRefill = true;
  bool notifyDispenser = true;
  bool biometricEnabled = false;
  bool pinEnabled = false;

  // --- Patients ---
  List<PatientInfo> get patients => List.unmodifiable(_patients);
  int get totalMissedDoses => _patients.fold(0, (s, p) => s + p.missedDoses);
  int get totalRefillAlerts => _patients.fold(0, (s, p) => s + p.refillAlerts);
  int get upcomingSchedules => _patients.fold(0, (s, p) => s + p.medications.length);

  void addPatient(PatientInfo patient) {
    _patients.add(patient);
    notifyListeners();
  }

  void removePatient(String id) {
    _patients.removeWhere((p) => p.id == id);
    _alerts.removeWhere((a) => a.patientId == id);
    _messages.removeWhere((m) => m.senderId == id);
    notifyListeners();
  }

  PatientInfo? getPatient(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  PatientInfo? getPatientByLinkedId(String linkedPatientId) {
    try {
      return _patients.firstWhere((p) => p.linkedPatientId == linkedPatientId);
    } catch (_) {
      return null;
    }
  }

  // --- Alerts ---
  List<CaregiverAlert> get alerts => List.unmodifiable(_alerts);
  List<CaregiverAlert> get unresolvedAlerts => _alerts.where((a) => !a.resolved).toList();
  List<CaregiverAlert> alertsByType(AlertType type) => _alerts.where((a) => a.type == type).toList();

  void resolveAlert(String id) {
    final i = _alerts.indexWhere((a) => a.id == id);
    if (i >= 0) {
      _alerts[i].resolved = true;
      notifyListeners();
    }
  }

  // --- Messages ---
  List<ChatMessage> messagesForPatient(String patientId) =>
      _messages.where((m) => m.senderId == patientId || m.senderId == 'caregiver_1').toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  void sendMessage(String patientId, String text, {bool isCaregiver = true}) {
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: isCaregiver ? 'caregiver_1' : patientId,
      senderName: isCaregiver ? 'You' : 'Patient',
      text: text,
      isFromCaregiver: isCaregiver,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  // --- Analytics ---
  List<double> getWeeklyAdherence(String patientId) {
    // Mock weekly adherence data (Mon-Sun)
    final data = <String, List<double>>{
      'p1': [85, 90, 78, 92, 88, 95, 80],
      'p2': [70, 65, 80, 75, 60, 72, 68],
      'p3': [95, 98, 100, 92, 97, 100, 96],
      'p4': [50, 60, 55, 70, 65, 58, 62],
    };
    return data[patientId] ?? [0, 0, 0, 0, 0, 0, 0];
  }

  // --- Default Data ---
  List<PatientInfo> _defaultPatients() => [
        PatientInfo(
          id: 'p1',
          linkedPatientId: 'PC-10001',
          name: 'Rajesh Kumar',
          age: 68,
          adherencePercent: 87,
          missedDoses: 2,
          refillAlerts: 1,
          email: 'rajesh.k@email.com',
          phone: '+91 98765 43210',
          medications: [
            Medication(id: 'm1', name: 'Metformin', dosage: '500mg', instruction: 'After Breakfast', time: '08:00 AM',
                icon: Icons.medication, color: const Color(0xFF135BEC), bgColor: const Color(0xFFEFF6FF), refillCount: 8, refillTotal: 30),
            Medication(id: 'm2', name: 'Amlodipine', dosage: '5mg', instruction: 'Before Sleep', time: '09:30 PM',
                icon: Icons.medication, color: const Color(0xFF16A34A), bgColor: const Color(0xFFF0FDF4), refillCount: 20, refillTotal: 30),
          ],
        ),
        PatientInfo(
          id: 'p2',
          linkedPatientId: 'PC-10002',
          name: 'Anita Sharma',
          age: 72,
          adherencePercent: 64,
          missedDoses: 5,
          refillAlerts: 2,
          email: 'anita.s@email.com',
          phone: '+91 87654 32109',
          medications: [
            Medication(id: 'm3', name: 'Lisinopril', dosage: '10mg', instruction: 'With Lunch', time: '01:00 PM',
                icon: Icons.medication, color: const Color(0xFF7C3AED), bgColor: const Color(0xFFF5F3FF), refillCount: 3, refillTotal: 30),
            Medication(id: 'm4', name: 'Atorvastatin', dosage: '20mg', instruction: 'After Dinner', time: '08:00 PM',
                icon: Icons.medication, color: const Color(0xFFDC2626), bgColor: const Color(0xFFFEF2F2), refillCount: 15, refillTotal: 30),
            Medication(id: 'm5', name: 'Aspirin', dosage: '75mg', instruction: 'After Breakfast', time: '09:00 AM',
                icon: Icons.medication, color: const Color(0xFFEA580C), bgColor: const Color(0xFFFFF7ED), refillCount: 25, refillTotal: 60),
          ],
        ),
        PatientInfo(
          id: 'p3',
          linkedPatientId: 'PC-10003',
          name: 'Vikram Patel',
          age: 55,
          adherencePercent: 96,
          missedDoses: 0,
          refillAlerts: 0,
          email: 'vikram.p@email.com',
          phone: '+91 76543 21098',
          medications: [
            Medication(id: 'm6', name: 'Vitamin D', dosage: '1000 IU', instruction: 'With Lunch', time: '01:00 PM',
                icon: Icons.water_drop, color: const Color(0xFF0891B2), bgColor: const Color(0xFFECFEFF), refillCount: 28, refillTotal: 30),
          ],
        ),
        PatientInfo(
          id: 'p4',
          linkedPatientId: 'PC-10004',
          name: 'Meena Devi',
          age: 80,
          adherencePercent: 58,
          missedDoses: 7,
          refillAlerts: 3,
          email: 'meena.d@email.com',
          phone: '+91 65432 10987',
          medications: [
            Medication(id: 'm7', name: 'Insulin', dosage: '10 units', instruction: 'Before Meals', time: '07:30 AM',
                icon: Icons.vaccines, color: const Color(0xFFDC2626), bgColor: const Color(0xFFFEF2F2), refillCount: 2, refillTotal: 30),
            Medication(id: 'm8', name: 'Metoprolol', dosage: '25mg', instruction: 'After Breakfast', time: '08:30 AM',
                icon: Icons.medication, color: const Color(0xFF135BEC), bgColor: const Color(0xFFEFF6FF), refillCount: 5, refillTotal: 30),
            Medication(id: 'm9', name: 'Omeprazole', dosage: '20mg', instruction: 'Before Breakfast', time: '07:00 AM',
                icon: Icons.medication_liquid, color: const Color(0xFF7C3AED), bgColor: const Color(0xFFF5F3FF), refillCount: 18, refillTotal: 30),
          ],
        ),
      ];

  List<CaregiverAlert> _defaultAlerts() {
    final now = DateTime.now();
    return [
      CaregiverAlert(id: 'a1', patientId: 'p2', patientName: 'Anita Sharma', type: AlertType.missedDose,
          message: 'Missed Lisinopril 10mg dose at 1:00 PM', timestamp: now.subtract(const Duration(minutes: 30))),
      CaregiverAlert(id: 'a2', patientId: 'p4', patientName: 'Meena Devi', type: AlertType.refillNeeded,
          message: 'Insulin refill needed — only 2 doses remaining', timestamp: now.subtract(const Duration(hours: 1))),
      CaregiverAlert(id: 'a3', patientId: 'p4', patientName: 'Meena Devi', type: AlertType.missedDose,
          message: 'Missed Metoprolol 25mg morning dose', timestamp: now.subtract(const Duration(hours: 2))),
      CaregiverAlert(id: 'a4', patientId: 'p1', patientName: 'Rajesh Kumar', type: AlertType.dispenserError,
          message: 'Smart Dispenser offline — check connection', timestamp: now.subtract(const Duration(hours: 3))),
      CaregiverAlert(id: 'a5', patientId: 'p2', patientName: 'Anita Sharma', type: AlertType.refillNeeded,
          message: 'Lisinopril refill needed — only 3 doses remaining', timestamp: now.subtract(const Duration(hours: 5))),
      CaregiverAlert(id: 'a6', patientId: 'p4', patientName: 'Meena Devi', type: AlertType.missedDose,
          message: 'Missed Omeprazole 20mg before breakfast', timestamp: now.subtract(const Duration(hours: 8))),
      CaregiverAlert(id: 'a7', patientId: 'p1', patientName: 'Rajesh Kumar', type: AlertType.refillNeeded,
          message: 'Metformin refill needed — 8 doses remaining', timestamp: now.subtract(const Duration(hours: 12))),
      CaregiverAlert(id: 'a8', patientId: 'p4', patientName: 'Meena Devi', type: AlertType.dispenserError,
          message: 'Dispenser lid left open for 10+ minutes', timestamp: now.subtract(const Duration(days: 1))),
    ];
  }

  List<ChatMessage> _defaultMessages() {
    final now = DateTime.now();
    return [
      ChatMessage(id: 'c1', senderId: 'caregiver_1', senderName: 'Dr. Sarah', text: 'Good morning! Did you take your Metformin today?', isFromCaregiver: true,
          timestamp: now.subtract(const Duration(hours: 6))),
      ChatMessage(id: 'c2', senderId: 'p1', senderName: 'Rajesh', text: 'Yes, I took it after breakfast. Thank you for checking!', isFromCaregiver: false,
          timestamp: now.subtract(const Duration(hours: 5, minutes: 45))),
      ChatMessage(id: 'c3', senderId: 'caregiver_1', senderName: 'Dr. Sarah', text: 'Hi Anita, I noticed you missed your afternoon dose. Everything okay?', isFromCaregiver: true,
          timestamp: now.subtract(const Duration(hours: 2))),
      ChatMessage(id: 'c4', senderId: 'p2', senderName: 'Anita', text: 'Oh I forgot! Taking it now. Thanks for the reminder.', isFromCaregiver: false,
          timestamp: now.subtract(const Duration(hours: 1, minutes: 50))),
      ChatMessage(id: 'c5', senderId: 'caregiver_1', senderName: 'Dr. Sarah', text: 'Meena ji, your insulin supply is running low. Shall I arrange a refill?', isFromCaregiver: true,
          timestamp: now.subtract(const Duration(hours: 4))),
      ChatMessage(id: 'c6', senderId: 'p4', senderName: 'Meena', text: 'Yes please, that would be helpful.', isFromCaregiver: false,
          timestamp: now.subtract(const Duration(hours: 3, minutes: 30))),
    ];
  }
}
