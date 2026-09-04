import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di.dart';
import '../../../../database/daos/audit_log_dao.dart';
import '../../../../database/daos/clinical_session_dao.dart';
import '../../../../database/daos/document_dao.dart';
import '../../../../database/daos/patient_profile_dao.dart';
import '../../../../database/daos/prescription_dao.dart';
import '../../../../database/daos/user_dao.dart';
import '../../../../shared/models/audit_log_model.dart';
import '../../../../shared/models/clinical_session_model.dart';
import '../../../../shared/models/patient_document_model.dart';
import '../../../../shared/models/patient_profile_model.dart';
import '../../../../shared/models/prescription_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PatientState {
  final UserModel? user;
  final PatientProfileModel? profile;
  final List<ClinicalSessionModel> sessions;
  final List<PatientDocumentModel> documents;
  final List<PrescriptionModel> prescriptions;
  final bool isLoading;
  final String? message;

  PatientState({
    this.user,
    this.profile,
    this.sessions = const [],
    this.documents = const [],
    this.prescriptions = const [],
    this.isLoading = false,
    this.message,
  });

  PatientState copyWith({
    UserModel? user,
    PatientProfileModel? profile,
    List<ClinicalSessionModel>? sessions,
    List<PatientDocumentModel>? documents,
    List<PrescriptionModel>? prescriptions,
    bool? isLoading,
    String? message,
  }) {
    return PatientState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      sessions: sessions ?? this.sessions,
      documents: documents ?? this.documents,
      prescriptions: prescriptions ?? this.prescriptions,
      isLoading: isLoading ?? this.isLoading,
      message: message,
    );
  }
}

class PatientNotifier extends StateNotifier<PatientState> {
  final PatientProfileDao _profileDao = getIt<PatientProfileDao>();
  final ClinicalSessionDao _sessionDao = getIt<ClinicalSessionDao>();
  final DocumentDao _documentDao = getIt<DocumentDao>();
  final PrescriptionDao _prescriptionDao = getIt<PrescriptionDao>();
  final UserDao _userDao = getIt<UserDao>();
  final AuditLogDao _auditDao = getIt<AuditLogDao>();

  PatientNotifier() : super(PatientState());

  Future<void> loadPatientData(UserModel user) async {
    state = state.copyWith(isLoading: true, user: user);

    final profile = await _profileDao.getProfileByUserId(user.id);
    final sessions = await _sessionDao.getPatientSessions(user.id);
    final documents = await _documentDao.getDocumentsByPatientId(user.id);
    final prescriptions = await _prescriptionDao.getPrescriptionsByPatientId(user.id);

    state = state.copyWith(
      profile: profile ?? PatientProfileModel(userId: user.id),
      sessions: sessions,
      documents: documents,
      prescriptions: prescriptions,
      isLoading: false,
    );
  }

  Future<bool> updateProfile({
    required String name,
    required String bloodType,
    required String allergies,
    required String gender,
    required String dob,
  }) async {
    if (state.user == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      final updatedUser = state.user!.copyWith(name: name);
      await _userDao.updateUser(updatedUser);

      final updatedProfile = (state.profile ?? PatientProfileModel(userId: state.user!.id)).copyWith(
        bloodType: bloodType,
        allergies: allergies,
        gender: gender,
        dateOfBirth: dob,
      );
      await _profileDao.insertOrUpdateProfile(updatedProfile);

      await _auditDao.insertLog(AuditLogModel(
        action: 'PROFILE_UPDATED',
        userId: state.user!.id,
        userRole: 'patient',
        details: 'Patient ${state.user!.name} updated health profile details.',
      ));

      state = state.copyWith(
        user: updatedUser,
        profile: updatedProfile,
        isLoading: false,
        message: 'Profile updated successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, message: 'Failed to update profile: $e');
      return false;
    }
  }

  Future<void> refreshDocuments() async {
    if (state.user == null) return;
    final docs = await _documentDao.getDocumentsByPatientId(state.user!.id);
    state = state.copyWith(documents: docs);
  }
}

final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>((ref) {
  final notifier = PatientNotifier();
  final auth = ref.watch(authProvider);
  if (auth.currentUser != null && auth.currentUser!.role == 'patient') {
    notifier.loadPatientData(auth.currentUser!);
  }
  return notifier;
});
