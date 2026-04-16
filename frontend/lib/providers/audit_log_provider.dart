import 'package:flutter/foundation.dart';
import '../models/audit_log.dart';
import '../services/api_service.dart';

class AuditLogProvider extends ChangeNotifier {
  final ApiService _api;
  AuditLogProvider(this._api);

  List<AuditLog> _logs = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<AuditLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchLogs({
    String? tableName,
    String? action,
    int? userId,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _logs = [];
      _hasMore = true;
    }
    if (!_hasMore) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final params = <String, dynamic>{'page': _currentPage};
      if (tableName != null && tableName.isNotEmpty) {
        params['table_name'] = tableName;
      }
      if (action != null && action.isNotEmpty) params['action'] = action;
      if (userId != null) params['user_id'] = userId;
      final data = await _api.get('/audit-logs', queryParameters: params);
      final list = data['data'] as List? ?? data as List? ?? [];
      final parsed = list
          .map((j) => AuditLog.fromJson(j as Map<String, dynamic>))
          .toList();
      if (refresh) {
        _logs = parsed;
      } else {
        _logs.addAll(parsed);
      }
      _hasMore = parsed.isNotEmpty;
      _currentPage++;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> deleteLog(int id) async {
    await _api.delete('/audit-logs/$id');
    _logs.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Future<void> bulkDeleteLogs(List<int> ids) async {
    await _api.post('/audit-logs/bulk-delete', data: {'ids': ids});
    _logs.removeWhere((l) => ids.contains(l.id));
    notifyListeners();
  }

  @override
  void dispose() {
    _logs = [];
    super.dispose();
  }
}
