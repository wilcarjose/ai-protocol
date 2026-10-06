<?php

declare(strict_types=1);

namespace App\Exceptions;

use RuntimeException;
use Throwable;

/**
 * Base de toda excepción de negocio (.ai/rules/arquitectura.md §Excepciones).
 *
 * Su `errorCode` (mayúsculas, estable) es el contrato: el cliente discrimina por él. El mensaje es el `detail` de la
 * respuesta problem+json que escribe App\Http\ProblemDetails; el contexto va al log, nunca a la respuesta.
 *
 * Es una semilla del kit ai-protocol: después de instalarla es del proyecto.
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
