# Money Manager — Laravel Backend API

A multi-showroom daily sales tracker with role-based access, card account management, PDF reporting, audit logging, and admin controls.

---

## Requirements

- PHP 8.2+
- Composer
- XAMPP (MySQL 5.7+ / MariaDB 10.4+)

---

## Packages Used

| Package | Purpose |
|---------|---------|
| `laravel/sanctum` | API token authentication |
| `barryvdh/laravel-dompdf` | PDF report generation |

---

## Setup Instructions (XAMPP)

### 1. Start XAMPP

Open XAMPP Control Panel and start both **Apache** and **MySQL**.

### 2. Create the Database

Open `http://localhost/phpmyadmin` and run:

```sql
CREATE DATABASE money_manager CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Or via the XAMPP MySQL shell:

```bash
/Applications/XAMPP/xamppfiles/bin/mysql -u root -e "CREATE DATABASE money_manager CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

### 3. Install Dependencies

```bash
cd backend
composer install
```

### 4. Configure Environment

```bash
cp .env.example .env
php artisan key:generate
```

Edit `.env` and confirm these values match your XAMPP setup:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=money_manager
DB_USERNAME=root
DB_PASSWORD=
```

> If your XAMPP MySQL has a root password, set it in `DB_PASSWORD`.

### 5. Run Migrations & Seed

```bash
php artisan migrate:fresh --seed
```

Seeds the database with:
- 3 showrooms (Downtown, Northside, Eastside)
- 1 admin user: `admin@admin.com` / `password`
- 3 staff users (one per showroom), all with password `password`
- 2 card accounts per showroom with sample balances
- 2 weeks of daily cash and card entries

### 6. Start the API Server

```bash
php artisan serve
```

API base URL: `http://localhost:8000/api`

---

## Seeded Users

| Role  | Email                        | Password |
|-------|------------------------------|----------|
| Admin | admin@admin.com              | password |
| Staff | staff.downtown@example.com   | password |
| Staff | staff.northside@example.com  | password |
| Staff | staff.eastside@example.com   | password |

---

## Authentication

All authenticated requests require the header:

```
Authorization: Bearer {token}
```

The token is returned from `POST /api/login`.

---

## API Routes Reference

All routes are prefixed with `/api`.

### Public Routes

| Method | Endpoint           | Description                              |
|--------|--------------------|------------------------------------------|
| POST   | `/login`           | Login — returns Sanctum bearer token     |
| POST   | `/forgot-password` | Send 6-digit reset code to email         |
| POST   | `/reset-password`  | Reset password using the 6-digit code    |

> **Development note:** `forgot-password` returns `dev_code` in the JSON response for easy testing. Remove it before going to production and configure Laravel Mail.

### Authenticated (all logged-in users)

| Method | Endpoint  | Description |
|--------|-----------|-------------|
| POST   | `/logout` | Revoke current token |

---

### Staff Routes

> Requires `auth:sanctum` + `staff` middleware.

| Method | Endpoint                    | Description                                  |
|--------|-----------------------------|----------------------------------------------|
| POST   | `/cash-entries`             | Submit a daily cash entry                    |
| GET    | `/cash-entries/my-history`  | Own cash entry history (paginated)           |
| POST   | `/card-entries`             | Submit a daily card entry (updates balance)  |
| GET    | `/card-entries/my-history`  | Own card entry history (paginated)           |
| GET    | `/my-card-accounts`         | Active card accounts in own showroom         |

---

### Admin Routes

> Requires `auth:sanctum` + `admin` middleware.

#### Showrooms

| Method    | Endpoint            | Description    |
|-----------|---------------------|----------------|
| GET       | `/showrooms`        | List all       |
| POST      | `/showrooms`        | Create         |
| GET       | `/showrooms/{id}`   | Get one        |
| PUT/PATCH | `/showrooms/{id}`   | Update         |
| DELETE    | `/showrooms/{id}`   | Delete         |

#### Card Accounts

| Method    | Endpoint                                    | Description |
|-----------|---------------------------------------------|-------------|
| GET       | `/showrooms/{id}/card-accounts`             | List        |
| POST      | `/showrooms/{id}/card-accounts`             | Create      |
| GET       | `/showrooms/{id}/card-accounts/{cid}`       | Get one     |
| PUT/PATCH | `/showrooms/{id}/card-accounts/{cid}`       | Update      |
| DELETE    | `/showrooms/{id}/card-accounts/{cid}`       | Delete      |

#### Staff Management

| Method    | Endpoint       | Description                    |
|-----------|----------------|--------------------------------|
| GET       | `/staff`       | List all staff                 |
| POST      | `/staff`       | Create staff user              |
| GET       | `/staff/{id}`  | Get one                        |
| PUT/PATCH | `/staff/{id}`  | Update (name, email, showroom, active status) |
| DELETE    | `/staff/{id}`  | Delete                         |

#### Cash Entries (Admin view)

