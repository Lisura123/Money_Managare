class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Staff
  static const String staffHome = '/staff/home';
  static const String cashEntry = '/staff/cash-entry';
  static const String cardEntry = '/staff/card-entry';
  static const String staffHistory = '/staff/history';
  static const String staffProfile = '/staff/profile';

  // Admin
  static const String adminHome = '/admin/home';
  static const String showroomList = '/admin/showrooms';
  static const String showroomDetail = '/admin/showrooms/detail';
  static const String showroomForm = '/admin/showrooms/form';
  static const String cardAccountList = '/admin/card-accounts';
  static const String cardAccountDetail = '/admin/card-accounts/detail';
  static const String cardAccountForm = '/admin/card-accounts/form';
  static const String staffList = '/admin/staff';
  static const String staffForm = '/admin/staff/form';
  static const String cashEntriesAdmin = '/admin/cash-entries';
  static const String cardEntriesAdmin = '/admin/card-entries';
  static const String cashAdjustment = '/admin/cash-adjustment';
  static const String cardAdjustment = '/admin/card-adjustment';
  static const String selfTransactionList = '/admin/self-transactions';
  static const String selfTransactionForm = '/admin/self-transactions/form';
  static const String cashTransactionList = '/admin/cash-transactions';
  static const String cashTransactionForm = '/admin/cash-transactions/form';
  static const String reports = '/admin/reports';
  static const String auditLog = '/admin/audit-logs';
  static const String settings = '/admin/settings';

  // Edit Requests
  static const String cashEditRequest = '/staff/cash-edit-request';
  static const String cardEditRequest = '/staff/card-edit-request';
  static const String myEditRequests = '/staff/my-edit-requests';
  static const String adminEditRequests = '/admin/edit-requests';

  // Common
  static const String changePassword = '/change-password';
}
