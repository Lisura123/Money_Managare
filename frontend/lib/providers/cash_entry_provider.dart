import 'package:flutter/foundation.dart';
import '../events/financial_event_bus.dart';
import '../models/daily_cash_entry.dart';
import '../models/admin_cash_adjustment.dart';
import '../services/api_service.dart';

class CashEntryProvider extends ChangeNotifier {
  final ApiService _api;
  final FinancialEventBus _eventBus;

  CashEntryProvider(this._api, this._eventBus) {
    _eventBus.addListener(_onFinancialChange);
  }

  List<DailyCashEntry> _entries = [];
  List<DailyCashEntry> _myHistory = [];
  List<AdminCashAdjustment> _adjustments = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  // Pagination (separate for admin entries and staff history)
  int _entriesPage = 1;
  bool _entriesHasMore = true;
  int _historyPage = 1;
  bool _historyHasMore = true;
  double _totalAmount = 0.0;
  int _totalEntries = 0;

  // Last-used query params for auto-refresh
  int? _lastShowroomId;
  String? _lastDate;
  String? _lastFrom;
  String? _lastTo;
  String? _lastCashAccountType;
  String? _lastHistoryCashAccountType;

  List<DailyCashEntry> get entries => _entries;
  List<DailyCashEntry> get myHistory => _myHistory;
  List<AdminCashAdjustment> get adjustments => _adjustments;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get hasMore => _entriesHasMore;
  bool get historyHasMore => _historyHasMore;
  double get totalAmount => _totalAmount;
  int get totalEntries => _totalEntries;

  void _onFinancialChange() {
    if (_entries.isNotEmpty) {
      fetchEntries(
        showroomId: _lastShowroomId,
        date: _lastDate,
        from: _lastFrom,
        to: _lastTo,
        cashAccountType: _lastCashAccountType,
        refresh: true,
        silent: true,
      );
    }
    if (_myHistory.isNotEmpty) {
      fetchMyHistory(
        cashAccountType: _lastHistoryCashAccountType,
        refresh: true,
        silent: true,
      );
    }
    if (_adjustments.isNotEmpty) {
      fetchAdjustments(silent: true);
    }
  }

