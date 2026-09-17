import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di.dart';
import '../../../../database/daos/audit_log_dao.dart';
import '../../../../database/daos/patient_profile_dao.dart';
import '../../../../database/daos/user_dao.dart';
import '../../../../shared/models/audit_log_model.dart';
import '../../../../shared/models/patient_profile_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../../../voice/services/tts_service.dart';

class AuthState {
  final UserModel? currentUser;
  final String currentLanguage;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.currentUser,
    this.currentLanguage = 'en',
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    UserModel? currentUser,
    String? currentLanguage,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      currentLanguage: currentLanguage ?? this.currentLanguage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final UserDao _userDao = getIt<UserDao>();
  final PatientProfileDao _profileDao = getIt<PatientProfileDao>();
  final AuditLogDao _auditDao = getIt<AuditLogDao>();
  final SecureStorageService _storage = getIt<SecureStorageService>();

  AuthNotifier() : super(AuthState()) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final lang = await _storage.getLanguage();
    if (state.currentLanguage == 'en') {
      state = state.copyWith(currentLanguage: lang);
      getIt<TTSService>().setLanguage(lang);
    }
  }

  Future<void> setLanguage(String langCode) async {
    state = state.copyWith(currentLanguage: langCode);
    await _storage.saveLanguage(langCode);
    await getIt<TTSService>().setLanguage(langCode);
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<bool> quickDemoLogin(String role) async {
    String id = 'patient_1024@abdm';
    String pass = 'patient123';
    if (role == 'doctor') {
      id = 'dr_sharma@abdm';
      pass = 'doctor123';
    } else if (role == 'admin') {
      id = 'admin_kiosk@abdm';
      pass = 'admin123';
    }
    return await login(identifier: id, password: pass, expectedRole: role);
  }

  Future<bool> login({
    required String identifier, // ABHA ID or phone or email
    required String password,
    required String expectedRole,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final cleanId = identifier.trim();
      final cleanPass = password.trim();
      final hash = _hashPassword(cleanPass);
      var user = await _userDao.findByCredentials(cleanId, hash);

      // Fallback: If not found immediately, scan users for case-insensitive identifier and matching password
      if (user == null) {
        final allUsers = await _userDao.getAllUsers();
        for (var u in allUsers) {
          final phone = u.phone.trim().toLowerCase();
          final abha = u.abhaId.trim().toLowerCase();
          final email = u.email.trim().toLowerCase();
          final id = u.id.trim().toLowerCase();
          final queryId = cleanId.toLowerCase();

          final matchesIdent = phone == queryId ||
              abha == queryId ||
              email == queryId ||
              id == queryId ||
              (queryId.isNotEmpty && (abha.startsWith(queryId) || email.startsWith(queryId)));

          final matchesPass = u.passwordHash == hash ||
              u.passwordHash == cleanPass ||
              u.passwordHash == _hashPassword(cleanPass);

          if (matchesIdent && matchesPass) {
            user = u;
            break;
          }
        }
      }

      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid credentials. Check your ID & password, or use 1-Tap Quick Demo Login.',
        );
        return false;
      }

      if (user.role.toLowerCase() != expectedRole.toLowerCase()) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'This account belongs to ${user.name} (${user.role.toUpperCase()}). Please switch to the ${user.role.toUpperCase()} tab above.',
        );
        return false;
      }

      // Generate local JWT simulation token
      final token = 'jwt_medikiosk_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
      await _storage.saveAuthToken(token);
      await _storage.saveSessionUser(user.id, user.role);

      await _auditDao.insertLog(AuditLogModel(
        action: 'USER_LOGIN',
        userId: user.id,
        userRole: user.role,
        details: 'User ${user.name} logged in successfully as ${user.role}.',
      ));

      state = state.copyWith(currentUser: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Login failed: $e');
      return false;
    }
  }

  Future<UserModel?> registerPatient({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String aadhaarOrId,
    String? bloodType,
    String? allergies,
    String? dob,
    String? gender,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Generate simulated ABHA ID: patient_XXXX@abdm
      final randomSuffix = (1000 + Random().nextInt(9000)).toString();
      final simulatedAbha = 'patient_$randomSuffix@abdm';
      final userId = 'usr_pat_${DateTime.now().millisecondsSinceEpoch}';
      final passHash = _hashPassword(password);

      final newUser = UserModel(
        id: userId,
        abhaId: simulatedAbha,
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim().isEmpty ? 'pat_$randomSuffix@medikiosk.ai' : email.trim(),
        passwordHash: passHash,
        role: 'patient',
      );

      await _userDao.insertUser(newUser);

      // Create Patient Profile
      final profile = PatientProfileModel(
        userId: userId,
        bloodType: bloodType ?? 'B+',
        allergies: allergies ?? 'None',
        dateOfBirth: dob ?? '1990-01-01',
        gender: gender ?? 'Male',
        demographics: {
          'aadhaar_last4': aadhaarOrId.length >= 4 ? aadhaarOrId.substring(aadhaarOrId.length - 4) : aadhaarOrId,
          'simulated_abha_number': '91-${randomSuffix.substring(0, 2)}-${randomSuffix.substring(2, 4)}-${randomSuffix.substring(0, 2)}89',
        },
      );
      await _profileDao.insertOrUpdateProfile(profile);

      await _auditDao.insertLog(AuditLogModel(
        action: 'PATIENT_REGISTRATION',
        userId: userId,
        userRole: 'patient',
        details: 'New patient registered: $name with ABHA $simulatedAbha',
      ));

      state = state.copyWith(isLoading: false);
      return newUser;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Registration failed: $e');
      return null;
    }
  }

  Future<void> logout() async {
    if (state.currentUser != null) {
      await _auditDao.insertLog(AuditLogModel(
        action: 'USER_LOGOUT',
        userId: state.currentUser!.id,
        userRole: state.currentUser!.role,
        details: 'User ${state.currentUser!.name} logged out.',
      ));
    }
    await _storage.clearAll();
    state = state.copyWith(clearUser: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
