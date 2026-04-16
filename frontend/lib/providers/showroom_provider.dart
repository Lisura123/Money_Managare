import 'package:flutter/foundation.dart';
import '../models/showroom.dart';
import '../services/api_service.dart';

class ShowroomProvider extends ChangeNotifier {
  final ApiService _api;
  ShowroomProvider(this._api);

  List<Showroom> _showrooms = [];
  bool _isLoading = false;
  String? _error;

  List<Showroom> get showrooms => _showrooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchShowrooms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/showrooms');
      final list =
          data['data'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
      _showrooms = list
          .map((j) => Showroom.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Showroom?> fetchShowroom(int id) async {
    try {
      final data = await _api.get('/showrooms/$id');
      final json = data['data'] ?? data;
      return Showroom.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> createShowroom(
      {required String name, required String location}) async {
    try {
      await _api.post('/showrooms', data: {'name': name, 'location': location});
      await fetchShowrooms();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> updateShowroom(int id,
      {required String name, required String location}) async {
    try {
      await _api
          .put('/showrooms/$id', data: {'name': name, 'location': location});
      await fetchShowrooms();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteShowroom(int id) async {
    try {
      await _api.delete('/showrooms/$id');
      _showrooms.removeWhere((s) => s.id == id);
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
    _showrooms = [];
    super.dispose();
  }
}