| Method | Endpoint                                        | Description                             |
|--------|-------------------------------------------------|-----------------------------------------|
| GET    | `/cash-entries?showroom_id=&date=&from=&to=`    | All entries with filters (paginated)    |
| PUT    | `/cash-entries/{id}`                            | Update entry (bypasses lock for admin)  |
| POST   | `/cash-entries/lock-old`                        | Lock entries older than `lock_hours`    |
| GET    | `/cash-entries/{id}/adjustments`                | List adjustments on an entry            |
| POST   | `/cash-entries/{id}/adjustments`                | Create adjustment (separate record)     |

#### Card Entries (Admin view)

| Method | Endpoint                                        | Description                             |
|--------|-------------------------------------------------|-----------------------------------------|
| GET    | `/card-entries?showroom_id=&date=&from=&to=`    | All entries with filters (paginated)    |
| PUT    | `/card-entries/{id}`                            | Update entry (bypasses lock for admin)  |
| POST   | `/card-entries/lock-old`                        | Lock entries older than `lock_hours`    |
| GET    | `/card-entries/{id}/adjustments`                | List adjustments on an entry            |
| POST   | `/card-entries/{id}/adjustments`                | Create adjustment (separate record)     |

#### Self-Transactions

| Method | Endpoint              | Description                                        |
|--------|-----------------------|----------------------------------------------------|
| GET    | `/self-transactions`  | List all (paginated)                               |
| POST   | `/self-transactions`  | Transfer funds between card accounts (atomic)      |

#### Settings

| Method | Endpoint            | Description                           |
|--------|---------------------|---------------------------------------|
| GET    | `/settings`         | List all settings                     |
| PUT    | `/settings/{id}`    | Update a setting value (e.g. `lock_hours`) |

#### Audit Logs

| Method | Endpoint                                         | Description                    |
|--------|--------------------------------------------------|--------------------------------|
| GET    | `/audit-logs?table_name=&action=&user_id=`       | List logs with filters (paginated) |

---

### PDF Report Routes

> Requires `auth:sanctum` + `admin` middleware. All endpoints return a PDF file download.

| Method | Endpoint                          | Required Query Params                          | Download Filename Example                        |
|--------|-----------------------------------|------------------------------------------------|--------------------------------------------------|
| GET    | `/reports/pdf/daily-summary`      | `date`                                         | `daily-summary-2026-04-11.pdf`                   |
| GET    | `/reports/pdf/showroom`           | `showroom_id`, `from`, `to`                    | `showroom-downtown-showroom-2026-04-01-to-2026-04-11.pdf` |
| GET    | `/reports/pdf/card-statement`     | `card_account_id`, `from`, `to`                | `card-statement-first-national-bank-1234-...pdf` |
| GET    | `/reports/pdf/self-transactions`  | `from`, `to`                                   | `self-transactions-2026-04-01-to-2026-04-11.pdf` |
| GET    | `/reports/pdf/adjustments`        | `from`, `to`                                   | `adjustments-2026-04-01-to-2026-04-11.pdf`       |

#### Report Descriptions

**Daily Summary** — For a single date, shows all showrooms with their cash entry total, card entry totals broken down by card account, and a grand total across all showrooms. Page break between showrooms.

**Showroom Report** — Landscape PDF. For a showroom and date range, shows all daily cash entries, daily card entries (with card account last-4 and bank name), inline admin adjustments indented under their parent entry, and running totals.

**Card Account Statement** — For a card account and date range, shows all card entries (+), admin adjustments (+/−), outgoing self-transactions (−), and incoming self-transactions (+), colour-coded with a net movement and current balance summary.

**Self-Transaction Report** — Landscape PDF. For a date range, lists every fund transfer showing source card (showroom + bank + last-4), destination card, amount, notes, admin who performed it, and timestamp.

**Adjustment Report** — For a date range, lists all admin cash adjustments and admin card adjustments grouped by showroom, with reasons, admin names, and subtotals per showroom.

#### PDF Layout Features

- Navy header with report title, date range, and generation timestamp
- Bordered tables with alternating row colours
- Subtotal rows (blue) and grand total rows (navy/white)
- Colour-coded amounts: green for credits, red for debits
- Fixed footer on every page: "Generated by Money Manager" + page number

---

## Key Design Notes

- **Lock system**: The `lock_hours` setting (default `24`) controls when entries become read-only for staff. Run `POST /cash-entries/lock-old` and `POST /card-entries/lock-old` to apply locks — schedule these with `php artisan schedule:run`.
- **Card balance**: Automatically updated inside a DB transaction when a card entry is created.
- **Self-transaction**: Uses `DB::transaction()` with `lockForUpdate()` on both card accounts to prevent race conditions.
- **Audit logging**: Model Observers on `DailyCashEntry`, `DailyCardEntry`, `CardAccount`, and `SelfTransaction` write every create/update/delete to `audit_logs`.
- **Password reset**: 6-digit code expires in 15 minutes. Remove `dev_code` from the response and wire up Laravel Mail before deploying to production.
- **Adjustments are non-destructive**: Admin adjustments create a separate record; the original staff entry is never modified.
- **PDF generation**: Uses `barryvdh/laravel-dompdf`. All templates live in `resources/views/reports/` and extend a shared layout with consistent styling.

