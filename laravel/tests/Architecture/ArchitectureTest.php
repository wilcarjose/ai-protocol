<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| Barandilla de arquitectura
|--------------------------------------------------------------------------
|
| Las reglas de `.ai/RULES.md` (§Patrón Action, §Tipado estricto y Value
| Objects) que se pueden comprobar sobre el código, con el plugin de
| arquitectura de Pest, que lee el código como código. Nunca con expresiones
| regulares sobre el fuente (`.ai/WORKFLOW.md §Obediencia arquitectónica`).
|
| Corre en su propio gate de `bin/verify.sh` («arquitectura») y sin base de
| datos. Un namespace que todavía no existe pasa sin comprobar nada: la regla
| empieza a morder con la primera clase.
|
| ⛔ Nada de `->ignoring()`, `->exclude()` ni saltar un `arch()` para que algo
| pase (`.ai/RULES.md §Lista negra`). Si una regla parece equivocada: STOP & ASK.
*/

arch('no quedan llamadas de depuración')
    ->expect(['dd', 'dump', 'ray', 'var_dump', 'die'])
    ->not->toBeUsed();

// Las capas que define `.ai/RULES.md §Arquitectura objetivo`. El esqueleto de Laravel (modelos, providers,
// controlador base) no declara strict_types: entra en esta lista cuando una fase lo toque entero.
arch('las capas del proyecto usan strict_types')
    ->expect(['App\Actions', 'App\ValueObjects', 'App\Contracts', 'App\Enums', 'App\Data'])
    ->toUseStrictTypes();

// ── Actions ──────────────────────────────────────────────────────────────

arch('las Actions son final readonly')
    ->expect('App\Actions')
    ->classes()
    ->toBeFinal()
    ->toBeReadonly();

arch('las Actions se llaman <Verbo><Sustantivo>Action')
    ->expect('App\Actions')
    ->classes()
    ->toHaveSuffix('Action');

arch('las Actions tienen un único método público: handle()')
    ->expect('App\Actions')
    ->classes()
    ->toHaveMethod('handle')
    ->not->toHavePublicMethodsBesides(['__construct', 'handle']);

arch('las Actions no conocen la petición HTTP')
    ->expect('App\Actions')
    ->not->toUse([
        'Illuminate\Http\Request',
        'request',
        'auth',
        'session',
    ]);

arch('las Actions no leen el entorno ni el reloj directamente')
    ->expect('App\Actions')
    ->not->toUse(['env', 'now', 'today']);

arch('las Actions no usan facades de infraestructura')
    ->expect('App\Actions')
    ->not->toUse([
        'Illuminate\Support\Facades\Http',
        'Illuminate\Support\Facades\Mail',
        'Illuminate\Support\Facades\Log',
        'Illuminate\Support\Facades\Cache',
        'Illuminate\Support\Facades\Auth',
    ]);

// ── Value Objects ────────────────────────────────────────────────────────

arch('los Value Objects son final readonly')
    ->expect('App\ValueObjects')
    ->classes()
    ->toBeFinal()
    ->toBeReadonly();

// ── Contratos y enums ────────────────────────────────────────────────────

arch('los contratos son interfaces')
    ->expect('App\Contracts')
    ->toBeInterfaces();

arch('los enums de estado son enums backed string')
    ->expect('App\Enums')
    ->toBeStringBackedEnums();
