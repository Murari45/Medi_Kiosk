import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_strings.dart';
import '../../../../voice/widgets/audio_waveform_visualizer.dart';
import '../../../../voice/widgets/voice_pointer_overlay.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/dashavidha_algorithm.dart';
import '../../domain/socrates_algorithm.dart';
import '../providers/clinical_intake_provider.dart';
import 'token_confirmation_screen.dart';

class ClinicalIntakeScreen extends ConsumerStatefulWidget {
  final String mode; // 'allopathy' or 'ayush'

  const ClinicalIntakeScreen({
    super.key,
    this.mode = 'allopathy',
  });

  @override
  ConsumerState<ClinicalIntakeScreen> createState() => _ClinicalIntakeScreenState();
}

class _ClinicalIntakeScreenState extends ConsumerState<ClinicalIntakeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = ref.read(authProvider).currentLanguage;
      ref.read(clinicalIntakeProvider.notifier).initMode(widget.mode, lang);
    });
  }

  @override
  void didUpdateWidget(ClinicalIntakeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      final lang = ref.read(authProvider).currentLanguage;
      ref.read(clinicalIntakeProvider.notifier).initMode(widget.mode, lang);
    }
  }

  void _speakCurrentAgain() {
    final lang = ref.read(authProvider).currentLanguage;
    ref.read(clinicalIntakeProvider.notifier).speakCurrentQuestion(lang);
  }

  void _toggleMic() {
    final intake = ref.read(clinicalIntakeProvider);
    final lang = ref.read(authProvider).currentLanguage;
    final notifier = ref.read(clinicalIntakeProvider.notifier);

    if (intake.isListening) {
      notifier.stopVoiceListening();
    } else {
      notifier.startVoiceListening(lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final intake = ref.watch(clinicalIntakeProvider);
    final lang = auth.currentLanguage;

    // Check if finished and triage generated
    if (intake.finalTriageResult != null) {
      return TokenConfirmationScreen(triageResult: intake.finalTriageResult!);
    }

    final effectiveMode = widget.mode.isNotEmpty ? widget.mode : intake.mode;
    final isAllopathy = effectiveMode == 'allopathy';
    final totalQ = isAllopathy
        ? SocratesAlgorithm.questions.length
        : DashavidhaAlgorithm.parameters.length;
    final qIndex = intake.currentQuestionIndex.clamp(0, totalQ > 0 ? totalQ - 1 : 0);
    final progress = totalQ > 0 ? ((qIndex + 1) / totalQ).clamp(0.0, 1.0) : 0.0;

    String qTitle = '';
    String qSub = '';
    List<String> options = [];

    if (isAllopathy) {
      final safeI = qIndex.clamp(0, SocratesAlgorithm.questions.length - 1);
      final q = SocratesAlgorithm.questions[safeI];
      qTitle = AppStrings.tr(q.titleKey, lang: lang);
      qSub = AppStrings.getQuestionSubtitle(q.key, lang: lang, defaultSub: q.description);
      options = AppStrings.getQuestionOptions(q.key, lang: lang, defaultOptions: q.quickOptions);
    } else {
      final safeI = qIndex.clamp(0, DashavidhaAlgorithm.parameters.length - 1);
      final q = DashavidhaAlgorithm.parameters[safeI];
      qTitle = AppStrings.tr(q.titleKey, lang: lang);
      qSub = AppStrings.getQuestionSubtitle(q.key, lang: lang, defaultSub: '${q.sanskritTerm} — ${q.englishMeaning}');
      options = AppStrings.getQuestionOptions(q.key, lang: lang, defaultOptions: q.options);
    }

    void handleClose() {
      ref.read(clinicalIntakeProvider.notifier).reset();
      context.go('/patient-dashboard');
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isAllopathy ? AppStrings.tr('allopathy_header', lang: lang) : AppStrings.tr('ayush_header', lang: lang),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 26),
          tooltip: AppStrings.tr('btn_close', lang: lang),
          onPressed: handleClose,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAllopathy ? AppColors.primaryContainer : AppColors.ayushGreenContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppStrings.tr('step_x_of_y', lang: lang, args: ['${qIndex + 1}', '$totalQ']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isAllopathy ? AppColors.primaryDark : AppColors.ayushGreen,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(
                AppStrings.tr('btn_close', lang: lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: handleClose,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.priorityP1Container,
                foregroundColor: AppColors.priorityP1,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: Text(
                AppStrings.tr('sign_out', lang: lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: () async {
                ref.read(clinicalIntakeProvider.notifier).reset();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/auth');
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Linear Progress Bar (guaranteed within [0.0, 1.0])
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isAllopathy ? AppColors.primary : AppColors.ayushGreen,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Question Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isAllopathy ? AppColors.primaryContainer : AppColors.ayushGreenContainer,
                                  child: Icon(
                                    isAllopathy ? Icons.medical_services_rounded : Icons.spa_rounded,
                                    color: isAllopathy ? AppColors.primary : AppColors.ayushGreen,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.tr('question_x', lang: lang, args: ['${qIndex + 1}']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isAllopathy ? AppColors.primary : AppColors.ayushGreen,
                                        ),
                                      ),
                                      Text(
                                        qSub,
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.volume_up_rounded),
                                  tooltip: AppStrings.tr('hear_question_again', lang: lang),
                                  onPressed: _speakCurrentAgain,
                                ),
                              ],
                            ),
                            const Divider(height: 28),
                            Text(
                              qTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Live Voice Waveform & Transcript Area
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: intake.isListening ? const Color(0xFFFEF2F2) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: intake.isListening ? AppColors.micActive : AppColors.border,
                            width: intake.isListening ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            AudioWaveformVisualizer(
                              isRecording: intake.isListening,
                              barHeight: 45,
                              waveColor: intake.isListening ? AppColors.micActive : AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              intake.isListening
                                  ? AppStrings.tr('mic_prompt_listening', lang: lang)
                                  : intake.currentTranscript.isNotEmpty
                                      ? '${AppStrings.tr('mic_recorded_prefix', lang: lang)}"${intake.currentTranscript}"'
                                      : AppStrings.tr('mic_prompt_idle', lang: lang),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: intake.isListening ? FontWeight.bold : FontWeight.w500,
                                color: intake.isListening ? AppColors.micActive : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Accessible Touch Options
                      if (options.isNotEmpty) ...[
                        Text(
                          AppStrings.tr('or_tap_answer', lang: lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: options.map((opt) {
                            return ActionChip(
                              label: Text(opt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onPressed: () {
                                ref.read(clinicalIntakeProvider.notifier).selectOptionManually(opt, lang);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Bottom Action Buttons: Mic Tap & Skip
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _toggleMic,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: intake.isListening
                                    ? AppColors.micActive
                                    : (isAllopathy ? AppColors.primary : AppColors.ayushGreen),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: Icon(
                                intake.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                intake.isListening ? AppStrings.tr('done_speaking', lang: lang) : AppStrings.tr('btn_speak', lang: lang),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {
                              ref.read(clinicalIntakeProvider.notifier).selectOptionManually(AppStrings.tr('not_sure_skip', lang: lang), lang);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(AppStrings.tr('not_sure_skip', lang: lang), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pointer Overlay on Voice/Option
            VoicePointerOverlay(
              isVisible: !intake.isListening && qIndex == 0,
              label: AppStrings.tr('tap_mic_to_respond', lang: lang),
              targetAlignment: const Alignment(0, 0.75),
            ),
          ],
        ),
      ),
    );
  }
}
