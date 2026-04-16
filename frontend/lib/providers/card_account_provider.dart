import 'package:flutter/foundation.dart';
import '../events/financial_event_bus.dart';
import '../models/card_account.dart';
import '../services/api_service.dart';

class CardAccountProvider extends ChangeNotifier {
  final ApiService _api;
  final FinancialEventBus _eventBus;

  CardAccountProvider(this._api, this._eventBus) {
    _eventBus.addListener(_onFinancialChange);
  }

  List<CardAccount> _accounts = [];
  List<CardAccount> _myAccounts = [];
  List<CardAccount> _allAccounts = [];
  bool _isLoading = false;
  String? _error;
  int? _lastShowroomId;
  List<int>? _lastShowroomIds;

  List<CardAccount> get accounts => _accounts;
  List<CardAccount> get myAccounts => _myAccounts;
  List<CardAccount> get allAccounts => _allAccounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _onFinancialChange() {
    if (_myAccounts.isNotEmpty) {
      _silentFetchMyAccounts();
    }
    if (_accounts.isNotEmpty && _lastShowroomId != null) {
      _silentFetchForShowroom(_lastShowroomId!);
    }
    if (_allAccounts.isNotEmpty && _lastShowroomIds != null) {
      _silentFetchAllAccounts(_lastShowroomIds!);
    }
  }

  Future<void> _silentFetchMyAccounts() async {
    try {
      final data = await _api.get('/my-card-accounts');
      final list = data['data'] as List? ?? data as List? ?? [];
      _myAccounts = list
          .map((j) => CardAccount.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _silentFetchForShowroom(int showroomId) async {
    try {
      final data = await _api.get('/showrooms/$showroomId/card-accounts');
      final list = data['data'] as List? ?? data as List? ?? [];
      _accounts = list
          .map((j) => CardAccount.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _silentFetchAllAccounts(List<int> showroomIds) async {
    try {
      final results = await Future.wait(
        showroomIds.map((id) => _api.get('/showrooms/$id/card-accounts')),
      );
      final List<CardAccount> all = [];
      for (final data in results) {
        final list = data['data'] as List? ?? data as List? ?? [];
        all.addAll(list
            .map((j) => CardAccount.fromJson(j as Map<String, dynamic>))
            .toList());
      }
      _allAccounts = all;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchForShowroom(int showroomId) async {
    _lastShowroomId = showroomId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/showrooms/$showroomId/card-accounts');
      final list = data['data'] as List? ?? data as List? ?? [];
      _accounts = list
          .map((j) => CardAccount.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyAccounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/my-card-accounts');
      final list = data['data'] as List? ?? data as List? ?? [];
      _myAccounts = list
          .map((j) => CardAccount.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllAccounts(List<int> showroomIds) async {
    _lastShowroomIds = showroomIds;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait(
        showroomIds.map((id) => _api.get('/showrooms/$id/card-accounts')),
      );
      final List<CardAccount> all = [];
      for (final data in results) {
        final list = data['data'] as List? ?? data as List? ?? [];
        all.addAll(list
            .map((j) => CardAccount.fromJson(j as Map<String, dynamic>))
            .toList());
      }
      _allAccounts = all;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(int showroomId,
      {required String bankName,
      required String lastFour,
      required double balance}) async {
    try {
      await _api.post('/showrooms/$showroomId/card-accounts', data: {
        'bank_name': bankName,
        'last_four': lastFour,
        'current_balance': balance,
      });
      await fetchForShowroom(showroomId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> update(int showroomId, int accountId,
      {required String bankName,
      required String lastFour,
      required double balance}) async {
    try {
      await _api.put('/showrooms/$showroomId/card-accounts/$accountId', data: {
        'bank_name': bankName,
        'last_four': lastFour,
        'current_balance': balance,
      });
      await fetchForShowroom(showroomId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteAccount(int showroomId, int accountId) async {
    try {
      await _api.delete('/showrooms/$showroomId/card-accounts/$accountId');
      _accounts.removeWhere((a) => a.id == accountId);
      notifyListeners();
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
    _accounts = [];
    _myAccounts = [];
    _allAccounts = [];
    super.dispose();
  }
}
