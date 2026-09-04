import 'package:get_it/get_it.dart';
import '../database/app_database.dart';
import '../database/daos/user_dao.dart';
import '../database/daos/patient_profile_dao.dart';
import '../database/daos/clinical_session_dao.dart';
import '../database/daos/clinical_intake_dao.dart';
import '../database/daos/document_dao.dart';
import '../database/daos/prescription_dao.dart';
import '../database/daos/ai_summary_dao.dart';
import '../database/daos/audit_log_dao.dart';
import '../shared/services/secure_storage_service.dart';
import '../shared/services/medical_ner_service.dart';
import '../shared/services/ocr_service.dart';
import '../voice/services/tts_service.dart';
import '../voice/services/stt_service.dart';
import '../voice/services/bhashini_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Database singleton
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);

  // DAOs
  getIt.registerLazySingleton<UserDao>(() => UserDao());
  getIt.registerLazySingleton<PatientProfileDao>(() => PatientProfileDao());
  getIt.registerLazySingleton<ClinicalSessionDao>(() => ClinicalSessionDao());
  getIt.registerLazySingleton<ClinicalIntakeDao>(() => ClinicalIntakeDao());
  getIt.registerLazySingleton<DocumentDao>(() => DocumentDao());
  getIt.registerLazySingleton<PrescriptionDao>(() => PrescriptionDao());
  getIt.registerLazySingleton<AISummaryDao>(() => AISummaryDao());
  getIt.registerLazySingleton<AuditLogDao>(() => AuditLogDao());

  // Services
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  getIt.registerLazySingleton<MedicalNERService>(() => MedicalNERService());
  getIt.registerLazySingleton<OCRService>(() => OCRService());

  // Voice Services
  getIt.registerLazySingleton<TTSService>(() => TTSService());
  getIt.registerLazySingleton<STTService>(() => STTService());
  getIt.registerLazySingleton<BhashiniService>(() => BhashiniService());
}
