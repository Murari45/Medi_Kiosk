import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di.dart';
import '../../../../shared/constants/app_colors.dart';
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
    tts.speak(text, langCode: 'en');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final doctorState = ref.watch(doctorProvider);
    final currentUser = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
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
            const Text('Doctor Clinical Portal (OPD Triage Station)'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Queue',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(doctorProvider.notifier).loadQueue(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Chip(
              backgroundColor: AppColors.surfaceVariant,
              avatar: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 16),
              label: Text(
                currentUser?.name ?? 'Dr. Sharma, MD',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
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
                  _buildSidebar(),
                  const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),

                  // Main Content Area
                  Expanded(
                    child: doctorState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildMainView(doctorState),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
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
                      const Text(
                        'OPD Room 104 • Active',
                        style: TextStyle(fontSize: 11, color: AppColors.certainGreen, fontWeight: FontWeight.bold),
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
                _buildSidebarItem(0, Icons.queue_play_next_rounded, 'Live Triage Queue', 'Active waiting list sorted by P1, P2, P3'),
                _buildSidebarItem(1, Icons.calendar_today_rounded, 'OPD Schedule', 'View doctor appointments & duty times'),
                _buildSidebarItem(2, Icons.history_rounded, 'Previous Patients', 'View consulted patients and prescriptions'),
                _buildSidebarItem(3, Icons.archive_rounded, 'Archived Records', 'Search archived clinical intakes'),
              ],
            ),
          ),

          // Logout
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.priorityP1),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.priorityP1, fontWeight: FontWeight.w600, fontSize: 14)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/');
            },
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
    );
  }

  Widget _buildMainView(DoctorState doctorState) {
    switch (_selectedSidebarIndex) {
      case 1:
        return _buildScheduleView();
      case 2:
        return _buildPreviousPatientsView(doctorState);
      case 3:
        return _buildArchivedView();
      case 0:
      default:
        return _buildQueueView(doctorState);
    }
  }

  Widget _buildQueueView(DoctorState doctorState) {
    final queue = doctorState.activeQueue;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth - 48 > 0 ? constraints.maxWidth - 48 : 0,
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Queue Metrics Header
                Row(
                  children: [
                    _buildStatMetricCard('Waiting in Queue', '${queue.length}', Icons.people_alt_rounded, AppColors.primary),
                    const SizedBox(width: 14),
                    _buildStatMetricCard('Priority 1 (Urgent)', '${queue.where((s) => s.priority == 'P1').length}', Icons.emergency_rounded, AppColors.priorityP1),
                    const SizedBox(width: 14),
                    _buildStatMetricCard('Priority 2 (Moderate)', '${queue.where((s) => s.priority == 'P2').length}', Icons.timer_rounded, AppColors.priorityP2),
                    const SizedBox(width: 14),
                    _buildStatMetricCard('Priority 3 (Routine)', '${queue.where((s) => s.priority == 'P3').length}', Icons.check_circle_outline_rounded, AppColors.priorityP3),
                  ],
                ),
                const SizedBox(height: 28),

                // Queue Table / Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Upcoming Patient Pre-Intake Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('Click on any patient to view the 3-Tier AI Summary & write Voice Prescription', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: const Text('Read Queue Status'),
                      onPressed: () {
                        _speakBrief('There are currently ${queue.length} patients in the live triage queue. ${queue.where((s) => s.priority == "P1").length} require urgent attention.');
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
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 48, color: AppColors.certainGreen),
                        SizedBox(height: 12),
                        Text('No patients waiting in queue.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Patients who complete Kiosk pre-intake will appear here automatically in real time.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                else
                  ...queue.map((session) => _buildPatientQueueCard(session)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatientQueueCard(ClinicalSessionModel session) {
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
                      isP1 ? 'URGENT' : isP2 ? 'MODERATE' : 'ROUTINE',
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
                  Row(
                    children: [
                      Text(
                        session.patientName ?? 'Ramesh Kumar',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: session.mode == 'allopathy' ? AppColors.primaryContainer : AppColors.ayushGreenContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          session.mode.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: session.mode == 'allopathy' ? AppColors.primaryDark : AppColors.ayushGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Token: ${session.tokenNumber}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chief Complaint: ${session.chiefComplaint ?? "Acute clinical pre-intake consultation"}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Pain Score: ${session.painScore}/10',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: session.painScore >= 7 ? AppColors.priorityP1 : AppColors.priorityP2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(width: 8),
                      Text(
                        'Registered: ${session.createdAt.toIso8601String().split("T").last.substring(0, 5)}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(width: 8),
                      const Text(
                        'AI 3-Tier Summary Ready',
                        style: TextStyle(fontSize: 11.5, color: AppColors.certainGreen, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // 3. Right Action Button (Fixed 180px width)
            SizedBox(
              width: 180,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _openConsultation(session),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.assignment_ind_rounded, size: 18, color: Colors.white),
                label: const Text('Open Consultation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth - 48 > 0 ? constraints.maxWidth - 48 : 0,
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('OPD Shift Schedule & Duty Roster', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule_rounded, color: AppColors.primary),
                    title: const Text('Morning OPD Clinic (Room 104)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('09:00 AM - 02:00 PM • 18 Pre-Intake Slots Available'),
                    trailing: const Chip(label: Text('ACTIVE NOW'), backgroundColor: AppColors.certainGreenBg),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviousPatientsView(DoctorState doctorState) {
    final completed = doctorState.completedSessions;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth - 48 > 0 ? constraints.maxWidth - 48 : 0,
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Completed Consultations (Today)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (completed.isEmpty)
                  const Center(child: Text('No consultations completed yet today.'))
                else
                  ...completed.map((sess) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_circle_rounded, color: AppColors.certainGreen),
                          title: Text(sess.patientName ?? 'Patient ${sess.patientId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${sess.mode.toUpperCase()} • Token: ${sess.tokenNumber} • Completed'),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.visibility_rounded, size: 16),
                            label: const Text('View Summary'),
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

  Widget _buildArchivedView() {
    return const Center(child: Text('Archived clinical consultations and records.'));
  }
}
