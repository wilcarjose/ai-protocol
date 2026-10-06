<?php

declare(strict_types=1);

namespace App\Exceptions;

use RuntimeException;
use Throwable;

/**
 * Base of every business exception (.ai/rules/arquitectura.md §Excepciones).
 *
 * Its `errorCode` (upper case, stable) is the contract: the client branches on it. The message is a translation key
 * (`listings.not_found`); App\Http\ProblemDetails translates it into the problem+json `detail`, with the context as
 * its parameters. The context goes to the log, never to the response.
 *
 * Seeded by the ai-protocol kit: once installed, it belongs to the project.
 */
class ApiException extends RuntimeException
{
    /**
     * @param  array<string, mixed>  $context
     */
    public function __construct(
        string $message,
        public readonly string $errorCode,
        public readonly array $context = [],
        public readonly int $status = 422,
        ?Throwable $previous = null,
    ) {
        parent::__construct($message, 0, $previous);
    }

    /**
     * @return array<string, mixed>
     */
    public function context(): array
    {
        return ['code' => $this->errorCode, ...$this->context];
    }
}
