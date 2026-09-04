import 'package:flutter_test/flutter_test.dart';
import 'package:medikiosk_ai/src/features/clinical_intake/domain/triage_engine.dart';
import 'package:medikiosk_ai/src/shared/constants/app_strings.dart';
import 'package:medikiosk_ai/src/shared/services/medical_ner_service.dart';
import 'package:medikiosk_ai/src/voice/services/stt_service.dart';

import 'package:medikiosk_ai/src/database/seed_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Triage Engine Tests', () {
    test('Calculates Priority 1 (Urgent) for high pain score >= 7', () {
      final result = TriageEngine.computeTriage(
        sessionId: 'sess_test_1',
        mode: 'allopathy',
        responses: {
          'site': 'Chest',
          'onset': 'Sudden',
          'character': 'Severe squeezing pressure',
          'radiation': 'Left arm and shoulder',
          'associated': 'Shortness of breath',
          'timing': 'Constant',
          'exacerbating': 'Worse on moving',
          'severity': '8 out of 10',
        },
        confidenceScores: {
          'site': 'certain',
          'onset': 'certain',
          'character': 'certain',
          'radiation': 'certain',
          'associated': 'certain',
          'timing': 'certain',
          'exacerbating': 'not_sure',
          'severity': 'certain',
        },
        painScoreInput: 8,
      );

      expect(result.priority, 'P1');
      expect(result.tokenNumber.startsWith('TK-P1-'), true);
      expect(result.painScore, 8);
      expect(result.aiSummary.certainItems.isNotEmpty, true);
      expect(result.aiSummary.notSureItems.isNotEmpty, true);
    });

    test('Calculates Priority 2 (Moderate) for pain score 5', () {
      final result = TriageEngine.computeTriage(
        sessionId: 'sess_test_2',
        mode: 'allopathy',
        responses: {
          'site': 'Lower back',
          'onset': 'Gradual',
          'character': 'Dull ache',
          'radiation': 'None',
          'associated': 'None',
          'timing': 'Intermittent',
          'exacerbating': 'Worse after sitting',
          'severity': '5 out of 10',
        },
        confidenceScores: {
          'site': 'certain',
          'onset': 'certain',
          'character': 'certain',
          'radiation': 'certain',
          'associated': 'certain',
          'timing': 'certain',
          'exacerbating': 'certain',
          'severity': 'certain',
        },
        painScoreInput: 5,
      );

      expect(result.priority, 'P2');
      expect(result.tokenNumber.startsWith('TK-P2-'), true);
      expect(result.painScore, 5);
    });

    test('Calculates Priority 3 (Routine) for pain score 2 in AYUSH mode', () {
      final result = TriageEngine.computeTriage(
        sessionId: 'sess_test_3',
        mode: 'ayush',
        responses: {
          'prakriti': 'Pitta Predominant',
          'vikriti': 'Pitta Aggravation',
          'sara': 'Madhyama',
          'samhanana': 'Susamhata',
          'pramana': 'Yathokta',
          'satmya': 'Sarva-Rasa Satmya',
          'satva': 'Pravara Satva',
          'ahara_shakti': 'Tikshnagni',
          'vyayama_shakti': 'Uttama',
          'vaya': 'Madhyama',
        },
        confidenceScores: {
          'prakriti': 'certain',
          'vikriti': 'certain',
          'sara': 'certain',
          'samhanana': 'certain',
          'pramana': 'certain',
          'satmya': 'not_sure',
          'satva': 'certain',
          'ahara_shakti': 'certain',
          'vyayama_shakti': 'certain',
          'vaya': 'certain',
        },
        painScoreInput: 2,
      );

      expect(result.priority, 'P3');
      expect(result.tokenNumber.startsWith('TK-P3-'), true);
      expect(result.chiefComplaint.contains('Pitta'), true);
    });
  });

  group('Medical NER Service Tests', () {
    test('Extracts drug name, dosage, frequency, and duration from prescription text', () {
      const text = 'Prescribe Tab Paracetamol 650mg twice daily for 5 days after food, and Tab Pantoprazole 40mg once daily for 7 days before food';
      final meds = MedicalNERService.extractPrescriptionItems(text);

      expect(meds.isNotEmpty, true);
      expect(meds.any((m) => m.drugName.toLowerCase().contains('paracetamol')), true);
      expect(meds.any((m) => m.dosage.contains('650mg')), true);
      expect(meds.any((m) => m.drugName.toLowerCase().contains('pantoprazole')), true);
    });

    test('Extracts lab values and identifies abnormal flags', () {
      const labText = '''
Total Cholesterol: 242 mg/dL
HDL Cholesterol: 35 mg/dL
Fasting Blood Sugar: 145 mg/dL
Hemoglobin: 14.2 g/dL
''';
      final result = MedicalNERService.extractLabEntities(labText);
      final labs = result['lab_values'] as List<Map<String, dynamic>>;
      final abnormal = result['abnormal'] as List<String>;

      expect(labs.length, greaterThanOrEqualTo(3));
      expect(abnormal.any((a) => a.contains('Cholesterol')), true);
      expect(abnormal.any((a) => a.contains('Fasting Blood Sugar')), true);
    });
  });

  group('Voice & Multilingual Localization Tests', () {
    test('Provides translations in all 5 supported languages', () {
      for (var lang in ['en', 'hi', 'ta', 'te', 'bn']) {
        final title = AppStrings.tr('app_name', lang: lang);
        expect(title.isNotEmpty, true);
        final welcome = AppStrings.tr('welcome_voice', lang: lang);
        expect(welcome.isNotEmpty, true);
      }
    });

    test('Assesses hesitation and confidence in voice transcripts', () {
      expect(STTService.assessConfidence('I have pain in chest since morning'), 'certain');
      expect(STTService.assessConfidence('I think maybe it started yesterday'), 'not_sure');
      expect(STTService.assessConfidence('shayad thoda dard hai'), 'not_sure');
      expect(STTService.assessConfidence(''), 'unclear');
    });
  });

  group('Authentication & Seed Data Tests', () {
    test('Verifies patient, doctor, and admin seeded credentials exist in database', () {
      final memoryTables = <String, List<Map<String, dynamic>>>{
        'users': [],
        'patient_profiles': [],
        'clinical_sessions': [],
        'clinical_intake': [],
        'patient_documents': [],
        'prescriptions': [],
        'ai_summaries': [],
        'audit_logs': [],
      };
      SeedData.seedWebMemoryTables(memoryTables);

      final users = memoryTables['users']!;
      expect(users.length, greaterThanOrEqualTo(5));

      // Test Patient lookup
      final patient = users.firstWhere((u) => u['abha_id'] == 'patient_1024@abdm');
      expect(patient['role'], 'patient');
      expect(patient['password_hash'], SeedData.hashPassword('patient123'));

      // Test Doctor lookup
      final doctor = users.firstWhere((u) => u['abha_id'] == 'dr_sharma@abdm');
      expect(doctor['role'], 'doctor');
      expect(doctor['password_hash'], SeedData.hashPassword('doctor123'));

      // Test Admin lookup
      final admin = users.firstWhere((u) => u['abha_id'] == 'admin_kiosk@abdm');
      expect(admin['role'], 'admin');
      expect(admin['password_hash'], SeedData.hashPassword('admin123'));
    });
  });
}
