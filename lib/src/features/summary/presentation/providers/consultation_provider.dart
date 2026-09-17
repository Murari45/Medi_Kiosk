import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di.dart';
import '../../../../database/daos/ai_summary_dao.dart';
import '../../../../database/daos/audit_log_dao.dart';
import '../../../../database/daos/clinical_intake_dao.dart';
import '../../../../database/daos/clinical_session_dao.dart';
import '../../../../database/daos/patient_profile_dao.dart';
import '../../../../database/daos/prescription_dao.dart';
import '../../../../database/daos/user_dao.dart';
import '../../../../shared/models/ai_summary_model.dart';
import '../../../../shared/models/audit_log_model.dart';
import '../../../../shared/models/clinical_intake_model.dart';
import '../../../../shared/models/clinical_session_model.dart';
import '../../../../shared/models/patient_profile_model.dart';
import '../../../../shared/models/prescription_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/medical_ner_service.dart';
import '../../../../voice/services/stt_service.dart';
import '../../../../voice/services/tts_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../doctor_dashboard/presentation/providers/doctor_provider.dart';
import '../../../patient_dashboard/presentation/providers/patient_provider.dart';

class ConsultationState {
  final ClinicalSessionModel? session;
  final UserModel? patient;
  final PatientProfileModel? patientProfile;
  final ClinicalIntakeModel? intake;
  final AISummaryModel? aiSummary;
  final List<PrescriptionItem> prescribedMedications;
  final String doctorNotes;
  final String diagnosis;
  final bool isLoading;
  final bool isReadingSummary;
  final bool isDictatingRx;
  final String currentDictation;

  ConsultationState({
    this.session,
    this.patient,
    this.patientProfile,
    this.intake,
    this.aiSummary,
    this.prescribedMedications = const [],
    this.doctorNotes = '',
    this.diagnosis = 'Acute Symptomatic Presentation',
    this.isLoading = false,
    this.isReadingSummary = false,
    this.isDictatingRx = false,
    this.currentDictation = '',
  });

  ConsultationState copyWith({
    ClinicalSessionModel? session,
    UserModel? patient,
    PatientProfileModel? patientProfile,
    ClinicalIntakeModel? intake,
    AISummaryModel? aiSummary,
    List<PrescriptionItem>? prescribedMedications,
    String? doctorNotes,
    String? diagnosis,
    bool? isLoading,
    bool? isReadingSummary,
    bool? isDictatingRx,
    String? currentDictation,
  }) {
    return ConsultationState(
      session: session ?? this.session,
      patient: patient ?? this.patient,
      patientProfile: patientProfile ?? this.patientProfile,
      intake: intake ?? this.intake,
      aiSummary: aiSummary ?? this.aiSummary,
      prescribedMedications: prescribedMedications ?? this.prescribedMedications,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      diagnosis: diagnosis ?? this.diagnosis,
      isLoading: isLoading ?? this.isLoading,
      isReadingSummary: isReadingSummary ?? this.isReadingSummary,
      isDictatingRx: isDictatingRx ?? this.isDictatingRx,
      currentDictation: currentDictation ?? this.currentDictation,
    );
  }
}

class ConsultationNotifier extends StateNotifier<ConsultationState> {
  final Ref _ref;
  final ClinicalSessionDao _sessionDao = getIt<ClinicalSessionDao>();
  final UserDao _userDao = getIt<UserDao>();
  final PatientProfileDao _profileDao = getIt<PatientProfileDao>();
  final ClinicalIntakeDao _intakeDao = getIt<ClinicalIntakeDao>();
  final AISummaryDao _summaryDao = getIt<AISummaryDao>();
  final PrescriptionDao _prescriptionDao = getIt<PrescriptionDao>();
  final AuditLogDao _auditDao = getIt<AuditLogDao>();
  final TTSService _tts = getIt<TTSService>();
  final STTService _stt = getIt<STTService>();

  ConsultationNotifier(this._ref) : super(ConsultationState());

