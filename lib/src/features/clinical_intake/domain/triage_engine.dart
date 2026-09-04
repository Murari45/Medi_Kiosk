import 'dart:math';
import '../../../shared/models/ai_summary_model.dart';

class TriageResult {
  final String priority; // 'P1', 'P2', 'P3'
  final String tokenNumber;
  final int painScore;
  final String chiefComplaint;
  final AISummaryModel aiSummary;

  TriageResult({
    required this.priority,
    required this.tokenNumber,
    required this.painScore,
    required this.chiefComplaint,
    required this.aiSummary,
  });
}

class TriageEngine {
  static TriageResult computeTriage({
    required String sessionId,
    required String mode, // 'allopathy' or 'ayush'
    required Map<String, dynamic> responses,
    required Map<String, dynamic> confidenceScores,
    int? painScoreInput,
  }) {
    int painScore = painScoreInput ?? 5;

    // Check if severity is explicitly provided in responses
    if (responses.containsKey('severity')) {
      final sevStr = responses['severity'].toString();
      final numMatch = RegExp(r'\b([1-9]|10)\b').firstMatch(sevStr);
      if (numMatch != null) {
        painScore = int.tryParse(numMatch.group(1)!) ?? painScore;
      }
    }

    // Check red flags and symptom severity in allopathy
    bool hasRedFlag = false;
    final site = (responses['site'] ?? '').toString().toLowerCase();
    final character = (responses['character'] ?? '').toString().toLowerCase();
    final radiation = (responses['radiation'] ?? '').toString().toLowerCase();
    final associated = (responses['associated'] ?? '').toString().toLowerCase();
    final onset = (responses['onset'] ?? '').toString().toLowerCase();

    if (site.contains('chest') && (radiation.contains('arm') || radiation.contains('shoulder') || associated.contains('breath') || associated.contains('sweat'))) {
      hasRedFlag = true;
      painScore = max(painScore, 8);
    } else if (character.contains('squeezing') || character.contains('stabbing') || associated.contains('fever') || onset.contains('sudden')) {
      if (painScoreInput == null && !responses.containsKey('severity')) {
        painScore = 7;
      }
    } else if (character.contains('dull') || onset.contains('gradual') || site.contains('back') || site.contains('joint')) {
      if (painScoreInput == null && !responses.containsKey('severity')) {
        painScore = 5;
      }
    }

    String priority;
    if (painScore >= 7 || hasRedFlag) {
      priority = 'P1';
    } else if (painScore >= 4) {
      priority = 'P2';
    } else {
      priority = 'P3';
    }

    // Generate Token Number e.g. TK-P1-248
    final randNum = 100 + Random().nextInt(899);
    final tokenNumber = 'TK-$priority-$randNum';

    // Build Chief Complaint string
    String chiefComplaint = '';
    if (mode == 'allopathy') {
      final siteVal = responses['site'] ?? 'Discomfort';
      final charVal = responses['character'] ?? 'pain';
      chiefComplaint = '$charVal in $siteVal (Severity: $painScore/10)';
    } else {
      final vikritiVal = responses['vikriti'] ?? 'Dosha Imbalance';
      final prakritiVal = responses['prakriti'] ?? 'Prakriti Assessment';
      chiefComplaint = '$vikritiVal in $prakritiVal';
    }

    // Build 3-Tier AI Summary: Certain, Not Sure, Unclear
    final List<String> certain = [];
    final List<String> notSure = [];
    final List<String> unclear = [];

    responses.forEach((key, val) {
      final conf = (confidenceScores[key] ?? 'certain').toString();
      final displayKey = key.toUpperCase();
      final valueStr = val.toString().trim();

      if (valueStr.isEmpty || conf == 'unclear') {
        unclear.add('Patient did not clearly answer parameter: $displayKey (Requires doctor inquiry)');
      } else if (conf == 'not_sure') {
        notSure.add('Patient was hesitant or ambiguous regarding $displayKey: "$valueStr"');
      } else {
        certain.add('$displayKey: $valueStr (Verified with high confidence)');
      }
    });

    if (hasRedFlag) {
      certain.insert(0, '🚨 RED FLAG ALERT: Acute chest discomfort with cardiac radiation pattern detected.');
    }

    final summaryText = priority == 'P1'
        ? 'URGENT (P1): High severity acute symptoms requiring immediate medical evaluation.'
        : priority == 'P2'
            ? 'MODERATE (P2): Sub-acute symptomatic presentation. Standard clinical examination recommended.'
            : 'ROUTINE (P3): Mild/chronic complaint. Routine outpatient consultation.';

    final recommendedAction = priority == 'P1'
        ? 'Immediate Doctor Consultation, Vital Signs Monitoring, Stat ECG/Diagnostic workup.'
        : priority == 'P2'
            ? 'Physical examination, symptom relief management, and lab test review.'
            : 'General consultation, lifestyle guidance, and regular follow-up.';

    final aiSummary = AISummaryModel(
      id: 'sum_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      certainItems: certain,
      notSureItems: notSure,
      unclearItems: unclear,
      triageSummary: summaryText,
      chiefComplaint: chiefComplaint,
      recommendedAction: recommendedAction,
    );

    return TriageResult(
      priority: priority,
      tokenNumber: tokenNumber,
      painScore: painScore,
      chiefComplaint: chiefComplaint,
      aiSummary: aiSummary,
    );
  }
}
