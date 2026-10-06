<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Demo;

use App\Actions\Demo\ShowDemo;
use Illuminate\Http\JsonResponse;

final class ShowDemoController
{
    public function __invoke(int $id, ShowDemo $showDemo): JsonResponse
    {
        return new JsonResponse($showDemo->handle($id));
    }
}
