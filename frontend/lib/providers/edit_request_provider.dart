import 'package:flutter/foundation.dart';
import '../events/financial_event_bus.dart';
import '../models/edit_request.dart';
import '../services/api_service.dart';

class EditRequestProvider extends ChangeNotifier {
  final ApiService _api;
  final FinancialEventBus _eventBus;

  EditRequestProvider(this._api, this._eventBus) {
    _eventBus.addListener(_onFinancialChange);
  }

  // Staff: my requests
  List<EditRequest> _myRequests = [];
  bool _myLoading = false;
  bool _myHasMore = true;
  int _myPage = 1;
  String? _myError;

  // Admin: all requests
  List<EditRequest> _allRequests = [];
  bool _allLoading = false;
  bool _allHasMore = true;
  int _allPage = 1;
  String? _allError;

  // Pending count (admin badge)
  int _pendingCount = 0;

  // Submit state
  bool _isSubmitting = false;

  List<EditRequest> get myRequests => _myRequests;
  bool get myLoading => _myLoading;
  bool get myHasMore => _myHasMore;
  String? get myError => _myError;

  List<EditRequest> get allRequests => _allRequests;
  bool get allLoading => _allLoading;
  bool get allHasMore => _allHasMore;
  String? get allError => _allError;

  int get pendingCount => _pendingCount;
  bool get isSubmitting => _isSubmitting;

  void _onFinancialChange() {
    fetchPendingCount();
    if (_myRequests.isNotEmpty) {
      fetchMyRequests(refresh: true, silent: true);
    }
    if (_allRequests.isNotEmpty) {
      fetchAllRequests(refresh: true, silent: true);
    }
  }

  // -------------------------------------------------------
  // Staff: fetch own requests
  // -------------------------------------------------------
  Future<void> fetchMyRequests(
      {bool refresh = false, bool silent = false}) async {
    if (refresh) {
      _myPage = 1;
      if (!silent) _myRequests = [];
      _myHasMore = true;
    }
    if (!_myHasMore) return;
    if (!silent) {
      _myLoading = true;
      _myError = null;
      notifyListeners();
    }
    try {
      final data = await _api.get('/edit-requests/my-requests',
          queryParameters: {'page': _myPage});
      final list = data['data'] as List? ?? [];
      final parsed = list
          .map((j) => EditRequest.fromJson(j as Map<String, dynamic>))
          .toList();
      if (silent || refresh) {
        _myRequests = parsed;
        _myPage = 2;
      } else {
        _myRequests.addAll(parsed);
        _myPage++;
      }
      _myHasMore = parsed.isNotEmpty;
    } catch (e) {
      if (!silent) _myError = e.toString();
    } finally {
      if (!silent) _myLoading = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------
  // Staff: submit new edit request
  // -------------------------------------------------------
  Future<EditRequest> submitEditRequest({
    required String entryType,
    required int entryId,
    required Map<String, dynamic> requestedChanges,
    required String reason,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final data = await _api.post('/edit-requests', data: {
        'entry_type': entryType,
        'entry_id': entryId,
        'requested_changes': requestedChanges,
        'reason': reason,
      });
      final created = EditRequest.fromJson(data as Map<String, dynamic>);
      _myRequests.insert(0, created);
      return created;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------
  // Staff: cancel own pending request
  // -------------------------------------------------------
  Future<void> cancelRequest(int id) async {
    await _api.delete('/edit-requests/$id');
    _myRequests.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // -------------------------------------------------------
  // Admin: fetch all requests with optional filters
  // -------------------------------------------------------
  Future<void> fetchAllRequests({
    bool refresh = false,
    bool silent = false,
    String? status,
    int? showroomId,
    String? entryType,
    int? userId,
    String? from,
    String? to,
  }) async {
    if (refresh) {
      _allPage = 1;
      if (!silent) _allRequests = [];
      _allHasMore = true;
    }
    if (!_allHasMore) return;
    if (!silent) {
      _allLoading = true;
      _allError = null;
      notifyListeners();
    }
    try {
      final params = <String, dynamic>{'page': _allPage};
      if (status != null) params['status'] = status;
      if (showroomId != null) params['showroom_id'] = showroomId;
      if (entryType != null) params['entry_type'] = entryType;
      if (userId != null) params['user_id'] = userId;
      if (from != null) params['from'] = from;
      if (to != null) params['to'] = to;

      final data = await _api.get('/edit-requests', queryParameters: params);
      final list = data['data'] as List? ?? [];
      final parsed = list
          .map((j) => EditRequest.fromJson(j as Map<String, dynamic>))
          .toList();
      if (silent || refresh) {
        _allRequests = parsed;
        _allPage = 2;
      } else {
        _allRequests.addAll(parsed);
        _allPage++;
      }
      _allHasMore = parsed.isNotEmpty;
    } catch (e) {
      if (!silent) _allError = e.toString();
    } finally {
      if (!silent) _allLoading = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------
  // Admin: pending count
  // -------------------------------------------------------
  Future<void> fetchPendingCount() async {
    try {
      final data = await _api.get('/edit-requests/pending-count');
      _pendingCount = (data['count'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  // -------------------------------------------------------
  // Admin: approve
  // -------------------------------------------------------
  Future<EditRequest> approveRequest(int id, {String? adminRemarks}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final data = await _api.put('/edit-requests/$id/approve', data: {
        'admin_remarks': adminRemarks ?? '',
      });
      final updated = EditRequest.fromJson(data as Map<String, dynamic>);
      _replaceInAllRequests(updated);
      if (_pendingCount > 0) _pendingCount--;
      return updated;
    } finally {
      _isSubmitting = false;
      notifyListeners();
      _eventBus.notifyChange();
    }
  }

  // -------------------------------------------------------
  // Admin: reject
  // -------------------------------------------------------
  Future<EditRequest> rejectRequest(int id,
      {required String adminRemarks}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final data = await _api.put('/edit-requests/$id/reject', data: {
        'admin_remarks': adminRemarks,
      });
      final updated = EditRequest.fromJson(data as Map<String, dynamic>);
      _replaceInAllRequests(updated);
      if (_pendingCount > 0) _pendingCount--;
      return updated;
    } finally {
      _isSubmitting = false;
      notifyListeners();
      _eventBus.notifyChange();
    }
  }

  void _replaceInAllRequests(EditRequest updated) {
    final idx = _allRequests.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _allRequests[idx] = updated;
    }
  }
}
