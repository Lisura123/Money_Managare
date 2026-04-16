import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  static final _dateDisplay = DateFormat('MMM dd, yyyy');
  static final _dateApi = DateFormat('yyyy-MM-dd');
  static final _dateTimeDisplay = DateFormat('MMM dd, yyyy • hh:mm a');

  static String currency(dynamic amount) {
    if (amount == null) return 'Rs. 0.00';
    final num value =
        amount is String ? double.tryParse(amount) ?? 0.0 : amount.toDouble();
    return 'Rs. ${_currencyFormat.format(value)}';
  }

  /// Converts "HH:mm" (24h) to "h:mm AM/PM"
  static String time12h(String? time24) {
    if (time24 == null || time24.isEmpty) return '';
    try {
      final parts = time24.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(2000, 1, 1, h, m);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time24;
    }
  }

  static String date(dynamic value) {
    if (value == null) return '';
    try {
      if (value is DateTime) {
        // Normalise to local so UTC midnight doesn't shift the day
        final local = value.isUtc ? value.toLocal() : value;
        return _dateDisplay.format(local);
      }
      final str = value.toString();
      // Date-only strings (yyyy-MM-dd): parse via DateFormat which yields local time
      final dt = str.contains('T') || str.contains(' ')
          ? DateTime.parse(str).toLocal()
          : _dateApi.parseStrict(str);
      return _dateDisplay.format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  static String dateTime(dynamic value) {
    if (value == null) return '';
    try {
      if (value is DateTime) return _dateTimeDisplay.format(value.toLocal());
      final dt = DateTime.parse(value.toString());
      return _dateTimeDisplay.format(dt.toLocal());
    } catch (_) {
      return value.toString();
    }
  }

  static String dateToApi(DateTime dt) => _dateApi.format(dt);

  static DateTime? parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      // Date-only strings: parse as local to avoid UTC offset shifting the day
      if (!value.contains('T') && !value.contains(' ')) {
        return _dateApi.parseStrict(value);
      }
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Masks card digits: "•••• 1234"
  static String maskedCard(String? lastFour) {
    if (lastFour == null || lastFour.isEmpty) return '•••• ••••';
    return '•••• $lastFour';
  }

  /// "City Bank •••• 1234"
  static String cardLabel(String? bankName, String? lastFour) {
    return '${bankName ?? 'Card'} ${maskedCard(lastFour)}';
  }

  /// "City Bank •••• 1234 — Balance: Rs. 50,000.00"
  static String cardDropdownLabel(
      String? bankName, String? lastFour, dynamic balance) {
    return '${cardLabel(bankName, lastFour)} — Balance: ${currency(balance)}';
  }
}
