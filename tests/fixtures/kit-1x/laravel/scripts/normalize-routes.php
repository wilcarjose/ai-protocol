<?php

declare(strict_types=1);

/*
 * Imprime el baseline de rutas del contrato HTTP: una línea «MÉTODO|URI|MIDDLEWARE» por ruta, en orden.
 *
 *   php scripts/normalize-routes.php > docs/contract/routes-baseline.txt
 *
 * bin/verify.sh (gate «rutas») compara su salida con el baseline commiteado: una ruta, un verbo o un middleware
 * que cambian sin un cambio de contrato autorizado hacen fallar el gate (.ai/RULES.md §Contrato HTTP).
 *
 * El contrato son las rutas bajo ROUTE_PREFIX. Si el proyecto expone otras a sus clientes, amplíalo aquí.
 */

const ROUTE_PREFIX = 'api';

$json = shell_exec('php artisan route:list --path='.ROUTE_PREFIX.' --json 2>/dev/null');
$routes = is_string($json) ? json_decode($json, true) : null;

// Sin rutas bajo el prefijo, `route:list` no imprime JSON sino un aviso: el baseline queda vacío.
if (! is_array($routes)) {
    $routes = [];
}

$lines = [];

foreach ($routes as $route) {
    $uri = (string) $route['uri'];

    if ($uri !== ROUTE_PREFIX && ! str_starts_with($uri, ROUTE_PREFIX.'/')) {
        continue;
    }

    $middleware = is_array($route['middleware'] ?? null) ? implode(',', $route['middleware']) : '';
    $lines[] = $route['method'].'|'.$uri.'|'.$middleware;
}

sort($lines, SORT_STRING);

echo '# Baseline de rutas del contrato HTTP — generado por scripts/normalize-routes.php'."\n";
echo '# Formato: MÉTODO|URI|MIDDLEWARE, en orden. Se regenera sólo con un cambio de contrato autorizado.'."\n";
echo '# Rutas: '.count($lines)."\n\n";
echo implode("\n", $lines).($lines === [] ? '' : "\n");
