class UserModel {
  final String id;
  final String abhaId;
  final String name;
  final String phone;
  final String email;
  final String passwordHash;
  final String role; // 'patient', 'doctor', 'admin'
  final String? profilePicturePath;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.abhaId,
    required this.name,
    required this.phone,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.profilePicturePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'abha_id': abhaId,
      'name': name,
      'phone': phone,
      'email': email,
      'password_hash': passwordHash,
      'role': role,
      'profile_picture_path': profilePicturePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      abhaId: map['abha_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      role: map['role'] as String? ?? 'patient',
      profilePicturePath: map['profile_picture_path'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? abhaId,
    String? name,
    String? phone,
    String? email,
    String? passwordHash,
    String? role,
    String? profilePicturePath,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      abhaId: abhaId ?? this.abhaId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
