import 'package:flutter/foundation.dart';

/// A simple event bus that broadcasts financial mutation events.
///
/// Any provider that mutates financial data (entries, adjustments, transfers)
/// should call [notifyChange()] after a successful mutation.
/// The [DashboardProvider] listens to this bus and automatically refreshes.
class FinancialEventBus extends ChangeNotifier {
  void notifyChange() => notifyListeners();
}
