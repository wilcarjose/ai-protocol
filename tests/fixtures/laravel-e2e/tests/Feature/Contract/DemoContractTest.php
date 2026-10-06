<?php

declare(strict_types=1);

it('GET /api/demos/{id} returns the demo', function (): void {
    $this->getJson('/api/demos/1')->assertOk()->assertExactJson(['id' => 1, 'name' => 'Demo']);
});

it('GET /api/demos/{id} of a missing demo is a DEMO_NOT_FOUND problem+json with the translated detail', function (): void {
    app()->setLocale('es');

    $this->getJson('/api/demos/2')
        ->assertNotFound()
        ->assertHeader('Content-Type', 'application/problem+json')
        ->assertJson(['status' => 404, 'code' => 'DEMO_NOT_FOUND', 'detail' => 'La demo 2 no existe.']);
});
