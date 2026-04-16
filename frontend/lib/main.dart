import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart'
    show ConnectivityResult;

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/showroom_provider.dart';
import 'providers/card_account_provider.dart';
import 'providers/cash_entry_provider.dart';
import 'providers/card_entry_provider.dart';
import 'providers/self_transaction_provider.dart';
import 'providers/cash_transaction_provider.dart';
import 'providers/staff_provider.dart';
import 'providers/audit_log_provider.dart';
import 'providers/report_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/edit_request_provider.dart';
import 'events/financial_event_bus.dart';
import 'providers/dashboard_provider.dart';
import 'providers/staff_status_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/connectivity_service.dart';
import 'screens/common/splash_screen.dart';
import 'screens/common/change_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/staff/staff_dashboard_screen.dart';
import 'screens/staff/cash_entry_screen.dart';
import 'screens/staff/card_entry_screen.dart';
import 'screens/staff/staff_history_screen.dart';
import 'screens/staff/staff_profile_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/showroom_list_screen.dart';
import 'screens/admin/showroom_detail_screen.dart';
import 'screens/admin/showroom_form_screen.dart';
import 'screens/admin/card_account_list_screen.dart';
import 'screens/admin/card_account_form_screen.dart';
import 'screens/admin/card_account_detail_screen.dart';
import 'screens/admin/staff_list_screen.dart';
import 'screens/admin/staff_form_screen.dart';
import 'screens/admin/cash_entries_admin_screen.dart';
import 'screens/admin/card_entries_admin_screen.dart';
import 'screens/admin/cash_adjustment_screen.dart';
import 'screens/admin/card_adjustment_screen.dart';
import 'screens/admin/self_transaction_list_screen.dart';
import 'screens/admin/self_transaction_form_screen.dart';
import 'screens/admin/cash_transaction_list_screen.dart';
import 'screens/admin/cash_transaction_form_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/admin/audit_log_screen.dart';
import 'screens/admin/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait orientation on both platforms.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar: white icons so they are visible on the navy app bar.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0x001B2A4A), // transparent — let the AppBar paint it
    statusBarIconBrightness: Brightness.light, // Android
    statusBarBrightness: Brightness.dark, // iOS (dark = light icons)
  ));

  final storageService = StorageService();
  final apiService = ApiService();
  final authService = AuthService(apiService);

  runApp(MoneyManagerApp(
    apiService: apiService,
    authService: authService,
    storageService: storageService,
  ));
}

class MoneyManagerApp extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;
  final StorageService storageService;

  const MoneyManagerApp({
    super.key,
    required this.apiService,
    required this.authService,
    required this.storageService,
  });

  @override
  State<MoneyManagerApp> createState() => _MoneyManagerAppState();
}

