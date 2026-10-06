<?php

declare(strict_types=1);

use App\Actions\Demo\ShowDemo;
use App\Exceptions\ApiException;

it('devuelve la demo que existe', function (): void {
    expect((new ShowDemo)->handle(1))->toBe(['id' => 1, 'name' => 'Demo']);
});

it('rechaza una demo que no existe con DEMO_NOT_FOUND', function (): void {
    (new ShowDemo)->handle(2);
})->throws(ApiException::class, 'La demo no existe.');
