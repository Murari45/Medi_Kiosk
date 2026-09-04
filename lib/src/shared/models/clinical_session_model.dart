class ClinicalSessionModel {
  final String id;
  final String patientId;
  final String? patientName;
  final String? doctorId;
  final String mode; // 'allopathy' or 'ayush'
  final String priority; // 'P1', 'P2', 'P3'
  final String tokenNumber;
  final int painScore; // 1 to 10
  final String status; // 'waiting', 'in_consultation', 'completed', 'cancelled'
  final String? chiefComplaint;
  final DateTime createdAt;

  ClinicalSessionModel({
    required this.id,
    required this.patientId,
    this.patientName,
    this.doctorId,
    required this.mode,
    required this.priority,
    required this.tokenNumber,
    this.painScore = 5,
    this.status = 'waiting',
    this.chiefComplaint,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'mode': mode,
      'priority': priority,
      'token_number': tokenNumber,
      'pain_score': painScore,
      'status': status,
      'chief_complaint': chiefComplaint,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ClinicalSessionModel.fromMap(Map<String, dynamic> map, {String? patientName}) {
    return ClinicalSessionModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String? ?? '',
      patientName: patientName ?? (map['patient_name'] as String?),
      doctorId: map['doctor_id'] as String?,
      mode: map['mode'] as String? ?? 'allopathy',
      priority: map['priority'] as String? ?? 'P3',
      tokenNumber: map['token_number'] as String? ?? 'TK-001',
      painScore: (map['pain_score'] as num?)?.toInt() ?? 5,
      status: map['status'] as String? ?? 'waiting',
      chiefComplaint: map['chief_complaint'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ClinicalSessionModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? mode,
    String? priority,
    String? tokenNumber,
    int? painScore,
    String? status,
    String? chiefComplaint,
    DateTime? createdAt,
  }) {
    return ClinicalSessionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      mode: mode ?? this.mode,
      priority: priority ?? this.priority,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      painScore: painScore ?? this.painScore,
      status: status ?? this.status,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
