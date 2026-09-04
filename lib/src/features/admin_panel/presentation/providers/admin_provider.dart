import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di.dart';
import '../../../../database/daos/audit_log_dao.dart';
import '../../../../database/daos/clinical_session_dao.dart';
import '../../../../database/daos/user_dao.dart';
import '../../../../shared/models/audit_log_model.dart';
import '../../../../shared/models/user_model.dart';

class AdminState {
  final List<UserModel> allUsers;
  final List<AuditLogModel> auditLogs;
  final int totalSessions;
  final int p1Count;
  final int p2Count;
  final int p3Count;
  final bool isLoading;
  final String? message;

  AdminState({
    this.allUsers = const [],
    this.auditLogs = const [],
    this.totalSessions = 0,
    this.p1Count = 0,
    this.p2Count = 0,
    this.p3Count = 0,
    this.isLoading = false,
    this.message,
  });

  AdminState copyWith({
    List<UserModel>? allUsers,
    List<AuditLogModel>? auditLogs,
    int? totalSessions,
    int? p1Count,
    int? p2Count,
    int? p3Count,
    bool? isLoading,
    String? message,
  }) {
    return AdminState(
      allUsers: allUsers ?? this.allUsers,
      auditLogs: auditLogs ?? this.auditLogs,
      totalSessions: totalSessions ?? this.totalSessions,
      p1Count: p1Count ?? this.p1Count,
      p2Count: p2Count ?? this.p2Count,
      p3Count: p3Count ?? this.p3Count,
      isLoading: isLoading ?? this.isLoading,
      message: message,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final UserDao _userDao = getIt<UserDao>();
  final ClinicalSessionDao _sessionDao = getIt<ClinicalSessionDao>();
  final AuditLogDao _auditDao = getIt<AuditLogDao>();

  AdminNotifier() : super(AdminState()) {
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    state = state.copyWith(isLoading: true);

    final users = await _userDao.getAllUsers();
    final logs = await _auditDao.getRecentLogs(limit: 40);
    final total = await _sessionDao.totalSessionsCount();
    final p1 = await _sessionDao.countSessionsByPriority('P1');
    final p2 = await _sessionDao.countSessionsByPriority('P2');
    final p3 = await _sessionDao.countSessionsByPriority('P3');

    state = state.copyWith(
      allUsers: users,
      auditLogs: logs,
      totalSessions: total,
      p1Count: p1,
      p2Count: p2,
      p3Count: p3,
      isLoading: false,
    );
  }

  Future<bool> createUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final passHash = sha256.convert(utf8.encode(password)).toString();
      final id = 'usr_${role}_${DateTime.now().millisecondsSinceEpoch}';
      final abha = '${role}_${phone.length >= 4 ? phone.substring(phone.length - 4) : "001"}@abdm';

      final newUser = UserModel(
        id: id,
        abhaId: abha,
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        passwordHash: passHash,
        role: role,
      );

      await _userDao.insertUser(newUser);

      await _auditDao.insertLog(AuditLogModel(
        action: 'ADMIN_USER_CREATED',
        userId: 'usr_admin_1',
        userRole: 'admin',
        details: 'Admin created new user account: $name ($role).',
      ));

      await loadAdminData();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword(String userId, String newPassword) async {
    try {
      final passHash = sha256.convert(utf8.encode(newPassword)).toString();
      await _userDao.updatePassword(userId, passHash);

      await _auditDao.insertLog(AuditLogModel(
        action: 'ADMIN_PASSWORD_RESET',
        userId: 'usr_admin_1',
        userRole: 'admin',
        details: 'Admin reset password for user ID: $userId.',
      ));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _userDao.deleteUser(userId);
      await loadAdminData();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});
