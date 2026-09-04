import '../../shared/models/prescription_model.dart';
import '../app_database.dart';

class PrescriptionDao {
  final AppDatabase _dbProvider;

  PrescriptionDao({AppDatabase? dbProvider}) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<int> insertPrescription(PrescriptionModel prescription) async {
    return await _dbProvider.insert('prescriptions', prescription.toMap());
  }

  Future<PrescriptionModel?> getPrescriptionBySessionId(String sessionId) async {
    final List<Map<String, dynamic>> maps = await _dbProvider.rawQuery('''
      SELECT p.*, doc.name AS doctor_name, pat.name AS patient_name
      FROM prescriptions p
      LEFT JOIN users doc ON p.doctor_id = doc.id
      LEFT JOIN users pat ON p.patient_id = pat.id
      WHERE p.session_id = ?
    ''', [sessionId]);

    if (maps.isNotEmpty) {
      return PrescriptionModel.fromMap(
        maps.first,
        doctorName: maps.first['doctor_name'] as String?,
        patientName: maps.first['patient_name'] as String?,
      );
    }
    return null;
  }

  Future<List<PrescriptionModel>> getPrescriptionsByPatientId(String patientId) async {
    final List<Map<String, dynamic>> maps = await _dbProvider.rawQuery('''
      SELECT p.*, doc.name AS doctor_name, pat.name AS patient_name
      FROM prescriptions p
      LEFT JOIN users doc ON p.doctor_id = doc.id
      LEFT JOIN users pat ON p.patient_id = pat.id
      WHERE p.patient_id = ?
      ORDER BY p.created_at DESC
    ''', [patientId]);

    return maps.map((m) => PrescriptionModel.fromMap(
      m,
      doctorName: m['doctor_name'] as String?,
      patientName: m['patient_name'] as String?,
    )).toList();
  }
}
