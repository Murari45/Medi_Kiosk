import '../../shared/models/clinical_intake_model.dart';
import '../app_database.dart';

class ClinicalIntakeDao {
  final AppDatabase _dbProvider;

  ClinicalIntakeDao({AppDatabase? dbProvider}) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<int> insertIntake(ClinicalIntakeModel intake) async {
    return await _dbProvider.insert('clinical_intake', intake.toMap());
  }

  Future<ClinicalIntakeModel?> getIntakeBySessionId(String sessionId) async {
    final maps = await _dbProvider.query('clinical_intake', where: 'session_id = ?', whereArgs: [sessionId]);
    if (maps.isNotEmpty) {
      return ClinicalIntakeModel.fromMap(maps.first);
    }
    return null;
  }
}
