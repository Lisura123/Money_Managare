import 'dart:async';
import 'package:flutter/foundation.dart';
import '../events/financial_event_bus.dart';
import '../models/dashboard_summary.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api;
  final FinancialEventBus _eventBus;

  DashboardSummary? _summary;
  bool _isLoading = false;
  bool _needsRefresh = false;
  bool _initialized = false;
  bool _isActive = false;
  bool _isFetching = false; // re-entrance guard
  String? _error;
  DateTime? _lastFetchedAt;
  String? _previousServerDate;

  // Midnight notification: set to true when server_date changes after a fetch
  bool _newDayDetected = false;

  Timer? _midnightTimer;
  Timer? _periodicTimer;

  DashboardProvider(this._api, this._eventBus);

  // -------------------------------------------------------
  // Getters
  // -------------------------------------------------------
  DashboardSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  bool get newDayDetected => _newDayDetected;
  String? get error => _error;
  DateTime? get lastFetchedAt => _lastFetchedAt;

  bool get isDataStale {
    if (_lastFetchedAt == null) return false;
    return DateTime.now().difference(_lastFetchedAt!).inMinutes >= 5;
  }

  // -------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------

  /// Call once from the admin dashboard's initState().
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _eventBus.addListener(_onFinancialChange);
    _scheduleMidnightReset();
    _startPeriodicRefresh();
    fetch();
  }

  /// Called when the admin dashboard moves to foreground/background.
  void setActive(bool active) {
    _isActive = active;
    if (active && _needsRefresh) {
      fetch(silent: true);
    }
  }

  void clearNewDayNotification() {
    _newDayDetected = false;
    notifyListeners();
  }

  // -------------------------------------------------------
  // Data fetching
  // -------------------------------------------------------

  Future<void> fetch({bool silent = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final data = await _api.get('/admin/dashboard-summary');
      final fetched = DashboardSummary.fromJson(data as Map<String, dynamic>);

      // Detect new day
      if (_previousServerDate != null &&
          _previousServerDate != fetched.serverDate) {
        _newDayDetected = true;
      }
      _previousServerDate = fetched.serverDate;
      _summary = fetched;
      _lastFetchedAt = DateTime.now();
      _needsRefresh = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (!silent) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      }
      // Silent errors are deliberately swallowed (e.g., staff context 403)
    } finally {
      _isFetching = false;
    }
  }

  // -------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------

  void _onFinancialChange() {
    _needsRefresh = true;
    if (_isActive) {
      fetch(silent: true);
    }
  }

  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);

    _midnightTimer = Timer(duration, () {
      _needsRefresh = true;
      fetch(); // visible refresh at midnight
      _scheduleMidnightReset(); // reschedule for the NEXT midnight
    });
  }

  void _startPeriodicRefresh() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_isActive) fetch(silent: true);
    });
  }

  // -------------------------------------------------------
  // Cleanup
  // -------------------------------------------------------

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _periodicTimer?.cancel();
    if (_initialized) {
      _eventBus.removeListener(_onFinancialChange);
    }
    super.dispose();
  }
}
