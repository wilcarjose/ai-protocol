<?php

declare(strict_types=1);

/*
 * The shape of an API error: application/problem+json (RFC 9457) with `type`, `title`, `status`, `detail` and the
 * `code` extension (.ai/rules/arquitectura.md §Excepciones). If it fails right after installing the stack,
 * App\Http\ProblemDetails is not registered in bootstrap/app.php yet (its docblock says how).
 *
 * Seeded by the ai-protocol kit: once installed, it belongs to the project.
 */

use App\Exceptions\ApiException;
use Illuminate\Support\Facades\Route;
use Illuminate\Testing\TestResponse;

beforeEach(function (): void {
    app('translator')->addLines(['problem_details_test.rejected' => 'La demo :id no admite eso.'], 'es');
    app()->setLocale('es');

    Route::middleware('api')->prefix('api/__problem')->group(function (): void {
        Route::get('business', fn () => throw new ApiException('problem_details_test.rejected', 'DEMO_REJECTED', ['id' => 7], 409));
        Route::get('validation', fn () => validator(['name' => ''], ['name' => 'required'])->validate());
        Route::get('crash', fn () => throw new RuntimeException('internal secret'));
    });
});

function expectProblem(TestResponse $response, int $status, string $code): void
{
    $response->assertStatus($status)->assertHeader('Content-Type', 'application/problem+json');
    expect($response->json())->toMatchArray(['type' => 'about:blank', 'status' => $status, 'code' => $code])
        ->and($response->json('title'))->toBeString()->not->toBeEmpty()
        ->and($response->json('detail'))->toBeString()->not->toBeEmpty();
}

it('renders a business exception with its status, its code and its translated message as detail', function (): void {
    $response = $this->getJson('/api/__problem/business');

    expectProblem($response, 409, 'DEMO_REJECTED');
    expect($response->json('detail'))->toBe('La demo 7 no admite eso.')
        ->and($response->json())->not->toHaveKey('id');
});

it('renders a validation error as VALIDATION_FAILED with the errors by field', function (): void {
    $response = $this->getJson('/api/__problem/validation');

    expectProblem($response, 422, 'VALIDATION_FAILED');
    expect($response->json('errors'))->toHaveKey('name');
});

it('renders an unknown route as NOT_FOUND', function (): void {
    expectProblem($this->getJson('/api/__problem/nothing'), 404, 'NOT_FOUND');
});

it('renders an unexpected error as SERVER_ERROR without exposing its message', function (): void {
    $response = $this->getJson('/api/__problem/crash');

    expectProblem($response, 500, 'SERVER_ERROR');
    expect($response->getContent())->not->toContain('internal secret');
});
