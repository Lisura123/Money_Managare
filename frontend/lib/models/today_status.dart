class CardEntryStatus {
  final int id;
  final double amount;
  final String? bankName;
  final String? lastFour;

  CardEntryStatus({
    required this.id,
    required this.amount,
    this.bankName,
    this.lastFour,
  });

  factory CardEntryStatus.fromJson(Map<String, dynamic> json) {
    return CardEntryStatus(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      bankName: json['bank_name'] as String?,
      lastFour: json['last_four'] as String?,
    );
  }
}

class CashEntryStatus {
  final bool submitted;
  final double? amount;
  final int? entryId;

  CashEntryStatus({
    required this.submitted,
    this.amount,
    this.entryId,
  });

  factory CashEntryStatus.fromJson(Map<String, dynamic> json) {
    return CashEntryStatus(
      submitted: json['submitted'] as bool,
      amount:
          json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      entryId: json['entry_id'] as int?,
    );
  }
}

class CardStatusToday {
  final int count;
  final double total;
  final List<CardEntryStatus> entries;

  CardStatusToday({
    required this.count,
    required this.total,
    required this.entries,
  });

  factory CardStatusToday.fromJson(Map<String, dynamic> json) {
    return CardStatusToday(
      count: json['count'] as int,
      total: (json['total'] as num).toDouble(),
      entries: (json['entries'] as List? ?? [])
          .map((e) => CardEntryStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TodayStatus {
  final String date;
  final CashEntryStatus mainCash;
  final CashEntryStatus manoCash;
  final CardStatusToday card;

  TodayStatus({
    required this.date,
    required this.mainCash,
    required this.manoCash,
    required this.card,
  });

  factory TodayStatus.fromJson(Map<String, dynamic> json) {
    return TodayStatus(
      date: json['date'] as String,
      mainCash:
          CashEntryStatus.fromJson(json['main_cash'] as Map<String, dynamic>),
      manoCash:
          CashEntryStatus.fromJson(json['mano_cash'] as Map<String, dynamic>),
      card: CardStatusToday.fromJson(json['card'] as Map<String, dynamic>),
    );
  }
}
