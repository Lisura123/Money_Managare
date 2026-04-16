class SelfTransaction {
  final int id;
  final int fromCardAccountId;
  final String? fromBankName;
  final String? fromLastFour;
  final String? fromShowroomName;
  final int toCardAccountId;
  final String? toBankName;
  final String? toLastFour;
  final String? toShowroomName;
  final double amount;
  final String? notes;
  final int adminId;
  final String? adminName;
  final String? createdAt;

  SelfTransaction({
    required this.id,
    required this.fromCardAccountId,
    this.fromBankName,
    this.fromLastFour,
    this.fromShowroomName,
    required this.toCardAccountId,
    this.toBankName,
    this.toLastFour,
    this.toShowroomName,
    required this.amount,
    this.notes,
    required this.adminId,
    this.adminName,
    this.createdAt,
  });

  factory SelfTransaction.fromJson(Map<String, dynamic> json) {
    final from = json['from_card_account'] as Map<String, dynamic>?;
    final to = json['to_card_account'] as Map<String, dynamic>?;
    return SelfTransaction(
      id: json['id'] as int,
      fromCardAccountId: json['from_card_account_id'] as int,
      fromBankName: from?['bank_name'] as String?,
      fromLastFour: from?['last_four'] as String?,
      fromShowroomName: from?['showroom']?['name'] as String?,
      toCardAccountId: json['to_card_account_id'] as int,
      toBankName: to?['bank_name'] as String?,
      toLastFour: to?['last_four'] as String?,
      toShowroomName: to?['showroom']?['name'] as String?,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      notes: json['notes'] as String?,
      adminId: json['admin_id'] as int,
      adminName: json['admin']?['name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
