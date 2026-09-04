import '../../shared/models/patient_profile_model.dart';
import '../app_database.dart';

class PatientProfileDao {
  final AppDatabase _dbProvider;

  PatientProfileDao({AppDatabase? dbProvider}) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<int> insertOrUpdateProfile(PatientProfileModel profile) async {
    return await _dbProvider.insert('patient_profiles', profile.toMap());
  }

  Future<PatientProfileModel?> getProfileByUserId(String userId) async {
    final maps = await _dbProvider.query('patient_profiles', where: 'user_id = ?', whereArgs: [userId]);
    if (maps.isNotEmpty) {
      return PatientProfileModel.fromMap(maps.first);
    }
    return null;
  }
}
