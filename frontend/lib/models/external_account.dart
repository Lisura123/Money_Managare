class ExternalAccount {
  final int id;
  final String name;
  final double balance;
  final String? cashAccountType;

  ExternalAccount({
    required this.id,
    required this.name,
    required this.balance,
    this.cashAccountType,
  });

  factory ExternalAccount.fromJson(Map<String, dynamic> json) {
    return ExternalAccount(
      id: json['id'] as int,
      name: json['name'] as String,
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      cashAccountType: json['cash_account_type'] as String?,
    );
  }
}
