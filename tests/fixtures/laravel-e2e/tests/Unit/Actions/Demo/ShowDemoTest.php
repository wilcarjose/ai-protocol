<?php

declare(strict_types=1);

use App\Actions\Demo\ShowDemo;
use App\Exceptions\ApiException;

it('returns the demo that exists', function (): void {
    expect((new ShowDemo)->handle(1))->toBe(['id' => 1, 'name' => 'Demo']);
});

it('rejects a missing demo with DEMO_NOT_FOUND', function (): void {
    (new ShowDemo)->handle(2);
})->throws(ApiException::class, 'demos.not_found');
