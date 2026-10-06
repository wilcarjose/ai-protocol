<?php

declare(strict_types=1);

namespace App\Actions\Demo;

use App\Exceptions\ApiException;

final readonly class ShowDemo
{
    /**
     * @return array{id: int, name: string}
     */
    public function handle(int $id): array
    {
        if ($id !== 1) {
            throw new ApiException('La demo no existe.', 'DEMO_NOT_FOUND', ['id' => $id], 404);
        }

        return ['id' => $id, 'name' => 'Demo'];
    }
}
