import '../../shared/models/audit_log_model.dart';
import '../app_database.dart';

class AuditLogDao {
  final AppDatabase _dbProvider;

  AuditLogDao({AppDatabase? dbProvider}) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<int> insertLog(AuditLogModel log) async {
    return await _dbProvider.insert('audit_logs', log.toMap());
  }

  Future<List<AuditLogModel>> getRecentLogs({int limit = 50}) async {
    final maps = await _dbProvider.query('audit_logs', orderBy: 'timestamp DESC', limit: limit);
    return maps.map((m) => AuditLogModel.fromMap(m)).toList();
  }
}
