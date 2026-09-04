import '../../shared/models/ai_summary_model.dart';
import '../app_database.dart';

class AISummaryDao {
  final AppDatabase _dbProvider;

  AISummaryDao({AppDatabase? dbProvider}) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<int> insertOrUpdateSummary(AISummaryModel summary) async {
    return await _dbProvider.insert('ai_summaries', summary.toMap());
  }

  Future<AISummaryModel?> getSummaryBySessionId(String sessionId) async {
    final maps = await _dbProvider.query('ai_summaries', where: 'session_id = ?', whereArgs: [sessionId]);
    if (maps.isNotEmpty) {
      return AISummaryModel.fromMap(maps.first);
    }
    return null;
  }
}
