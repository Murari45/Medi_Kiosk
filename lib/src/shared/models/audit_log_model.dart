class AuditLogModel {
  final int? id;
  final String action;
  final String userId;
  final String userRole;
  final String details;
  final DateTime timestamp;

  AuditLogModel({
    this.id,
    required this.action,
    required this.userId,
    this.userRole = 'system',
    required this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'action': action,
      'user_id': userId,
      'user_role': userRole,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as int?,
      action: map['action'] as String? ?? 'SYSTEM_EVENT',
      userId: map['user_id'] as String? ?? 'system',
      userRole: map['user_role'] as String? ?? 'system',
      details: map['details'] as String? ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
