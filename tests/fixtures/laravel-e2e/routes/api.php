<?php

use App\Http\Controllers\Api\Demo\ShowDemoController;
use Illuminate\Support\Facades\Route;

Route::get('demos/{id}', ShowDemoController::class)->whereNumber('id');
