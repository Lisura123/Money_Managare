class CashTransaction {
  final int id;
  final int adminId;
  final String? adminName;
  final String fromAccountType;
  final String fromLabel;
  final String? toAccountType;
  final String toLabel;
  final int? toExternalAccountId;
  final String? toExternalAccountName;
  final double amount;
  final String? notes;
  final String transactionDate;
  final String? createdAt;

  CashTransaction({
    required this.id,
    required this.adminId,
    this.adminName,
    required this.fromAccountType,
    required this.fromLabel,
    this.toAccountType,
    required this.toLabel,
    this.toExternalAccountId,
    this.toExternalAccountName,
    required this.amount,
    this.notes,
    required this.transactionDate,
    this.createdAt,
  });

  factory CashTransaction.fromJson(Map<String, dynamic> json) {
    final ext = json['to_external_account'] as Map<String, dynamic>?;
    return CashTransaction(
      id: json['id'] as int,
      adminId: json['admin_id'] as int,
      adminName: json['admin_name'] as String?,
      fromAccountType: json['from_account_type'] as String,
      fromLabel: json['from_label'] as String? ?? 'Main Cash',
      toAccountType: json['to_account_type'] as String?,
      toLabel: json['to_label'] as String? ?? 'Others (External)',
      toExternalAccountId: json['to_external_account_id'] as int?,
      toExternalAccountName: ext?['name'] as String?,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      notes: json['notes'] as String?,
      transactionDate: json['transaction_date'] as String,
      createdAt: json['created_at'] as String?,
    );
  }
}
