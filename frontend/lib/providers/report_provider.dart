import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/api_service.dart';

class ReportProvider extends ChangeNotifier {
  final ApiService _api;
  ReportProvider(this._api);

  bool _isGenerating = false;
  String? _error;
  String? _lastFilePath;
  // Populated when no PDF viewer is installed on the device.
  String? _noViewerFilePath;

  bool get isGenerating => _isGenerating;
  String? get error => _error;
  String? get lastFilePath => _lastFilePath;

  /// Non-null when the file was saved but could not be opened (no viewer app).
  String? get noViewerFilePath => _noViewerFilePath;

  Future<String?> generateDailySummary({
    required String from,
    required String to,
    int? showroomId,
  }) async {
    final params = <String, dynamic>{'from': from, 'to': to};
    if (showroomId != null) params['showroom_id'] = showroomId;
    return _generate('/reports/pdf/daily-summary', params,
        'daily_summary_${from}_to_$to.pdf');
  }

  Future<String?> generateShowroomReport({
    required int showroomId,
    required String from,
    required String to,
  }) async {
    return _generate(
        '/reports/pdf/showroom',
        {'showroom_id': showroomId, 'from': from, 'to': to},
        'showroom_report_${from}_$to.pdf');
  }

  Future<String?> generateCardStatement({
    required int cardAccountId,
    required String from,
    required String to,
  }) async {
    return _generate(
        '/reports/pdf/card-statement',
        {'card_account_id': cardAccountId, 'from': from, 'to': to},
        'card_statement_${from}_$to.pdf');
  }

  Future<String?> generateSelfTransactions({
    required String from,
    required String to,
  }) async {
    return _generate('/reports/pdf/self-transactions', {'from': from, 'to': to},
        'self_transactions_${from}_$to.pdf');
  }

  Future<String?> generateAdjustments({
    required String from,
    required String to,
  }) async {
    return _generate('/reports/pdf/adjustments', {'from': from, 'to': to},
        'adjustments_${from}_$to.pdf');
  }

  Future<String?> _generate(
      String path, Map<String, dynamic> params, String filename) async {
    _isGenerating = true;
    _error = null;
    _noViewerFilePath = null;
    notifyListeners();
    try {
      final bytes = await _api.getBytes(path, queryParameters: params);
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      _lastFilePath = filePath;

      // Attempt to open the file; handle missing PDF viewer gracefully.
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        // No app installed to open PDF — surface the path for the UI to show.
        _noViewerFilePath = filePath;
      }

      _isGenerating = false;
      notifyListeners();
      return filePath;
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearNoViewer() {
    _noViewerFilePath = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
