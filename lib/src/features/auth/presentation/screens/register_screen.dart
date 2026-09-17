import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_strings.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../voice/services/tts_service.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _passwordController = TextEditingController();
  final _allergiesController = TextEditingController(text: 'None');

  String _selectedBloodType = 'O+';
  String _selectedGender = 'Male';
  final DateTime _selectedDob = DateTime(1990, 5, 20);

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _aadhaarController.dispose();
    _passwordController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final registeredUser = await ref.read(authProvider.notifier).registerPatient(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      aadhaarOrId: _aadhaarController.text.trim(),
      bloodType: _selectedBloodType,
      allergies: _allergiesController.text.trim(),
      dob: _selectedDob.toIso8601String().split('T').first,
      gender: _selectedGender,
    );

    if (!mounted) return;

    if (registeredUser != null) {
      final tts = getIt<TTSService>();
      final lang = ref.read(authProvider).currentLanguage;
      final speechMsg = lang == 'hi'
          ? 'पंजीकरण पूर्ण हुआ। आपकी आभा आईडी ${registeredUser.abhaId} है। साइन इन पर भेजा जा रहा है।'
          : lang == 'ta'
              ? 'பதிவு முடிந்தது. உங்கள் ஆபா ஐடி ${registeredUser.abhaId}. உள்நுழைவு பக்கத்திற்கு திருப்பி விடப்படுகிறீர்கள்.'
              : lang == 'te'
                  ? 'నమోదు పూర్తయింది. మీ ఆభా ఐడి ${registeredUser.abhaId}. సైన్ ఇన్ పేజీకి దారి మళ్లించబడుతోంది.'
                  : lang == 'bn'
                      ? 'নিবন্ধন সম্পন্ন হয়েছে। আপনার আভা আইডি হল ${registeredUser.abhaId}। সাইন ইন পৃষ্ঠায় পুনর্নির্দেশ করা হচ্ছে।'
                      : 'Registration complete. Your simulated ABHA ID is ${registeredUser.abhaId}. Redirecting to sign in.';
      tts.speak(speechMsg, langCode: lang);

      // Show ABHA ID preview dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.certainGreen, size: 28),
              const SizedBox(width: 10),
              Text(AppStrings.tr('abha_card_created', lang: lang)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ayushman Bharat Digital Mission', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 24),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(registeredUser.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${AppStrings.tr('token_label', lang: lang)} ABHA: ${registeredUser.abhaId}', style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${registeredUser.phone} | Blood: $_selectedBloodType', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(AppStrings.tr('digital_token_synced', lang: lang), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/auth');
              },
              child: Text(AppStrings.tr('proceed_to_signin', lang: lang)),
            ),
          ],
        ),
      );
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Registration failed';
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
        title: Text(AppStrings.tr('register', lang: lang)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
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
                      Text(
                        AppStrings.tr('reg_title', lang: lang),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.tr('reg_subtitle', lang: lang),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const Divider(height: 28),

                      // Full Name
                      Text(AppStrings.tr('full_name_req', lang: lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Anand Varma',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? AppStrings.tr('full_name', lang: lang) : null,
                      ),
                      const SizedBox(height: 14),

                      // Mobile & Aadhaar in a Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.tr('mobile_req', lang: lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    hintText: '98XXXXXXXX',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  validator: (val) => val == null || val.trim().length < 10 ? AppStrings.tr('phone_number', lang: lang) : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.tr('aadhaar_gov_id', lang: lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _aadhaarController,
                                  decoration: const InputDecoration(
                                    hintText: '1234 5678 XXXX',
                                    prefixIcon: Icon(Icons.credit_card_rounded),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Email & Password in a Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.tr('email_address', lang: lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: 'patient@example.com',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.tr('create_password_req', lang: lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: Icon(Icons.lock_outline_rounded),
                                  ),
                                  validator: (val) => val == null || val.length < 4 ? AppStrings.tr('enter_password_error', lang: lang) : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Blood Group & Gender Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.tr('blood_group_label', lang: lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedBloodType,
                                  decoration: const InputDecoration(prefixIcon: Icon(Icons.bloodtype_outlined)),
                                  items: _bloodTypes.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                                  onChanged: (val) => setState(() => _selectedBloodType = val ?? 'O+'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.tr('gender_label', lang: lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedGender,
                                  decoration: const InputDecoration(prefixIcon: Icon(Icons.wc_rounded)),
                                  items: _genders.map((g) {
                                    final label = g == 'Male' ? AppStrings.tr('gender_male', lang: lang) : g == 'Female' ? AppStrings.tr('gender_female', lang: lang) : AppStrings.tr('gender_other', lang: lang);
                                    return DropdownMenuItem(value: g, child: Text(label));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedGender = val ?? 'Male'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Allergies
                      Text(AppStrings.tr('known_allergies_hint', lang: lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _allergiesController,
                        decoration: InputDecoration(
                          hintText: AppStrings.tr('none', lang: lang),
                          prefixIcon: const Icon(Icons.warning_amber_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: authState.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.how_to_reg_rounded, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(AppStrings.tr('create_account_btn', lang: lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
