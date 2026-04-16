class AdminCashAdjustment {
  final int id;
  final int cashEntryId;
  final int adminId;
  final String? adminName;
  final double adjustedAmount;
  final String? reason;
  final String? createdAt;

  AdminCashAdjustment({
    required this.id,
    required this.cashEntryId,
    required this.adminId,
    this.adminName,
    required this.adjustedAmount,
    this.reason,
    this.createdAt,
  });

  factory AdminCashAdjustment.fromJson(Map<String, dynamic> json) {
    return AdminCashAdjustment(
      id: json['id'] as int,
      cashEntryId:
          (json['cash_entry_id'] ?? json['daily_cash_entry_id'] ?? 0) as int,
      adminId: json['admin_id'] as int,
      adminName: json['admin']?['name'] as String?,
      adjustedAmount:
          double.tryParse(json['adjusted_amount'].toString()) ?? 0.0,
      reason: json['reason'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
