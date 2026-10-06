<?php

declare(strict_types=1);

it('GET /api/demos/{id} devuelve la demo', function (): void {
    $this->getJson('/api/demos/1')->assertOk()->assertExactJson(['id' => 1, 'name' => 'Demo']);
});

it('GET /api/demos/{id} de una demo que no existe es un problem+json DEMO_NOT_FOUND', function (): void {
    $this->getJson('/api/demos/2')
        ->assertNotFound()
        ->assertHeader('Content-Type', 'application/problem+json')
        ->assertJson(['status' => 404, 'code' => 'DEMO_NOT_FOUND', 'detail' => 'La demo no existe.']);
});
