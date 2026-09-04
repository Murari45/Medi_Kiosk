import 'dart:convert';

class PrescriptionItem {
  final String drugName;
  final String dosage;
  final String frequency; // e.g. '1-0-1', 'OD', 'BD', 'TDS'
  final String duration; // e.g. '5 days'
  final String instruction; // e.g. 'After food'

  PrescriptionItem({
    required this.drugName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instruction,
  });

  Map<String, dynamic> toMap() {
    return {
      'drug_name': drugName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instruction': instruction,
    };
  }

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      drugName: map['drug_name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      instruction: map['instruction'] as String? ?? '',
    );
  }
}

class PrescriptionModel {
  final String id;
  final String sessionId;
  final String doctorId;
  final String? doctorName;
  final String patientId;
  final String? patientName;
  final List<PrescriptionItem> medications;
  final String instructions;
  final String diagnosis;
  final DateTime createdAt;

  PrescriptionModel({
    required this.id,
    required this.sessionId,
    required this.doctorId,
    this.doctorName,
    required this.patientId,
    this.patientName,
    required this.medications,
    this.instructions = '',
    this.diagnosis = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'medications_json': jsonEncode(medications.map((m) => m.toMap()).toList()),
      'instructions': instructions,
      'diagnosis': diagnosis,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PrescriptionModel.fromMap(Map<String, dynamic> map, {String? doctorName, String? patientName}) {
    List<PrescriptionItem> parsedMeds = [];
    if (map['medications_json'] != null) {
      try {
        final decoded = jsonDecode(map['medications_json'] as String) as List<dynamic>;
        parsedMeds = decoded.map((item) => PrescriptionItem.fromMap(item as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    return PrescriptionModel(
      id: map['id'] as String,
      sessionId: map['session_id'] as String? ?? '',
      doctorId: map['doctor_id'] as String? ?? '',
      doctorName: doctorName,
      patientId: map['patient_id'] as String? ?? '',
      patientName: patientName,
      medications: parsedMeds,
      instructions: map['instructions'] as String? ?? '',
      diagnosis: map['diagnosis'] as String? ?? '',
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
