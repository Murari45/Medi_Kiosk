import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di.dart';
import '../../../../database/daos/clinical_session_dao.dart';
import '../../../../shared/models/clinical_session_model.dart';
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

  DoctorNotifier() : super(DoctorState()) {
    loadQueue();
  }

  Future<void> loadQueue() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final waitingList = await _sessionDao.getDoctorQueue(status: 'waiting');
      final completedList = await _sessionDao.getDoctorQueue(status: 'completed');

      state = state.copyWith(
        activeQueue: waitingList,
        completedSessions: completedList,
        isLoading: false,
      );
    } catch (e) {
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
  final auth = ref.watch(authProvider);
  if (auth.currentUser != null && auth.currentUser!.role == 'doctor') {
    notifier.loadQueue();
  }
  return notifier;
});
