import 'package:flutter/foundation.dart';
import '../events/financial_event_bus.dart';
import '../models/today_status.dart';
import '../services/api_service.dart';

class StaffStatusProvider extends ChangeNotifier {
  final ApiService _api;
  final FinancialEventBus _eventBus;

  StaffStatusProvider(this._api, this._eventBus) {
    _eventBus.addListener(_onFinancialChange);
  }

  TodayStatus? _status;
  bool _isLoading = false;
  String? _error;

  bool _isEditWindowOpen = true;
  String? _editWindowStart;
  String? _editWindowEnd;

  TodayStatus? get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isEditWindowOpen => _isEditWindowOpen;
  String? get editWindowStart => _editWindowStart;
  String? get editWindowEnd => _editWindowEnd;

  void _onFinancialChange() {
    if (_status != null) {
      _silentRefresh();
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final results = await Future.wait([
        _api.get('/today-status'),
        _api.get('/edit-window'),
      ]);
      _status = TodayStatus.fromJson(results[0] as Map<String, dynamic>);
      final ew = results[1] as Map<String, dynamic>;
      _isEditWindowOpen = ew['is_within_window'] as bool? ?? true;
      _editWindowStart = ew['edit_window_start'] as String?;
      _editWindowEnd = ew['edit_window_end'] as String?;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchTodayStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.get('/today-status'),
        _api.get('/edit-window'),
      ]);
      _status = TodayStatus.fromJson(results[0] as Map<String, dynamic>);
      final ew = results[1] as Map<String, dynamic>;
      _isEditWindowOpen = ew['is_within_window'] as bool? ?? true;
      _editWindowStart = ew['edit_window_start'] as String?;
      _editWindowEnd = ew['edit_window_end'] as String?;
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

  @override
  void dispose() {
    _eventBus.removeListener(_onFinancialChange);
    super.dispose();
  }
}
