import '../../shared/models/clinical_session_model.dart';
import '../app_database.dart';

class ClinicalSessionDao {
  final AppDatabase _dbProvider;

  ClinicalSessionDao({AppDatabase? dbProvider}) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<int> insertSession(ClinicalSessionModel session) async {
    return await _dbProvider.insert('clinical_sessions', session.toMap());
  }

  Future<ClinicalSessionModel?> getSessionById(String id) async {
    final List<Map<String, dynamic>> maps = await _dbProvider.rawQuery('''
      SELECT s.*, u.name AS patient_name
      FROM clinical_sessions s
      LEFT JOIN users u ON s.patient_id = u.id
      WHERE s.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      return ClinicalSessionModel.fromMap(maps.first, patientName: maps.first['patient_name'] as String?);
    }
    return null;
  }

  Future<List<ClinicalSessionModel>> getDoctorQueue({String? status}) async {
    final statusFilter = status ?? 'waiting';
    final List<Map<String, dynamic>> maps = await _dbProvider.rawQuery('''
      SELECT s.*, u.name AS patient_name
      FROM clinical_sessions s
      LEFT JOIN users u ON s.patient_id = u.id
      WHERE s.status = ?
      ORDER BY 
        CASE s.priority
          WHEN 'P1' THEN 1
          WHEN 'P2' THEN 2
          WHEN 'P3' THEN 3
          ELSE 4
        END,
        s.created_at ASC
    ''', [statusFilter]);

    return maps.map((m) => ClinicalSessionModel.fromMap(m, patientName: m['patient_name'] as String?)).toList();
  }

  Future<List<ClinicalSessionModel>> getPatientSessions(String patientId) async {
    final List<Map<String, dynamic>> maps = await _dbProvider.rawQuery('''
      SELECT s.*, u.name AS patient_name
      FROM clinical_sessions s
      LEFT JOIN users u ON s.patient_id = u.id
      WHERE s.patient_id = ?
      ORDER BY s.created_at DESC
    ''', [patientId]);

    return maps.map((m) => ClinicalSessionModel.fromMap(m, patientName: m['patient_name'] as String?)).toList();
  }

  Future<int> updateSessionStatus(String id, String status, {String? doctorId}) async {
    final data = <String, dynamic>{'status': status};
    if (doctorId != null) {
      data['doctor_id'] = doctorId;
    }
    return await _dbProvider.update('clinical_sessions', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countSessionsByPriority(String priority) async {
    final maps = await _dbProvider.rawQuery('SELECT COUNT(*) FROM clinical_sessions WHERE priority = ?', [priority]);
    if (maps.isNotEmpty) {
      final val = maps.first.values.first;
      if (val is int) return val;
      if (val is num) return val.toInt();
    }
    return 0;
  }

  Future<int> totalSessionsCount() async {
    final maps = await _dbProvider.rawQuery('SELECT COUNT(*) FROM clinical_sessions');
    if (maps.isNotEmpty) {
      final val = maps.first.values.first;
      if (val is int) return val;
      if (val is num) return val.toInt();
    }
    return 0;
  }
}
