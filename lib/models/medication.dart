import 'package:flutter/material.dart';

class Medication {
  String id;
  String name;
  String dosage;
  String instruction;
  String time;
  IconData icon;
  Color color;
  Color bgColor;
  int refillCount;
  int refillTotal;
  bool takenToday;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.instruction,
    required this.time,
    this.icon = Icons.medication,
    this.color = const Color(0xFF135BEC),
    this.bgColor = const Color(0xFFEFF6FF),
    this.refillCount = 30,
    this.refillTotal = 30,
    this.takenToday = false,
  });

  Medication copy() => Medication(
    id: id, name: name, dosage: dosage, instruction: instruction, time: time,
    icon: icon, color: color, bgColor: bgColor,
    refillCount: refillCount, refillTotal: refillTotal, takenToday: takenToday,
  );

  String get displayTime => time;
  String get displayDosage => '$dosage • $instruction';
  double get refillPercent => refillTotal > 0 ? refillCount / refillTotal : 0;
  bool get isLowRefill => refillCount <= 5;
}

// Preset medication types
class MedPreset {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const MedPreset(this.label, this.icon, this.color, this.bgColor);
}

const medPresets = [
  MedPreset('Pill', Icons.medication, Color(0xFF135BEC), Color(0xFFEFF6FF)),
  MedPreset('Capsule', Icons.medication_liquid, Color(0xFF0891B2), Color(0xFFECFEFF)),
  MedPreset('Liquid', Icons.water_drop, Color(0xFF7C3AED), Color(0xFFF5F3FF)),
  MedPreset('Tablet', Icons.medication, Color(0xFF16A34A), Color(0xFFF0FDF4)),
  MedPreset('Injection', Icons.vaccines, Color(0xFFDC2626), Color(0xFFFEF2F2)),
  MedPreset('Drops', Icons.opacity, Color(0xFFEA580C), Color(0xFFFFF7ED)),
];
