import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class StaffProvider extends ChangeNotifier {
  final ApiService _api;
  StaffProvider(this._api);

  List<User> _staff = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  List<User> get staff => _staff;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Future<void> fetchStaff() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/staff');
      final list = data['data'] as List? ?? data as List? ?? [];
      _staff =
          list.map((j) => User.fromJson(j as Map<String, dynamic>)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> fetchStaffMember(int id) async {
    try {
      final data = await _api.get('/staff/$id');
      final json = data['data'] ?? data;
      return User.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createStaff({
    required String name,
    required String email,
    required String password,
    required int showroomId,
    bool isActive = true,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.post('/staff', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'showroom_id': showroomId,
        'is_active': isActive,
      });
      await fetchStaff();
      _isSubmitting = false;
      notifyListeners();
      return {
        'email_sent': response['email_sent'] as bool? ?? true,
      };
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> updateStaff(
    int id, {
    String? name,
    String? email,
    String? password,
    int? showroomId,
    bool? isActive,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
        body['password_confirmation'] = password;
      }
      if (showroomId != null) body['showroom_id'] = showroomId;
      if (isActive != null) body['is_active'] = isActive;
      await _api.put('/staff/$id', data: body);
      await fetchStaff();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteStaff(int id) async {
    try {
      await _api.delete('/staff/$id');
      _staff.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendResetEmail(int id) async {
    await _api.post('/staff/$id/send-reset-email');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _staff = [];
    super.dispose();
  }
}
