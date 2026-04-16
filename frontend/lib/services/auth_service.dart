import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthService {
  final ApiService _api;
  AuthService(this._api);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _api.post('/login', data: {
      'email': email.trim(),
      'password': password,
    });
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await StorageService.saveToken(token);
    await StorageService.saveUser(user);
    return {'token': token, 'user': user};
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {
      // Even if the server call fails, clear local storage
    } finally {
      await StorageService.clearAll();
    }
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/forgot-password', data: {
      'email': email.trim(),
    });
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _api.post('/reset-password', data: {
      'email': email.trim(),
      'code': code.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _api.post('/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    });
  }

  Future<User?> getStoredUser() async {
    return StorageService.getUser();
  }

  Future<String?> getStoredToken() async {
    return StorageService.getToken();
  }
}
