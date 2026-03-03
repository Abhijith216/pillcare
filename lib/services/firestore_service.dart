import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication.dart';

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
}
