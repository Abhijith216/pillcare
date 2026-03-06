import 'dart:async';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'firestore_service.dart';

class MedicationStore extends ChangeNotifier {
  static final MedicationStore _instance = MedicationStore._();
  factory MedicationStore() => _instance;
  
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<Medication>>? _subscription;

  MedicationStore._() {
    _initStream();
  }

  void _initStream() {
    _subscription?.cancel();
    _subscription = _firestoreService.streamMedications().listen((meds) {
      _medications = meds;
      notifyListeners();
    });
  }

  // Refresh stream explicitly if user signs in, since singleton persists
  void refresh() {
    _initStream();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<Medication> _medications = [];
  List<Medication> get medications => List.unmodifiable(_medications);
  /// Only medications approved by caregiver — used on the Home screen
  List<Medication> get approvedMedications =>
      List.unmodifiable(_medications.where((m) => m.isApproved).toList());
  /// Medications awaiting caregiver approval
  List<Medication> get pendingMedications =>
      List.unmodifiable(_medications.where((m) => m.isPending).toList());
  int get lowRefillCount => _medications.where((m) => m.isLowRefill && m.isApproved).length;

  Future<void> add(Medication med) async {
    await _firestoreService.addMedication(med);
  }

  Future<void> update(String id, Medication updated) async {
    await _firestoreService.updateMedication(updated);
  }

  Future<void> remove(String id) async {
    await _firestoreService.deleteMedication(id);
  }

  void insertAt(int index, Medication med) {
    // Firestore lacks explicit ordering by index out of the box without an order field.
    // For now, simply add it.
    add(med);
  }

  int indexOf(String id) => _medications.indexWhere((m) => m.id == id);

  Future<void> toggleTaken(String id) async {
    final i = _medications.indexWhere((m) => m.id == id);
    if (i >= 0) {
      final med = _medications[i];
      final isNowTaken = !med.takenToday;
      int newRefillCount = med.refillCount;
      
      if (isNowTaken && med.refillCount > 0) {
        newRefillCount--;
      } else if (!isNowTaken) {
        newRefillCount++;
      }
      
      // Optimistic local update
      med.takenToday = isNowTaken;
      med.refillCount = newRefillCount;
      notifyListeners();

      await _firestoreService.toggleTakenStatus(id, isNowTaken);
      await _firestoreService.updateRefillCount(id, newRefillCount);
    }
  }

  Future<void> updateRefillCount(String id, int count) async {
    // Optimistic local update
    final i = _medications.indexWhere((m) => m.id == id);
    if (i >= 0) {
      _medications[i].refillCount = count;
      notifyListeners();
    }
    await _firestoreService.updateRefillCount(id, count);
  }
}
