# Money Manager — Flutter Frontend

A Flutter mobile application for multi-showroom daily sales tracking. Staff members log daily cash and card entries; admins manage showrooms, staff, card accounts, adjustments, self-transactions, and generate reports.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart ≥ 3.0) |
| State Management | Provider 6.x |
| HTTP Client | Dio 5.x |
| Secure Storage | flutter_secure_storage 9.x |
| Fonts | Google Fonts (Poppins + Inter) |
| Connectivity | connectivity_plus 5.x |
| Animations | animations 2.x |
| Shimmer Loading | shimmer 3.x |
| File Opening | open_file 3.x |

---

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart                        # App entry point, MultiProvider setup, offline banner
│   ├── config/
│   │   ├── app_config.dart              # Base URL, timeouts, constants
│   │   ├── routes.dart                  # Named route constants
│   │   └── theme.dart                   # AppColors, text styles, ThemeData
│   ├── models/
│   │   ├── user.dart
│   │   ├── showroom.dart
│   │   ├── card_account.dart
│   │   ├── daily_cash_entry.dart
│   │   ├── daily_card_entry.dart
│   │   ├── self_transaction.dart
│   │   ├── admin_cash_adjustment.dart
│   │   ├── admin_card_adjustment.dart
│   │   ├── audit_log.dart
│   │   └── setting.dart
│   ├── services/
│   │   ├── api_service.dart             # Dio client, token injection, error handling
│   │   ├── auth_service.dart            # Login, logout, forgot/reset password
│   │   ├── storage_service.dart         # Secure token & user storage (static methods)
│   │   └── connectivity_service.dart    # Network connectivity stream
│   ├── providers/
│   │   ├── auth_provider.dart           # Auth state, login, logout, forceLogout
│   │   ├── showroom_provider.dart       # Showroom CRUD
│   │   ├── card_account_provider.dart   # Card account CRUD, my/all accounts
│   │   ├── cash_entry_provider.dart     # Cash entries, history, adjustments
│   │   ├── card_entry_provider.dart     # Card entries, history, adjustments
│   │   ├── self_transaction_provider.dart
│   │   ├── staff_provider.dart          # Staff CRUD
│   │   ├── report_provider.dart         # Report generation (PDF download)
│   │   ├── settings_provider.dart       # App settings CRUD
│   │   └── audit_log_provider.dart      # Audit log pagination
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   └── reset_password_screen.dart
│   │   ├── common/
│   │   │   └── splash_screen.dart       # Auth check + redirect
│   │   ├── staff/
│   │   │   ├── staff_dashboard_screen.dart
│   │   │   ├── cash_entry_screen.dart
│   │   │   ├── card_entry_screen.dart
│   │   │   ├── staff_history_screen.dart
│   │   │   └── staff_profile_screen.dart
│   │   └── admin/
│   │       ├── admin_dashboard_screen.dart
│   │       ├── showroom_list_screen.dart
│   │       ├── showroom_detail_screen.dart
│   │       ├── showroom_form_screen.dart
│   │       ├── card_account_list_screen.dart
│   │       ├── card_account_form_screen.dart
│   │       ├── staff_list_screen.dart
│   │       ├── staff_form_screen.dart
│   │       ├── cash_entries_admin_screen.dart
│   │       ├── card_entries_admin_screen.dart
│   │       ├── cash_adjustment_screen.dart
│   │       ├── card_adjustment_screen.dart
│   │       ├── self_transaction_list_screen.dart
│   │       ├── self_transaction_form_screen.dart
│   │       ├── reports_screen.dart
│   │       ├── audit_log_screen.dart
│   │       └── settings_screen.dart
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── app_button.dart          # Primary/secondary button
│   │   │   ├── app_card.dart            # Elevated card wrapper
│   │   │   ├── app_text_field.dart      # AppTextField + AmountTextField
│   │   │   ├── amount_display.dart      # Formatted currency display
│   │   │   ├── date_range_picker.dart   # pickDate() helper
│   │   │   ├── empty_state.dart         # Empty list placeholder
│   │   │   ├── error_state.dart         # Error with retry button
│   │   │   ├── shimmer_loading.dart     # Skeleton loading list
│   │   │   └── stat_card.dart           # Dashboard stat tile
│   │   ├── admin/
│   │   │   ├── adjustment_tile.dart
│   │   │   ├── entry_list_tile.dart
│   │   │   ├── filter_bottom_sheet.dart
│   │   │   ├── self_transaction_tile.dart
│   │   │   └── showroom_summary_card.dart
│   │   └── staff/
│   │       ├── cash_entry_card.dart
│   │       └── card_entry_card.dart
│   └── utils/
│       ├── constants.dart
│       ├── formatters.dart              # date, currency, relative time
│       └── validators.dart             # required, email, password, positiveAmount
└── test/
    └── widget_test.dart
