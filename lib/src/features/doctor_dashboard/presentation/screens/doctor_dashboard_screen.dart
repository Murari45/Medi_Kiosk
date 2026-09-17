import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_strings.dart';
import '../../../../shared/models/clinical_session_model.dart';
import '../../../../voice/services/tts_service.dart';
import '../../../../shared/widgets/portal_switcher_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/doctor_provider.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  int _selectedSidebarIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorProvider.notifier).loadQueue();
    });
  }

  void _openConsultation(ClinicalSessionModel session) {
    context.push('/consultation/${session.id}');
  }

  void _speakBrief(String text) {
    final tts = getIt<TTSService>();
    final lang = ref.read(authProvider).currentLanguage;
    tts.speak(text, langCode: lang);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final doctorState = ref.watch(doctorProvider);
    final currentUser = auth.currentUser;
    final lang = auth.currentLanguage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.ayushGreenContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.medical_information_rounded, color: AppColors.ayushGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                AppStrings.tr('role_doctor', lang: lang),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.tr('live_demo_sync', lang: lang),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(doctorProvider.notifier).loadQueue(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Chip(
              backgroundColor: AppColors.surfaceVariant,
              avatar: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 16),
              label: Text(
                currentUser?.name ?? 'Dr. Sharma, MD',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.priorityP1Container,
                foregroundColor: AppColors.priorityP1,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: Text(
                AppStrings.tr('sign_out', lang: lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/auth');
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const PortalDemoSwitcher(currentPortal: 'doctor'),
            Expanded(
              child: Row(
                children: [
                  // Left Sidebar
                  _buildSidebar(lang),
                  const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),

                  // Main Content Area
                  Expanded(
                    child: doctorState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildMainView(doctorState, lang),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(String lang) {
    return Container(
      width: 250,
      color: AppColors.surface,
      child: Column(
        children: [
          // Doctor Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.watch(authProvider).currentUser?.name ?? 'Dr. Rajesh Sharma',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AppStrings.tr('doc_opd_active', lang: lang),
                        style: const TextStyle(fontSize: 11, color: AppColors.certainGreen, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildSidebarItem(0, Icons.queue_play_next_rounded, AppStrings.tr('doc_sidebar_queue', lang: lang), AppStrings.tr('doc_sidebar_queue_sub', lang: lang)),
                _buildSidebarItem(1, Icons.calendar_today_rounded, AppStrings.tr('doc_sidebar_schedule', lang: lang), AppStrings.tr('doc_sidebar_schedule_sub', lang: lang)),
                _buildSidebarItem(2, Icons.history_rounded, AppStrings.tr('doc_sidebar_previous', lang: lang), AppStrings.tr('doc_sidebar_previous_sub', lang: lang)),
                _buildSidebarItem(3, Icons.archive_rounded, AppStrings.tr('doc_sidebar_archived', lang: lang), AppStrings.tr('doc_sidebar_archived_sub', lang: lang)),
              ],
            ),
          ),

          // Logout
          const Divider(height: 1, color: AppColors.border),
          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.priorityP1),
              title: Text(AppStrings.tr('sign_out', lang: lang), style: const TextStyle(color: AppColors.priorityP1, fontWeight: FontWeight.w600, fontSize: 14)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (mounted) context.go('/auth');
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title, String subtitle) {
    final isSelected = _selectedSidebarIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
          onTap: () => setState(() => _selectedSidebarIndex = index),
        ),
      ),
    );
  }

  Widget _buildMainView(DoctorState doctorState, String lang) {
    if (doctorState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.priorityP1, size: 48),
              const SizedBox(height: 12),
              Text(
                doctorState.errorMessage!,
                style: const TextStyle(color: AppColors.priorityP1, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(doctorProvider.notifier).loadQueue(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppStrings.tr('btn_continue', lang: lang)),
              ),
            ],
          ),
        ),
      );
    }

    switch (_selectedSidebarIndex) {
      case 1:
        return _buildScheduleView(lang);
      case 2:
        return _buildPreviousPatientsView(doctorState, lang);
      case 3:
        return _buildArchivedView(lang);
      case 0:
      default:
        return _buildQueueView(doctorState, lang);
    }
  }

  Widget _buildQueueView(DoctorState doctorState, String lang) {
    final queue = doctorState.activeQueue;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Responsive Queue Metrics Header
                LayoutBuilder(
                  builder: (context, box) {
                    final isNarrow = box.maxWidth < 800;
                    if (isNarrow) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildStatMetricCard(AppStrings.tr('waiting_in_queue', lang: lang), '${queue.length}', Icons.people_alt_rounded, AppColors.primary)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatMetricCard(AppStrings.tr('p1_urgent', lang: lang), '${queue.where((s) => s.priority == 'P1').length}', Icons.emergency_rounded, AppColors.priorityP1)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildStatMetricCard(AppStrings.tr('p2_moderate', lang: lang), '${queue.where((s) => s.priority == 'P2').length}', Icons.timer_rounded, AppColors.priorityP2)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatMetricCard(AppStrings.tr('p3_routine', lang: lang), '${queue.where((s) => s.priority == 'P3').length}', Icons.check_circle_outline_rounded, AppColors.priorityP3)),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: _buildStatMetricCard(AppStrings.tr('waiting_in_queue', lang: lang), '${queue.length}', Icons.people_alt_rounded, AppColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatMetricCard(AppStrings.tr('p1_urgent', lang: lang), '${queue.where((s) => s.priority == 'P1').length}', Icons.emergency_rounded, AppColors.priorityP1)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatMetricCard(AppStrings.tr('p2_moderate', lang: lang), '${queue.where((s) => s.priority == 'P2').length}', Icons.timer_rounded, AppColors.priorityP2)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatMetricCard(AppStrings.tr('p3_routine', lang: lang), '${queue.where((s) => s.priority == 'P3').length}', Icons.check_circle_outline_rounded, AppColors.priorityP3)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Queue Sub-Header (safe from horizontal overflow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.tr('upcoming_intake_queue', lang: lang),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            AppStrings.tr('click_patient_sub', lang: lang),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: Text(AppStrings.tr('read_queue_status', lang: lang)),
                      onPressed: () {
                        _speakBrief(AppStrings.getSpeechDescription('doc_queue_status', lang: lang));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (queue.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.certainGreen),
                        const SizedBox(height: 12),
                        Text(AppStrings.tr('no_patients_queue', lang: lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(AppStrings.tr('no_patients_sub', lang: lang), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
                      ],
                    ),
                  )
                else
                  ...queue.map((session) => _buildPatientQueueCard(session, lang)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatientQueueCard(ClinicalSessionModel session, String lang) {
    final isP1 = session.priority == 'P1';
    final isP2 = session.priority == 'P2';

    final priorityColor = isP1 ? AppColors.priorityP1 : isP2 ? AppColors.priorityP2 : AppColors.priorityP3;
    final priorityBg = isP1 ? AppColors.priorityP1Container : isP2 ? AppColors.priorityP2Container : AppColors.priorityP3Container;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isP1 ? AppColors.priorityP1 : AppColors.border,
          width: isP1 ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isP1 ? AppColors.priorityP1.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openConsultation(session),
        borderRadius: BorderRadius.circular(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Priority Token Badge (Fixed 80px)
            SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: priorityBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: priorityColor, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session.priority,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: priorityColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isP1 ? AppStrings.tr('urgent_badge', lang: lang) : isP2 ? AppStrings.tr('moderate_badge', lang: lang) : AppStrings.tr('routine_badge', lang: lang),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        color: priorityColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 2. Middle Content: Patient Info, Mode, Chief Complaint, Pain Score
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        session.patientName ?? 'Patient',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: session.mode == 'allopathy' ? AppColors.primaryContainer : AppColors.ayushGreenContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          session.mode == 'ayush' ? AppStrings.tr('ayush_title', lang: lang) : AppStrings.tr('allopathy_title', lang: lang),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: session.mode == 'allopathy' ? AppColors.primaryDark : AppColors.ayushGreen,
                          ),
                        ),
                      ),
                      Text(
                        '${AppStrings.tr('token_label', lang: lang)}: ${session.tokenNumber}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppStrings.tr('chief_complaint_label', lang: lang)}: ${session.chiefComplaint ?? AppStrings.tr('general_triage', lang: lang)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${AppStrings.tr('pain_score_label', lang: lang)}: ${session.painScore}/10',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: session.painScore >= 7 ? AppColors.priorityP1 : AppColors.priorityP2,
                        ),
                      ),
                      const Text('•', style: TextStyle(color: AppColors.textMuted)),
                      Text(
                        '${AppStrings.tr('registered_label', lang: lang)}: ${session.createdAt.toIso8601String().split("T").last.substring(0, 5)}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      const Text('•', style: TextStyle(color: AppColors.textMuted)),
                      Text(
                        AppStrings.tr('ai_summary_ready', lang: lang),
                        style: const TextStyle(fontSize: 11.5, color: AppColors.certainGreen, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // 3. Right Action Button (Responsive width)
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _openConsultation(session),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.assignment_ind_rounded, size: 18, color: Colors.white),
                label: Text(AppStrings.tr('open_consultation', lang: lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleView(String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppStrings.tr('opd_shift_schedule', lang: lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule_rounded, color: AppColors.primary),
                    title: Text(AppStrings.tr('morning_opd_clinic', lang: lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(AppStrings.tr('morning_opd_time', lang: lang)),
                    trailing: Chip(label: Text(AppStrings.tr('active_now', lang: lang)), backgroundColor: AppColors.certainGreenBg),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviousPatientsView(DoctorState doctorState, String lang) {
    final completed = doctorState.completedSessions;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppStrings.tr('completed_consultations_today', lang: lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (completed.isEmpty)
                  Center(child: Text(AppStrings.tr('no_consultations_today', lang: lang)))
                else
                  ...completed.map((sess) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_circle_rounded, color: AppColors.certainGreen),
                          title: Text(sess.patientName ?? 'Patient ${sess.patientId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${sess.mode == 'ayush' ? AppStrings.tr('ayush_title', lang: lang) : AppStrings.tr('allopathy_title', lang: lang)} • ${AppStrings.tr('token_label', lang: lang)}: ${sess.tokenNumber} • ${AppStrings.tr('status_completed', lang: lang)}'),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.visibility_rounded, size: 16),
                            label: Text(AppStrings.tr('view_summary', lang: lang)),
                            onPressed: () => _openConsultation(sess),
                          ),
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArchivedView(String lang) {
    return Center(child: Text(AppStrings.tr('doc_sidebar_archived_sub', lang: lang)));
  }
}
