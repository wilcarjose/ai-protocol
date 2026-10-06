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
 * API errors as application/problem+json (RFC 9457): `type`, `title`, `status`, `detail` and the `code` extension,
 * which the client branches on (.ai/rules/arquitectura.md §Excepciones). It is the only place that shapes an error.
 *
 * `detail` is user-facing text: an ApiException message is a translation key, translated here with the exception
 * context as parameters; the fixed texts below go through the translator too (lang/<locale>.json).
 *
 * Registered in bootstrap/app.php, with `use App\Http\ProblemDetails;`:
 *
 *     ->withExceptions(function (Exceptions $exceptions): void {
 *         ProblemDetails::register($exceptions);
 *     })
 *
 * Seeded by the ai-protocol kit: once installed, it belongs to the project. The codes below are contract.
 */
final class ProblemDetails
{
    public const string CONTENT_TYPE = 'application/problem+json';

    /** The codes of the errors that are not business errors, by status. */
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
        // A legitimate rejection (4xx) is not an application error: it is not reported.
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
            $e instanceof ApiException => self::response($e->status, $e->errorCode, self::translate($e->getMessage(), $e->context)),
            $e instanceof ValidationException => self::response(422, self::CODES[422], $e->getMessage(), ['errors' => $e->errors()]),
            $e instanceof AuthenticationException => self::response(401, self::CODES[401], self::translate('Unauthenticated.')),
            $e instanceof HttpExceptionInterface => self::response(
                $e->getStatusCode(),
                self::CODES[$e->getStatusCode()] ?? 'HTTP_'.$e->getStatusCode(),
                self::detail($e),
                headers: $e->getHeaders(),
            ),
            // A 500 never exposes the exception message: a fixed text, and the details go to the log.
            default => self::response(500, self::CODES[500], self::translate(self::title(500).'.')),
        };
    }

    /**
     * The message of an abort(403, '…') is for the client; the one of a 5xx or of a missing model (it names the
     * class) is not.
     */
    private static function detail(HttpExceptionInterface $e): string
    {
        $status = $e->getStatusCode();

        if ($status >= 500 || $e->getMessage() === '' || $e->getPrevious() instanceof ModelNotFoundException) {
            return self::translate(self::title($status).'.');
        }

        return self::translate($e->getMessage());
    }

    /**
     * @param  array<string, mixed>  $context
     */
    private static function translate(string $key, array $context = []): string
    {
        $replace = array_filter($context, static fn (mixed $value): bool => is_scalar($value));
        $text = __($key, $replace);

        return is_string($text) ? $text : $key;
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
