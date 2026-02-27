import 'package:flutter/material.dart';
import '../models/medication.dart';

class MedicationStore extends ChangeNotifier {
  static final MedicationStore _instance = MedicationStore._();
  factory MedicationStore() => _instance;
  MedicationStore._() {
    _medications = _defaultMeds();
  }

  late List<Medication> _medications;
  List<Medication> get medications => List.unmodifiable(_medications);
  int get lowRefillCount => _medications.where((m) => m.isLowRefill).length;

  List<Medication> _defaultMeds() => [
    Medication(id: '1', name: 'Amoxicillin', dosage: '500mg', instruction: 'After Breakfast', time: '08:00 AM',
      icon: Icons.medication, color: const Color(0xFF135BEC), bgColor: const Color(0xFFEFF6FF), refillCount: 12, refillTotal: 30, takenToday: false),
    Medication(id: '2', name: 'Vitamin D', dosage: '1000 IU', instruction: 'With Lunch', time: '01:00 PM',
      icon: Icons.water_drop, color: const Color(0xFF7C3AED), bgColor: const Color(0xFFF5F3FF), refillCount: 4, refillTotal: 60, takenToday: true),
    Medication(id: '3', name: 'Ibuprofen', dosage: '200mg', instruction: 'Before Sleep', time: '09:30 PM',
      icon: Icons.medication, color: const Color(0xFF16A34A), bgColor: const Color(0xFFF0FDF4), refillCount: 22, refillTotal: 30, takenToday: false),
  ];

  void add(Medication med) {
    _medications.add(med);
    notifyListeners();
  }

  void update(String id, Medication updated) {
    final i = _medications.indexWhere((m) => m.id == id);
    if (i >= 0) { _medications[i] = updated; notifyListeners(); }
  }

  void remove(String id) {
    _medications.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void insertAt(int index, Medication med) {
    _medications.insert(index.clamp(0, _medications.length), med);
    notifyListeners();
  }

  int indexOf(String id) => _medications.indexWhere((m) => m.id == id);

  void toggleTaken(String id) {
    final i = _medications.indexWhere((m) => m.id == id);
    if (i >= 0) {
      _medications[i].takenToday = !_medications[i].takenToday;
      if (_medications[i].takenToday && _medications[i].refillCount > 0) {
        _medications[i].refillCount--;
      } else if (!_medications[i].takenToday) {
        _medications[i].refillCount++;
      }
      notifyListeners();
    }
  }

  void updateRefillCount(String id, int count) {
    final i = _medications.indexWhere((m) => m.id == id);
    if (i >= 0) { _medications[i].refillCount = count; notifyListeners(); }
  }
}
