<?php

declare(strict_types=1);

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;

uses(RefreshDatabase::class);

it('corre contra PostgreSQL con PostGIS', function (): void {
    expect(DB::connection()->getDriverName())->toBe('pgsql')
        ->and(DB::scalar('SELECT PostGIS_Version()'))->toBeString()->not->toBeEmpty();
});
