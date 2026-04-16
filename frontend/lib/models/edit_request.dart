class EditRequest {
  final int id;
  final String entryType; // 'cash' or 'card'
  final int entryId;
  final Map<String, dynamic> originalValues;
  final Map<String, dynamic> requestedChanges;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminRemarks;
  final String? staffName;
  final String? staffEmail;
  final String? showroomName;
  final String? reviewerName;
  final String? reviewedAt;
  final String createdAt;

  // Nested entry snapshot (optional — only when loaded with relations)
  final Map<String, dynamic>? entry;

  const EditRequest({
    required this.id,
    required this.entryType,
    required this.entryId,
    required this.originalValues,
    required this.requestedChanges,
    required this.reason,
    required this.status,
    this.adminRemarks,
    this.staffName,
    this.staffEmail,
    this.showroomName,
    this.reviewerName,
    this.reviewedAt,
    required this.createdAt,
    this.entry,
  });

  factory EditRequest.fromJson(Map<String, dynamic> json) {
    return EditRequest(
      id: json['id'] as int,
      entryType: json['entry_type'] as String,
      entryId: json['entry_id'] as int,
      originalValues:
          Map<String, dynamic>.from(json['original_values'] as Map? ?? {}),
      requestedChanges:
          Map<String, dynamic>.from(json['requested_changes'] as Map? ?? {}),
      reason: json['reason'] as String,
      status: json['status'] as String,
      adminRemarks: json['admin_remarks'] as String?,
      staffName: json['staff_name'] as String?,
      staffEmail: json['staff_email'] as String?,
      showroomName: json['showroom_name'] as String?,
      reviewerName: json['reviewer_name'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
      createdAt: json['created_at'] as String,
      entry: json['entry'] != null
          ? Map<String, dynamic>.from(json['entry'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entry_type': entryType,
        'entry_id': entryId,
        'original_values': originalValues,
        'requested_changes': requestedChanges,
        'reason': reason,
        'status': status,
        'admin_remarks': adminRemarks,
        'staff_name': staffName,
        'staff_email': staffEmail,
        'showroom_name': showroomName,
        'reviewer_name': reviewerName,
        'reviewed_at': reviewedAt,
        'created_at': createdAt,
        'entry': entry,
      };
}
