# RULES — backend Laravel

> Las reglas de **cómo se escribe código** en este repositorio, para cualquier agente de IA y para cualquier humano.
> Este archivo es el núcleo y se lee entero antes de escribir una línea; los temas de `.ai/rules/` se leen cuando la
> fase los cita (§Reglas por tema). Si algo aquí contradice tu instinto, gana este archivo.
>
> 1. Si crees que una regla está mal o desactualizada: **STOP & ASK** (`.ai/WORKFLOW.md §STOP & ASK`). Quién la
>    cambia y cómo: `.ai/WORKFLOW.md §Archivos del protocolo`.
> 2. Cómo se trabaja vive en `.ai/WORKFLOW.md` y en las skills; lo que cambia con el proyecto, en `.ai/DOMAIN.md`,
>    `.ai/STATE.md` y `.ai/project/`. Aquí sólo hay reglas **estables**. Si chocan, gana este archivo.
> 3. Son las reglas del stack del kit `ai-protocol`, y las actualiza `install.sh --upgrade`. Lo que decide cada
>    proyecto vive en `.ai/project/`, y aquí se cita. Un proyecto puede cambiar este archivo, pero entonces el
>    upgrade lo enseña como conflicto en vez de actualizarlo.

---

## 1. Stack y versiones exactas

Los paquetes que el stack da por hechos. Sus versiones exactas son del proyecto y viven en
`.ai/project/DECISIONS.md §Stack y versiones exactas`: el chequeo «stack» de `bin/check-docs.sh` exige allí una por
cada paquete de esta tabla y la compara con `composer.json`. Una fila por paquete (varios en una fila, separados por
« / »).

| Paquete | Nota |
|---|---|
| `php` | Property hooks y visibilidad asimétrica disponibles, con las restricciones de `.ai/rules/arquitectura.md §PHP 8.4+` |
| `laravel/framework` | Esqueleto slim: `bootstrap/app.php`, sin `Kernel.php` |
| `pestphp/pest` | Pest, no PHPUnit clásico. Incluye el plugin de arquitectura |
| `laravel/pint` | Estilo |
| `larastan/larastan` | Análisis estático (`phpstan.neon`) |
| `dedoc/scramble` | El OpenAPI, generado desde el código (`sh bin/contract.sh`) |

**Regla dura:** la documentación de dos versiones seguidas de Laravel se parece mucho y los modelos de lenguaje
las mezclan. Si necesitas una API del framework y no estás 100 % seguro de que existe en **tu** versión, no la uses:
escribe la versión explícita y verbosa, o consulta la documentación de esa versión exacta
(`https://laravel.com/docs/<versión>.x/`), nunca la de otra ni `master`.

Que el framework traiga incluida una funcionalidad (un SDK, un tipo de recurso, un sistema de colas nuevo) no la
convierte en parte del alcance: añadirla es funcionalidad nueva y la autoriza una fase.

---

## 2. Alcance — qué puedes tocar

### ✅ Dentro de alcance (con autorización de la fase activa)

Lo no listado queda fuera. Cada carpeta incluye sus subcarpetas por funcionalidad
(`.ai/rules/arquitectura.md §Arquitectura objetivo`).

```
app/{Actions,Contracts,Data,Enums,Exceptions,Services,ValueObjects}/**
app/{Console/Commands,Events,Filament,Http,Jobs,Listeners,Policies}/**
app/Models/**          (accessors, casts y relaciones: con cuidado, son contrato — §3)
app/Providers/AppServiceProvider.php   (bindings de contratos en register())
bootstrap/app.php      (rutas, middleware y excepciones)
database/{factories,seeders}/**
routes/**              (URLs y verbos sólo con CAMBIO AUTORIZADO — §3)
tests/**
```

### ⛔ Fuera de alcance salvo autorización explícita de la fase

```
database/migrations/**     ← sólo si la fase lo autoriza en su cabecera «Migraciones:»
config/**                  ← sólo si la fase lo pide
composer.json              ← dependencias nuevas: .ai/WORKFLOW.md §Dependencia nueva
.env*                      ← nunca se leen ni se escriben secretos
```

Lo que este proyecto deja fuera además: `.ai/project/ARCHITECTURE.md §Fuera de alcance`.

Si un cambio *parece* requerir tocar algo de fuera de alcance: **detente y repórtalo**. Es una señal de que el
alcance de la fase está mal, no un obstáculo que sortear.

---

## 3. Contrato HTTP

El contrato HTTP es todo lo que un cliente ve: URLs, verbos, status, claves de entrada y salida, su forma y su
orden, cabeceras y el texto de los mensajes de error. **No cambia por defecto.** Cualquier cambio, aunque sea para
cerrar un agujero, requiere:

1. **STOP & ASK** (`.ai/WORKFLOW.md §Contrato`), salvo que la fase ya lo traiga autorizado.
2. La autorización del Tech Lead escrita en la fase: su cabecera dice `Contrato HTTP: CAMBIO AUTORIZADO`, con el
   cambio campo por campo y la decisión de `.ai/DOMAIN.md` que lo respalda.
3. El traspaso al repo hermano que lo consume (`CLAUDE.md §El otro repositorio`).
4. Los tests de contrato (`tests/Feature/Contract/`) y los baselines actualizados en la misma fase: el OpenAPI
   (`docs/contract/openapi.json`, con `sh bin/contract.sh`) y las rutas (`php scripts/normalize-routes.php`).

Si no cambia, los tests de contrato pasan **sin modificarlos** y los baselines no se tocan: son la red.

Los errores (problem+json) y la forma de la salida: `.ai/rules/arquitectura.md`, siempre que la fase toque HTTP.

---

## 4. Reglas por tema

