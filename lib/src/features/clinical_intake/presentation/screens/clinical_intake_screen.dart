import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_strings.dart';
import '../../../../voice/services/tts_service.dart';
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

    final isAllopathy = intake.mode == 'allopathy';
    final qIndex = intake.currentQuestionIndex;
    final totalQ = intake.totalQuestions;

    String qTitle = '';
    String qSub = '';
    List<String> options = [];

    if (isAllopathy) {
      if (qIndex < SocratesAlgorithm.questions.length) {
        final q = SocratesAlgorithm.questions[qIndex];
        qTitle = AppStrings.tr(q.titleKey, lang: lang);
        qSub = q.description;
        options = q.quickOptions;
      }
    } else {
      if (qIndex < DashavidhaAlgorithm.parameters.length) {
        final q = DashavidhaAlgorithm.parameters[qIndex];
        qTitle = AppStrings.tr(q.titleKey, lang: lang);
        qSub = '${q.sanskritTerm} — ${q.englishMeaning}';
        options = q.options;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isAllopathy ? 'Allopathy (SOCRATES Triage)' : 'AYUSH (Dashavidha Pariksha)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(clinicalIntakeProvider.notifier).stopVoiceListening();
            getIt<TTSService>().stop();
            context.pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAllopathy ? AppColors.primaryContainer : AppColors.ayushGreenContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Step ${qIndex + 1} of $totalQ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isAllopathy ? AppColors.primaryDark : AppColors.ayushGreen,
                  ),
                ),
              ),
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
                      // Linear Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (qIndex + 1) / totalQ,
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
                                        'Question ${qIndex + 1}',
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
                                  tooltip: 'Hear question again',
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
                                  ? AppStrings.tr('listening', lang: lang)
                                  : intake.currentTranscript.isNotEmpty
                                      ? 'Recorded: "${intake.currentTranscript}"'
                                      : 'Tap microphone or speak your answer naturally...',
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
                        const Text(
                          'Or tap an answer below:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
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
                                backgroundColor: intake.isListening ? AppColors.micActive : AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: Icon(
                                intake.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                intake.isListening ? 'Done Speaking (Submit Voice)' : AppStrings.tr('btn_speak', lang: lang),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {
                              ref.read(clinicalIntakeProvider.notifier).selectOptionManually('Not Sure / Not Applicable', lang);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Not Sure / Skip', style: TextStyle(fontWeight: FontWeight.w600)),
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
              label: 'Tap Mic or Option to respond 🎙️',
              targetAlignment: const Alignment(0, 0.75),
            ),
          ],
        ),
      ),
    );
  }
}
