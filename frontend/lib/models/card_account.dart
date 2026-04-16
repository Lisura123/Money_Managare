class CardAccount {
  final int id;
  final int showroomId;
  final String? showroomName;
  final String bankName;
  final String lastFour;
  final double currentBalance;
  final bool isActive;
  final String? createdAt;

  CardAccount({
    required this.id,
    required this.showroomId,
    this.showroomName,
    required this.bankName,
    required this.lastFour,
    required this.currentBalance,
    required this.isActive,
    this.createdAt,
  });

  factory CardAccount.fromJson(Map<String, dynamic> json) {
    return CardAccount(
      id: json['id'] as int,
      showroomId: json['showroom_id'] as int,
      showroomName: json['showroom']?['name'] as String?,
      bankName: json['bank_name'] as String,
      lastFour: json['last_four'] as String,
      currentBalance:
          double.tryParse(json['current_balance'].toString()) ?? 0.0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'showroom_id': showroomId,
        'bank_name': bankName,
        'last_four': lastFour,
        'current_balance': currentBalance,
        'is_active': isActive,
      };

  String get maskedNumber => '•••• $lastFour';

  String get displayLabel => '$bankName •••• $lastFour';

  String dropdownLabel(String? sName) =>
      '${sName ?? showroomName ?? ''} — $bankName •••• $lastFour';
}
