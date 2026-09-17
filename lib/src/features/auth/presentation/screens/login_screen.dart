import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_strings.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../voice/services/tts_service.dart';
import '../../../../voice/widgets/voice_pointer_overlay.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(text: 'patient_1024@abdm');
  final _passwordController = TextEditingController(text: 'patient123');

  String _selectedRole = 'patient'; // 'patient', 'doctor', 'admin'
  bool _obscurePassword = true;
  final bool _showPointerOnSignIn = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'patient') {
        _identifierController.text = 'patient_1024@abdm';
        _passwordController.text = 'patient123';
      } else if (role == 'doctor') {
        _identifierController.text = 'dr_sharma@abdm';
        _passwordController.text = 'doctor123';
      } else {
        _identifierController.text = 'admin_kiosk@abdm';
        _passwordController.text = 'admin123';
      }
    });

    final lang = ref.read(authProvider).currentLanguage;
    final tts = getIt<TTSService>();
    final roleName = role == 'patient'
        ? AppStrings.tr('role_patient', lang: lang)
        : role == 'doctor'
            ? AppStrings.tr('role_doctor', lang: lang)
            : AppStrings.tr('role_admin', lang: lang);
    final prompt = lang == 'hi'
        ? '$roleName चुना गया। साइन इन करने के लिए अपना विवरण दर्ज करें।'
        : lang == 'ta'
            ? '$roleName தேர்ந்தெடுக்கப்பட்டது. உள்நுழைய உங்கள் விவரங்களை உள்ளிடவும்.'
            : lang == 'te'
                ? '$roleName ఎంపిక చేయబడింది. సైన్ ఇన్ చేయడానికి మీ వివరాలను నమోదు చేయండి.'
                : lang == 'bn'
                    ? '$roleName নির্বাচিত হয়েছে। সাইন ইন করতে আপনার বিবরণ লিখুন।'
                    : 'Selected $roleName. Enter your credentials to sign in.';
    tts.speak(prompt, langCode: lang);
  }

  void _speakSignInGuidance() {
    final lang = ref.read(authProvider).currentLanguage;
    final tts = getIt<TTSService>();
    tts.speak(
      AppStrings.getSpeechDescription('btn_signin', lang: lang),
      langCode: lang,
    );
  }

  void _handleQuickDemoLogin(String role) async {
    _onRoleSelected(role);
    final success = await ref.read(authProvider.notifier).quickDemoLogin(role);
    if (!mounted) return;

    if (success) {
      NotificationService.showSuccess('Signed in successfully as ${role.toUpperCase()}!');
      if (role == 'patient') {
        context.go('/patient-dashboard');
      } else if (role == 'doctor') {
        context.go('/doctor-dashboard');
      } else {
        context.go('/admin');
      }
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Demo login failed';
      NotificationService.showError(error);
    }
  }

  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text.trim(),
      expectedRole: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      NotificationService.showSuccess('Signed in successfully as $_selectedRole!');
      if (_selectedRole == 'patient') {
        context.go('/patient-dashboard');
      } else if (_selectedRole == 'doctor') {
        context.go('/doctor-dashboard');
      } else {
        context.go('/admin');
      }
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Login failed';
      NotificationService.showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final lang = authState.currentLanguage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.tr('app_name', lang: lang)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ActionChip(
              avatar: const Icon(Icons.language_rounded, size: 16),
              label: Text(lang.toUpperCase()),
              onPressed: () => context.go('/'),
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
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role Selector Tabs (Patient, Doctor, Admin)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              _buildRoleTab('patient', Icons.person_rounded, AppStrings.tr('role_patient', lang: lang)),
                              _buildRoleTab('doctor', Icons.medical_services_rounded, AppStrings.tr('role_doctor', lang: lang)),
                              _buildRoleTab('admin', Icons.admin_panel_settings_rounded, AppStrings.tr('role_admin', lang: lang)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Main Login Card
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
                                    backgroundColor: _selectedRole == 'patient'
                                        ? AppColors.primaryContainer
                                        : _selectedRole == 'doctor'
                                            ? AppColors.ayushGreenContainer
                                            : Colors.amber.shade50,
                                    child: Icon(
                                      _selectedRole == 'patient'
                                          ? Icons.person_rounded
                                          : _selectedRole == 'doctor'
                                              ? Icons.medical_information_rounded
                                              : Icons.security_rounded,
                                      color: _selectedRole == 'patient'
                                          ? AppColors.primary
                                          : _selectedRole == 'doctor'
                                              ? AppColors.ayushGreen
                                              : Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedRole == 'patient'
                                              ? AppStrings.tr('patient_sign_in_title', lang: lang)
                                              : _selectedRole == 'doctor'
                                                  ? AppStrings.tr('doctor_sign_in_title', lang: lang)
                                                  : AppStrings.tr('admin_sign_in_title', lang: lang),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          _selectedRole == 'patient'
                                              ? AppStrings.tr('enter_abha_or_mobile', lang: lang)
                                              : AppStrings.tr('enter_credentials', lang: lang),
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),

                              // Identifier Field (ABHA ID / Mobile)
                              Text(
                                _selectedRole == 'patient'
                                    ? AppStrings.tr('abha_id_label', lang: lang)
                                    : AppStrings.tr('username_email', lang: lang),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _identifierController,
                                decoration: InputDecoration(
                                  hintText: AppStrings.tr('abha_id_hint', lang: lang),
                                  prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.primary),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? AppStrings.tr('enter_id_error', lang: lang) : null,
                              ),
                              const SizedBox(height: 18),

                              // Password Field
                              Text(
                                AppStrings.tr('password_label', lang: lang),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (val) => val == null || val.isEmpty ? AppStrings.tr('enter_password_error', lang: lang) : null,
                              ),
                              const SizedBox(height: 24),

                              // Sign In Button with Speaker Guidance and Pointer Animation
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: authState.isLoading ? null : _handleSignIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: authState.isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.login_rounded, color: Colors.white),
                                                const SizedBox(width: 8),
                                                Text(
                                                  AppStrings.tr('sign_in', lang: lang),
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Tooltip(
                                    message: AppStrings.tr('btn_listen', lang: lang),
                                    child: IconButton.filledTonal(
                                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                                      onPressed: _speakSignInGuidance,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick 1-Tap Demo Logins Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.08),
                                AppColors.ayushGreen.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppStrings.tr('quick_login_title', lang: lang),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ActionChip(
                                    avatar: const Icon(Icons.person_rounded, size: 16, color: Colors.white),
                                    label: Text(AppStrings.tr('demo_patient_label', lang: lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                    backgroundColor: AppColors.primary,
                                    onPressed: () => _handleQuickDemoLogin('patient'),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.medical_services_rounded, size: 16, color: Colors.white),
                                    label: Text(AppStrings.tr('demo_doctor_label', lang: lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                    backgroundColor: AppColors.ayushGreen,
                                    onPressed: () => _handleQuickDemoLogin('doctor'),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Colors.white),
                                    label: Text(AppStrings.tr('demo_admin_label', lang: lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                    backgroundColor: Colors.purple.shade700,
                                    onPressed: () => _handleQuickDemoLogin('admin'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Register New Patient Link (for Patients)
                        if (_selectedRole == 'patient') ...[
                          OutlinedButton.icon(
                            onPressed: () => context.push('/register'),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: Text(AppStrings.tr('register', lang: lang)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Pointer Overlay on Sign In Button
            VoicePointerOverlay(
              isVisible: _showPointerOnSignIn,
              label: AppStrings.tr('tap_sign_in_hint', lang: lang),
              targetAlignment: const Alignment(0, 0.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTab(String role, IconData icon, String title) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onRoleSelected(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
