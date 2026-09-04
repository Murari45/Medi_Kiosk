import 'dart:convert';

class ClinicalIntakeModel {
  final String id;
  final String sessionId;
  final Map<String, dynamic> socratesData;
  final Map<String, dynamic> dashavidhaData;
  final Map<String, dynamic> confidenceScores; // { questionKey: 'certain' | 'not_sure' | 'unclear' }

  ClinicalIntakeModel({
    required this.id,
    required this.sessionId,
    Map<String, dynamic>? socratesData,
    Map<String, dynamic>? dashavidhaData,
    Map<String, dynamic>? confidenceScores,
  })  : socratesData = socratesData ?? {},
        dashavidhaData = dashavidhaData ?? {},
        confidenceScores = confidenceScores ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'socrates_json': jsonEncode(socratesData),
      'dashavidha_json': jsonEncode(dashavidhaData),
      'confidence_scores_json': jsonEncode(confidenceScores),
    };
  }

  factory ClinicalIntakeModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parseJson(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      try {
        return jsonDecode(value as String) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    }

    return ClinicalIntakeModel(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      socratesData: parseJson(map['socrates_json']),
      dashavidhaData: parseJson(map['dashavidha_json']),
      confidenceScores: parseJson(map['confidence_scores_json']),
    );
  }
}
