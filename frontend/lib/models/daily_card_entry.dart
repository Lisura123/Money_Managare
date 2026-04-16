class DailyCardEntry {
  final int id;
  final int showroomId;
  final String? showroomName;
  final int userId;
  final String? userName;
  final int cardAccountId;
  final String? bankName;
  final String? lastFour;
  final String entryDate;
  final double amount;
  final String? notes;
  final bool isLocked;
  final String? createdAt;
  final String? updatedAt;

  DailyCardEntry({
    required this.id,
    required this.showroomId,
    this.showroomName,
    required this.userId,
    this.userName,
    required this.cardAccountId,
    this.bankName,
    this.lastFour,
    required this.entryDate,
    required this.amount,
    this.notes,
    required this.isLocked,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyCardEntry.fromJson(Map<String, dynamic> json) {
    return DailyCardEntry(
      id: json['id'] as int,
      showroomId: json['showroom_id'] as int,
      showroomName: json['showroom']?['name'] as String?,
      userId: json['user_id'] as int,
      userName: json['user']?['name'] as String?,
      cardAccountId: json['card_account_id'] as int,
      bankName: json['card_account']?['bank_name'] as String?,
      lastFour: json['card_account']?['last_four'] as String?,
      entryDate: json['entry_date'] as String,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      notes: json['notes'] as String?,
      isLocked: json['is_locked'] == true || json['is_locked'] == 1,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
