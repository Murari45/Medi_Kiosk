import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di.dart';
import '../../../../database/daos/ai_summary_dao.dart';
import '../../../../database/daos/audit_log_dao.dart';
import '../../../../database/daos/clinical_intake_dao.dart';
import '../../../../database/daos/clinical_session_dao.dart';
import '../../../../shared/constants/app_strings.dart';
import '../../../../shared/models/audit_log_model.dart';
import '../../../../shared/models/clinical_intake_model.dart';
import '../../../../shared/models/clinical_session_model.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../voice/services/stt_service.dart';
import '../../../../voice/services/tts_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../doctor_dashboard/presentation/providers/doctor_provider.dart';
import '../../../patient_dashboard/presentation/providers/patient_provider.dart';
import '../../domain/dashavidha_algorithm.dart';
import '../../domain/socrates_algorithm.dart';
import '../../domain/triage_engine.dart';

class ClinicalIntakeState {
  final String mode; // 'allopathy' or 'ayush'
  final int currentQuestionIndex;
  final Map<String, dynamic> responses;
  final Map<String, dynamic> confidenceScores;
  final bool isSpeakingQuestion;
  final bool isListening;
  final String currentTranscript;
  final int retryCount;
  final bool isSubmitting;
  final TriageResult? finalTriageResult;

  ClinicalIntakeState({
    this.mode = 'allopathy',
    this.currentQuestionIndex = 0,
    Map<String, dynamic>? responses,
    Map<String, dynamic>? confidenceScores,
    this.isSpeakingQuestion = false,
    this.isListening = false,
    this.currentTranscript = '',
    this.retryCount = 0,
    this.isSubmitting = false,
    this.finalTriageResult,
  })  : responses = responses ?? {},
        confidenceScores = confidenceScores ?? {};

  int get totalQuestions => mode == 'allopathy'
      ? SocratesAlgorithm.questions.length
      : DashavidhaAlgorithm.parameters.length;

  bool get isLastQuestion => currentQuestionIndex >= totalQuestions - 1;

  ClinicalIntakeState copyWith({
    String? mode,
    int? currentQuestionIndex,
    Map<String, dynamic>? responses,
    Map<String, dynamic>? confidenceScores,
    bool? isSpeakingQuestion,
    bool? isListening,
    String? currentTranscript,
    int? retryCount,
    bool? isSubmitting,
    TriageResult? finalTriageResult,
  }) {
    return ClinicalIntakeState(
      mode: mode ?? this.mode,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      responses: responses ?? this.responses,
      confidenceScores: confidenceScores ?? this.confidenceScores,
      isSpeakingQuestion: isSpeakingQuestion ?? this.isSpeakingQuestion,
      isListening: isListening ?? this.isListening,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      retryCount: retryCount ?? this.retryCount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      finalTriageResult: finalTriageResult ?? this.finalTriageResult,
    );
  }
}

class ClinicalIntakeNotifier extends StateNotifier<ClinicalIntakeState> {
  final Ref _ref;
  final TTSService _tts = getIt<TTSService>();
  final STTService _stt = getIt<STTService>();
  final ClinicalSessionDao _sessionDao = getIt<ClinicalSessionDao>();
  final ClinicalIntakeDao _intakeDao = getIt<ClinicalIntakeDao>();
  final AISummaryDao _summaryDao = getIt<AISummaryDao>();
  final AuditLogDao _auditDao = getIt<AuditLogDao>();

  ClinicalIntakeNotifier(this._ref) : super(ClinicalIntakeState());

  void initMode(String mode, String lang) {
    state = ClinicalIntakeState(mode: mode);
    _stt.setLocale(lang);
    speakCurrentQuestion(lang);
  }

  void speakCurrentQuestion(String lang) async {
    state = state.copyWith(isSpeakingQuestion: true, currentTranscript: '');

    String questionText = '';
    if (state.mode == 'allopathy') {
      final q = SocratesAlgorithm.questions[state.currentQuestionIndex];
      questionText = AppStrings.tr(q.titleKey, lang: lang);
    } else {
      final q = DashavidhaAlgorithm.parameters[state.currentQuestionIndex];
      questionText = '${AppStrings.tr(q.titleKey, lang: lang)} (${q.sanskritTerm})';
    }

    await _tts.speak(
      questionText,
      langCode: lang,
      onComplete: () {
        state = state.copyWith(isSpeakingQuestion: false);
        // Automatically start listening after speaking for hands-free intake
        startVoiceListening(lang);
      },
    );
  }

