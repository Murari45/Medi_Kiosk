import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di.dart';
import '../../../../database/daos/clinical_session_dao.dart';
import '../../../../shared/models/clinical_session_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DoctorState {
  final List<ClinicalSessionModel> activeQueue;
  final List<ClinicalSessionModel> completedSessions;
  final bool isLoading;
  final String? errorMessage;

  DoctorState({
    this.activeQueue = const [],
    this.completedSessions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DoctorState copyWith({
    List<ClinicalSessionModel>? activeQueue,
    List<ClinicalSessionModel>? completedSessions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DoctorState(
      activeQueue: activeQueue ?? this.activeQueue,
      completedSessions: completedSessions ?? this.completedSessions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DoctorNotifier extends StateNotifier<DoctorState> {
  final ClinicalSessionDao _sessionDao = getIt<ClinicalSessionDao>();

  DoctorNotifier() : super(DoctorState());

  Future<void> loadQueue() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final waitingList = await _sessionDao.getDoctorQueue(status: 'waiting');
      final completedList = await _sessionDao.getDoctorQueue(status: 'completed');

      if (!mounted) return;

      state = state.copyWith(
        activeQueue: waitingList,
        completedSessions: completedList,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load doctor queue: $e');
    }
  }

  Future<void> updateStatus(String sessionId, String status) async {
    await _sessionDao.updateSessionStatus(sessionId, status);
    await loadQueue();
  }
}

final doctorProvider = StateNotifierProvider<DoctorNotifier, DoctorState>((ref) {
  final notifier = DoctorNotifier();
  ref.listen<UserModel?>(
    authProvider.select((s) => s.currentUser),
    (previous, next) {
      if (next != null && next.role == 'doctor' && (previous == null || previous.id != next.id)) {
        notifier.loadQueue();
      }
    },
    fireImmediately: true,
  );
  return notifier;
});
