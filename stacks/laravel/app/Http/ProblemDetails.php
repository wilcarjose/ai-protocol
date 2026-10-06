<?php

declare(strict_types=1);

namespace App\Http;

use App\Exceptions\ApiException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Throwable;

/**
 * Los errores de la API en application/problem+json (RFC 9457): `type`, `title`, `status`, `detail` y la extensión
 * `code`, por la que discrimina el cliente (.ai/rules/arquitectura.md §Excepciones). Es el único sitio que da forma a
 * un error.
 *
 * Se registra en bootstrap/app.php, con `use App\Http\ProblemDetails;`:
 *
 *     ->withExceptions(function (Exceptions $exceptions): void {
 *         ProblemDetails::register($exceptions);
 *     })
 *
 * Es una semilla del kit ai-protocol: después de instalarla es del proyecto. Los códigos de abajo son contrato.
 */
final class ProblemDetails
{
    public const string CONTENT_TYPE = 'application/problem+json';

    /** Los códigos de los errores que no son de negocio, por status. */
    private const array CODES = [
        401 => 'UNAUTHENTICATED',
        403 => 'FORBIDDEN',
        404 => 'NOT_FOUND',
        405 => 'METHOD_NOT_ALLOWED',
        419 => 'SESSION_EXPIRED',
        422 => 'VALIDATION_FAILED',
        429 => 'TOO_MANY_REQUESTS',
        500 => 'SERVER_ERROR',
        503 => 'SERVICE_UNAVAILABLE',
    ];

    public static function register(Exceptions $exceptions): void
    {
        // Un rechazo legítimo (4xx) no es un error de la aplicación: no se reporta.
        $exceptions->report(static fn (ApiException $e): ?bool => $e->status >= 500 ? null : false);

        $exceptions->render(static fn (Throwable $e, Request $request): ?JsonResponse => self::applies($request) ? self::render($e) : null);
    }

    public static function applies(Request $request): bool
    {
        return $request->is('api', 'api/*') || $request->expectsJson();
    }

    public static function render(Throwable $e): ?JsonResponse
    {
        return match (true) {
            $e instanceof HttpResponseException => null,
            $e instanceof ApiException => self::response($e->status, $e->errorCode, $e->getMessage()),
            $e instanceof ValidationException => self::response(422, self::CODES[422], $e->getMessage(), ['errors' => $e->errors()]),
            $e instanceof AuthenticationException => self::response(401, self::CODES[401], 'Unauthenticated.'),
            $e instanceof HttpExceptionInterface => self::response(
                $e->getStatusCode(),
                self::CODES[$e->getStatusCode()] ?? 'HTTP_'.$e->getStatusCode(),
                self::detail($e),
                headers: $e->getHeaders(),
            ),
            // Un 500 nunca expone el mensaje de la excepción: texto fijo, y el detalle al log.
            default => self::response(500, self::CODES[500], self::title(500).'.'),
        };
    }

    /**
     * El mensaje de un abort(403, '…') es para el cliente; el de un 5xx o un modelo que no existe (nombra la clase),
     * no.
     */
    private static function detail(HttpExceptionInterface $e): string
    {
        $status = $e->getStatusCode();

        if ($status >= 500 || $e->getMessage() === '' || $e->getPrevious() instanceof ModelNotFoundException) {
            return self::title($status).'.';
        }

        return $e->getMessage();
    }

    /**
     * @param  array<string, mixed>  $extensions
     * @param  array<string, string>  $headers
     */
    private static function response(int $status, string $code, string $detail, array $extensions = [], array $headers = []): JsonResponse
    {
        return new JsonResponse(
            ['type' => 'about:blank', 'title' => self::title($status), 'status' => $status, 'detail' => $detail, 'code' => $code, ...$extensions],
            $status,
            ['Content-Type' => self::CONTENT_TYPE, ...$headers],
        );
    }

    private static function title(int $status): string
    {
        return Response::$statusTexts[$status] ?? 'Error';
    }
}
