import 'dart:convert';

class AISummaryModel {
  final String id;
  final String sessionId;
  final List<String> certainItems;
  final List<String> notSureItems;
  final List<String> unclearItems;
  final String triageSummary;
  final String chiefComplaint;
  final String recommendedAction;
  final DateTime createdAt;

  AISummaryModel({
    required this.id,
    required this.sessionId,
    List<String>? certainItems,
    List<String>? notSureItems,
    List<String>? unclearItems,
    this.triageSummary = '',
    this.chiefComplaint = '',
    this.recommendedAction = '',
    DateTime? createdAt,
  })  : certainItems = certainItems ?? [],
        notSureItems = notSureItems ?? [],
        unclearItems = unclearItems ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'certain_json': jsonEncode(certainItems),
      'not_sure_json': jsonEncode(notSureItems),
      'unclear_json': jsonEncode(unclearItems),
      'triage_summary': triageSummary,
      'chief_complaint': chiefComplaint,
      'recommended_action': recommendedAction,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AISummaryModel.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      try {
        final decoded = jsonDecode(value as String) as List<dynamic>;
        return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        return [];
      }
    }

    return AISummaryModel(
      id: map['id'] as String,
      sessionId: map['session_id'] as String? ?? '',
      certainItems: parseList(map['certain_json']),
      notSureItems: parseList(map['not_sure_json']),
      unclearItems: parseList(map['unclear_json']),
      triageSummary: map['triage_summary'] as String? ?? '',
      chiefComplaint: map['chief_complaint'] as String? ?? '',
      recommendedAction: map['recommended_action'] as String? ?? '',
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AISummaryModel copyWith({
    String? id,
    String? sessionId,
    List<String>? certainItems,
    List<String>? notSureItems,
    List<String>? unclearItems,
    String? triageSummary,
    String? chiefComplaint,
    String? recommendedAction,
    DateTime? createdAt,
  }) {
    return AISummaryModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      certainItems: certainItems ?? this.certainItems,
      notSureItems: notSureItems ?? this.notSureItems,
      unclearItems: unclearItems ?? this.unclearItems,
      triageSummary: triageSummary ?? this.triageSummary,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
