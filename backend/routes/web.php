<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TicketPrintController;

// Default page (optional)
Route::get('/', function () {
    return view('welcome');
});

// Routes for printing citations (web view)
Route::middleware(['auth']) // or your own web middleware, or remove if no login yet
    ->prefix('tickets')
    ->name('tickets.')
    ->group(function () {
        // GET /tickets/{ticket}/print
        Route::get('{ticket}/print', [TicketPrintController::class, 'show'])
            ->name('print');
    }); // Close the group

// Temporary route to clear cache on free hosting (Uncomment if needed)
// Route::get('/clear-cache', function () {
//     \Illuminate\Support\Facades\Artisan::call('route:clear');
//     \Illuminate\Support\Facades\Artisan::call('config:clear');
//     \Illuminate\Support\Facades\Artisan::call('cache:clear');
//     return 'Routes and config cleared!';
// });


