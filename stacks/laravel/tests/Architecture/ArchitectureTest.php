<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| Barandilla de arquitectura
|--------------------------------------------------------------------------
|
| Las capas de `.ai/rules/arquitectura.md` que se pueden comprobar sobre el
| código, con el plugin de arquitectura de Pest, que lee el código como
| código. Nunca con expresiones regulares sobre el fuente
| (`.ai/WORKFLOW.md §Obediencia arquitectónica`).
|
| Es del kit `ai-protocol` y está protegido. Las reglas propias del proyecto
| van en `tests/Architecture/ProjectArchitectureTest.php`.
|
| Corre en su propio gate de `bin/verify.sh` («arquitectura») y sin base de
| datos. Un namespace que todavía no existe pasa sin comprobar nada: la regla
| empieza a morder con la primera clase. Las reglas miran el namespace, no la
| subcarpeta: una funcionalidad (`App\Actions\Listings`) cumple las de su capa.
|
| Una regla, un namespace y una expectativa: con varios namespaces, Pest da
| por buena la regla entera si uno no existe, y `->ignoring()` sólo vale
| para la última expectativa de la cadena.
|
| ⛔ Nada de añadir `->ignoring()`, `->exclude()` ni saltar un `arch()` para que
| algo pase (`.ai/RULES.md §Lista negra`). Las dos exclusiones de abajo son del
| kit y dicen por qué. Si una regla parece equivocada: STOP & ASK.
*/

// La lógica de negocio: las carpetas por tipo de `.ai/rules/arquitectura.md §Arquitectura objetivo`.
$businessLogic = ['App\Actions', 'App\Services', 'App\ValueObjects', 'App\Contracts', 'App\Data', 'App\Enums'];

// Lo que sólo conoce la capa HTTP. El cliente HTTP saliente (Illuminate\Http\Client) no lo es: lo usa la
// implementación de un contrato que llama a un servicio externo y captura su ConnectionException
// (.ai/rules/rendimiento.md §Rendimiento y resiliencia).
$httpLayer = ['App\Http', 'Illuminate\Http', 'Illuminate\Routing', 'Illuminate\Foundation\Http', 'request', 'response', 'redirect'];
$outgoingHttp = 'Illuminate\Http\Client';

// Las Actions que publica Laravel Fortify siguen su propio contrato (create(), sin final): son del framework.
$frameworkActions = 'App\Actions\Fortify';

arch('no quedan llamadas de depuración')
    ->expect(['dd', 'dump', 'ray', 'var_dump', 'die'])
    ->not->toBeUsed();

// El esqueleto de Laravel (modelos, providers, controlador base) no declara strict_types: entra en esta lista cuando
// una fase lo toque entero.
foreach (['App\Actions', 'App\ValueObjects', 'App\Contracts', 'App\Enums', 'App\Data'] as $layer) {
    arch("$layer usa strict_types")
        ->expect($layer)
        ->toUseStrictTypes()
        ->ignoring($frameworkActions);
}

// ── Capas ────────────────────────────────────────────────────────────────

foreach ($businessLogic as $layer) {
    arch("$layer no conoce la capa HTTP ni los controladores")
        ->expect($layer)
        ->not->toUse($httpLayer)
        ->ignoring([$outgoingHttp, $frameworkActions]);
}

arch('los modelos no dependen de la lógica de negocio ni de HTTP')
    ->expect('App\Models')
    ->not->toUse(['App\Actions', 'App\Services', ...$httpLayer])
    ->ignoring($outgoingHttp);

// ── Actions ──────────────────────────────────────────────────────────────

arch('las Actions son final')
    ->expect('App\Actions')
    ->classes()
    ->toBeFinal()
    ->ignoring($frameworkActions);

arch('las Actions son readonly')
    ->expect('App\Actions')
    ->classes()
    ->toBeReadonly()
    ->ignoring($frameworkActions);

arch('las Actions tienen handle()')
    ->expect('App\Actions')
    ->classes()
    ->toHaveMethod('handle')
    ->ignoring($frameworkActions);

arch('las Actions no tienen más métodos públicos que handle()')
    ->expect('App\Actions')
    ->classes()
    ->not->toHavePublicMethodsBesides(['__construct', 'handle'])
    ->ignoring($frameworkActions);

arch('las Actions no conocen la sesión ni el usuario autenticado')
    ->expect('App\Actions')
    ->not->toUse(['auth', 'session', 'Illuminate\Support\Facades\Auth', 'Illuminate\Support\Facades\Session'])
    ->ignoring($frameworkActions);

arch('las Actions no leen el entorno ni el reloj directamente')
    ->expect('App\Actions')
    ->not->toUse(['env', 'now', 'today'])
    ->ignoring($frameworkActions);

arch('las Actions no usan facades de infraestructura')
    ->expect('App\Actions')
    ->not->toUse([
        'Illuminate\Support\Facades\Http',
        'Illuminate\Support\Facades\Mail',
        'Illuminate\Support\Facades\Log',
        'Illuminate\Support\Facades\Cache',
    ])
    ->ignoring($frameworkActions);

// ── Value Objects ────────────────────────────────────────────────────────

arch('los Value Objects son final')
    ->expect('App\ValueObjects')
    ->classes()
    ->toBeFinal();

arch('los Value Objects son inmutables (readonly)')
    ->expect('App\ValueObjects')
    ->classes()
    ->toBeReadonly();

// ── Contratos y enums ────────────────────────────────────────────────────

arch('los contratos son interfaces')
    ->expect('App\Contracts')
    ->toBeInterfaces();

arch('los enums de estado son enums backed string')
    ->expect('App\Enums')
    ->toBeStringBackedEnums();
