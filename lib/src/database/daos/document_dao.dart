import '../../shared/models/patient_document_model.dart';
import '../app_database.dart';

class DocumentDao {
  final AppDatabase _dbProvider;

  DocumentDao({AppDatabase? dbProvider}) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<int> insertDocument(PatientDocumentModel doc) async {
    return await _dbProvider.insert('patient_documents', doc.toMap());
  }

  Future<List<PatientDocumentModel>> getDocumentsByPatientId(String patientId) async {
    final maps = await _dbProvider.query(
      'patient_documents',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => PatientDocumentModel.fromMap(m)).toList();
  }

  Future<List<PatientDocumentModel>> getAllDocuments() async {
    final maps = await _dbProvider.query('patient_documents', orderBy: 'created_at DESC');
    return maps.map((m) => PatientDocumentModel.fromMap(m)).toList();
  }

  Future<int> deleteDocument(String id) async {
    return await _dbProvider.delete('patient_documents', where: 'id = ?', whereArgs: [id]);
  }
}
