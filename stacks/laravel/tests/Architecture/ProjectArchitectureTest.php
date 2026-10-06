<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| Reglas de arquitectura del proyecto
|--------------------------------------------------------------------------
|
| Las que este proyecto añade a las del kit (`ArchitectureTest.php`, que está
| protegido y no se toca): una por regla de `.ai/project/ARCHITECTURE.md` que
| se pueda comprobar sobre el código. Corren en el mismo gate y con las
| mismas prohibiciones (`.ai/RULES.md §Lista negra`).
|
| Es una semilla del kit `ai-protocol`: después de instalarla es del proyecto.
|
| Ejemplo: una funcionalidad no usa las Actions de otra.
|
|     arch('Anuncios no depende de Pagos')
|         ->expect('App\Actions\Anuncios')
|         ->not->toUse('App\Actions\Pagos');
*/
