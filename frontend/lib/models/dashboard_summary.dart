class ShowroomSnapshot {
  final int showroomId;
  final String showroomName;
  final double cashMainTotal;
  final double cashManoTotal;
  final double cardTotal;
  final double combinedTotal;
  final double cashMainAdjusted;
  final double cashManoAdjusted;
  final double cardAdjusted;
  final int entryCount;

  ShowroomSnapshot({
    required this.showroomId,
    required this.showroomName,
    required this.cashMainTotal,
    required this.cashManoTotal,
    required this.cardTotal,
    required this.combinedTotal,
    required this.cashMainAdjusted,
    required this.cashManoAdjusted,
    required this.cardAdjusted,
    required this.entryCount,
  });

  factory ShowroomSnapshot.fromJson(Map<String, dynamic> json) {
    return ShowroomSnapshot(
      showroomId: json['showroom_id'] as int,
      showroomName: json['showroom_name'] as String,
      cashMainTotal: double.tryParse(json['cash_main_total'].toString()) ?? 0.0,
      cashManoTotal: double.tryParse(json['cash_mano_total'].toString()) ?? 0.0,
      cardTotal: double.tryParse(json['card_total'].toString()) ?? 0.0,
      combinedTotal: double.tryParse(json['combined_total'].toString()) ?? 0.0,
      cashMainAdjusted:
          double.tryParse(json['cash_main_adjusted'].toString()) ?? 0.0,
      cashManoAdjusted:
          double.tryParse(json['cash_mano_adjusted'].toString()) ?? 0.0,
      cardAdjusted: double.tryParse(json['card_adjusted'].toString()) ?? 0.0,
      entryCount: (json['entry_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailySnapshot {
  final double cashMainTotal;
  final double cashManoTotal;
  final double cardTotal;
  final double grandTotal;
  final double cashMainAdjusted;
  final double cashManoAdjusted;
  final double cardAdjusted;
  final double grandAdjusted;
  final List<ShowroomSnapshot> perShowroom;

  DailySnapshot({
    required this.cashMainTotal,
    required this.cashManoTotal,
    required this.cardTotal,
    required this.grandTotal,
    required this.cashMainAdjusted,
    required this.cashManoAdjusted,
    required this.cardAdjusted,
    required this.grandAdjusted,
    required this.perShowroom,
  });

  factory DailySnapshot.fromJson(Map<String, dynamic> json) {
    return DailySnapshot(
      cashMainTotal: double.tryParse(json['cash_main_total'].toString()) ?? 0.0,
      cashManoTotal: double.tryParse(json['cash_mano_total'].toString()) ?? 0.0,
      cardTotal: double.tryParse(json['card_total'].toString()) ?? 0.0,
      grandTotal: double.tryParse(json['grand_total'].toString()) ?? 0.0,
      cashMainAdjusted:
          double.tryParse(json['cash_main_adjusted'].toString()) ?? 0.0,
      cashManoAdjusted:
          double.tryParse(json['cash_mano_adjusted'].toString()) ?? 0.0,
      cardAdjusted: double.tryParse(json['card_adjusted'].toString()) ?? 0.0,
      grandAdjusted: double.tryParse(json['grand_adjusted'].toString()) ?? 0.0,
      perShowroom: (json['per_showroom'] as List? ?? [])
          .map((e) => ShowroomSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static DailySnapshot empty() => DailySnapshot(
        cashMainTotal: 0,
        cashManoTotal: 0,
        cardTotal: 0,
        grandTotal: 0,
        cashMainAdjusted: 0,
        cashManoAdjusted: 0,
        cardAdjusted: 0,
        grandAdjusted: 0,
        perShowroom: [],
      );
}

class DashboardSummary {
  final String serverDate;
  final String lastUpdatedAt;
  final DailySnapshot today;
  final DailySnapshot yesterday;

  DashboardSummary({
    required this.serverDate,
    required this.lastUpdatedAt,
    required this.today,
    required this.yesterday,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      serverDate: json['server_date'] as String,
      lastUpdatedAt: json['last_updated_at'] as String,
      today: DailySnapshot.fromJson(json['today'] as Map<String, dynamic>),
      yesterday:
          DailySnapshot.fromJson(json['yesterday'] as Map<String, dynamic>),
    );
  }
}