  Future<void> fetchEntries({
    int? showroomId,
    String? date,
    String? from,
    String? to,
    String? cashAccountType,
    bool refresh = false,
    bool silent = false,
  }) async {
    // Store last-used params for event-bus driven auto-refresh
    if (!silent) {
      _lastShowroomId = showroomId;
      _lastDate = date;
      _lastFrom = from;
      _lastTo = to;
      _lastCashAccountType = cashAccountType;
    }
    if (refresh) {
      _entriesPage = 1;
      if (!silent) _entries = [];
      _entriesHasMore = true;
    }
    if (!_entriesHasMore) return;
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final params = <String, dynamic>{'page': _entriesPage};
      if (showroomId != null) params['showroom_id'] = showroomId;
      if (date != null) params['date'] = date;
      if (from != null) params['from'] = from;
      if (to != null) params['to'] = to;
      if (cashAccountType != null) {
        params['cash_account_type'] = cashAccountType;
      }

      final data = await _api.get('/cash-entries', queryParameters: params);
      final list = data['data'] as List? ?? data as List? ?? [];
      final parsed = list
          .map((j) => DailyCashEntry.fromJson(j as Map<String, dynamic>))
          .toList();
      final meta = data['meta'] as Map<String, dynamic>?;
      final currentPage = (meta?['current_page'] as int?) ?? _entriesPage;
      final lastPage = (meta?['last_page'] as int?) ??
          (parsed.isEmpty ? currentPage : currentPage + 1);
      _entriesHasMore = currentPage < lastPage;
      _totalEntries = (meta?['total'] as int?) ?? parsed.length;
      // Use server-calculated total when available (covers all pages)
      if (meta != null && meta.containsKey('total_amount')) {
        _totalAmount = (meta['total_amount'] as num?)?.toDouble() ?? 0.0;
      } else if (refresh || silent) {
        _totalAmount = parsed.fold(0.0, (s, e) => s + e.cashAmount);
      }
      if (silent) {
        // Replace the full list so new entries at the top become visible
        _entries = parsed;
        _entriesPage = 2;
      } else if (refresh) {
        _entries = parsed;
        _entriesPage = 2;
      } else {
        _entries.addAll(parsed);
        _entriesPage++;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (!silent) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchMyHistory(
      {String? cashAccountType,
      bool refresh = false,
      bool silent = false}) async {
    if (!silent) _lastHistoryCashAccountType = cashAccountType;
    if (refresh) {
      _historyPage = 1;
      if (!silent) _myHistory = [];
      _historyHasMore = true;
    }
    if (!_historyHasMore) return;
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final params = <String, dynamic>{'page': _historyPage};
      if (cashAccountType != null) {
        params['cash_account_type'] = cashAccountType;
      }
      final data =
          await _api.get('/cash-entries/my-history', queryParameters: params);
      final list = data['data'] as List? ?? data as List? ?? [];
      final parsed = list
          .map((j) => DailyCashEntry.fromJson(j as Map<String, dynamic>))
          .toList();
      if (silent) {
        _myHistory = parsed;
        _historyPage = 2;
      } else if (refresh) {
        _myHistory = parsed;
        _historyPage = 2;
      } else {
        _myHistory.addAll(parsed);
        _historyPage++;
      }
      final meta = data['meta'] as Map<String, dynamic>?;
      final currentPage = (meta?['current_page'] as int?) ?? _historyPage;
      final lastPage = (meta?['last_page'] as int?) ??
          (parsed.isEmpty ? currentPage : currentPage + 1);
      _historyHasMore = currentPage < lastPage;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (!silent) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> submitEntry(
      {required String entryDate,
      required double cashAmount,
      String? notes,
      String cashAccountType = 'main'}) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post('/cash-entries', data: {
        'entry_date': entryDate,
        'cash_amount': cashAmount,
        'cash_account_type': cashAccountType,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      _isSubmitting = false;
      notifyListeners();
      _eventBus.notifyChange();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> updateEntry(int id, {double? cashAmount, String? notes}) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      final body = <String, dynamic>{};
      if (cashAmount != null) body['cash_amount'] = cashAmount;
      if (notes != null) body['notes'] = notes;
      await _api.put('/cash-entries/$id', data: body);
      _isSubmitting = false;
      notifyListeners();
      _eventBus.notifyChange();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchAdjustments({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final data = await _api.get('/adjustments/cash');
      final list = data['data'] as List? ?? data as List? ?? [];
      _adjustments = list
          .map((j) => AdminCashAdjustment.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (!silent) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addEntryAdjustment(
    int entryId, {
    required double amount,
    required String reason,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _api.post('/cash-entries/$entryId/adjustments',
          data: {'adjusted_amount': amount, 'reason': reason});
      _isSubmitting = false;
      notifyListeners();
      _eventBus.notifyChange();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> addAdjustment({
    int? showroomId,
    required double amount,
    required String reason,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _api.post('/adjustments/cash', data: {
        'adjusted_amount': amount,
        'reason': reason,
        if (showroomId != null) 'showroom_id': showroomId,
      });
      _isSubmitting = false;
      notifyListeners();
      _eventBus.notifyChange();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteEntry(int id) async {
    try {
      await _api.delete('/cash-entries/$id');
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
      _eventBus.notifyChange();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteAdjustment(int id) async {
    try {
      await _api.delete('/adjustments/cash/$id');
      _adjustments.removeWhere((a) => a.id == id);
      notifyListeners();
      _eventBus.notifyChange();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> bulkDeleteEntries(List<int> ids) async {
    try {
      await _api.post('/cash-entries/bulk-delete', data: {'ids': ids});
      _entries.removeWhere((e) => ids.contains(e.id));
      notifyListeners();
      _eventBus.notifyChange();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> bulkDeleteAdjustments(List<int> ids) async {
    try {
      await _api.post('/adjustments/cash/bulk-delete', data: {'ids': ids});
      _adjustments.removeWhere((a) => ids.contains(a.id));
      notifyListeners();
      _eventBus.notifyChange();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _eventBus.removeListener(_onFinancialChange);
    _entries = [];
    _myHistory = [];
    _adjustments = [];
    super.dispose();
  }
}
