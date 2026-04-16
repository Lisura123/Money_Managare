class AdminCardAdjustment {
  final int id;
  final int cardEntryId;
  final int adminId;
  final String? adminName;
  final double adjustedAmount;
  final String? reason;
  final String? createdAt;

  AdminCardAdjustment({
    required this.id,
    required this.cardEntryId,
    required this.adminId,
    this.adminName,
    required this.adjustedAmount,
    this.reason,
    this.createdAt,
  });

  factory AdminCardAdjustment.fromJson(Map<String, dynamic> json) {
    return AdminCardAdjustment(
      id: json['id'] as int,
      cardEntryId:
          (json['card_entry_id'] ?? json['daily_card_entry_id'] ?? 0) as int,
      adminId: json['admin_id'] as int,
      adminName: json['admin']?['name'] as String?,
      adjustedAmount:
          double.tryParse(json['adjusted_amount'].toString()) ?? 0.0,
      reason: json['reason'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
