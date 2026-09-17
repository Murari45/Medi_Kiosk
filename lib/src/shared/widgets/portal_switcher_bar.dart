import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/doctor_dashboard/presentation/providers/doctor_provider.dart';
import '../../features/patient_dashboard/presentation/providers/patient_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../services/notification_service.dart';

class PortalDemoSwitcher extends ConsumerWidget {
  final String currentPortal; // 'patient', 'doctor', 'admin'

  const PortalDemoSwitcher({
    super.key,
    required this.currentPortal,
  });

  void _switchPortal(BuildContext context, WidgetRef ref, String targetPortal) async {
    if (targetPortal == currentPortal) return;

    if (targetPortal == 'patient') {
      await ref.read(authProvider.notifier).quickDemoLogin('patient');
      final user = ref.read(authProvider).currentUser;
      if (user != null) {
        await ref.read(patientProvider.notifier).loadPatientData(user);
      }
      if (context.mounted) {
        NotificationService.showSuccess('Switched to Patient Portal (Ramesh Kumar)');
        context.go('/patient-dashboard');
      }
    } else if (targetPortal == 'doctor') {
      await ref.read(authProvider.notifier).quickDemoLogin('doctor');
      await ref.read(doctorProvider.notifier).loadQueue();
      if (context.mounted) {
        NotificationService.showSuccess('Switched to Doctor Portal (Dr. Rajesh Sharma, MD)');
        context.go('/doctor-dashboard');
      }
    } else if (targetPortal == 'admin') {
      await ref.read(authProvider.notifier).quickDemoLogin('admin');
      if (context.mounted) {
        NotificationService.showSuccess('Switched to Admin Panel (Kiosk Administrator)');
        context.go('/admin');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(authProvider).currentLanguage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live Sync Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    AppStrings.tr('live_demo_sync', lang: lang),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.tr('switch_portal', lang: lang),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),

            // Portal Tabs
            _buildPortalChip(
              context: context,
              ref: ref,
              portalId: 'patient',
              label: AppStrings.tr('portal_patient', lang: lang),
              icon: Icons.person_rounded,
              activeColor: AppColors.primary,
              activeBg: AppColors.primaryContainer,
            ),
            const SizedBox(width: 6),
            _buildPortalChip(
              context: context,
              ref: ref,
              portalId: 'doctor',
              label: AppStrings.tr('portal_doctor', lang: lang),
              icon: Icons.medical_services_rounded,
              activeColor: AppColors.ayushGreen,
              activeBg: AppColors.ayushGreenContainer,
            ),
            const SizedBox(width: 6),
            _buildPortalChip(
              context: context,
              ref: ref,
              portalId: 'admin',
              label: AppStrings.tr('portal_admin', lang: lang),
              icon: Icons.admin_panel_settings_rounded,
              activeColor: Colors.purple.shade700,
              activeBg: Colors.purple.shade50,
            ),

            const SizedBox(width: 24),

            // Hackathon Demo Helper Pill
            Tooltip(
              message: 'All 3 portals share the same live SQLite database.',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.tr('multi_portal_demo', lang: lang),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalChip({
    required BuildContext context,
    required WidgetRef ref,
    required String portalId,
    required String label,
    required IconData icon,
    required Color activeColor,
    required Color activeBg,
  }) {
    final isActive = currentPortal == portalId;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _switchPortal(context, ref, portalId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? activeColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : AppColors.textPrimary,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: 13, color: activeColor),
            ],
          ],
        ),
      ),
    );
  }
}
