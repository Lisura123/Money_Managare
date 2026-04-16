import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthState _state = AuthState.initial;
  User? _user;
  String? _error;
  bool _isLoading = false;

  AuthProvider(this._authService);

  AuthState get state => _state;
  User? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _state == AuthState.authenticated && _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isStaff => _user?.isStaff ?? false;

  Future<void> checkAuth() async {
    _state = AuthState.loading;
    notifyListeners();
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }
      final user = await StorageService.getUser();
      if (user == null) {
        await StorageService.clearAll();
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }
      _user = user;
      _state = AuthState.authenticated;
      notifyListeners();
    } catch (_) {
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.login(email, password);
      _user = result['user'] as User;
      _state = AuthState.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _state = AuthState.unauthenticated;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void forceLogout() {
    _user = null;
    _state = AuthState.unauthenticated;
    _error = null;
    notifyListeners();
  }
}
