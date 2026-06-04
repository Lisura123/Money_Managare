<?php

use App\Http\Controllers\Api\AdminCardAdjustmentController;
use App\Http\Controllers\Api\AdminCashAdjustmentController;
use App\Http\Controllers\Api\AuditLogController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CardAccountController;
use App\Http\Controllers\Api\CashTransactionController;
use App\Http\Controllers\Api\DailyCardEntryController;
use App\Http\Controllers\Api\DailyCashEntryController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EditRequestController;
use App\Http\Controllers\Api\ExternalAccountController;
use App\Http\Controllers\Api\ShowroomCashController;
use App\Http\Controllers\Api\SelfTransactionController;
use App\Http\Controllers\Api\SettingController;
use App\Http\Controllers\Api\ShowroomController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\StaffController;
use App\Http\Controllers\Api\StaffStatusController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Public Routes
|--------------------------------------------------------------------------
*/
Route::post('/login', [AuthController::class, 'login']);
Route::match(['GET', 'HEAD'], '/login', fn() => response()->noContent());
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);

/*
|--------------------------------------------------------------------------
| Authenticated Routes (any logged-in user)
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);

    /*
    |----------------------------------------------------------------------
    | Staff Routes
    |----------------------------------------------------------------------
    */
    Route::middleware('staff')->group(function () {
        // Today's submission status
        Route::get('/today-status', [StaffStatusController::class, 'today']);

        // Edit window status
        Route::get('/edit-window', [SettingController::class, 'editWindow']);

        // Cash entries
        Route::post('/cash-entries', [DailyCashEntryController::class, 'store']);
        Route::get('/cash-entries/my-history', [DailyCashEntryController::class, 'myHistory']);

        // Card entries
        Route::post('/card-entries', [DailyCardEntryController::class, 'store']);
        Route::get('/card-entries/my-history', [DailyCardEntryController::class, 'myHistory']);

        // My showroom card accounts
        Route::get('/my-card-accounts', [CardAccountController::class, 'myShowroomAccounts']);

        // Edit requests (staff)
        Route::post('/edit-requests', [EditRequestController::class, 'store']);
        Route::get('/edit-requests/my-requests', [EditRequestController::class, 'myRequests']);
        Route::delete('/edit-requests/{editRequest}', [EditRequestController::class, 'cancel']);
    });

    /*
    |----------------------------------------------------------------------
    | Admin Routes
    |----------------------------------------------------------------------
    */
    Route::middleware('admin')->group(function () {
        // Dashboard summary + balance diagnostics
        Route::get('/admin/dashboard-summary', [DashboardController::class, 'summary']);
        Route::get('/admin/verify-balances',   [DashboardController::class, 'verifyBalances']);
        Route::post('/admin/fix-balances',     [DashboardController::class, 'fixBalances']);

        // Showrooms CRUD
        Route::apiResource('/showrooms', ShowroomController::class);

        // Card accounts per showroom
        Route::apiResource('/showrooms/{showroom}/card-accounts', CardAccountController::class);

        // All card accounts (flat list for admin pickers + iOS create/update/delete)
        Route::get('/card-accounts', [CardAccountController::class, 'adminIndex']);
        Route::post('/card-accounts', [CardAccountController::class, 'storeFlat']);
        Route::put('/card-accounts/{cardAccount}', [CardAccountController::class, 'updateFlat']);
        Route::patch('/card-accounts/{cardAccount}', [CardAccountController::class, 'updateFlat']);
        Route::delete('/card-accounts/{cardAccount}', [CardAccountController::class, 'destroyFlat']);

        // Staff management
        Route::apiResource('/staff', StaffController::class);
        Route::post('/staff/{staff}/send-reset-email', [StaffController::class, 'sendResetEmail']);
        Route::patch('/staff/{staff}/toggle-active', [StaffController::class, 'toggleActive']);

        // Admin user management
        Route::get('/admins', [AdminController::class, 'index']);
        Route::post('/admins', [AdminController::class, 'store']);
        Route::put('/admins/{admin}', [AdminController::class, 'update']);
        Route::delete('/admins/{admin}', [AdminController::class, 'destroy']);
        Route::post('/admins/bulk-delete', [AdminController::class, 'bulkDestroy']);
        Route::patch('/admins/{admin}/toggle-active', [AdminController::class, 'toggleActive']);

        // All cash entries with filters
        Route::get('/cash-entries', [DailyCashEntryController::class, 'index']);
        Route::put('/cash-entries/{dailyCashEntry}', [DailyCashEntryController::class, 'update']);
        Route::delete('/cash-entries/{dailyCashEntry}', [DailyCashEntryController::class, 'destroy']);
        Route::post('/cash-entries/bulk-delete', [DailyCashEntryController::class, 'bulkDestroy']);
        Route::get('/cash-summary', [DailyCashEntryController::class, 'summary']);

        // Cash adjustments
        Route::get('/cash-entries/{dailyCashEntry}/adjustments', [AdminCashAdjustmentController::class, 'index']);
        Route::post('/cash-entries/{dailyCashEntry}/adjustments', [AdminCashAdjustmentController::class, 'store']);
        Route::get('/adjustments/cash', [AdminCashAdjustmentController::class, 'all']);
        Route::post('/adjustments/cash', [AdminCashAdjustmentController::class, 'storeForShowroom']);
        Route::delete('/adjustments/cash/{adminCashAdjustment}', [AdminCashAdjustmentController::class, 'destroy']);
        Route::post('/adjustments/cash/bulk-delete', [AdminCashAdjustmentController::class, 'bulkDestroy']);

        // All card entries with filters
        Route::get('/card-entries', [DailyCardEntryController::class, 'index']);
        Route::put('/card-entries/{dailyCardEntry}', [DailyCardEntryController::class, 'update']);
        Route::delete('/card-entries/{dailyCardEntry}', [DailyCardEntryController::class, 'destroy']);
        Route::post('/card-entries/bulk-delete', [DailyCardEntryController::class, 'bulkDestroy']);

        // Card adjustments
        Route::get('/card-entries/{dailyCardEntry}/adjustments', [AdminCardAdjustmentController::class, 'index']);
        Route::post('/card-entries/{dailyCardEntry}/adjustments', [AdminCardAdjustmentController::class, 'store']);
        Route::get('/adjustments/card', [AdminCardAdjustmentController::class, 'all']);
        Route::post('/adjustments/card', [AdminCardAdjustmentController::class, 'storeForAccount']);
        Route::delete('/adjustments/card/{adminCardAdjustment}', [AdminCardAdjustmentController::class, 'destroy']);
        Route::post('/adjustments/card/bulk-delete', [AdminCardAdjustmentController::class, 'bulkDestroy']);

        // Self transactions
        Route::get('/self-transactions', [SelfTransactionController::class, 'index']);
        Route::post('/self-transactions', [SelfTransactionController::class, 'store']);
        Route::delete('/self-transactions/{selfTransaction}', [SelfTransactionController::class, 'destroy']);
        Route::post('/self-transactions/bulk-delete', [SelfTransactionController::class, 'bulkDestroy']);

        // External accounts
        Route::get('/external-accounts', [ExternalAccountController::class, 'index']);
        Route::get('/showroom-cash-balances', [ShowroomCashController::class, 'index']);

        // Cash transactions
        Route::get('/cash-transactions', [CashTransactionController::class, 'index']);
        Route::post('/cash-transactions', [CashTransactionController::class, 'store']);
        Route::delete('/cash-transactions/{cashTransaction}', [CashTransactionController::class, 'destroy']);
        Route::post('/cash-transactions/bulk-delete', [CashTransactionController::class, 'bulkDestroy']);

        // Settings
        Route::get('/settings', [SettingController::class, 'index']);
        Route::put('/settings/{setting}', [SettingController::class, 'update']);

        // Audit logs
        Route::get('/audit-logs', [AuditLogController::class, 'index']);
        Route::delete('/audit-logs/{auditLog}', [AuditLogController::class, 'destroy']);
        Route::post('/audit-logs/bulk-delete', [AuditLogController::class, 'bulkDestroy']);

        // Edit requests (admin)
        Route::get('/edit-requests/pending-count', [EditRequestController::class, 'pendingCount']);
        Route::get('/edit-requests', [EditRequestController::class, 'index']);
        Route::get('/edit-requests/{editRequest}', [EditRequestController::class, 'show']);
        Route::put('/edit-requests/{editRequest}/approve', [EditRequestController::class, 'approve']);
        Route::put('/edit-requests/{editRequest}/reject', [EditRequestController::class, 'reject']);

        // PDF Reports
        Route::prefix('reports/pdf')->group(function () {
            Route::get('/daily-summary',     [ReportController::class, 'dailySummary']);
            Route::get('/showroom',          [ReportController::class, 'showroom']);
            Route::get('/card-statement',    [ReportController::class, 'cardStatement']);
            Route::get('/self-transactions', [ReportController::class, 'selfTransactions']);
            Route::get('/adjustments',       [ReportController::class, 'adjustments']);
        });
    });
});