---

## Database Tables

| Table                    | Purpose                                            |
|--------------------------|----------------------------------------------------|
| `users`                  | Admins and staff with role and showroom assignment |
| `showrooms`              | Showroom names, locations, and active status       |
| `card_accounts`          | Card accounts per showroom with live balance       |
| `daily_cash_entries`     | Staff daily cash submissions                       |
| `daily_card_entries`     | Staff daily card submissions                       |
| `admin_cash_adjustments` | Admin balance adjustments for cash entries         |
| `admin_card_adjustments` | Admin balance adjustments for card entries         |
| `self_transactions`      | Card-to-card fund transfers between showrooms      |
| `password_resets`        | 6-digit reset codes with 15-minute expiry          |
| `audit_logs`             | Full audit trail: action, table, old/new values    |
| `settings`               | Key-value config (e.g. `lock_hours`)               |

---

## Project Structure

```
backend/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   └── Api/
│   │   │       ├── AuthController.php
│   │   │       ├── ShowroomController.php
│   │   │       ├── CardAccountController.php
│   │   │       ├── StaffController.php
│   │   │       ├── DailyCashEntryController.php
│   │   │       ├── DailyCardEntryController.php
│   │   │       ├── AdminCashAdjustmentController.php
│   │   │       ├── AdminCardAdjustmentController.php
│   │   │       ├── SelfTransactionController.php
│   │   │       ├── SettingController.php
│   │   │       ├── AuditLogController.php
│   │   │       └── ReportController.php         ← PDF exports
│   │   ├── Middleware/
│   │   │   ├── AdminMiddleware.php
│   │   │   └── StaffMiddleware.php
│   │   ├── Requests/                            ← Form Request validation
│   │   │   ├── LoginRequest.php
│   │   │   ├── ForgotPasswordRequest.php
│   │   │   ├── ResetPasswordRequest.php
│   │   │   ├── CardAccountRequest.php
│   │   │   ├── DailyCashEntryRequest.php
│   │   │   ├── DailyCardEntryRequest.php
│   │   │   ├── AdminCashAdjustmentRequest.php
│   │   │   ├── AdminCardAdjustmentRequest.php
│   │   │   ├── SelfTransactionRequest.php
│   │   │   ├── StaffRequest.php
│   │   │   ├── SettingRequest.php
│   │   │   ├── DailySummaryReportRequest.php
│   │   │   ├── ShowroomReportRequest.php
│   │   │   ├── CardStatementReportRequest.php
│   │   │   └── DateRangeReportRequest.php
│   │   └── Resources/                           ← API JSON Resources
│   │       ├── UserResource.php
│   │       ├── ShowroomResource.php
│   │       ├── CardAccountResource.php
│   │       ├── DailyCashEntryResource.php
│   │       ├── DailyCardEntryResource.php
│   │       ├── AdminCashAdjustmentResource.php
│   │       ├── AdminCardAdjustmentResource.php
│   │       ├── SelfTransactionResource.php
│   │       ├── AuditLogResource.php
│   │       └── SettingResource.php
│   ├── Models/
│   │   ├── User.php
│   │   ├── Showroom.php
│   │   ├── CardAccount.php
│   │   ├── DailyCashEntry.php
│   │   ├── DailyCardEntry.php
│   │   ├── AdminCashAdjustment.php
│   │   ├── AdminCardAdjustment.php
│   │   ├── SelfTransaction.php
│   │   ├── PasswordReset.php
│   │   ├── AuditLog.php
│   │   └── Setting.php
│   ├── Observers/
│   │   ├── DailyCashEntryObserver.php
│   │   ├── DailyCardEntryObserver.php
│   │   ├── CardAccountObserver.php
│   │   └── SelfTransactionObserver.php
│   └── Providers/
│       └── AppServiceProvider.php
├── bootstrap/
│   └── app.php                                  ← Routes + middleware registration
├── database/
│   ├── migrations/                              ← 13 migration files
│   └── seeders/
│       ├── DatabaseSeeder.php
│       ├── ShowroomSeeder.php
│       ├── UserSeeder.php
│       ├── CardAccountSeeder.php
│       ├── SettingsSeeder.php
│       └── DailyEntrySeeder.php
├── resources/
│   └── views/
│       └── reports/                             ← Blade PDF templates
│           ├── layout.blade.php                 ← Shared CSS + footer
│           ├── daily-summary.blade.php
│           ├── showroom.blade.php
│           ├── card-statement.blade.php
│           ├── self-transactions.blade.php
│           └── adjustments.blade.php
├── routes/
│   └── api.php                                  ← All 44 API routes
└── .env                                         ← Environment configuration
```