class _MoneyManagerAppState extends State<MoneyManagerApp> {
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(widget.authService);
    widget.apiService.onUnauthorised = () {
      _authProvider.forceLogout();
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: widget.storageService),
        Provider<ApiService>.value(value: widget.apiService),
        Provider<AuthService>.value(value: widget.authService),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider(
            create: (c) => ShowroomProvider(c.read<ApiService>())),
        ChangeNotifierProvider<FinancialEventBus>(
            create: (_) => FinancialEventBus()),
        ChangeNotifierProvider(
            create: (c) => CardAccountProvider(
                c.read<ApiService>(), c.read<FinancialEventBus>())),
        ChangeNotifierProvider(
            create: (c) => CashEntryProvider(
                c.read<ApiService>(), c.read<FinancialEventBus>())),
        ChangeNotifierProvider(
            create: (c) => CardEntryProvider(
                c.read<ApiService>(), c.read<FinancialEventBus>())),
        ChangeNotifierProvider(
            create: (c) => SelfTransactionProvider(
                c.read<ApiService>(), c.read<FinancialEventBus>())),
        ChangeNotifierProvider(
            create: (c) => DashboardProvider(
                c.read<ApiService>(), c.read<FinancialEventBus>())),
        ChangeNotifierProvider(
            create: (c) => StaffStatusProvider(
                c.read<ApiService>(), c.read<FinancialEventBus>())),
        ChangeNotifierProvider(
            create: (c) => CashTransactionProvider(
                c.read<ApiService>(), c.read<FinancialEventBus>())),
        ChangeNotifierProvider(
            create: (c) => StaffProvider(c.read<ApiService>())),
        ChangeNotifierProvider(
            create: (c) => AuditLogProvider(c.read<ApiService>())),
        ChangeNotifierProvider(
            create: (c) => ReportProvider(c.read<ApiService>())),
        ChangeNotifierProvider(
            create: (c) => SettingsProvider(c.read<ApiService>())),
        ChangeNotifierProvider(
            create: (c) => EditRequestProvider(
                c.read<ApiService>(), c.read<FinancialEventBus>())),
      ],
      child: MaterialApp(
        title: 'Money Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
          AppRoutes.resetPassword: (_) => const ResetPasswordScreen(),
          AppRoutes.staffHome: (_) => const StaffDashboardScreen(),
          AppRoutes.cashEntry: (_) => const CashEntryScreen(),
          AppRoutes.cardEntry: (_) => const CardEntryScreen(),
          AppRoutes.staffHistory: (_) => const StaffHistoryScreen(),
          AppRoutes.staffProfile: (_) => const StaffProfileScreen(),
          AppRoutes.adminHome: (_) => const AdminDashboardScreen(),
          AppRoutes.showroomList: (_) => const ShowroomListScreen(),
          AppRoutes.showroomDetail: (_) => const ShowroomDetailScreen(),
          AppRoutes.showroomForm: (_) => const ShowroomFormScreen(),
          AppRoutes.cardAccountList: (_) => const CardAccountListScreen(),
          AppRoutes.cardAccountForm: (_) => const CardAccountFormScreen(),
          AppRoutes.cardAccountDetail: (_) => const CardAccountDetailScreen(),
          AppRoutes.staffList: (_) => const StaffListScreen(),
          AppRoutes.staffForm: (_) => const StaffFormScreen(),
          AppRoutes.cashEntriesAdmin: (_) => const CashEntriesAdminScreen(),
          AppRoutes.cardEntriesAdmin: (_) => const CardEntriesAdminScreen(),
          AppRoutes.cashAdjustment: (_) => const CashAdjustmentScreen(),
          AppRoutes.cardAdjustment: (_) => const CardAdjustmentScreen(),
          AppRoutes.selfTransactionList: (_) =>
              const SelfTransactionListScreen(),
          AppRoutes.selfTransactionForm: (_) =>
              const SelfTransactionFormScreen(),
          AppRoutes.cashTransactionList: (_) =>
              const CashTransactionListScreen(),
          AppRoutes.cashTransactionForm: (_) =>
              const CashTransactionFormScreen(),
          AppRoutes.reports: (_) => const ReportsScreen(),
          AppRoutes.auditLog: (_) => const AuditLogScreen(),
          AppRoutes.settings: (_) => const SettingsScreen(),
          AppRoutes.changePassword: (_) => const ChangePasswordScreen(),
        },
        builder: (context, child) => _OfflineBanner(child: child!),
      ),
    );
  }
}

class _OfflineBanner extends StatefulWidget {
  final Widget child;
  const _OfflineBanner({required this.child});

  @override
  State<_OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<_OfflineBanner> {
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    ConnectivityService.onConnectivityChanged.listen((result) {
      final connected = result != ConnectivityResult.none;
      if (mounted) setState(() => _isConnected = connected);
    });
    _checkInitial();
  }

  Future<void> _checkInitial() async {
    final connected = await ConnectivityService.isConnected();
    if (mounted) setState(() => _isConnected = connected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isConnected)
          Material(
            color: AppColors.error,
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('No internet connection',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
