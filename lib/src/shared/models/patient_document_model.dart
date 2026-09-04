import 'dart:convert';

class PatientDocumentModel {
  final String id;
  final String patientId;
  final String fileName;
  final String docType; // 'Prescription', 'Lab Report', 'Discharge Summary', 'Other'
  final String extractedText;
  final Map<String, dynamic> entities; // { 'medications': [], 'lab_values': [], 'abnormal': [] }
  final String? imagePath;
  final DateTime createdAt;

  PatientDocumentModel({
    required this.id,
    required this.patientId,
    required this.fileName,
    this.docType = 'Lab Report',
    this.extractedText = '',
    Map<String, dynamic>? entities,
    this.imagePath,
    DateTime? createdAt,
  })  : entities = entities ?? {},
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'file_name': fileName,
      'doc_type': docType,
      'extracted_text': extractedText,
      'entities_json': jsonEncode(entities),
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PatientDocumentModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedEntities = {};
    if (map['entities_json'] != null) {
      try {
        parsedEntities = jsonDecode(map['entities_json'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return PatientDocumentModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String? ?? '',
      fileName: map['file_name'] as String? ?? 'Document',
      docType: map['doc_type'] as String? ?? 'Lab Report',
      extractedText: map['extracted_text'] as String? ?? '',
      entities: parsedEntities,
      imagePath: map['image_path'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
