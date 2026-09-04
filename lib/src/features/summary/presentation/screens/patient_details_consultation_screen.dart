import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/models/prescription_model.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../voice/widgets/audio_waveform_visualizer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../doctor_dashboard/presentation/providers/doctor_provider.dart';
import '../../../prescription/domain/pdf_prescription_generator.dart';
import '../providers/consultation_provider.dart';

class PatientDetailsConsultationScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const PatientDetailsConsultationScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<PatientDetailsConsultationScreen> createState() => _PatientDetailsConsultationScreenState();
}

class _PatientDetailsConsultationScreenState extends ConsumerState<PatientDetailsConsultationScreen> {
  final _diagController = TextEditingController();
  final _notesController = TextEditingController();

  // New Drug Input Controllers
  final _drugNameController = TextEditingController();
  final _dosageController = TextEditingController(text: '500mg');
  final _freqController = TextEditingController(text: 'Twice Daily (BD)');
  final _durationController = TextEditingController(text: '5 days');
  final _instController = TextEditingController(text: 'After food');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(consultationProvider.notifier).loadSession(widget.sessionId);
    });
  }

  @override
  void dispose() {
    _diagController.dispose();
    _notesController.dispose();
    _drugNameController.dispose();
    _dosageController.dispose();
    _freqController.dispose();
    _durationController.dispose();
    _instController.dispose();
    super.dispose();
  }

  void _handleAddDrug() {
    if (_drugNameController.text.trim().isEmpty) return;

    ref.read(consultationProvider.notifier).addMedication(
      PrescriptionItem(
        drugName: _drugNameController.text.trim(),
        dosage: _dosageController.text.trim(),
        frequency: _freqController.text.trim(),
        duration: _durationController.text.trim(),
        instruction: _instController.text.trim(),
      ),
    );

    _drugNameController.clear();
    Navigator.pop(context);
    NotificationService.showSuccess('Medication added to prescription.');
  }

  void _showAddDrugDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Medication to Prescription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _drugNameController, decoration: const InputDecoration(labelText: 'Drug Name (e.g. Paracetamol, Amoxicillin)')),
              const SizedBox(height: 10),
              TextFormField(controller: _dosageController, decoration: const InputDecoration(labelText: 'Dosage (e.g. 650mg, 10ml)')),
              const SizedBox(height: 10),
              TextFormField(controller: _freqController, decoration: const InputDecoration(labelText: 'Frequency (e.g. OD, BD, TDS)')),
              const SizedBox(height: 10),
              TextFormField(controller: _durationController, decoration: const InputDecoration(labelText: 'Duration (e.g. 5 days)')),
              const SizedBox(height: 10),
              TextFormField(controller: _instController, decoration: const InputDecoration(labelText: 'Instructions (e.g. After food)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: _handleAddDrug, child: const Text('Add Drug')),
        ],
      ),
    );
  }

  void _generateAndPrintPdf() async {
    final state = ref.read(consultationProvider);
    final doctor = ref.read(authProvider).currentUser;

    if (state.session == null) return;

    final prescription = PrescriptionModel(
      id: 'RX-${state.session!.tokenNumber}',
      sessionId: state.session!.id,
      doctorId: doctor?.id ?? 'dr_1',
      patientId: state.session!.patientId,
      medications: state.prescribedMedications,
      instructions: _notesController.text.trim().isEmpty ? state.doctorNotes : _notesController.text.trim(),
      diagnosis: _diagController.text.trim().isEmpty ? state.diagnosis : _diagController.text.trim(),
    );

    await PDFPrescriptionGenerator.printPrescription(
      prescription: prescription,
      patientName: state.patient?.name ?? 'Patient',
      doctorName: doctor?.name ?? 'Dr. Rajesh Sharma, MD',
      diagnosis: prescription.diagnosis,
    );
  }

  void _handleSubmitConsultation() async {
    final doctor = ref.read(authProvider).currentUser;
    final doctorName = doctor?.name ?? 'Dr. Rajesh Sharma, MD';
    final doctorId = doctor?.id ?? 'usr_doctor_1';

    ref.read(consultationProvider.notifier).updateDiagnosis(_diagController.text.trim());
    ref.read(consultationProvider.notifier).updateNotes(_notesController.text.trim());

    final success = await ref.read(consultationProvider.notifier).completeConsultation(doctorId, doctorName);
    if (success && mounted) {
      ref.read(doctorProvider.notifier).loadQueue();
      NotificationService.showSuccess('Consultation completed and saved to SQLite! Moving to next patient.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consultationProvider);
    final session = state.session;
    final patient = state.patient;
    final profile = state.patientProfile;
    final summary = state.aiSummary;

    if (_diagController.text.isEmpty && state.diagnosis.isNotEmpty) {
      _diagController.text = state.diagnosis;
    }
    if (_notesController.text.isEmpty && state.doctorNotes.isNotEmpty) {
      _notesController.text = state.doctorNotes;
    }

    if (state.isLoading || session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text('Consultation: ${patient?.name ?? "Patient"} (${session.tokenNumber})'),
            const SizedBox(width: 12),
            Chip(
              backgroundColor: session.priority == 'P1'
                  ? AppColors.priorityP1Container
                  : session.priority == 'P2'
                      ? AppColors.priorityP2Container
                      : AppColors.priorityP3Container,
              label: Text(
                '${session.priority} TRIAGE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: session.priority == 'P1'
                      ? AppColors.priorityP1
                      : session.priority == 'P2'
                          ? AppColors.priorityP2
                          : AppColors.priorityP3,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: state.isReadingSummary ? 'Stop Voice Summary' : 'Read AI Summary Aloud',
            icon: Icon(state.isReadingSummary ? Icons.stop_rounded : Icons.volume_up_rounded, color: AppColors.primary),
            onPressed: () {
              if (state.isReadingSummary) {
                ref.read(consultationProvider.notifier).stopReadingSummary();
              } else {
                ref.read(consultationProvider.notifier).readSummaryAloud();
              }
            },
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _generateAndPrintPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.white),
            label: const Text('Print PDF Rx', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
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
                    // Patient Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        patient?.name.isNotEmpty == true ? patient!.name[0] : 'P',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient?.name ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 2),
                          Text('ABHA ID: ${patient?.abhaId} • Phone: ${patient?.phone} • Blood: ${profile?.bloodType ?? "O+"} • Allergies: ${profile?.allergies ?? "None"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                      child: Text('Mode: ${session.mode.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ==========================================
              // 3-TIER AI CONSULTATION SUMMARY SECTION
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI Clinical Pre-Intake Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  TextButton.icon(
                    icon: Icon(state.isReadingSummary ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                    label: Text(state.isReadingSummary ? 'Stop Audio' : 'Play Voice Summary'),
                    onPressed: () {
                      if (state.isReadingSummary) {
                        ref.read(consultationProvider.notifier).stopReadingSummary();
                      } else {
                        ref.read(consultationProvider.notifier).readSummaryAloud();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Section 1: 100% CERTAIN
              _buildCertaintyBox(
                title: '🟢 100% CERTAIN (AI Verified Clinical Facts)',
                subtitle: 'The patient gave clear, confident responses to these parameters during pre-intake:',
                items: summary?.certainItems ?? ['Clinical facts verified.'],
                borderColor: AppColors.certainGreen,
                bgColor: AppColors.certainGreenBg,
                textColor: AppColors.certainGreen,
              ),
              const SizedBox(height: 14),

              // Section 2: NOT SURE
              _buildCertaintyBox(
                title: '🟡 NOT SURE (Patient Hesitated / Ambiguous)',
                subtitle: 'The patient hesitated or used uncertainty markers ("maybe", "I think so"). Verify these:',
                items: summary?.notSureItems.isNotEmpty == true
                    ? summary!.notSureItems
                    : ['No significant hesitation detected in pre-intake.'],
                borderColor: AppColors.notSureYellow,
                bgColor: AppColors.notSureYellowBg,
                textColor: AppColors.notSureYellow,
              ),
              const SizedBox(height: 14),

              // Section 3: UNCLEAR
              _buildCertaintyBox(
                title: '🔴 UNCLEAR (Requires Doctor Clarification)',
                subtitle: 'Unanswered or speech was unrecognized. Please ask these questions directly:',
                items: summary?.unclearItems.isNotEmpty == true
                    ? summary!.unclearItems
                    : ['All clinical questions were successfully captured.'],
                borderColor: AppColors.unclearRed,
                bgColor: AppColors.unclearRedBg,
                textColor: AppColors.unclearRed,
              ),
              const SizedBox(height: 28),

              // ==========================================
              // DOCTOR CONSULTATION & PRESCRIPTION
              // ==========================================
              Container(
                padding: const EdgeInsets.all(22),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                            SizedBox(width: 8),
                            Text('Clinical Prescription & Doctor Assessment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        // Voice Dictation Button
                        ElevatedButton.icon(
                          onPressed: () {
                            if (state.isDictatingRx) {
                              ref.read(consultationProvider.notifier).stopVoiceDictation();
                            } else {
                              ref.read(consultationProvider.notifier).startVoiceDictation();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.isDictatingRx ? AppColors.micActive : AppColors.primaryLight,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          icon: Icon(state.isDictatingRx ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 16),
                          label: Text(
                            state.isDictatingRx ? 'Stop Dictation' : 'Dictate Voice Rx',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (state.isDictatingRx) ...[
                      const SizedBox(height: 12),
                      AudioWaveformVisualizer(isRecording: true, barHeight: 35),
                      const SizedBox(height: 6),
                      Text('Dictating: "${state.currentDictation}"', style: const TextStyle(fontSize: 12, color: AppColors.micActive, fontWeight: FontWeight.bold)),
                    ],
                    const Divider(height: 24),

                    // Diagnosis Input
                    const Text('Clinical Diagnosis / Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _diagController,
                      decoration: const InputDecoration(hintText: 'e.g., Acute Musculoskeletal Back Pain / Viral Bronchitis'),
                    ),
                    const SizedBox(height: 18),

                    // Medications List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Prescribed Medications (Rx)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        OutlinedButton.icon(
                          onPressed: _showAddDrugDialog,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Drug Manually', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Medications Table / Cards
                    if (state.prescribedMedications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No medications added. Use Voice Dictation or tap "Add Drug Manually".', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      )
                    else
                      ...state.prescribedMedications.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final med = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.medication_rounded, color: AppColors.primary, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${med.drugName} - ${med.dosage}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('${med.frequency} • ${med.duration} • ${med.instruction}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.priorityP1, size: 20),
                                onPressed: () => ref.read(consultationProvider.notifier).removeMedication(idx),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 18),

                    // Doctor Notes / Instructions
                    const Text('Advice / Follow-Up Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'e.g., Maintain rest, drink warm fluids, review in OPD after 5 days if fever persists.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Bottom Actions: Done/Submit Consultation
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generateAndPrintPdf,
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Preview & Print Prescription PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleSubmitConsultation,
                      icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                      label: const Text('Complete Consultation & Next Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.certainGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
  ),
),
);
}

  Widget _buildCertaintyBox({
    required String title,
    required String subtitle,
    required List<String> items,
    required Color borderColor,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: textColor)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                    Expanded(
                      child: Text(item, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
