import 'package:flutter/foundation.dart';
import '../models/setting.dart';
import '../services/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  final ApiService _api;
  SettingsProvider(this._api);

  List<Setting> _settings = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  List<Setting> get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Setting? get editWindowStartSetting =>
      _settings.where((s) => s.key == 'edit_window_start').firstOrNull;

  Setting? get editWindowEndSetting =>
      _settings.where((s) => s.key == 'edit_window_end').firstOrNull;

  Future<void> fetchSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/settings');
      final list = data['data'] as List? ?? data as List? ?? [];
      _settings =
          list.map((j) => Setting.fromJson(j as Map<String, dynamic>)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSetting(int id, String value) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _api.put('/settings/$id', data: {'value': value});
      await fetchSettings();
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings = [];
    super.dispose();
  }
}