Cada tema vive en su archivo de `.ai/rules/` y es tan innegociable como este. La fase lista en «Contexto que debes
leer antes» los que toca; si vas a tocar algo de un tema que la fase no cita, léelo igual antes de escribir.

| Archivo | Qué cubre | Se lee si la fase toca |
|---|---|---|
| `.ai/rules/arquitectura.md` | Estructura de `app/` por funcionalidad, errores, estados, Actions, Value Objects, contratos, PHP 8.4+, forma de las respuestas | Cualquier clase de `app/` |
| `.ai/rules/tests.md` | Dónde va cada test, el motor de la suite, Fakes y red; cómo explorar la base de datos local | `tests/` (casi siempre), o consultas a la base de datos local |
| `.ai/rules/rendimiento.md` | N+1, caché compartida, llamadas externas, serialización y colas | Consultas, caché, colas o servicios externos |

---

## 5. Zonas sensibles

Tocar estas zonas de una forma que la fase no describe con precisión es motivo de parada
(`.ai/WORKFLOW.md §Zona sensible`):

- Autenticación, sesiones, tokens y permisos.
- Pagos, planes y facturación.
- Las del proyecto: `.ai/project/SENSITIVE-ZONES.md`.

---

## 6. Verificación del stack

`bash bin/verify.sh` corre los gates en su orden; aquí sólo lo que no cabe en el script:

- **Pint** con la configuración del repo; no se desactivan reglas para que algo pase.
- **PHPStan / Larastan** al nivel de `phpstan.neon`, que nunca baja. Si existe `phpstan-baseline.neon`, **sólo
  mengua**: un error nuevo se arregla, no se añade al baseline. Si el análisis falla con `ignore.unmatched`, un
  patrón quedó huérfano: regenera el baseline (`vendor/bin/phpstan analyse --generate-baseline`), revisa el diff
  línea por línea (cada patrón que desaparece corresponde a un error que de verdad se arregló; si protegía un error
  que sigue ahí, se restaura y se arregla el código) y va en su propio commit.
- **Arquitectura** (`tests/Architecture/`): las capas de `.ai/rules/arquitectura.md`; las del proyecto, en
  `ProjectArchitectureTest.php`.
- **Contrato y rutas:** sus baselines se regeneran sólo con un cambio de contrato autorizado (§3).

---

## 7. Lista negra

Las prohibiciones que valen para cualquier stack no se repiten aquí: no arreglar de paso (`CLAUDE.md §Alcance`),
dependencias nuevas (`.ai/WORKFLOW.md §Dependencia nueva`) y exenciones a un gate
(`.ai/WORKFLOW.md §Obediencia arquitectónica`). Éstas son las de Laravel:

1. ⛔ **No inventes funcionalidad**: ni un endpoint, ni un campo, ni un flag «de paso».
2. ⛔ **No crees ni edites migraciones** sin que la cabecera de la fase las autorice.
3. ⛔ **No renombres columnas, tablas ni claves de respuesta** sin `CAMBIO AUTORIZADO` (§3).
4. ⛔ **No cambies el texto de un mensaje de error** sin `CAMBIO AUTORIZADO`: el cliente puede mostrarlo tal cual.
5. ⛔ **No borres código comentado que parezca una regla de negocio desactivada.** Repórtalo.
6. ⛔ **No cambies TTLs de caché ni valores de configuración** sin autorización. Si están mal, repórtalo.
7. ⛔ **No uses paquetes de Actions ni de DTOs** (`lorisleiva/laravel-actions`, `spatie/laravel-data`): las Actions
   son clases PHP planas resueltas por el contenedor.
8. ⛔ **No añadas un `JsonResource` con envoltorio `data`** donde hoy hay un array plano, ni reordenes las claves de
   una respuesta.
9. ⛔ **No refactorices más de un endpoint por commit.**
10. ⛔ **No dejes la Action y el Service viejo activos a la vez**: si extraes a una Action, el Service deja de tener
    esa lógica.
11. ⛔ **No uses `auth()->user()` en Services ni Actions.** Sólo controladores y middleware conocen la petición.
12. ⛔ **No silencies excepciones** (`catch (\Exception $e) { continue; }`). Si el código existente lo hace, se
    conserva y se reporta; código nuevo así, nunca.
13. ⛔ **No añadas `->ignoring()`, `->exclude()` ni saltes un `arch()`** en el test de arquitectura: son exenciones a
    un gate.
14. ⛔ **No cambies comportamiento dentro de una tarea declarada «sin cambio de comportamiento».**
15. ⛔ **No uses `array_first()` ni `array_last()` globales**: un polyfill las define con otra semántica. Usa
    `Illuminate\Support\Arr::first()` / `Arr::last()`.
16. ⛔ **No uses `ReflectionMethod::setAccessible()` para probar un método privado**, ni quites `final` a una clase
    para heredarla en un test: falta un contrato o un Fake, o el test prueba implementación en vez de comportamiento.
17. ⛔ **No cites catálogos mutables** (`P<n>-<m>`, `§X` de una lista que se renumera) desde código, tests ni
    documentos. El porqué que debe sobrevivir va a `.ai/DOMAIN.md` o a `docs/`.
18. ⛔ **No dejes llamadas de depuración**: `dd()`, `dump()`, `ray()`, `var_dump()`.

---

## 8. Ámbitos de commit

Conventional Commits en inglés (`.claude/skills/phase/SKILL.md §Commits durante la fase`). Ámbitos:

- Transversales: `api`, `auth`, `infra`, `deps`, `docs`, `tests`, `ci`, `planning`, `protocol`, y
  `phase-<NN>-<FF>` para los commits de arranque, reanudación y cierre de una fase.
- Del dominio: los de `.ai/project/COMMIT-SCOPES.md`, donde se añade uno nuevo antes de usarlo.
