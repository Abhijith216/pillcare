import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/patient_info.dart';
import '../models/medication.dart';

class CaregiverStore extends ChangeNotifier {
  static final CaregiverStore _instance = CaregiverStore._();
  factory CaregiverStore() => _instance;
  CaregiverStore._() {
    _patients = [];
    _alerts = [];
    _messages = [];
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
        caregiverPhone = data['phone'] as String? ?? '';

        // Generate or load caregiverId
        final storedCgId = data['caregiverId'] as String? ?? '';
        if (storedCgId.isNotEmpty) {
          _caregiverId = storedCgId;
        } else {
          _caregiverId = 'CG-${user.uid.substring(0, 8).toUpperCase()}';
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'caregiverId': _caregiverId})
              .catchError((_) {});
        }

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
    _startAlertsStream();

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
        final age = ageRaw is int
            ? ageRaw
            : int.tryParse(ageRaw?.toString() ?? '') ?? 0;

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

        _patients.add(
          PatientInfo(
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
                ? [
                    Medication(
                      id: 'none',
                      name: 'No medications yet',
                      dosage: '-',
                      instruction: '-',
                      time: '-',
                    ),
                  ]
                : medications,
          ),
        );
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
              final adherence = totalMeds > 0
                  ? (takenMeds / totalMeds * 100)
                  : 0.0;

              _patients[idx] = _patients[idx].copy()..medications.clear();
              _patients[idx].medications.addAll(
                meds.isEmpty
                    ? [
                        Medication(
                          id: 'none',
                          name: 'No medications yet',
                          dosage: '-',
                          instruction: '-',
                          time: '-',
                        ),
                      ]
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
                    ? [
                        Medication(
                          id: 'none',
                          name: 'No medications yet',
                          dosage: '-',
                          instruction: '-',
                          time: '-',
                        ),
                      ]
                    : meds,
              );
              notifyListeners();
            }
          });

      _medSyncSubscriptions[patientUid] = sub;
    }
  }

  /// Public method to link a patient by their patientId (e.g. 'PC-12345').
  /// Loads the patient from Firestore, saves the link, and notifies listeners.
  Future<bool> linkPatient(String patientId) async {
    if (_patients.any((p) => p.linkedPatientId == patientId)) return false;
    await _loadPatientByPatientId(patientId);
    await saveLinkToFirestore(patientId);
    _startMedicationSync();
    _subscribeRtdbAlertsForPatients();
    notifyListeners();
    return true;
  }

  /// Saves a newly linked patient ID to the caregiver's Firestore doc
  Future<void> saveLinkToFirestore(String patientId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'linkedPatientIds': FieldValue.arrayUnion([patientId]),
        },
      );
    } catch (e) {
      debugPrint('CaregiverStore: Error saving link: $e');
    }
  }

  /// Save caregiver profile fields to Firestore.
  Future<void> updateProfile({String? name, String? phone}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final updates = <String, dynamic>{};
    if (name != null && name.isNotEmpty) {
      caregiverName = name;
      updates['name'] = name;
    }
    if (phone != null) {
      caregiverPhone = phone;
      updates['phone'] = phone;
    }
    if (updates.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);
      notifyListeners();
    }
  }

  /// Start real-time Firestore alerts stream for the caregiver.
  void _startAlertsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _alertsStreamSub?.cancel();
    _alertsStreamSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen((snap) {
          final fsAlerts = snap.docs
              .map((doc) => CaregiverAlert.fromMap(doc.data(), doc.id))
              .toList();
          // Keep RTDB alerts (prefixed rtdb_), merge with Firestore
          final rtdbAlerts = _alerts.where((a) => a.id.startsWith('rtdb_')).toList();
          _alerts = [...fsAlerts, ...rtdbAlerts
              .where((r) => !fsAlerts.any((f) => f.id == r.id))];
          _subscribeRtdbAlertsForPatients();
          notifyListeners();
        }, onError: (e) {
          debugPrint('CaregiverStore: alerts stream error: $e');
        });
  }

  /// Listen to RTDB hardware events for every Firestore-loaded patient.
  void _subscribeRtdbAlertsForPatients() {
    for (final patient in _patients) {
      if (!patient.id.startsWith('fb_')) continue;
      final uid = patient.id.replaceFirst('fb_', '');
      if (_subscribedAlertUids.contains(uid)) continue;
      _subscribedAlertUids.add(uid);

      final ref = FirebaseDatabase.instance.ref('users/$uid/events');
      final sub = ref.onChildAdded.listen((event) {
        final raw = event.snapshot.value;
        if (raw is! Map) return;
        final data = Map<String, dynamic>.from(raw);
        final alertId = 'rtdb_${event.snapshot.key}';
        if (_alerts.any((a) => a.id == alertId)) return;
        final typeStr = data['type']?.toString() ?? '';
        final alertType = typeStr == 'missed'
            ? AlertType.missedDose
            : typeStr == 'refill'
                ? AlertType.refillNeeded
                : AlertType.dispenserError;
        final tsRaw = data['timestamp'];
        final ts = tsRaw is int
            ? DateTime.fromMillisecondsSinceEpoch(tsRaw)
            : DateTime.now();
        _alerts.add(CaregiverAlert(
          id: alertId,
          patientId: patient.id,
          patientName: patient.name,
          type: alertType,
          message: data['message']?.toString() ??
              'Hardware event from ${patient.name}\'s dispenser',
          timestamp: ts,
        ));
        notifyListeners();
      });
      _rtdbAlertSubs.add(sub);
    }
  }

  /// Sign out and clear store state.
  Future<void> signOut() async {
    _alertsStreamSub?.cancel();
    for (final s in _rtdbAlertSubs) s.cancel();
    for (final s in _medSyncSubscriptions.values) s.cancel();
    _patients = [];
    _alerts = [];
    _messages = [];
    caregiverName = '';
    caregiverEmail = '';
    caregiverPhone = '';
    _caregiverId = '';
    _firestoreLoaded = false;
    _subscribedAlertUids.clear();
    await FirebaseAuth.instance.signOut();
  }

  late List<PatientInfo> _patients;
  late List<CaregiverAlert> _alerts;
  late List<ChatMessage> _messages;

  // --- Caregiver profile ---
  String caregiverName = '';
  String caregiverEmail = '';
  String caregiverPhone = '';
  String _caregiverId = '';
  String get caregiverId => _caregiverId;

  StreamSubscription<QuerySnapshot>? _alertsStreamSub;
  final Set<String> _subscribedAlertUids = {};
  final List<StreamSubscription> _rtdbAlertSubs = [];

  bool notifyMissedDose = true;
  bool notifyRefill = true;
  bool notifyDispenser = true;
  bool biometricEnabled = false;
  bool pinEnabled = false;

  // --- Patients ---
  List<PatientInfo> get patients => List.unmodifiable(_patients);
  int get totalMissedDoses => _patients.fold(0, (s, p) => s + p.missedDoses);
  int get totalRefillAlerts => _patients.fold(0, (s, p) => s + p.refillAlerts);
  int get upcomingSchedules =>
      _patients.fold(0, (s, p) => s + p.medications.length);

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
  List<CaregiverAlert> get unresolvedAlerts =>
      _alerts.where((a) => !a.resolved).toList();
  List<CaregiverAlert> alertsByType(AlertType type) =>
      _alerts.where((a) => a.type == type).toList();

  void resolveAlert(String id) {
    final i = _alerts.indexWhere((a) => a.id == id);
    if (i >= 0) {
      _alerts[i].resolved = true;
      notifyListeners();
    }
  }

  // --- Messages ---
  List<ChatMessage> messagesForPatient(String patientId) =>
      _messages
          .where((m) => m.senderId == patientId || m.senderId == 'caregiver_1')
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  void sendMessage(String patientId, String text, {bool isCaregiver = true}) {
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: isCaregiver ? 'caregiver_1' : patientId,
        senderName: isCaregiver ? 'You' : 'Patient',
        text: text,
        isFromCaregiver: isCaregiver,
        timestamp: DateTime.now(),
      ),
    );
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

  // â”€â”€â”€ Medication Approval â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Approve a pending medication in the patient's Firestore collection.
  /// [patient.id] must start with 'fb_' (Firestore-loaded patients).
  Future<void> approveMedication(PatientInfo patient, String medId) async {
    if (!patient.id.startsWith('fb_')) return;
    final patientUid = patient.id.replaceFirst('fb_', '');
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientUid)
          .collection('medications')
          .doc(medId)
          .update({'status': 'approved'});
    } catch (e) {
      debugPrint('CaregiverStore: approveMedication error: $e');
    }
  }

  /// Reject a pending medication in the patient's Firestore collection.
  Future<void> rejectMedication(PatientInfo patient, String medId) async {
    if (!patient.id.startsWith('fb_')) return;
    final patientUid = patient.id.replaceFirst('fb_', '');
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientUid)
          .collection('medications')
          .doc(medId)
          .update({'status': 'rejected'});
    } catch (e) {
      debugPrint('CaregiverStore: rejectMedication error: $e');
    }
  }
}
