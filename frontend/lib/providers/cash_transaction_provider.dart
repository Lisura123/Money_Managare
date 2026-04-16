import 'package:flutter/foundation.dart';
import '../events/financial_event_bus.dart';
import '../models/cash_transaction.dart';
import '../models/external_account.dart';
import '../services/api_service.dart';

class CashTransactionProvider extends ChangeNotifier {
  final ApiService _api;
  final FinancialEventBus _eventBus;

  CashTransactionProvider(this._api, this._eventBus) {
    _eventBus.addListener(_onFinancialChange);
  }

  List<CashTransaction> _transactions = [];
  List<ExternalAccount> _externalAccounts = [];
  double _mainBalance = 0;
  double _manoBalance = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Active filters
  String? _filterFromAccount; // 'main' | 'mano' | null
  String? _filterType; // 'internal' | 'external' | null
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;

  List<CashTransaction> get transactions => _transactions;
  List<ExternalAccount> get externalAccounts => _externalAccounts;
  double get mainBalance => _mainBalance;
  double get manoBalance => _manoBalance;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get filterFromAccount => _filterFromAccount;
  String? get filterType => _filterType;
  DateTime? get filterDateFrom => _filterDateFrom;
  DateTime? get filterDateTo => _filterDateTo;
  bool get hasActiveFilters =>
      _filterFromAccount != null ||
      _filterType != null ||
      _filterDateFrom != null ||
      _filterDateTo != null;

  void _onFinancialChange() {
    if (_transactions.isNotEmpty) {
      _silentRefreshTransactions();
    }
    // Always refresh balances as they can change with any financial mutation
    fetchSummary();
  }

  Future<void> _silentRefreshTransactions() async {
    try {
      final params = <String, dynamic>{'page': 1};
      if (_filterFromAccount != null) {
        params['from_account_type'] = _filterFromAccount!;
      }
      if (_filterType != null) params['type'] = _filterType!;
      if (_filterDateFrom != null) {
        params['date_from'] = _fmtDate(_filterDateFrom!);
      }
      if (_filterDateTo != null) {
        params['date_to'] = _fmtDate(_filterDateTo!);
      }
      final data =
          await _api.get('/cash-transactions', queryParameters: params);
      final list = (data['data'] as List?) ?? [];
      _transactions = list
          .map((j) => CashTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
      _currentPage = 2;
      _hasMore = _transactions.isNotEmpty &&
          (data['current_page'] as int? ?? 1) <
              (data['last_page'] as int? ?? 1);
      notifyListeners();
    } catch (_) {}
  }

  void setFilters({
    String? fromAccount,
    String? type,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    _filterFromAccount = fromAccount;
    _filterType = type;
    _filterDateFrom = dateFrom;
    _filterDateTo = dateTo;
  }

  void clearFilters() {
    _filterFromAccount = null;
    _filterType = null;
    _filterDateFrom = null;
    _filterDateTo = null;
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> fetchTransactions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _transactions = [];
      _hasMore = true;
    }
    if (!_hasMore) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final params = <String, dynamic>{'page': _currentPage};
      if (_filterFromAccount != null) {
        params['from_account_type'] = _filterFromAccount!;
      }
      if (_filterType != null) {
        params['type'] = _filterType!;
      }
      if (_filterDateFrom != null) {
        params['date_from'] = _fmtDate(_filterDateFrom!);
      }
      if (_filterDateTo != null) {
        params['date_to'] = _fmtDate(_filterDateTo!);
      }

      final data =
          await _api.get('/cash-transactions', queryParameters: params);
      final list = (data['data'] as List?) ?? [];
      final parsed = list
          .map((j) => CashTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
      if (refresh) {
        _transactions = parsed;
      } else {
        _transactions.addAll(parsed);
      }
      _hasMore = parsed.isNotEmpty &&
          (data['current_page'] as int? ?? 1) <
              (data['last_page'] as int? ?? 1);
      _currentPage++;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSummary() async {
    try {
      final data = await _api.get('/cash-summary');
      _mainBalance = double.tryParse(data['main']?.toString() ?? '0') ?? 0;
      _manoBalance = double.tryParse(data['mano']?.toString() ?? '0') ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchExternalAccounts() async {
    try {
      final data = await _api.get('/external-accounts');
      final list = data as List? ?? [];
      _externalAccounts = list
          .map((j) => ExternalAccount.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createTransaction({
    required String fromAccountType,
    String? toAccountType,
    int? toExternalAccountId,
    required double amount,
    required String transactionDate,
    String? notes,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post('/cash-transactions', data: {
        'from_account_type': fromAccountType,
        if (toAccountType != null) 'to_account_type': toAccountType,
        if (toExternalAccountId != null)
          'to_external_account_id': toExternalAccountId,
        'amount': amount,
        'transaction_date': transactionDate,
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

  Future<bool> deleteTransaction(int id) async {
    try {
      await _api.delete('/cash-transactions/$id');
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      _eventBus.notifyChange();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> bulkDeleteTransactions(List<int> ids) async {
    try {
      await _api.post('/cash-transactions/bulk-delete', data: {'ids': ids});
      _transactions.removeWhere((t) => ids.contains(t.id));
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
    super.dispose();
  }
}
