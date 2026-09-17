import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SeedData {
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static void seedWebMemoryTables(Map<String, List<Map<String, dynamic>>> tables) {
    if ((tables['users'] ?? []).isNotEmpty) return;

    final now = DateTime.now();

    // 1. Seed Users
    tables['users'] = [
      {
        'id': 'usr_patient_1',
        'abha_id': 'patient_1024@abdm',
        'name': 'Ramesh Kumar',
        'phone': '9876543210',
        'email': 'ramesh.kumar@example.com',
        'password_hash': hashPassword('patient123'),
        'role': 'patient',
        'profile_picture_path': null,
        'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
      },
      {
        'id': 'usr_patient_2',
        'abha_id': 'patient_2048@abdm',
        'name': 'Sunita Devi',
        'phone': '9812345678',
        'email': 'sunita.devi@example.com',
        'password_hash': hashPassword('patient123'),
        'role': 'patient',
        'profile_picture_path': null,
        'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 'usr_patient_3',
        'abha_id': 'patient_4096@abdm',
        'name': 'Ananya Sharma',
        'phone': '9723456789',
        'email': 'ananya.sharma@example.com',
        'password_hash': hashPassword('patient123'),
        'role': 'patient',
        'profile_picture_path': null,
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'usr_doctor_1',
        'abha_id': 'dr_sharma@abdm',
        'name': 'Dr. Rajesh Sharma, MD',
        'phone': '9899001122',
        'email': 'dr.rajesh@medikiosk.ai',
        'password_hash': hashPassword('doctor123'),
        'role': 'doctor',
        'profile_picture_path': null,
        'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': 'usr_admin_1',
        'abha_id': 'admin_kiosk@abdm',
        'name': 'Kiosk Administrator',
        'phone': '9900112233',
        'email': 'admin@medikiosk.ai',
        'password_hash': hashPassword('admin123'),
        'role': 'admin',
        'profile_picture_path': null,
        'created_at': now.subtract(const Duration(days: 60)).toIso8601String(),
      },
    ];

    // 2. Seed Patient Profiles
    tables['patient_profiles'] = [
      {
        'user_id': 'usr_patient_1',
        'blood_type': 'O+',
        'allergies': 'Penicillin, Dust',
        'date_of_birth': '1974-04-12',
        'gender': 'Male',
        'demographics_json': jsonEncode({
          'address': 'Sector 14, Gurugram, Haryana',
          'aadhaar_last4': '4512',
          'emergency_contact': '9876543211 (Wife)',
        }),
      },
      {
        'user_id': 'usr_patient_2',
        'blood_type': 'B+',
        'allergies': 'Sulfa drugs',
        'date_of_birth': '1982-11-23',
        'gender': 'Female',
        'demographics_json': jsonEncode({
          'address': 'Andheri West, Mumbai, Maharashtra',
          'aadhaar_last4': '8901',
          'emergency_contact': '9812345679 (Son)',
        }),
      },
      {
        'user_id': 'usr_patient_3',
        'blood_type': 'A+',
        'allergies': 'None',
        'date_of_birth': '1996-08-05',
        'gender': 'Female',
        'demographics_json': jsonEncode({
          'address': 'Salt Lake City, Kolkata, West Bengal',
          'aadhaar_last4': '3321',
          'emergency_contact': '9723456780 (Father)',
        }),
      },
    ];

    // 3. Seed Clinical Sessions
    tables['clinical_sessions'] = [
      {
        'id': 'sess_101',
        'patient_id': 'usr_patient_1',
        'doctor_id': 'usr_doctor_1',
        'mode': 'allopathy',
        'priority': 'P1',
        'token_number': 'TK-P1-001',
        'pain_score': 8,
        'status': 'waiting',
        'chief_complaint': 'Acute chest tightness and radiating left arm pain since morning',
        'created_at': now.subtract(const Duration(minutes: 25)).toIso8601String(),
      },
      {
        'id': 'sess_102',
        'patient_id': 'usr_patient_2',
        'doctor_id': 'usr_doctor_1',
        'mode': 'allopathy',
        'priority': 'P2',
        'token_number': 'TK-P2-014',
        'pain_score': 5,
        'status': 'waiting',
        'chief_complaint': 'Moderate lower back pain with stiffness upon waking',
        'created_at': now.subtract(const Duration(minutes: 40)).toIso8601String(),
      },
      {
        'id': 'sess_103',
        'patient_id': 'usr_patient_3',
        'doctor_id': 'usr_doctor_1',
        'mode': 'ayush',
        'priority': 'P3',
        'token_number': 'TK-P3-088',
        'pain_score': 2,
        'status': 'waiting',
        'chief_complaint': 'Chronic indigestion, Pitta aggravation, and seasonal sleep disturbance',
        'created_at': now.subtract(const Duration(minutes: 55)).toIso8601String(),
      },
    ];

    // 4. Seed Clinical Intake
    tables['clinical_intake'] = [
      {
        'id': 'intake_101',
        'session_id': 'sess_101',
        'socrates_json': jsonEncode({
          'site': 'Substernal chest region',
          'onset': 'Sudden onset 4 hours ago while climbing stairs',
          'character': 'Heavy pressure and squeezing sensation',
          'radiation': 'Radiates down the left shoulder and inner arm',
          'associated': 'Mild diaphoresis, shortness of breath, nausea',
          'timing': 'Persistent with increasing discomfort',
          'exacerbating': 'Worsens with mild exertion, resting offers slight relief',
          'severity': '8 out of 10 on visual analog scale',
        }),
        'dashavidha_json': jsonEncode({}),
        'confidence_scores_json': jsonEncode({
          'site': 'certain',
          'onset': 'certain',
          'character': 'certain',
          'radiation': 'certain',
          'associated': 'not_sure',
          'timing': 'certain',
          'exacerbating': 'not_sure',
          'severity': 'certain',
        }),
      },
    ];

    // 5. Seed AI Summary
    tables['ai_summaries'] = [
      {
        'id': 'sum_101',
        'session_id': 'sess_101',
        'certain_json': jsonEncode([
          'Substernal chest pressure rated 8/10 on pain scale (High Severity)',
          'Pain started suddenly 4 hours ago while climbing stairs',
          'Pain character described as heavy squeezing sensation',
          'Clear radiation pattern to left inner arm and shoulder',
          'Known history: Allergy to Penicillin, blood type O+',
        ]),
        'not_sure_json': jsonEncode([
          'Patient hesitated when asked if diaphoresis (sweating) started before or after chest pain',
          'Patient was unsure whether antacids taken 2 hours ago provided any temporary relief',
        ]),
        'unclear_json': jsonEncode([
          'Exact duration of previous similar sub-acute episodes over the past month',
          'Family history of premature coronary artery disease could not be confirmed by patient',
        ]),
        'triage_summary': 'URGENT: 50-year-old male presenting with acute high-risk ischemic chest pain symptoms (P1). Immediate ECG and cardiac troponin advised.',
        'chief_complaint': 'Acute chest tightness and radiating left arm pain',
        'recommended_action': 'Stat 12-lead ECG, Sublingual Nitroglycerin evaluation, Cardiac enzyme panel.',
        'created_at': now.subtract(const Duration(minutes: 24)).toIso8601String(),
      },
    ];

    // 6. Seed Patient Documents
    tables['patient_documents'] = [
      {
        'id': 'doc_101',
        'patient_id': 'usr_patient_1',
        'file_name': 'Lipid_Profile_Report_Aug2026.pdf',
        'doc_type': 'Lab Report',
        'extracted_text': 'LIPID PROFILE TEST RESULTS:\nTotal Cholesterol: 242 mg/dL [HIGH]\nTriglycerides: 195 mg/dL [HIGH]\nHDL Cholesterol: 38 mg/dL [LOW]\nLDL Cholesterol: 165 mg/dL [HIGH]\nVLDL: 39 mg/dL\nFasting Blood Sugar: 112 mg/dL [BORDERLINE]',
        'entities_json': jsonEncode({
          'lab_values': [
            {'test': 'Total Cholesterol', 'value': '242 mg/dL', 'flag': 'HIGH'},
            {'test': 'LDL Cholesterol', 'value': '165 mg/dL', 'flag': 'HIGH'},
            {'test': 'Triglycerides', 'value': '195 mg/dL', 'flag': 'HIGH'},
            {'test': 'HDL Cholesterol', 'value': '38 mg/dL', 'flag': 'LOW'},
          ],
          'abnormal': ['High Cholesterol', 'Elevated LDL', 'Low HDL'],
        }),
        'image_path': null,
        'created_at': now.subtract(const Duration(days: 12)).toIso8601String(),
      },
    ];

    // 7. Seed Audit Logs
    tables['audit_logs'] = [
      {
        'id': 1,
        'action': 'SYSTEM_STARTUP',
        'user_id': 'system',
        'user_role': 'system',
        'details': 'AyuDwar initialized on secure runtime.',
        'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 2,
        'action': 'PATIENT_TRIAGE_COMPLETED',
        'user_id': 'usr_patient_1',
        'user_role': 'patient',
        'details': 'Patient Ramesh Kumar completed SOCRATES pre-intake. Assigned Token TK-P1-001.',
        'timestamp': now.subtract(const Duration(minutes: 25)).toIso8601String(),
      },
    ];
  }

  static Future<void> seedInitialData(Database db) async {
    final res = await db.rawQuery('SELECT COUNT(*) FROM users');
    if (res.isNotEmpty) {
      final countVal = res.first.values.first;
      if (countVal is int && countVal > 0) return;
    }

    final dummy = <String, List<Map<String, dynamic>>>{};
    seedWebMemoryTables(dummy);

    for (var u in dummy['users'] ?? []) {
      await db.insert('users', u);
    }
    for (var p in dummy['patient_profiles'] ?? []) {
      await db.insert('patient_profiles', p);
    }
    for (var s in dummy['clinical_sessions'] ?? []) {
      await db.insert('clinical_sessions', s);
    }
    for (var i in dummy['clinical_intake'] ?? []) {
      await db.insert('clinical_intake', i);
    }
    for (var a in dummy['ai_summaries'] ?? []) {
      await db.insert('ai_summaries', a);
    }
    for (var d in dummy['patient_documents'] ?? []) {
      await db.insert('patient_documents', d);
    }
    for (var l in dummy['audit_logs'] ?? []) {
      final logCopy = Map<String, dynamic>.from(l)..remove('id');
      await db.insert('audit_logs', logCopy);
    }
  }
}
