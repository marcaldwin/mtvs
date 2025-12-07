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
    });
