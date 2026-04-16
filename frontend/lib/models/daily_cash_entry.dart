class DailyCashEntry {
  final int id;
  final int showroomId;
  final String? showroomName;
  final int userId;
  final String? userName;
  final String entryDate;
  final double cashAmount;
  final String? notes;
  final bool isLocked;
  final String cashAccountType;
  final String cashAccountLabel;
  final String? createdAt;
  final String? updatedAt;

  DailyCashEntry({
    required this.id,
    required this.showroomId,
    this.showroomName,
    required this.userId,
    this.userName,
    required this.entryDate,
    required this.cashAmount,
    this.notes,
    required this.isLocked,
    this.cashAccountType = 'main',
    this.cashAccountLabel = 'Main Account',
    this.createdAt,
    this.updatedAt,
  });

  factory DailyCashEntry.fromJson(Map<String, dynamic> json) {
    final accountType = (json['cash_account_type'] as String?) ?? 'main';
    return DailyCashEntry(
      id: json['id'] as int,
      showroomId: json['showroom_id'] as int,
      showroomName: json['showroom']?['name'] as String?,
      userId: json['user_id'] as int,
      userName: json['user']?['name'] as String?,
      entryDate: json['entry_date'] as String,
      cashAmount: double.tryParse(json['cash_amount'].toString()) ?? 0.0,
      notes: json['notes'] as String?,
      isLocked: json['is_locked'] == true || json['is_locked'] == 1,
      cashAccountType: accountType,
      cashAccountLabel: (json['cash_account_label'] as String?) ??
          (accountType == 'mano' ? "Mano's Account" : 'Main Account'),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
