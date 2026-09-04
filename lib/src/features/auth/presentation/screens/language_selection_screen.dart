import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_strings.dart';
import '../../../../voice/services/tts_service.dart';
import '../../../../voice/widgets/voice_pointer_overlay.dart';
import '../providers/auth_provider.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String _selectedLang = 'en';
  bool _hasVoicedWelcome = false;
  bool _showPointer = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playWelcomeVoice();
    });
  }

  void _playWelcomeVoice() async {
    if (_hasVoicedWelcome) return;
    _hasVoicedWelcome = true;
    final tts = getIt<TTSService>();
    final welcomeText = AppStrings.tr('welcome_voice', lang: _selectedLang);
    await tts.speak(welcomeText, langCode: _selectedLang);
  }

  void _onLanguageChanged(String langCode) async {
    setState(() {
      _selectedLang = langCode;
      _showPointer = true;
    });
    ref.read(authProvider.notifier).setLanguage(langCode);
    final tts = getIt<TTSService>();
    final welcomeText = AppStrings.tr('welcome_voice', lang: langCode);
    await tts.speak(welcomeText, langCode: langCode);
  }

  void _proceedToAuth() {
    context.push('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo & Branding
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.tr('app_name', lang: _selectedLang),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.tr('tagline', lang: _selectedLang),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // Welcome & Guidance Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.translate_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.tr('welcome_title', lang: _selectedLang),
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppStrings.tr('welcome_subtitle', lang: _selectedLang),
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Language Selection List
                            ...AppStrings.supportedLanguages.map((lang) {
                              final isSelected = _selectedLang == lang['code'];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryContainer : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _onLanguageChanged(lang['code']!),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lang['native']!,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                lang['name']!,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Speaker button to hear in this language
                                        IconButton(
                                          tooltip: 'Hear in ${lang['name']}',
                                          icon: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primary.withValues(alpha: 0.15)
                                                  : Colors.black.withValues(alpha: 0.05),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.volume_up_rounded,
                                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                              size: 20,
                                            ),
                                          ),
                                          onPressed: () {
                                            final tts = getIt<TTSService>();
                                            final txt = AppStrings.tr('welcome_voice', lang: lang['code']!);
                                            tts.speak(txt, langCode: lang['code']!);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Continue Button with Voice Icon
                      ElevatedButton(
                        onPressed: _proceedToAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.tr('btn_continue', lang: _selectedLang),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Animated Pointer Guidance Overlay
            VoicePointerOverlay(
              isVisible: _showPointer,
              label: 'Tap language & listen 🔊',
              targetAlignment: const Alignment(0, -0.65),
            ),
          ],
        ),
      ),
    );
  }
}
