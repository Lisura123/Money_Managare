import 'package:flutter/foundation.dart';
import '../events/financial_event_bus.dart';
import '../models/external_account.dart';
import '../models/self_transaction.dart';
import '../services/api_service.dart';

class SelfTransactionProvider extends ChangeNotifier {
  final ApiService _api;
  final FinancialEventBus _eventBus;

  SelfTransactionProvider(this._api, this._eventBus) {
    _eventBus.addListener(_onFinancialChange);
  }

  List<SelfTransaction> _transactions = [];
  List<ExternalAccount> _externalAccounts = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<SelfTransaction> get transactions => _transactions;
  List<ExternalAccount> get externalAccounts => _externalAccounts;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get hasMore => _hasMore;

  void _onFinancialChange() {
    if (_transactions.isNotEmpty) {
      _silentRefreshTransactions();
    }
  }

  Future<void> _silentRefreshTransactions() async {
    try {
      final data =
          await _api.get('/self-transactions', queryParameters: {'page': 1});
      final list = data['data'] as List? ?? data as List? ?? [];
      _transactions = list
          .map((j) => SelfTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
      _currentPage = 2;
      _hasMore = _transactions.isNotEmpty;
      notifyListeners();
    } catch (_) {}
  }

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
      final data = await _api
          .get('/self-transactions', queryParameters: {'page': _currentPage});
      final list = data['data'] as List? ?? data as List? ?? [];
      final parsed = list
          .map((j) => SelfTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
      if (refresh) {
        _transactions = parsed;
      } else {
        _transactions.addAll(parsed);
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

  Future<void> fetchExternalAccounts() async {
    try {
      final data = await _api.get('/external-accounts');
      final list = data as List? ?? [];
      _externalAccounts = list
          .map((j) => ExternalAccount.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // Non-critical — dropdown falls back to no external accounts
    }
  }

  Future<bool> createTransaction({
    required int fromCardAccountId,
    int? toCardAccountId,
    int? toExternalAccountId,
    required double amount,
    String? notes,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post('/self-transactions', data: {
        'from_card_account_id': fromCardAccountId,
        if (toCardAccountId != null) 'to_card_account_id': toCardAccountId,
        if (toExternalAccountId != null)
          'to_external_account_id': toExternalAccountId,
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

  Future<bool> deleteTransaction(int id) async {
    try {
      await _api.delete('/self-transactions/$id');
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
      await _api.post('/self-transactions/bulk-delete', data: {'ids': ids});
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
    _transactions = [];
    super.dispose();
  }
}
