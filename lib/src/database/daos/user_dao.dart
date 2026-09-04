import '../../shared/models/user_model.dart';
import '../app_database.dart';

class UserDao {
  final AppDatabase _dbProvider;

  UserDao({AppDatabase? dbProvider}) : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<int> insertUser(UserModel user) async {
    return await _dbProvider.insert('users', user.toMap());
  }

  Future<UserModel?> getUserById(String id) async {
    final maps = await _dbProvider.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel?> findByCredentials(String identifier, String passwordHash) async {
    final maps = await _dbProvider.query(
      'users',
      where: '(phone = ? OR abha_id = ? OR email = ?) AND password_hash = ?',
      whereArgs: [identifier, identifier, identifier, passwordHash],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers({String? role}) async {
    List<Map<String, dynamic>> maps;
    if (role != null) {
      maps = await _dbProvider.query('users', where: 'role = ?', whereArgs: [role], orderBy: 'created_at DESC');
    } else {
      maps = await _dbProvider.query('users', orderBy: 'created_at DESC');
    }
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<int> updateUser(UserModel user) async {
    return await _dbProvider.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> updatePassword(String userId, String newPasswordHash) async {
    return await _dbProvider.update(
      'users',
      {'password_hash': newPasswordHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(String id) async {
    return await _dbProvider.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
