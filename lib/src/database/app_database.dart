import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'seed_data.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _nativeDb;
  static final Map<String, List<Map<String, dynamic>>> _memoryTables = {
    'users': [],
    'patient_profiles': [],
    'clinical_sessions': [],
    'clinical_intake': [],
    'patient_documents': [],
    'prescriptions': [],
    'ai_summaries': [],
    'audit_logs': [],
  };
  static bool _initialized = false;

  AppDatabase._init();

  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      // Fast, safe in-memory store for Web
      SeedData.seedWebMemoryTables(_memoryTables);
      _initialized = true;
    } else {
      if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        final appDocDir = await getApplicationDocumentsDirectory();
        final path = join(appDocDir.path, 'medikiosk_ai.db');
        _nativeDb = await openDatabase(
          path,
          version: 1,
          onCreate: _createDB,
        );
      } else {
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'medikiosk_ai.db');
        _nativeDb = await openDatabase(
          path,
          version: 1,
          onCreate: _createDB,
        );
      }
      await SeedData.seedInitialData(_nativeDb!);
      _initialized = true;
    }
  }

  Future<Database?> get database async {
    if (!_initialized) {
      await initialize();
    }
    return _nativeDb;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        abha_id TEXT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        profile_picture_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS patient_profiles (
        user_id TEXT PRIMARY KEY,
        blood_type TEXT DEFAULT 'B+',
        allergies TEXT DEFAULT 'None',
        date_of_birth TEXT DEFAULT '1985-06-15',
        gender TEXT DEFAULT 'Male',
        demographics_json TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clinical_sessions (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        doctor_id TEXT,
        mode TEXT NOT NULL,
        priority TEXT NOT NULL,
        token_number TEXT NOT NULL,
        pain_score INTEGER DEFAULT 5,
        status TEXT NOT NULL,
        chief_complaint TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clinical_intake (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        socrates_json TEXT,
        dashavidha_json TEXT,
        confidence_scores_json TEXT,
        FOREIGN KEY (session_id) REFERENCES clinical_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS patient_documents (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        doc_type TEXT NOT NULL,
        extracted_text TEXT,
        entities_json TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS prescriptions (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        patient_id TEXT NOT NULL,
        medications_json TEXT NOT NULL,
        instructions TEXT,
        diagnosis TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES clinical_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_summaries (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        certain_json TEXT,
        not_sure_json TEXT,
        unclear_json TEXT,
        triage_summary TEXT,
        chief_complaint TEXT,
        recommended_action TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES clinical_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_role TEXT NOT NULL,
        details TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // Universal CRUD Operations (handles both Native SQLite & Web in-memory)
  Future<int> insert(String table, Map<String, dynamic> values) async {
    if (!_initialized) await initialize();

    if (kIsWeb || _nativeDb == null) {
      final list = _memoryTables[table] ??= [];
      final idKey = table == 'patient_profiles' ? 'user_id' : table == 'audit_logs' ? 'id' : 'id';
      
      final mutable = Map<String, dynamic>.from(values);
      if (table == 'audit_logs' && mutable['id'] == null) {
        mutable['id'] = list.length + 1;
      }

      final existingIndex = list.indexWhere((item) => item[idKey] != null && item[idKey] == mutable[idKey]);
      if (existingIndex >= 0) {
        list[existingIndex] = mutable;
      } else {
        list.add(mutable);
      }
      return 1;
    } else {
      return await _nativeDb!.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    if (!_initialized) await initialize();

    if (kIsWeb || _nativeDb == null) {
      var list = List<Map<String, dynamic>>.from(_memoryTables[table] ?? []);

      if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
        if (where.contains('role = ?')) {
          final role = whereArgs.first as String;
          list = list.where((item) => item['role'] == role).toList();
        } else if (where.contains('id = ?')) {
          final id = whereArgs.first;
          list = list.where((item) => item['id'] == id).toList();
        } else if (where.contains('user_id = ?')) {
          final userId = whereArgs.first;
          list = list.where((item) => item['user_id'] == userId).toList();
        } else if (where.contains('patient_id = ?')) {
          final patientId = whereArgs.first;
          list = list.where((item) => item['patient_id'] == patientId).toList();
        } else if (where.contains('session_id = ?')) {
          final sessId = whereArgs.first;
          list = list.where((item) => item['session_id'] == sessId).toList();
        } else if (where.contains('password_hash = ?')) {
          final rawIdent = (whereArgs.first?.toString() ?? '').trim().toLowerCase();
          final rawPass = (whereArgs.length > 3 ? whereArgs[3]?.toString() : whereArgs.last?.toString())?.trim() ?? '';
          list = list.where((item) {
            final phone = (item['phone']?.toString() ?? '').trim().toLowerCase();
            final abha = (item['abha_id']?.toString() ?? '').trim().toLowerCase();
            final email = (item['email']?.toString() ?? '').trim().toLowerCase();
            final id = (item['id']?.toString() ?? '').trim().toLowerCase();
            final storedHash = (item['password_hash']?.toString() ?? '').trim();

            final matchesIdent = phone == rawIdent ||
                abha == rawIdent ||
                email == rawIdent ||
                id == rawIdent ||
                (rawIdent.isNotEmpty && abha.startsWith(rawIdent)) ||
                (rawIdent.isNotEmpty && email.startsWith(rawIdent));

            final matchesPass = storedHash == rawPass ||
                storedHash == SeedData.hashPassword(rawPass);

            return matchesIdent && matchesPass;
          }).toList();
        }
      }

      if (orderBy != null) {
        if (orderBy.contains('created_at DESC')) {
          list.sort((a, b) => (b['created_at']?.toString() ?? '').compareTo(a['created_at']?.toString() ?? ''));
        } else if (orderBy.contains('timestamp DESC')) {
          list.sort((a, b) => (b['timestamp']?.toString() ?? '').compareTo(a['timestamp']?.toString() ?? ''));
        }
      }

      if (limit != null && list.length > limit) {
        list = list.sublist(0, limit);
      }

      return list;
    } else {
      return await _nativeDb!.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
    }
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (!_initialized) await initialize();

    if (kIsWeb || _nativeDb == null) {
      final list = _memoryTables[table] ?? [];
      final id = whereArgs?.first;
      if (id != null) {
        final idKey = table == 'patient_profiles' ? 'user_id' : 'id';
        final idx = list.indexWhere((item) => item[idKey] == id);
        if (idx >= 0) {
          final updated = Map<String, dynamic>.from(list[idx])..addAll(values);
          list[idx] = updated;
          return 1;
        }
      }
      return 0;
    } else {
      return await _nativeDb!.update(table, values, where: where, whereArgs: whereArgs);
    }
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (!_initialized) await initialize();

    if (kIsWeb || _nativeDb == null) {
      final list = _memoryTables[table] ?? [];
      final id = whereArgs?.first;
      if (id != null) {
        final idKey = table == 'patient_profiles' ? 'user_id' : 'id';
        list.removeWhere((item) => item[idKey] == id);
        return 1;
      }
      return 0;
    } else {
      return await _nativeDb!.delete(table, where: where, whereArgs: whereArgs);
    }
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    if (!_initialized) await initialize();

    if (kIsWeb || _nativeDb == null) {
      final sqlLower = sql.toLowerCase();

      // Count queries
      if (sqlLower.contains('select count(*)')) {
        if (sqlLower.contains('from users')) {
          return [{'COUNT(*)': _memoryTables['users']?.length ?? 0}];
        } else if (sqlLower.contains('from clinical_sessions')) {
          if (arguments != null && arguments.isNotEmpty) {
            final priority = arguments.first as String;
            final count = (_memoryTables['clinical_sessions'] ?? []).where((s) => s['priority'] == priority).length;
            return [{'COUNT(*)': count}];
          } else {
            return [{'COUNT(*)': _memoryTables['clinical_sessions']?.length ?? 0}];
          }
        }
      }

      // Doctor queue / Session queries with patient joins
      if (sqlLower.contains('from clinical_sessions')) {
        var sessions = List<Map<String, dynamic>>.from(_memoryTables['clinical_sessions'] ?? []);
        final users = _memoryTables['users'] ?? [];

        // Join patient name
        sessions = sessions.map((sess) {
          final pat = users.firstWhere((u) => u['id'] == sess['patient_id'], orElse: () => {});
          final map = Map<String, dynamic>.from(sess);
          map['patient_name'] = pat['name'] ?? 'Patient';
          return map;
        }).toList();

        if (sqlLower.contains('where s.status = ?') && arguments != null && arguments.isNotEmpty) {
          final status = arguments.first as String;
          sessions = sessions.where((s) => s['status'] == status).toList();

          // Sort by Priority (P1, P2, P3)
          sessions.sort((a, b) {
            final pOrder = {'P1': 1, 'P2': 2, 'P3': 3};
            final pa = pOrder[a['priority']] ?? 4;
            final pb = pOrder[b['priority']] ?? 4;
            if (pa != pb) return pa.compareTo(pb);
            return (a['created_at']?.toString() ?? '').compareTo(b['created_at']?.toString() ?? '');
          });
          return sessions;
        } else if (sqlLower.contains('where s.id = ?') && arguments != null && arguments.isNotEmpty) {
          final id = arguments.first as String;
          return sessions.where((s) => s['id'] == id).toList();
        } else if (sqlLower.contains('where s.patient_id = ?') && arguments != null && arguments.isNotEmpty) {
          final patId = arguments.first as String;
          sessions = sessions.where((s) => s['patient_id'] == patId).toList();
          sessions.sort((a, b) => (b['created_at']?.toString() ?? '').compareTo(a['created_at']?.toString() ?? ''));
          return sessions;
        }
        return sessions;
      }

      // Prescriptions with joins
      if (sqlLower.contains('from prescriptions')) {
        var prescriptions = List<Map<String, dynamic>>.from(_memoryTables['prescriptions'] ?? []);
        final users = _memoryTables['users'] ?? [];

        prescriptions = prescriptions.map((p) {
          final doc = users.firstWhere((u) => u['id'] == p['doctor_id'], orElse: () => {});
          final pat = users.firstWhere((u) => u['id'] == p['patient_id'], orElse: () => {});
          final map = Map<String, dynamic>.from(p);
          map['doctor_name'] = doc['name'] ?? 'Doctor';
          map['patient_name'] = pat['name'] ?? 'Patient';
          return map;
        }).toList();

        if (sqlLower.contains('where p.session_id = ?') && arguments != null && arguments.isNotEmpty) {
          final sessId = arguments.first as String;
          return prescriptions.where((p) => p['session_id'] == sessId).toList();
        } else if (sqlLower.contains('where p.patient_id = ?') && arguments != null && arguments.isNotEmpty) {
          final patId = arguments.first as String;
          return prescriptions.where((p) => p['patient_id'] == patId).toList();
        }
        return prescriptions;
      }

      return [];
    } else {
      return await _nativeDb!.rawQuery(sql, arguments);
    }
  }

  Future<void> close() async {
    final db = _nativeDb;
    if (db != null) {
      await db.close();
      _nativeDb = null;
    }
  }
}