  void startVoiceListening(String lang) async {
    if (state.isListening) return;

    state = state.copyWith(isListening: true, currentTranscript: '');
    _stt.setLocale(lang);

    await _stt.startListening(
      onResult: (words, isFinal) {
        state = state.copyWith(currentTranscript: words);
        if (isFinal && words.trim().isNotEmpty) {
          handleVoiceResponse(words.trim(), lang);
        }
      },
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void stopVoiceListening() async {
    await _stt.stopListening();
    state = state.copyWith(isListening: false);
  }

  void handleVoiceResponse(String transcript, String lang) async {
    stopVoiceListening();

    if (transcript.trim().isEmpty) {
      _handleUnclearResponse(lang);
      return;
    }

    final confidence = STTService.assessConfidence(transcript);
    final currentKey = _getCurrentQuestionKey();

    final newResponses = Map<String, dynamic>.from(state.responses);
    final newConfidence = Map<String, dynamic>.from(state.confidenceScores);

    newResponses[currentKey] = transcript;
    newConfidence[currentKey] = confidence;

    state = state.copyWith(
      responses: newResponses,
      confidenceScores: newConfidence,
      retryCount: 0,
    );

    if (confidence == 'not_sure') {
      NotificationService.showInfo('Response recorded (Marked as Not Sure for Doctor review)');
    }

    // Advance or Submit
    _advanceNextQuestion(lang);
  }

  void _handleUnclearResponse(String lang) async {
    if (state.retryCount < 1) {
      // First retry: voice repeat message
      state = state.copyWith(retryCount: state.retryCount + 1);
      final repeatText = AppStrings.tr('not_understood', lang: lang);
      await _tts.speak(
        repeatText,
        langCode: lang,
        onComplete: () => startVoiceListening(lang),
      );
    } else {
      // Mark as unclear and proceed so patient is not stuck
      final currentKey = _getCurrentQuestionKey();
      final newResponses = Map<String, dynamic>.from(state.responses);
      final newConfidence = Map<String, dynamic>.from(state.confidenceScores);

      newResponses[currentKey] = 'Unclear response';
      newConfidence[currentKey] = 'unclear';

      state = state.copyWith(
        responses: newResponses,
        confidenceScores: newConfidence,
        retryCount: 0,
      );

      _advanceNextQuestion(lang);
    }
  }

  void selectOptionManually(String optionText, String lang) {
    stopVoiceListening();
    final currentKey = _getCurrentQuestionKey();

    final newResponses = Map<String, dynamic>.from(state.responses);
    final newConfidence = Map<String, dynamic>.from(state.confidenceScores);

    newResponses[currentKey] = optionText;
    newConfidence[currentKey] = 'certain'; // Manual touch selection is certain

    state = state.copyWith(
      responses: newResponses,
      confidenceScores: newConfidence,
      currentTranscript: optionText,
      retryCount: 0,
    );

    _advanceNextQuestion(lang);
  }

  void _advanceNextQuestion(String lang) {
    if (state.isLastQuestion) {
      // Intake finished -> compute triage & save to SQLite
      submitIntake();
    } else {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
      speakCurrentQuestion(lang);
    }
  }

  String _getCurrentQuestionKey() {
    if (state.mode == 'allopathy') {
      return SocratesAlgorithm.questions[state.currentQuestionIndex].key;
    } else {
      return DashavidhaAlgorithm.parameters[state.currentQuestionIndex].key;
    }
  }

  Future<TriageResult?> submitIntake() async {
    state = state.copyWith(isSubmitting: true);
    final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final triageResult = TriageEngine.computeTriage(
        sessionId: sessionId,
        mode: state.mode,
        responses: state.responses,
        confidenceScores: state.confidenceScores,
      );

      final currentUser = _ref.read(authProvider).currentUser;
      final patientId = currentUser?.id ?? 'usr_patient_1';
      final patientName = currentUser?.name ?? 'Ramesh Kumar';

      // 1. Create Clinical Session in SQLite
      final session = ClinicalSessionModel(
        id: sessionId,
        patientId: patientId,
        patientName: patientName,
        mode: state.mode,
        priority: triageResult.priority,
        tokenNumber: triageResult.tokenNumber,
        painScore: triageResult.painScore,
        status: 'waiting',
        chiefComplaint: triageResult.chiefComplaint,
      );
      await _sessionDao.insertSession(session);

      // 2. Save Clinical Intake (SOCRATES or Dashavidha)
      final intake = ClinicalIntakeModel(
        id: 'intake_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        socratesData: state.mode == 'allopathy' ? state.responses : {},
        dashavidhaData: state.mode == 'ayush' ? state.responses : {},
        confidenceScores: state.confidenceScores,
      );
      await _intakeDao.insertIntake(intake);

      // 3. Save AI Summary (Certain, Not Sure, Unclear)
      await _summaryDao.insertOrUpdateSummary(triageResult.aiSummary);

      // 4. Log Audit
      await _auditDao.insertLog(AuditLogModel(
        action: 'TRIAGE_SESSION_COMPLETED',
        userId: patientId,
        userRole: 'patient',
        details: 'Intake completed (${state.mode.toUpperCase()}) for $patientName. Assigned ${triageResult.tokenNumber} (${triageResult.priority}).',
      ));

      // 5. Instantly refresh Doctor Queue & Patient Dashboard for live demo sync
      await _ref.read(doctorProvider.notifier).loadQueue();
      if (currentUser != null) {
        await _ref.read(patientProvider.notifier).loadPatientData(currentUser);
      }

      state = state.copyWith(
        isSubmitting: false,
        finalTriageResult: triageResult,
      );

      return triageResult;
    } catch (e) {
      debugPrint('Error submitting intake: $e');
      state = state.copyWith(isSubmitting: false);
      return null;
    }
  }
}

final clinicalIntakeProvider = StateNotifierProvider<ClinicalIntakeNotifier, ClinicalIntakeState>((ref) {
  return ClinicalIntakeNotifier(ref);
});
