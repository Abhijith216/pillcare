import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication.dart';
import '../models/patient_info.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of medications for the current user
  Stream<List<Medication>> streamMedications() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medication.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add a new medication
  Future<void> addMedication(Medication med) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .doc(med.id)
        .set(med.toMap());
  }

  // Update a single medication
  Future<void> updateMedication(Medication med) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .doc(med.id)
        .update(med.toMap());
  }

  // Delete a medication
  Future<void> deleteMedication(String medId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .doc(medId)
        .delete();
  }

  // Stream of user profile data
  Stream<Map<String, dynamic>?> streamUserData() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // Get user data once
  Future<Map<String, dynamic>?> getUserData() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // Update user profile fields
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update(data);
  }

  // Update refill count specifically
  Future<void> updateRefillCount(String medId, int newCount) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .doc(medId)
        .update({'refillCount': newCount});
  }

  // Toggle taken today status specifically
  Future<void> toggleTakenStatus(String medId, bool isTaken) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .doc(medId)
        .update({'takenToday': isTaken});
  }

  // ─── Caregiver: Patients ───────────────────────────────────────────────────

  Stream<List<PatientInfo>> streamPatients() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .snapshots()
        .map((s) => s.docs.map((d) => PatientInfo.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addPatient(PatientInfo patient) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patient.id)
        .set(patient.toMap());
  }

  Future<void> updatePatient(PatientInfo patient) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patient.id)
        .update(patient.toMap());
  }

  Future<void> deletePatient(String patientId) async {
    final uid = currentUserId;
    if (uid == null) return;
    // Delete subcollections first
    final medsSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('medications')
        .get();
    for (final doc in medsSnap.docs) {
      await doc.reference.delete();
    }
    final msgsSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('messages')
        .get();
    for (final doc in msgsSnap.docs) {
      await doc.reference.delete();
    }
    await _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .delete();
  }

  // ─── Caregiver: Patient Medications ───────────────────────────────────────

  Stream<List<Medication>> streamPatientMedications(String patientId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('medications')
        .snapshots()
        .map((s) => s.docs.map((d) => Medication.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addPatientMedication(String patientId, Medication med) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('medications')
        .doc(med.id)
        .set(med.toMap());
  }

  Future<void> updatePatientMedication(String patientId, Medication med) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('medications')
        .doc(med.id)
        .update(med.toMap());
  }

  Future<void> deletePatientMedication(String patientId, String medId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('medications')
        .doc(medId)
        .delete();
  }

  // ─── Caregiver: Alerts ────────────────────────────────────────────────────

  Stream<List<CaregiverAlert>> streamAlerts() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => CaregiverAlert.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addAlert(CaregiverAlert alert) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .doc(alert.id)
        .set(alert.toMap());
  }

  Future<void> resolveAlert(String alertId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .doc(alertId)
        .update({'resolved': true});
  }

  Future<void> deleteAlert(String alertId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .doc(alertId)
        .delete();
  }

  // ─── Caregiver: Chat Messages ─────────────────────────────────────────────

  Stream<List<ChatMessage>> streamMessages(String patientId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((s) => s.docs.map((d) => ChatMessage.fromMap(d.data(), d.id)).toList());
  }

  Future<void> sendMessage(String patientId, ChatMessage msg) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('messages')
        .doc(msg.id)
        .set(msg.toMap());
  }
}
