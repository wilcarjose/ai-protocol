<?php

declare(strict_types=1);

/*
 * La forma de un error de la API: application/problem+json (RFC 9457) con `type`, `title`, `status`, `detail` y la
 * extensión `code` (.ai/rules/arquitectura.md §Excepciones). Si falla nada más instalar el stack, falta registrar
 * App\Http\ProblemDetails en bootstrap/app.php (su docblock dice cómo).
 *
 * Es una semilla del kit ai-protocol: después de instalarla es del proyecto.
 */

use App\Exceptions\ApiException;
use Illuminate\Support\Facades\Route;
use Illuminate\Testing\TestResponse;

beforeEach(function (): void {
    Route::middleware('api')->prefix('api/__problem')->group(function (): void {
        Route::get('business', fn () => throw new ApiException('La demo no admite eso.', 'DEMO_REJECTED', ['id' => 1], 409));
        Route::get('validation', fn () => validator(['name' => ''], ['name' => 'required'])->validate());
        Route::get('crash', fn () => throw new RuntimeException('secreto interno'));
    });
});

function expectProblem(TestResponse $response, int $status, string $code): void
{
    $response->assertStatus($status)->assertHeader('Content-Type', 'application/problem+json');
    expect($response->json())->toMatchArray(['type' => 'about:blank', 'status' => $status, 'code' => $code])
        ->and($response->json('title'))->toBeString()->not->toBeEmpty()
        ->and($response->json('detail'))->toBeString()->not->toBeEmpty();
}

it('una excepción de negocio sale con su status, su code y su mensaje como detail', function (): void {
    $response = $this->getJson('/api/__problem/business');

    expectProblem($response, 409, 'DEMO_REJECTED');
    expect($response->json('detail'))->toBe('La demo no admite eso.')
        ->and($response->json())->not->toHaveKey('id');
});

it('un error de validación sale como VALIDATION_FAILED con los errores por campo', function (): void {
    $response = $this->getJson('/api/__problem/validation');

    expectProblem($response, 422, 'VALIDATION_FAILED');
    expect($response->json('errors'))->toHaveKey('name');
});

it('una ruta que no existe sale como NOT_FOUND', function (): void {
    expectProblem($this->getJson('/api/__problem/nada'), 404, 'NOT_FOUND');
});

it('un error inesperado sale como SERVER_ERROR sin exponer su mensaje', function (): void {
    $response = $this->getJson('/api/__problem/crash');

    expectProblem($response, 500, 'SERVER_ERROR');
    expect($response->getContent())->not->toContain('secreto interno');
});