  Future<void> loadSession(String sessionId) async {
    state = state.copyWith(isLoading: true);

    final session = await _sessionDao.getSessionById(sessionId);
    if (session == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final patient = await _userDao.getUserById(session.patientId);
    final profile = await _profileDao.getProfileByUserId(session.patientId);
    final intake = await _intakeDao.getIntakeBySessionId(sessionId);
    final summary = await _summaryDao.getSummaryBySessionId(sessionId);

    // Check if prescription already exists
    final existingRx = await _prescriptionDao.getPrescriptionBySessionId(sessionId);

    state = state.copyWith(
      session: session,
      patient: patient,
      patientProfile: profile,
      intake: intake,
      aiSummary: summary,
      prescribedMedications: existingRx?.medications ?? [
        PrescriptionItem(
          drugName: 'Paracetamol',
          dosage: '650mg',
          frequency: 'Twice Daily (BD)',
          duration: '5 days',
          instruction: 'After food',
        ),
      ],
      diagnosis: existingRx?.diagnosis.isNotEmpty == true
          ? existingRx!.diagnosis
          : (session.chiefComplaint ?? 'Clinical Pre-Intake Evaluation'),
      doctorNotes: existingRx?.instructions ?? 'Patient advised rest and adequate hydration.',
      isLoading: false,
    );
  }

  void readSummaryAloud() async {
    final summary = state.aiSummary;
    if (summary == null) return;

    state = state.copyWith(isReadingSummary: true);
    final lang = _ref.read(authProvider).currentLanguage;

    final textToRead = StringBuffer();
    switch (lang) {
      case 'hi':
        textToRead.write('मरीज ${state.patient?.name ?? ""} का एआई क्लिनिकल सारांश। ');
        textToRead.write('मुख्य शिकायत: ${summary.chiefComplaint}। ');
        if (summary.certainItems.isNotEmpty) {
          textToRead.write('सत्यापित तथ्य: ${summary.certainItems.join("। ")}। ');
        }
        if (summary.notSureItems.isNotEmpty) {
          textToRead.write('अनिश्चित तथ्य: ${summary.notSureItems.join("। ")}। ');
        }
        if (summary.unclearItems.isNotEmpty) {
          textToRead.write('स्पष्टीकरण योग्य बिंदु: ${summary.unclearItems.join("। ")}। ');
        }
        textToRead.write('अनुशंसित कार्रवाई: ${summary.recommendedAction}');
        break;
      case 'ta':
        textToRead.write('நோயாளி ${state.patient?.name ?? ""} க்கான AI மருத்துவ சுருக்கம். ');
        textToRead.write('முதன்மை பிரச்சனை: ${summary.chiefComplaint}. ');
        if (summary.certainItems.isNotEmpty) {
          textToRead.write('உறுதிப்படுத்தப்பட்ட விவரங்கள்: ${summary.certainItems.join(". ")}. ');
        }
        if (summary.notSureItems.isNotEmpty) {
          textToRead.write('தயக்கம் உள்ள விவரங்கள்: ${summary.notSureItems.join(". ")}. ');
        }
        if (summary.unclearItems.isNotEmpty) {
          textToRead.write('தெளிவுபடுத்த வேண்டியவை: ${summary.unclearItems.join(". ")}. ');
        }
        textToRead.write('பரிந்துரைக்கப்பட்ட நடவடிக்கை: ${summary.recommendedAction}');
        break;
      case 'te':
        textToRead.write('రోగి ${state.patient?.name ?? ""} కొరకు AI క్లినికల్ సారాంశం. ');
        textToRead.write('ప్రధాన సమస్య: ${summary.chiefComplaint}. ');
        if (summary.certainItems.isNotEmpty) {
          textToRead.write('నిర్ధారిత అంశాలు: ${summary.certainItems.join(". ")}. ');
        }
        if (summary.notSureItems.isNotEmpty) {
          textToRead.write('అనిశ్చిత అంశాలు: ${summary.notSureItems.join(". ")}. ');
        }
        if (summary.unclearItems.isNotEmpty) {
          textToRead.write('స్పష్టత అవసరమైన అంశాలు: ${summary.unclearItems.join(". ")}. ');
        }
        textToRead.write('సిఫార్సు చేయబడిన చర్య: ${summary.recommendedAction}');
        break;
      case 'bn':
        textToRead.write('রোগী ${state.patient?.name ?? ""} এর এআই ক্লিনিকাল সারাংশ। ');
        textToRead.write('প্রধান অভিযোগ: ${summary.chiefComplaint}। ');
        if (summary.certainItems.isNotEmpty) {
          textToRead.write('নিশ্চিত তথ্য: ${summary.certainItems.join("। ")}। ');
        }
        if (summary.notSureItems.isNotEmpty) {
          textToRead.write('অনিশ্চিত তথ্য: ${summary.notSureItems.join("। ")}। ');
        }
        if (summary.unclearItems.isNotEmpty) {
          textToRead.write('স্পষ্টীকরণ প্রয়োজন এমন তথ্য: ${summary.unclearItems.join("। ")}। ');
        }
        textToRead.write('প্রস্তাবিত পদক্ষেপ: ${summary.recommendedAction}');
        break;
      default:
        textToRead.write('AI Pre-Intake Summary for ${state.patient?.name ?? "patient"}. ');
        textToRead.write('Chief complaint: ${summary.chiefComplaint}. ');
        if (summary.certainItems.isNotEmpty) {
          textToRead.write('Certain findings: ${summary.certainItems.join(". ")}. ');
        }
        if (summary.notSureItems.isNotEmpty) {
          textToRead.write('Items with uncertainty: ${summary.notSureItems.join(". ")}. ');
        }
        if (summary.unclearItems.isNotEmpty) {
          textToRead.write('Unclear items requiring clarification: ${summary.unclearItems.join(". ")}. ');
        }
        textToRead.write('Recommended action: ${summary.recommendedAction}');
    }

    await _tts.speak(
      textToRead.toString(),
      langCode: lang,
      onComplete: () {
        state = state.copyWith(isReadingSummary: false);
      },
    );
  }

  void stopReadingSummary() async {
    await _tts.stop();
    state = state.copyWith(isReadingSummary: false);
  }

  void startVoiceDictation() async {
    state = state.copyWith(isDictatingRx: true, currentDictation: '');

    await _stt.startListening(
      onResult: (words, isFinal) {
        state = state.copyWith(currentDictation: words);
        if (isFinal && words.trim().isNotEmpty) {
          _processDictation(words.trim());
        }
      },
      listenFor: const Duration(seconds: 20),
    );
  }

  void stopVoiceDictation() async {
    await _stt.stopListening();
    state = state.copyWith(isDictatingRx: false);
    if (state.currentDictation.trim().isNotEmpty) {
      _processDictation(state.currentDictation.trim());
    }
  }

  void _processDictation(String text) {
    // Extract medications via MedicalNER
    final parsedMeds = MedicalNERService.extractPrescriptionItems(text);
    if (parsedMeds.isNotEmpty) {
      final updated = List<PrescriptionItem>.from(state.prescribedMedications)..addAll(parsedMeds);
      state = state.copyWith(
        prescribedMedications: updated,
        doctorNotes: '${state.doctorNotes}\nVoice Note: $text'.trim(),
        isDictatingRx: false,
      );
    } else {
      state = state.copyWith(
        doctorNotes: '${state.doctorNotes}\nVoice Note: $text'.trim(),
        isDictatingRx: false,
      );
    }
  }

  void addMedication(PrescriptionItem item) {
    final updated = List<PrescriptionItem>.from(state.prescribedMedications)..add(item);
    state = state.copyWith(prescribedMedications: updated);
  }

  void removeMedication(int index) {
    final updated = List<PrescriptionItem>.from(state.prescribedMedications)..removeAt(index);
    state = state.copyWith(prescribedMedications: updated);
  }

  void updateDiagnosis(String diag) {
    state = state.copyWith(diagnosis: diag);
  }

  void updateNotes(String notes) {
    state = state.copyWith(doctorNotes: notes);
  }

  Future<bool> completeConsultation(String doctorId, String doctorName) async {
    final session = state.session;
    if (session == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      // 1. Create and save Prescription
      final prescription = PrescriptionModel(
        id: 'rx_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: session.id,
        doctorId: doctorId,
        patientId: session.patientId,
        medications: state.prescribedMedications,
        instructions: state.doctorNotes,
        diagnosis: state.diagnosis,
      );
      await _prescriptionDao.insertPrescription(prescription);

      // 2. Mark Session as Completed
      await _sessionDao.updateSessionStatus(session.id, 'completed', doctorId: doctorId);

      // 3. Log Audit Trail
      await _auditDao.insertLog(AuditLogModel(
        action: 'CONSULTATION_COMPLETED',
        userId: doctorId,
        userRole: 'doctor',
        details: 'Doctor $doctorName completed consultation for ${state.patient?.name ?? session.patientId} (Token ${session.tokenNumber}).',
      ));

      // 4. Instantly sync doctor queue and patient portal records
      await _ref.read(doctorProvider.notifier).loadQueue();
      if (state.patient != null) {
        await _ref.read(patientProvider.notifier).loadPatientData(state.patient!);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Error completing consultation: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}

final consultationProvider = StateNotifierProvider<ConsultationNotifier, ConsultationState>((ref) {
  return ConsultationNotifier(ref);
});
