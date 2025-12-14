<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\AdminUserController;
use App\Http\Controllers\API\ViolationController; // Fixed import
use App\Http\Controllers\API\AdminNotificationController; // [NEW]
use App\Http\Controllers\API\TicketController;
use App\Http\Controllers\API\EnforcerStatsController;
use App\Http\Controllers\ClerkPaymentController;
use App\Http\Controllers\API\AdminPaymentController;
use App\Http\Controllers\API\AdminReportsController;
use App\Http\Controllers\API\AdminStatsController;

Route::get('/ping', function () {
    return response()->json([
        'pong' => true,
        'env' => app()->environment(),
    ]);
});

// =====================
// AUTH (Public)
// =====================
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('forgot-password', [AuthController::class, 'requestPasswordReset']); // Public

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('me', [AuthController::class, 'me']);
        Route::post('logout', [AuthController::class, 'logout']);
    });
});

// =====================
// PUBLIC LOOKUP ROUTES
// =====================
Route::get('violation-types', [ViolationController::class, 'types']);
Route::get('violations', [ViolationController::class, 'index']);

// =====================
// PROTECTED ROUTES
// =====================
Route::middleware(['auth:sanctum'])->group(function () {

    // Enforcer: create tickets
    Route::post('tickets', [TicketController::class, 'store']);

    // Enforcer: dashboard stats for TODAY
    Route::get('enforcer/stats/today', [EnforcerStatsController::class, 'today']);

    // Clerk payments
    Route::get('clerk/payments/ticket-lookup', [ClerkPaymentController::class, 'lookupTicket']);
    Route::get('clerk/payments/unpaid', [ClerkPaymentController::class, 'recentUnpaid']);
    Route::get('clerk/payments/history', [ClerkPaymentController::class, 'recentPaid']);
    Route::post('clerk/payments', [ClerkPaymentController::class, 'store']);
    Route::post('clerk/payments/{payment}/void', [ClerkPaymentController::class, 'voidPayment']);

    // =====================
    // ADMIN ROUTES
    // =====================
    Route::prefix('admin')->group(function () {

        // Notifications
        Route::get('notifications/password-resets', [AdminNotificationController::class, 'index']);
        Route::post('notifications/password-resets/{id}/resolve', [AdminNotificationController::class, 'resolve']);

        // Users
        Route::get('users', [AdminUserController::class, 'index']);
        Route::get('users/{id}', [AdminUserController::class, 'show']);
        Route::patch('users/{id}', [AdminUserController::class, 'update']);
        Route::post('users/{id}/set-password', [AdminUserController::class, 'setPassword']);
        Route::delete('users/{id}', [AdminUserController::class, 'destroy']);

        // Violations
        // Route::get('violations', [ViolationController::class, 'adminIndex']); // If needed
        Route::post('violations', [ViolationController::class, 'store']);
        Route::patch('violations/{violation}', [ViolationController::class, 'update']);
        Route::delete('violations/{violation}', [ViolationController::class, 'destroy']);

        // Payments
        Route::get('payments', [AdminPaymentController::class, 'index']);

        // Reports
        Route::get('reports/overview', [AdminReportsController::class, 'overview']);
        Route::get('reports/citations', [AdminReportsController::class, 'citations']);

        // Stats
        Route::get('stats', AdminStatsController::class);
    });
});
