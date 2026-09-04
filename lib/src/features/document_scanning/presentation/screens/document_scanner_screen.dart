import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../voice/services/tts_service.dart';
import '../../../../shared/widgets/camera_scanner_dialog.dart';
import '../../../../shared/widgets/portal_switcher_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/document_provider.dart';

class DocumentScannerScreen extends ConsumerStatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  ConsumerState<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends ConsumerState<DocumentScannerScreen> {
  void _speakGuidance() {
    final tts = getIt<TTSService>();
    tts.speak('Use your device camera or upload a file to scan prescriptions and lab reports with on-device OCR.');
  }

  void _openCameraModal() {
    CameraScannerDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final docState = ref.watch(documentProvider);
    final patientId = auth.currentUser?.id ?? 'usr_patient_1';
    final latestResult = docState.latestResult;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Document Scanner & OCR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Hear scanning instructions',
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
            onPressed: _speakGuidance,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const PortalDemoSwitcher(currentPortal: 'patient'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scan Actions Header Card
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
                            const Row(
                              children: [
                                Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 28),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Scan Prescriptions & Lab Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                      Text('On-device OCR extracts medications, dosages, and abnormal lab metrics in real time.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 28),

                            // Scan Buttons Row
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: docState.isScanning ? null : _openCameraModal,
                                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                                    label: const Text('Take Photo with Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: docState.isScanning
                                        ? null
                                        : () => ref.read(documentProvider.notifier).uploadFromFilePicker(patientId),
                                    icon: const Icon(Icons.upload_file_rounded),
                                    label: const Text('Upload PDF / Image File', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
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
                const SizedBox(height: 24),

                // OCR Processing Indicator
                if (docState.isScanning) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 14),
                        Text('Processing ${docState.scannedFileName ?? "document"} with OCR...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Text('Extracting medical NER entities & abnormal flags...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // OCR Extraction Result Card
                if (latestResult != null && !docState.isScanning) ...[
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.certainGreen, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.certainGreen, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'OCR Extraction Results (${latestResult.detectedDocType})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                              ),
                            ),
                            Chip(
                              label: Text('Saved to SQLite', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.certainGreen)),
                              backgroundColor: AppColors.certainGreenBg,
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Flagged Warnings (if any)
                        if (latestResult.flaggedWarnings.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.unclearRedBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.priorityP1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.warning_rounded, color: AppColors.priorityP1, size: 18),
                                    SizedBox(width: 6),
                                    Text('Abnormal Lab Findings Detected:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.priorityP1, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...latestResult.flaggedWarnings.map((w) => Text('• $w', style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Extracted Lab Values Table
                        if ((latestResult.entities['lab_values'] as List?)?.isNotEmpty == true) ...[
                          const Text('Parsed Lab Test Parameters:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          ...((latestResult.entities['lab_values'] as List).map((lv) {
                            final map = lv as Map<String, dynamic>;
                            final isAbnormal = map['flag'] == 'HIGH' || map['flag'] == 'LOW';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isAbnormal ? AppColors.priorityP2Container : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(map['test'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Row(
                                    children: [
                                      Text(map['value'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(map['flag'] ?? 'NORMAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isAbnormal ? Colors.deepOrange : Colors.green)),
                                        backgroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          })),
                          const SizedBox(height: 16),
                        ],

                        // Extracted Medications (if any)
                        if ((latestResult.entities['medications'] as List?)?.isNotEmpty == true) ...[
                          const Text('Parsed Medications (Rx):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          ...((latestResult.entities['medications'] as List).map((med) {
                            final map = med as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.medication_rounded, color: AppColors.primary),
                              title: Text('${map['drug_name']} (${map['dosage']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${map['frequency']} • ${map['duration']} • ${map['instruction']}'),
                              contentPadding: EdgeInsets.zero,
                            );
                          })),
                          const SizedBox(height: 16),
                        ],

                        // Raw OCR Text Expansion
                        ExpansionTile(
                          title: const Text('View Raw OCR Output', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                              child: Text(latestResult.rawText, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // All Previously Scanned Documents
                const Text('All Scanned Medical Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                if (docState.documents.isEmpty)
                  const Text('No documents saved yet.')
                else
                  ...docState.documents.map((d) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.description_rounded, color: AppColors.primary),
                          title: Text(d.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${d.docType} • ${d.createdAt.toIso8601String().split("T").first}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
