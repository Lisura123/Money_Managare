import 'package:flutter/foundation.dart';
import '../events/financial_event_bus.dart';
import '../models/daily_card_entry.dart';
import '../models/admin_card_adjustment.dart';
import '../services/api_service.dart';

class CardEntryProvider extends ChangeNotifier {
  final ApiService _api;
  final FinancialEventBus _eventBus;

  CardEntryProvider(this._api, this._eventBus) {
    _eventBus.addListener(_onFinancialChange);
  }

  List<DailyCardEntry> _entries = [];
  List<DailyCardEntry> _myHistory = [];
  List<AdminCardAdjustment> _adjustments = [];
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
  int? _lastCardAccountId;
  String? _lastDate;
  String? _lastFrom;
  String? _lastTo;
  int? _lastAdjCardAccountId;

  List<DailyCardEntry> get entries => _entries;
  List<DailyCardEntry> get myHistory => _myHistory;
  List<AdminCardAdjustment> get adjustments => _adjustments;
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
        cardAccountId: _lastCardAccountId,
        date: _lastDate,
        from: _lastFrom,
        to: _lastTo,
        refresh: true,
        silent: true,
      );
    }
    if (_myHistory.isNotEmpty) {
      fetchMyHistory(refresh: true, silent: true);
    }
    if (_adjustments.isNotEmpty) {
      fetchAdjustments(cardAccountId: _lastAdjCardAccountId, silent: true);
    }
  }

  Future<void> fetchEntries({
    int? showroomId,
    int? cardAccountId,
    String? date,
    String? from,
    String? to,
    bool refresh = false,
    bool silent = false,
  }) async {
    // Store last-used params for event-bus driven auto-refresh
    if (!silent) {
      _lastShowroomId = showroomId;
      _lastCardAccountId = cardAccountId;
      _lastDate = date;
      _lastFrom = from;
      _lastTo = to;
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
      if (cardAccountId != null) params['card_account_id'] = cardAccountId;
      if (date != null) params['date'] = date;
      if (from != null) params['from'] = from;
      if (to != null) params['to'] = to;
      final data = await _api.get('/card-entries', queryParameters: params);
      final list = data['data'] as List? ?? data as List? ?? [];
      final parsed = list
          .map((j) => DailyCardEntry.fromJson(j as Map<String, dynamic>))
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
        _totalAmount = parsed.fold(0.0, (s, e) => s + e.amount);
      }
      if (silent) {
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
      {bool refresh = false, bool silent = false}) async {
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
      final data = await _api.get('/card-entries/my-history',
          queryParameters: {'page': _historyPage});
      final list = data['data'] as List? ?? data as List? ?? [];
      final parsed = list
          .map((j) => DailyCardEntry.fromJson(j as Map<String, dynamic>))
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

  Future<bool> submitEntry({
    required String entryDate,
    required int cardAccountId,
    required double amount,
    String? notes,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post('/card-entries', data: {
        'entry_date': entryDate,
        'card_account_id': cardAccountId,
        'amount': amount,
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

  Future<bool> updateEntry(int id, {double? amount, String? notes}) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      final body = <String, dynamic>{};
      if (amount != null) body['amount'] = amount;
      if (notes != null) body['notes'] = notes;
      await _api.put('/card-entries/$id', data: body);
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

  Future<void> fetchAdjustments(
      {int? cardAccountId, bool silent = false}) async {
    if (!silent) _lastAdjCardAccountId = cardAccountId;
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final params = cardAccountId != null
          ? <String, dynamic>{'card_account_id': cardAccountId}
          : null;
      final data = await _api.get('/adjustments/card', queryParameters: params);
      final list = data['data'] as List? ?? data as List? ?? [];
      _adjustments = list
          .map((j) => AdminCardAdjustment.fromJson(j as Map<String, dynamic>))
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
      await _api.post('/card-entries/$entryId/adjustments',
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
    int? cardAccountId,
    required double amount,
    required String reason,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _api.post('/adjustments/card', data: {
        'adjusted_amount': amount,
        'reason': reason,
        if (cardAccountId != null) 'card_account_id': cardAccountId,
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
      await _api.delete('/card-entries/$id');
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
      await _api.delete('/adjustments/card/$id');
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
      await _api.post('/card-entries/bulk-delete', data: {'ids': ids});
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
      await _api.post('/adjustments/card/bulk-delete', data: {'ids': ids});
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
