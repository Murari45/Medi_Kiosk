import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_strings.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../voice/services/tts_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/triage_engine.dart';

class TokenConfirmationScreen extends ConsumerStatefulWidget {
  final TriageResult triageResult;

  const TokenConfirmationScreen({
    super.key,
    required this.triageResult,
  });

  @override
  ConsumerState<TokenConfirmationScreen> createState() => _TokenConfirmationScreenState();
}

class _TokenConfirmationScreenState extends ConsumerState<TokenConfirmationScreen> {
  int _countdown = 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _playVoiceAnnouncement();
    _startCountdown();

    // Trigger mock SMS notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).currentUser;
      NotificationService.showMockSMS(
        recipientPhone: user?.phone ?? '9876543210',
        tokenNumber: widget.triageResult.tokenNumber,
        priority: widget.triageResult.priority,
      );
    });
  }

  void _playVoiceAnnouncement() async {
    final lang = ref.read(authProvider).currentLanguage;
    final tts = getIt<TTSService>();
    final token = widget.triageResult.tokenNumber;
    final priority = widget.triageResult.priority;

    final msg = lang == 'hi'
        ? 'जांच पूरी हो गई है। आपका टोकन नंबर है $token, प्राथमिकता $priority। कृपया प्रतीक्षालय में प्रतीक्षा करें।'
        : 'Pre-intake completed. Your token number is $token, priority $priority. Please proceed to the waiting area.';

    await tts.speak(msg, langCode: lang);
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        _completeAndLogout();
      }
    });
  }

  void _completeAndLogout() async {
    _timer?.cancel();
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(authProvider).currentLanguage;
    final result = widget.triageResult;
    final isP1 = result.priority == 'P1';
    final isP2 = result.priority == 'P2';

    final priorityColor = isP1 ? AppColors.priorityP1 : isP2 ? AppColors.priorityP2 : AppColors.priorityP3;
    final priorityBg = isP1 ? AppColors.priorityP1Container : isP2 ? AppColors.priorityP2Container : AppColors.priorityP3Container;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Header
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.certainGreenBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.certainGreen, width: 2),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.certainGreen, size: 44),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.tr('token_generated', lang: lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.tr('token_message', lang: lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Digital Token Slip Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Hospital Header
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 20),
                                SizedBox(width: 6),
                                Text('MediKiosk Smart OPD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Text('Smart India Hackathon 2026', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                        const Divider(height: 28),

                        // Token Number Display
                        Text(
                          'YOUR TOKEN NUMBER',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueGrey.shade600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          result.tokenNumber,
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: priorityColor,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: priorityBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: priorityColor, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isP1 ? Icons.emergency_rounded : Icons.schedule_rounded,
                                color: priorityColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isP1
                                    ? AppStrings.tr('priority_p1', lang: lang)
                                    : isP2
                                        ? AppStrings.tr('priority_p2', lang: lang)
                                        : AppStrings.tr('priority_p3', lang: lang),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: priorityColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Chief Complaint & Estimated Queue Position
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Complaint: ${result.chiefComplaint}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Triage Action: ${result.aiSummary.triageSummary}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // QR Code Simulation for OPD Scanner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2_rounded, size: 50, color: AppColors.textPrimary),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Scan at Doctor\'s Station', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Digital ABHA Triage Token Synchronized with Local SQLite', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions: Print Slip & Finish
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            NotificationService.showSuccess('Token Slip Sent to Kiosk Thermal Printer!');
                          },
                          icon: const Icon(Icons.print_rounded),
                          label: const Text('Print Token Slip'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _completeAndLogout,
                          icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                          label: Text(
                            'Done ($_countdown s)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kiosk will automatically reset and clear session in $_countdown seconds.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