```

---

## Features

### Authentication
- Email/password login with JWT token stored in secure storage
- Forgot password — sends OTP/reset link to email
- Reset password with token
- Auto-login on app start (token persisted across sessions)
- Force logout on 401 Unauthorized responses

### Role-Based Navigation
- **Staff** role → Staff dashboard and entry screens
- **Admin** role → Full admin panel
- Splash screen checks stored token and redirects accordingly

### Offline Banner
- Real-time connectivity monitoring via `connectivity_plus`
- A red banner slides in at the top when the device goes offline

---

### Staff Features

| Screen | Description |
|---|---|
| Dashboard | Today's cash/card entry summary, quick-add buttons, recent entries |
| Cash Entry | Submit or edit a daily cash entry (date picker, amount, notes) |
| Card Entry | Submit or edit a daily card entry with card account selector |
| History | Paginated view of own cash and card entries with pull-to-refresh |
| Profile | View profile info and logout |

---

### Admin Features

| Screen | Description |
|---|---|
| Dashboard | Overview of today's totals across all showrooms |
| Showrooms | List, create, edit, delete showrooms |
| Showroom Detail | Per-showroom card accounts, recent cash/card entries |
| Card Accounts | List and manage card accounts per showroom |
| Staff | List, create, edit, deactivate staff members |
| Cash Entries | Paginated list of all cash entries with date/showroom filters |
| Card Entries | Paginated list of all card entries with date/showroom filters |
| Cash Adjustments | Create adjustment entries against cash records |
| Card Adjustments | Create adjustment entries against card records |
| Self Transactions | Inter-account fund transfers — list and create |
| Reports | Generate and download PDF reports (Daily Summary, Showroom, Card Statement, Self Transactions, Adjustments) |
| Audit Logs | Paginated audit trail with search and filters |
| Settings | View and edit application settings |

---

## API Configuration

The app connects to the Laravel backend. URLs are resolved per platform in `lib/config/app_config.dart`:

```dart
// Android emulator → host machine localhost
http://10.0.2.2:8000/api

// iOS simulator
http://localhost:8000/api
```

To point at a real device or staging server, update `AppConfig.baseUrl`.

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0 (`flutter --version`)
- Android Studio / Xcode for emulator/simulator
- Laravel backend running on port 8000

### Install Dependencies
```bash
cd frontend
flutter pub get
```

### Run on Android Emulator
```bash
flutter run
```

### Run on iOS Simulator
```bash
flutter run -d iPhone
```

### Build Release APK
```bash
flutter build apk --release
```

### Build Release iOS
```bash
flutter build ios --release
```

---

## State Management

All state is managed with the **Provider** pattern. `main.dart` sets up a `MultiProvider` at the root that exposes:

- `AuthProvider` — authentication state and current user
- `ShowroomProvider` — showroom list and CRUD operations
- `CardAccountProvider` — card accounts (per-showroom and all)
- `CashEntryProvider` — cash entries and adjustments
- `CardEntryProvider` — card entries and adjustments
- `SelfTransactionProvider`
- `StaffProvider`
- `ReportProvider`
- `SettingsProvider`
- `AuditLogProvider`

---

## Services

| Service | Responsibility |
|---|---|
| `ApiService` | Configures Dio, adds `Authorization: Bearer` header on every request, handles 401 auto-logout, wraps errors into typed exceptions |
| `AuthService` | Login, logout, forgot password, reset password — delegates to `ApiService` |
| `StorageService` | Static helpers wrapping `flutter_secure_storage` — read/write/delete token and user JSON |
| `ConnectivityService` | Exposes a `Stream<ConnectivityResult>` and an async `isConnected()` check |

---

## Models

| Model | Key Fields |
|---|---|
| `User` | id, name, email, role (`admin`/`staff`), showroomId |
| `Showroom` | id, name, location |
| `CardAccount` | id, showroomId, bankName, lastFour, isActive |
| `DailyCashEntry` | id, showroomId, userId, entryDate, cashAmount, isLocked |
| `DailyCardEntry` | id, showroomId, userId, cardAccountId, bankName, lastFour, entryDate, amount, isLocked |
| `SelfTransaction` | id, fromCardAccountId, toCardAccountId, fromBankName, fromLastFour, toBankName, toLastFour, amount |
| `AdminCashAdjustment` | id, showroomId, adjustedAmount, reason, createdAt |
| `AdminCardAdjustment` | id, cardAccountId, adjustedAmount, reason, createdAt |
| `AuditLog` | id, userId, action, model, modelId, createdAt |
| `Setting` | id, key, value, description |

---

## Utilities

- **`Formatters`** — `date(String)`, `currency(double)`, `relativeTime(String)` using `intl`
- **`Validators`** — `required`, `email`, `password`, `confirmPassword`, `positiveAmount` — all return `String?` for use with `FormField.validator`
- **`AppColors`** — `primary`, `accent`, `success`, `error`, `textSecondary` defined in `theme.dart`

---

## Android Configuration

- Package: `com.moneymanager`
- Min SDK: 21
- Target SDK: 34
- Internet permission declared in `AndroidManifest.xml`
- Cleartext HTTP traffic allowed for emulator development (localhost)



Admin	admin@admin.com	 password
Staff (Downtown)	staff.downtown@example.com	 password
Staff (Northside)	staff.northside@example.com	 password
Staff (Eastside)	staff.eastside@example.com	password

Backend:
cd "/Users/lisura/Desktop/Money Manager/backend" && php artisan serve --host=0.0.0.0 --port=8000


# 1. Launch the Android emulator
/opt/homebrew/bin/flutter emulators --launch gimbal_pixel

# 2. Wait ~15 seconds for it to boot, then run the app
cd "/Users/lisura/Desktop/Money Manager/frontend" && flutter run -d emulator-5554




# 1. Boot simulator (if not already running)
xcrun simctl boot 3B088CFD-27B0-45A7-A06B-6BCE421FDDA6 && open -a Simulator

# 2. Run the app (wrapper auto-fixes iCloud build symlink)
cd "/Users/lisura/Desktop/Money Manager/frontend" && ./flutter_run.sh run -d "3B088CFD-27B0-45A7-A06B-6BCE421FDDA6"