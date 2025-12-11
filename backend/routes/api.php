<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\AdminUserController;
use App\Http\Controllers\API\ViolationController;
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
// AUTH
// =====================
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);

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
// (tickets + enforcer stats + admin APIs)
// =====================
Route::middleware(['auth:sanctum'])->group(function () {

    // Enforcer: create tickets
    Route::post('tickets', [TicketController::class, 'store']);

    // Enforcer: dashboard stats for TODAY
    Route::get('enforcer/stats/today', [EnforcerStatsController::class, 'today']);

    // Admin users
    Route::get('admin/users', [AdminUserController::class, 'index']);
    Route::get('admin/users/{id}', [AdminUserController::class, 'show']);
    Route::patch('admin/users/{id}', [AdminUserController::class, 'update']);
    Route::post('admin/users/{id}/reset-password', [AdminUserController::class, 'resetPassword']);
    Route::delete('admin/users/{id}', [AdminUserController::class, 'destroy']);

    // Admin violations
    Route::get('admin/violations', [ViolationController::class, 'adminIndex']);
    Route::post('admin/violations', [ViolationController::class, 'store']);
    Route::put('admin/violations/{violation}', [ViolationController::class, 'update']);
    Route::patch('admin/violations/{violation}', [ViolationController::class, 'update']);

    // Admin payments
    Route::get('admin/payments', [AdminPaymentController::class, 'index']);

    // Clerk payments
    Route::get('clerk/payments/ticket-lookup', [ClerkPaymentController::class, 'lookupTicket']);
    Route::get('clerk/payments/unpaid', [ClerkPaymentController::class, 'recentUnpaid']);
    Route::get('clerk/payments/history', [ClerkPaymentController::class, 'recentPaid']);
    Route::post('clerk/payments', [ClerkPaymentController::class, 'store']);
    Route::post('clerk/payments/{payment}/void', [ClerkPaymentController::class, 'voidPayment']);

    // Admin reports
    Route::get('admin/reports/overview', [AdminReportsController::class, 'overview']);
    Route::get('admin/reports/citations', [AdminReportsController::class, 'citations']);

    // Admin stats
    Route::get('admin/stats', AdminStatsController::class);
});
