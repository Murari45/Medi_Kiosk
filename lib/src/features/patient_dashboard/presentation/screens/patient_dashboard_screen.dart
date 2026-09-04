import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_strings.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/patient_profile_model.dart';
import '../../../../voice/widgets/voice_guidance_button.dart';
import '../../../../shared/widgets/camera_scanner_dialog.dart';
import '../../../../shared/widgets/portal_switcher_bar.dart';
import '../../../document_scanning/presentation/providers/document_provider.dart';
import '../../../prescription/domain/pdf_prescription_generator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/patient_provider.dart';

import '../../../../voice/services/tts_service.dart';

class PatientDashboardScreen extends ConsumerStatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  ConsumerState<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends ConsumerState<PatientDashboardScreen> {
  int _selectedSidebarIndex = 0;

  // Profile Edit Controllers
  late TextEditingController _nameController;
  late TextEditingController _allergiesController;
  String _selectedBlood = 'O+';
  String _selectedGender = 'Male';
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _allergiesController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).currentUser;
      if (user != null) {
        ref.read(patientProvider.notifier).loadPatientData(user);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _speakSection(String text) {
    final lang = ref.read(authProvider).currentLanguage;
    final tts = getIt<TTSService>();
    tts.speak(text, langCode: lang);
  }

  void _startAllopathyIntake() {
    context.push('/clinical-intake?mode=allopathy');
  }

  void _startAyushIntake() {
    context.push('/clinical-intake?mode=ayush');
  }

  void _openDocScanner() {
    context.push('/document-scanner');
  }

  void _openCameraDialog() {
    CameraScannerDialog.show(context);
  }

  void _saveProfileChanges() async {
    final success = await ref.read(patientProvider.notifier).updateProfile(
      name: _nameController.text.trim(),
      bloodType: _selectedBlood,
      allergies: _allergiesController.text.trim(),
      gender: _selectedGender,
      dob: ref.read(patientProvider).profile?.dateOfBirth ?? '1985-06-15',
    );
    if (success) {
      setState(() => _isEditingProfile = false);
      NotificationService.showSuccess('Patient profile updated successfully in SQLite!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final patient = ref.watch(patientProvider);
    final lang = auth.currentLanguage;
    final currentUser = auth.currentUser;
    final profile = patient.profile;

    if (currentUser != null && _nameController.text.isEmpty && !_isEditingProfile) {
      _nameController.text = currentUser.name;
      _allergiesController.text = profile?.allergies ?? 'None';
      _selectedBlood = profile?.bloodType ?? 'O+';
      _selectedGender = profile?.gender ?? 'Male';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(AppStrings.tr('patient_dashboard', lang: lang)),
          ],
        ),
        actions: [
          // Voice narration helper
          IconButton(
            tooltip: 'Listen to page overview',
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
            onPressed: () => _speakSection(
              lang == 'hi'
                  ? 'मरीज पोर्टल में आपका स्वागत है। जांच शुरू करने के लिए एलोपैथी या आयुष चुनें।'
                  : 'Welcome to Patient Portal. Choose Allopathy or AYUSH intake to begin pre-consultation triage.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Chip(
              backgroundColor: AppColors.primaryContainer,
              avatar: const Icon(Icons.badge_rounded, size: 16, color: AppColors.primary),
              label: Text(currentUser?.abhaId ?? 'patient@abdm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const PortalDemoSwitcher(currentPortal: 'patient'),
            Expanded(
              child: Row(
                children: [
                  // Left Navigation Sidebar
                  _buildSidebar(lang),
                  const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),

                  // Main Content View
                  Expanded(
                    child: patient.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildMainContent(lang, currentUser, profile, patient),
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
          // Patient Mini Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.watch(authProvider).currentUser?.name ?? 'Patient',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ABHA: ${ref.watch(authProvider).currentUser?.abhaId ?? ""}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
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
                _buildSidebarItem(0, Icons.dashboard_rounded, 'Dashboard', 'Go to Main Triage Intake & Quick Actions'),
                _buildSidebarItem(1, Icons.account_circle_rounded, 'My Health Profile', 'View & edit blood group, allergies, vitals'),
                _buildSidebarItem(2, Icons.history_edu_rounded, 'Previous Summaries', 'View past clinical triage results & tokens'),
                _buildSidebarItem(3, Icons.document_scanner_rounded, 'Upload / Scan Docs', 'Scan prescriptions & lab reports via OCR'),
                _buildSidebarItem(4, Icons.calendar_month_rounded, 'Upcoming Visits', 'View doctor appointments & schedule'),
              ],
            ),
          ),

          // Logout Item
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.priorityP1),
            title: Text(AppStrings.tr('sign_out', lang: lang), style: const TextStyle(color: AppColors.priorityP1, fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: IconButton(
              icon: const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.textMuted),
              onPressed: () => _speakSection(lang == 'hi' ? 'साइन आउट करने के लिए यहां दबाएं।' : 'Tap to sign out of patient kiosk.'),
            ),
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

  Widget _buildSidebarItem(int index, IconData icon, String title, String voiceDesc) {
    final isSelected = _selectedSidebarIndex == index;
    final lang = ref.watch(authProvider).currentLanguage;

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
        trailing: IconButton(
          icon: Icon(Icons.volume_up_rounded, size: 17, color: isSelected ? AppColors.primary : AppColors.textMuted),
          onPressed: () => _speakSection(lang == 'hi' ? '$title: $voiceDesc' : '$title. $voiceDesc'),
        ),
        onTap: () {
          setState(() {
            _selectedSidebarIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildMainContent(String lang, UserModel? user, PatientProfileModel? profile, PatientState patient) {
    switch (_selectedSidebarIndex) {
      case 1:
        return _buildProfileTab(lang, user, profile);
      case 2:
        return _buildSummariesTab(patient);
      case 3:
        return _buildDocsTab(patient);
      case 4:
        return _buildAppointmentsTab();
      case 0:
      default:
        return _buildDashboardHome(lang, user, profile, patient);
    }
  }

  Widget _buildDashboardHome(String lang, UserModel? user, PatientProfileModel? profile, PatientState patient) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Namaste, ${user?.name ?? "Patient"}!',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select a clinical mode below for voice-guided pre-intake triage. You will receive an instant OPD queue token.',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                  onPressed: () => _speakSection(
                    lang == 'hi'
                        ? 'नमस्ते! क्लिनिकल जांच शुरू करने के लिए एलोपैथी या आयुष चुनें।'
                        : 'Hello! Choose Allopathy or AYUSH intake for your voice guided consultation.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Active Session or Prescription Alert Card
          if (patient.sessions.any((s) => s.status == 'waiting')) ...[
            Builder(builder: (context) {
              final waitingSess = patient.sessions.firstWhere((s) => s.status == 'waiting');
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.priorityP1Container.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.priorityP1, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.priorityP1, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.timer_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Token ${waitingSess.tokenNumber}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.priorityP1),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('${waitingSess.priority} TRIAGE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
                                backgroundColor: AppColors.priorityP1,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Active in Doctor OPD Queue (Room 104) • Mode: ${waitingSess.mode.toUpperCase()}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Chief complaint: ${waitingSess.chiefComplaint ?? "Pre-intake completed"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() => _selectedSidebarIndex = 2),
                      child: const Text('View Status'),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ] else if (patient.prescriptions.isNotEmpty) ...[
            Builder(builder: (context) {
              final latestRx = patient.prescriptions.first;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.certainGreenBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.certainGreen, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.certainGreen, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Doctor Consultation Completed by ${latestRx.doctorName ?? "Dr. Rajesh Sharma, MD"}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.certainGreen),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Diagnosis: ${latestRx.diagnosis} • ${latestRx.medications.length} Medications Prescribed',
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.certainGreen),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
                      label: const Text('View Rx PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        PDFPrescriptionGenerator.printPrescription(
                          prescription: latestRx,
                          patientName: user?.name ?? 'Patient',
                          doctorName: latestRx.doctorName ?? 'Dr. Rajesh Sharma, MD',
                          diagnosis: latestRx.diagnosis,
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          // Two Main Clinical Intake Cards: Allopathy & AYUSH
          const Text('Start Clinical Intake', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Allopathy Card
              Expanded(
                child: VoiceGuidanceButton(
                  title: AppStrings.tr('allopathy_title', lang: lang),
                  subtitle: AppStrings.tr('allopathy_desc', lang: lang),
                  icon: Icons.medical_services_rounded,
                  backgroundColor: AppColors.primary,
                  voiceDescription: AppStrings.getSpeechDescription('btn_allopathy', lang: lang),
                  isLarge: true,
                  onPressed: _startAllopathyIntake,
                  langCode: lang,
                ),
              ),
              const SizedBox(width: 16),
              // AYUSH Card
              Expanded(
                child: VoiceGuidanceButton(
                  title: AppStrings.tr('ayush_title', lang: lang),
                  subtitle: AppStrings.tr('ayush_desc', lang: lang),
                  icon: Icons.spa_rounded,
                  backgroundColor: AppColors.ayushGreen,
                  voiceDescription: AppStrings.getSpeechDescription('btn_ayush', lang: lang),
                  isLarge: true,
                  onPressed: _startAyushIntake,
                  langCode: lang,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Quick Patient Health Snapshot & Uploaded Docs
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health Snapshot Card
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                              SizedBox(width: 8),
                              Text('Health Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit'),
                            onPressed: () => setState(() => _selectedSidebarIndex = 1),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildInfoRow('Blood Group', profile?.bloodType ?? 'O+', Icons.bloodtype_rounded, Colors.red),
                      const SizedBox(height: 10),
                      _buildInfoRow('Allergies', profile?.allergies ?? 'None', Icons.warning_amber_rounded, Colors.orange),
                      const SizedBox(height: 10),
                      _buildInfoRow('Gender / Age', '${profile?.gender ?? "Male"}, 42 yrs', Icons.person_outline_rounded, Colors.blue),
                      const SizedBox(height: 10),
                      _buildInfoRow('ABHA Status', 'Verified (Local SQLite)', Icons.verified_rounded, Colors.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Scanned Documents Card
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.folder_shared_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text('Scanned Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                            label: const Text('Scan Doc', style: TextStyle(fontSize: 12, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            onPressed: _openDocScanner,
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      if (patient.documents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('No documents scanned yet. Tap "Scan Doc" to upload.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ),
                        )
                      else
                        ...patient.documents.take(3).map((doc) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 24),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(doc.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                        Text('${doc.docType} • ${doc.createdAt.toIso8601String().split('T').first}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  const Chip(
                                    label: Text('OCR Parsed', style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                                    backgroundColor: AppColors.primaryContainer,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
},
);
}

  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab(String lang, UserModel? user, PatientProfileModel? profile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, maxWidth: 1200),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Edit Patient Health Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                            onPressed: () => _speakSection(
                              lang == 'hi'
                                  ? 'यहां आप अपने रक्त समूह, एलर्जी और व्यक्तिगत स्वास्थ्य विवरण को संपादित और सहेज सकते हैं।'
                                  : 'Here you can view and edit your blood group, allergies, and health metrics. Changes will be saved to the SQLite database.',
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(controller: _nameController, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_rounded))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Blood Group', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedBlood,
                                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: (v) => setState(() => _selectedBlood = v ?? 'O+'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedGender,
                                  items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: (v) => setState(() => _selectedGender = v ?? 'Male'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Known Allergies', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(controller: _allergiesController, decoration: const InputDecoration(prefixIcon: Icon(Icons.warning_amber_rounded))),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _saveProfileChanges,
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: const Text('Save Profile to Local Database', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummariesTab(PatientState patient) {
    final user = ref.read(authProvider).currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Section 1: Doctor Consultations & Digital Prescriptions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Doctor Consultations & Prescriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('Consultations completed by doctors and issued Rx orders', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                Chip(
                  backgroundColor: AppColors.certainGreenBg,
                  avatar: const Icon(Icons.medication_rounded, size: 16, color: AppColors.certainGreen),
                  label: Text('${patient.prescriptions.length} Prescriptions', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.certainGreen)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (patient.prescriptions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 40, color: AppColors.textMuted),
                    SizedBox(height: 10),
                    Text('No completed consultations yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('When the Doctor completes a consultation in the Doctor Portal, the digital prescription & diagnosis will appear here automatically.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              ...patient.prescriptions.map((rx) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.certainGreen, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.certainGreen.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.certainGreenBg,
                              child: const Icon(Icons.medical_services_rounded, color: AppColors.certainGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rx.doctorName ?? 'Dr. Rajesh Sharma, MD',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                  ),
                                  Text('Consultation Date: ${rx.createdAt.toIso8601String().split("T").first}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                PDFPrescriptionGenerator.printPrescription(
                                  prescription: rx,
                                  patientName: user?.name ?? 'Patient',
                                  doctorName: rx.doctorName ?? 'Dr. Rajesh Sharma, MD',
                                  diagnosis: rx.diagnosis,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.certainGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
                              label: const Text('Print PDF Rx', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Diagnosis: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                            Expanded(
                              child: Text(rx.diagnosis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('Prescribed Medications:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        ...rx.medications.map((med) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.medication_liquid_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${med.drugName} ${med.dosage} — ${med.frequency} • ${med.duration} (${med.instruction})',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        if (rx.instructions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Doctor Advice: ${rx.instructions}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  )),
            const SizedBox(height: 24),

            // Section 2: Clinical Pre-Intake Summaries & Tokens
            const Text('Clinical Pre-Intake Triage Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 14),

            if (patient.sessions.isEmpty)
              const Center(child: Text('No previous triage sessions recorded.'))
            else
              ...patient.sessions.map((sess) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: sess.priority == 'P1'
                            ? AppColors.priorityP1Container
                            : sess.priority == 'P2'
                                ? AppColors.priorityP2Container
                                : AppColors.priorityP3Container,
                        child: Text(
                          sess.priority,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sess.priority == 'P1'
                                ? AppColors.priorityP1
                                : sess.priority == 'P2'
                                    ? AppColors.priorityP2
                                    : AppColors.priorityP3,
                          ),
                        ),
                      ),
                      title: Text('Token: ${sess.tokenNumber} (${sess.mode.toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(sess.chiefComplaint ?? 'General Pre-Intake Triage', style: const TextStyle(fontSize: 12)),
                      trailing: Chip(
                        label: Text(
                          sess.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: sess.status == 'completed' ? AppColors.certainGreen : AppColors.priorityP1,
                          ),
                        ),
                        backgroundColor: sess.status == 'completed' ? AppColors.certainGreenBg : AppColors.priorityP1Container,
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

  Widget _buildDocsTab(PatientState patient) {
    final patientId = ref.read(authProvider).currentUser?.id ?? 'usr_patient_1';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Quick Document Scanner & Upload Action Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
                        child: const Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload & Scan Medical Records (OCR)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Capture via live optical camera or upload lab reports & prescriptions for automatic NER extraction.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openCameraDialog,
                          icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                          label: const Text('Take Photo with Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await ref.read(documentProvider.notifier).uploadFromFilePicker(patientId);
                            await ref.read(patientProvider.notifier).refreshDocuments();
                          },
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('Upload PDF / Image File', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Scanned Documents List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Medical Documents (${patient.documents.length})',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                TextButton.icon(
                  onPressed: _openDocScanner,
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
                  label: const Text('Open Full OCR Studio'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (patient.documents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No documents scanned yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text('Use the buttons above to scan a prescription or fast-load a demo report.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              )
            else
              ...patient.documents.map((doc) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: doc.docType.toLowerCase().contains('lab') ? Colors.purple.shade50 : AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          doc.docType.toLowerCase().contains('lab') ? Icons.science_rounded : Icons.medication_rounded,
                          color: doc.docType.toLowerCase().contains('lab') ? Colors.purple.shade700 : AppColors.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        doc.fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        '${doc.docType} • Scanned ${doc.createdAt.toIso8601String().split("T").first}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Chip(
                        label: Text('OCR Processed', style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                        backgroundColor: AppColors.primaryContainer,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('OCR Extracted Content & Clinical Data:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  doc.extractedText,
                                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming OPD Consultations',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Complete your voice pre-intake triage to receive an instant prioritized queue token.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                      SizedBox(width: 6),
                      Text('2 Confirmed Slots', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Doctor 1: Dr. Rajesh Sharma, MD (Allopathy)
            _buildDoctorAppointmentCard(
              doctorName: 'Dr. Rajesh Sharma, MD',
              specialty: 'Cardiology & General Internal Medicine',
              department: 'Central OPD Block • Room 104',
              timeSlot: 'Today at 11:30 AM',
              queueStatus: 'Queue Active (Waiting: 3)',
              isAllopathy: true,
              onStartIntake: _startAllopathyIntake,
            ),
            const SizedBox(height: 16),

            // Doctor 2: Dr. Priya Nair, BAMS, MD (AYUSH)
            _buildDoctorAppointmentCard(
              doctorName: 'Dr. Priya Nair, BAMS, MD',
              specialty: 'Ayurveda Kayachikitsa & Panchakarma',
              department: 'AYUSH Specialty Wing • Room 208',
              timeSlot: 'Tomorrow at 10:00 AM',
              queueStatus: 'Intake Available Now',
              isAllopathy: false,
              onStartIntake: _startAyushIntake,
            ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorAppointmentCard({
    required String doctorName,
    required String specialty,
    required String department,
    required String timeSlot,
    required String queueStatus,
    required bool isAllopathy,
    required VoidCallback onStartIntake,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Avatar with Badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isAllopathy ? AppColors.primaryContainer : AppColors.ayushGreenContainer,
                    child: Icon(
                      isAllopathy ? Icons.medical_services_rounded : Icons.spa_rounded,
                      color: isAllopathy ? AppColors.primary : AppColors.ayushGreen,
                      size: 28,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Doctor Details Section (Never collapsed vertically)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            doctorName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAllopathy ? AppColors.primaryContainer : AppColors.ayushGreenContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAllopathy ? 'Allopathy OPD' : 'AYUSH OPD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAllopathy ? AppColors.primaryDark : AppColors.ayushGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(department, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Bottom Action Bar with Time & Start Pre-Intake Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(timeSlot, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_rounded, size: 14, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(queueStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
                      ],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onStartIntake,
                icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                label: Text(
                  isAllopathy ? 'Start Pre-Intake (SOCRATES)' : 'Start AYUSH Pre-Intake',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAllopathy ? AppColors.primary : AppColors.ayushGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
