class AuditLog {
  final int id;
  final String tableName;
  final int recordId;
  final String action;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final int? userId;
  final String? userName;
  final String? createdAt;

  AuditLog({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.action,
    this.oldValues,
    this.newValues,
    this.userId,
    this.userName,
    this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parseValues(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      if (v is String) {
        try {
          return Map<String, dynamic>.from(Uri.parse(v) as Map? ?? {});
        } catch (_) {}
      }
      return null;
    }

    return AuditLog(
      id: json['id'] as int,
      tableName: json['table_name'] as String,
      recordId: json['record_id'] as int,
      action: json['action'] as String,
      oldValues: parseValues(json['old_values']),
      newValues: parseValues(json['new_values']),
      userId: json['user_id'] as int?,
      userName: json['user']?['name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
