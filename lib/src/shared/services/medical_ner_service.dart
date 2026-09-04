import '../models/prescription_model.dart';

class MedicalNERService {
  // Common Indian and global pharmaceutical formulations
  static final List<String> _knownDrugs = [
    'Paracetamol', 'Dolo 650', 'Amoxicillin', 'Azithromycin', 'Metformin',
    'Telmisartan', 'Amlodipine', 'Atorvastatin', 'Pantoprazole', 'Omeprazole',
    'Cetirizine', 'Montelukast', 'Ibuprofen', 'Ciprofloxacin', 'Losartan',
    'Thyronorm', 'Aspirin', 'Clopidogrel', 'Levothyroxine', 'Glimipride',
    'Rabeprazole', 'Domperidone', 'Cough Syrup', 'ORS', 'Vitamin D3',
    'Ashwagandha', 'Triphala', 'Brahmi', 'Chyawanprash', 'Gokshura', 'Trikatu',
  ];

  static List<PrescriptionItem> extractPrescriptionItems(String voiceOrOcrText) {
    final List<PrescriptionItem> items = [];
    if (voiceOrOcrText.trim().isEmpty) return items;

    final lines = voiceOrOcrText.split(RegExp(r'[\n\.,;]'));

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      String? matchedDrug;
      for (var drug in _knownDrugs) {
        if (RegExp(r'\b' + RegExp.escape(drug) + r'\b', caseSensitive: false).hasMatch(trimmed)) {
          matchedDrug = drug;
          break;
        }
      }

      // If no pre-listed drug found, check if line mentions 'Tab' or 'Cap' or 'Syrup'
      if (matchedDrug == null) {
        final formMatch = RegExp(r'\b(Tab|Tablet|Cap|Capsule|Syrup|Inj)\s+([A-Za-z0-9\-]+)', caseSensitive: false).firstMatch(trimmed);
        if (formMatch != null) {
          matchedDrug = '${formMatch.group(1)} ${formMatch.group(2)}';
        }
      }

      if (matchedDrug != null) {
        // Extract dosage (e.g., 650mg, 500 mg, 10ml, 5mg)
        final doseMatch = RegExp(r'(\d+\.?\d*\s*(mg|g|ml|mcg|iu|IU))', caseSensitive: false).firstMatch(trimmed);
        final dosage = doseMatch != null ? doseMatch.group(1)! : '1 Tablet';

        // Extract frequency (e.g. BD, OD, TDS, twice daily, once daily, 1-0-1, 1-1-1, SOS)
        String frequency = 'Once Daily (OD)';
        if (RegExp(r'\b(BD|BID|twice daily|2 times|1-0-1)\b', caseSensitive: false).hasMatch(trimmed)) {
          frequency = 'Twice Daily (BD)';
        } else if (RegExp(r'\b(TDS|TID|thrice daily|3 times|1-1-1)\b', caseSensitive: false).hasMatch(trimmed)) {
          frequency = 'Thrice Daily (TDS)';
        } else if (RegExp(r'\b(QID|4 times)\b', caseSensitive: false).hasMatch(trimmed)) {
          frequency = 'Four Times Daily (QID)';
        } else if (RegExp(r'\b(SOS|when needed|as needed)\b', caseSensitive: false).hasMatch(trimmed)) {
          frequency = 'When Needed (SOS)';
        } else if (RegExp(r'\b(HS|at night|bedtime)\b', caseSensitive: false).hasMatch(trimmed)) {
          frequency = 'At Bedtime (HS)';
        }

        // Extract duration (e.g., for 5 days, 1 week, 10 days, 1 month)
        final durationMatch = RegExp(r'(\d+\s*(days|day|weeks|week|months|month))', caseSensitive: false).firstMatch(trimmed);
        final duration = durationMatch != null ? durationMatch.group(1)! : '5 days';

        // Extract instruction (after food, before food, with warm water)
        String instruction = 'After food';
        if (RegExp(r'\b(before food|empty stomach|before meals|ac)\b', caseSensitive: false).hasMatch(trimmed)) {
          instruction = 'Before food (Empty stomach)';
        } else if (RegExp(r'\b(with warm water|lukewarm milk)\b', caseSensitive: false).hasMatch(trimmed)) {
          instruction = 'With warm water';
        }

        items.add(PrescriptionItem(
          drugName: matchedDrug,
          dosage: dosage,
          frequency: frequency,
          duration: duration,
          instruction: instruction,
        ));
      }
    }

    return items;
  }

  static Map<String, dynamic> extractLabEntities(String text) {
    final List<Map<String, dynamic>> labValues = [];
    final List<String> abnormalFlags = [];

    final tests = [
      {'name': 'Hemoglobin', 'regex': r'Hemoglobin|Hb', 'unit': 'g/dL', 'min': 12.0, 'max': 17.5},
      {'name': 'WBC Count', 'regex': r'WBC|Total\s+Leukocyte', 'unit': '/cumm', 'min': 4000.0, 'max': 11000.0},
      {'name': 'Platelets', 'regex': r'Platelet', 'unit': 'lakh/cumm', 'min': 1.5, 'max': 4.5},
      {'name': 'Fasting Blood Sugar', 'regex': r'Fasting\s+(Blood\s+)?(Sugar|Glucose)|FBS', 'unit': 'mg/dL', 'min': 70.0, 'max': 100.0},
      {'name': 'Postprandial Glucose', 'regex': r'PPBS|Postprandial', 'unit': 'mg/dL', 'min': 80.0, 'max': 140.0},
      {'name': 'HbA1c', 'regex': r'HbA1c|Glycated\s+Hemoglobin', 'unit': '%', 'min': 4.0, 'max': 5.7},
      {'name': 'Serum Creatinine', 'regex': r'Creatinine', 'unit': 'mg/dL', 'min': 0.6, 'max': 1.2},
      {'name': 'Total Cholesterol', 'regex': r'Total\s+Cholesterol|Cholesterol', 'unit': 'mg/dL', 'min': 120.0, 'max': 200.0},
      {'name': 'Triglycerides', 'regex': r'Triglycerides|TGL', 'unit': 'mg/dL', 'min': 50.0, 'max': 150.0},
      {'name': 'HDL Cholesterol', 'regex': r'HDL(\s+Cholesterol)?', 'unit': 'mg/dL', 'min': 40.0, 'max': 60.0},
      {'name': 'LDL Cholesterol', 'regex': r'LDL(\s+Cholesterol)?', 'unit': 'mg/dL', 'min': 50.0, 'max': 100.0},
      {'name': 'Blood Pressure', 'regex': r'BP|Blood\s+Pressure', 'unit': 'mmHg', 'min': 90.0, 'max': 120.0},
    ];

    for (var t in tests) {
      final pattern = RegExp(
        '(${t['regex']})\\s*[:=-]?\\s*(\\d+\\.?\\d*)',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);
      if (match != null) {
        final valStr = match.group(match.groupCount);
        if (valStr != null) {
          final val = double.tryParse(valStr);
          if (val != null) {
            final min = t['min'] as double;
            final max = t['max'] as double;
            String flag = 'NORMAL';
            if (val < min) {
              flag = 'LOW';
              abnormalFlags.add('Low ${t['name']} ($val ${t['unit']})');
            } else if (val > max) {
              flag = 'HIGH';
              abnormalFlags.add('High ${t['name']} ($val ${t['unit']})');
            }

            labValues.add({
              'test': t['name'],
              'value': '$val ${t['unit']}',
              'flag': flag,
            });
          }
        }
      }
    }

    return {
      'lab_values': labValues,
      'abnormal': abnormalFlags,
    };
  }
}
