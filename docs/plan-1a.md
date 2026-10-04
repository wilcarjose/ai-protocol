# Plan 1a — Adaptación del kit ai-protocol

> **Origen:** tarea 1a de la Etapa 1 del portal inmobiliario.
> **Criterio de aceptación de la tarea:** una épica de prueba pasa el guardián y `verify.sh` en ambos stacks, y la CI del kit corre sus casos de fallo.
> **Análisis completo (para la persona):** https://claude.ai/code/artifact/43b693f7-4208-4afa-b908-d09ecd623c67 — todo lo que el agente necesita está en este archivo.
> **Rutas:** hasta la fase 2 los kits viven en `laravel/` y `nextjs/`; desde la fase 2, en `core/` y `stacks/`.

## Estado

| Fase | Objetivo | Depende de | Estado | PR |
|---|---|---|---|---|
| 1 | Base de verificación e inconsistencias | — | pendiente | — |
| 2 | Núcleo, stacks e instalador | 1 | pendiente | — |
| 3 | Menos tokens | 2 | pendiente | — |
| 4 | Planificador, revisor y tipos de tarea | 3 | pendiente | — |
| 5 | Modo remoto y CI de los proyectos | 4 | pendiente | — |
| 6 | Stack Laravel modular por defecto | 5 | pendiente | — |
| 7 | Stack Next.js completo | 5 | pendiente | — |
| 8 | Validación de punta a punta y versión 2.0.0 | 6, 7 | pendiente | — |

## Cómo se ejecuta una fase

Prompt: «Ejecuta la fase N de docs/plan-1a.md».

1. Lee este archivo completo y los archivos que cite la fase. Si la fase anterior tiene su PR fusionado, márcala `hecha` en la tabla.
2. Antes de editar, resume en el chat qué harás, qué archivos tocarás, riesgos y preguntas. Espera el visto bueno.
3. Trabaja en la rama `plan-1a/fase-N`, nunca en `main`. Commits pequeños con Conventional Commits y ámbito `kit`, `core`, `laravel` o `nextjs`.
4. Cumple cada criterio de aceptación ejecutando su comando y pega la salida en la descripción del PR.
5. En el mismo PR, marca la fase `en revisión` en la tabla, con el número de PR, y anota en «Registro» lo que la siguiente fase necesite saber.
6. Empuja la rama y deja el PR listo. No lo fusiones: la persona revisa y fusiona.
7. Si la fase supera unos 10 archivos con lógica nueva o no se revisa en 10 minutos, divídela en Na, Nb… sin renumerar, y anótalo en la tabla.

**Para y pregunta**, con opciones y una recomendación, si falta una decisión que este plan no cubre, si un criterio no se puede cumplir, si hace falta una dependencia o herramienta no listada, o si un cambio rompería algo que el plan no autoriza.

## Decisiones que no se reabren

1. Un solo repo con el núcleo y los stacks; cada stack depende solo del núcleo, nunca de otro stack.
2. Cada stack declara un manifiesto `stack.json` con los archivos que aporta y el rango de versiones del núcleo con el que es compatible.
3. Versiones por paquete con etiquetas (`core-vX.Y.Z`, `laravel-vX.Y.Z`, `nextjs-vX.Y.Z`); cada proyecto guarda lo instalado en `.ai/protocol.lock`.
4. El instalador copia núcleo + stack; los proyectos no dependen de este repo para funcionar. La capa del proyecto vive en `.ai/project/` y el instalador nunca la toca.
5. El stack de Laravel es modular por defecto (`app/Modules/<Módulo>/`); no hay variante por capas.
6. Toda fase termina igual: rama de fase en GitHub, PR, CI que corre `verify.sh` y revisor IA; la persona aprueba cada PR. Se ejecuta en la nube por defecto o en local, con el mismo final.
7. El estado de ejecución vive en el repo (`STATE.md` y archivos de fase).
8. «Fase» es la unidad del protocolo. Los planes externos (épicas, tramos y tareas de otro documento) entran como paquetes de tareas y no se vuelven a planificar.
9. Expo queda fuera de este plan: `stacks/expo/` solo lleva un README que lo anuncia.
10. Los proyectos que ya usan el kit 1.x no cambian hasta que corran `install.sh --upgrade`.

## Línea base (kit actual, `laravel/`, en caracteres)

| Sesión | Archivos | Caracteres |
|---|---|---|
| Cualquiera | `CLAUDE.md` | 20 812 |
| Ejecutor | `CLAUDE.md`, comando `/phase`, `STATE`, `DOMAIN`, `RULES`, `WORKFLOW`, `BACKLOG` y la plantilla de fase | 76 196 |
| Planificador | `CLAUDE.md`, `STATE`, `DOMAIN`, `RULES`, `WORKFLOW`, `PLANNING`, `BACKLOG`, `PROTOCOL` y las dos plantillas | 89 300 |
| Rescate | `CLAUDE.md`, comando `/close`, `STATE`, `WORKFLOW` y la plantilla de fase | 47 906 |

---

## Fase 1 — Base de verificación e inconsistencias

**Objetivo:** que el kit se verifique solo en cada PR y quede coherente con sus propias reglas.

Entregables:

- `.github/workflows/kit.yml`: en cada PR corre `shellcheck -s sh` sobre todos los scripts, `sh check-kits.sh` y `sh tests/run.sh`.
- `tests/run.sh` y `tests/fixtures/`: instala cada kit en un directorio temporal (rellena los `{{RELLENAR}}`, crea `composer.json` o `package.json` con las versiones del §1 de `RULES.md` y una épica de prueba desde las plantillas), comprueba que el guardián pasa y luego provoca cada uno de los 13 fallos de la cabecera de `bin/check-docs.sh`, comprobando que falla.
- `bin/measure-context.sh`: imprime los caracteres de cada sesión de la tabla «Línea base» sobre una instalación. Copia su salida en «Registro».
- Correcciones, idénticas en los archivos comunes de ambos kits:
  1. Reglas repetidas: cada una queda en un solo archivo y los demás la citan (sin exenciones a gates, no arreglar de paso, dependencias nuevas, «git push»).
  2. Las citas entre archivos llevan el nombre de la sección (`WORKFLOW.md §STOP & ASK`), no solo su número; el chequeo 12 del guardián valida el nombre.
  3. El guardián encuentra las secciones de la fase por su nombre («Criterios de éxito», «Plan de commits»), no por `## 5.` y `## 9.`.
  4. `check-kits.sh` cita una sección del README que no existe («Qué es común y qué es del stack»); corrige la cita.
  5. `CLAUDE.md §Orden de lectura` deja de pedir que se relea el propio archivo.
  6. `laravel/bin/verify.sh` no corre dos veces los tests de arquitectura en modo completo.

Las otras cuatro inconsistencias del análisis se resuelven en su fase: reporte duplicado (fase 3), protección de los archivos del protocolo (fase 5), alcance de `RULES.md` de Laravel (fase 6) y configuración de ESLint y Playwright (fase 7).

Criterios de aceptación:

- [ ] `sh tests/run.sh` termina en 0 y reporta los 13 fallos provocados y detectados.
- [ ] `tests/run.sh` incluye una cita entre archivos que usa solo el número, y el guardián la rechaza.
- [ ] `shellcheck -s sh check-kits.sh laravel/bin/*.sh nextjs/bin/*.sh tests/*.sh` no da avisos (si falta, `pip install shellcheck-py`).
- [ ] La CI del PR está en verde.

## Fase 2 — Núcleo, stacks e instalador

**Objetivo:** una sola copia del núcleo y un instalador versionado.

Entregables:

- Estructura `core/` (lo que hoy es común a los dos kits), `stacks/laravel/`, `stacks/nextjs/`, `stacks/expo/README.md`, `ci/`, `tests/` y `docs/`.
- `stacks/<stack>/stack.json`: nombre, versión, archivos que aporta, rango compatible del núcleo y gates de su `verify.sh`.
- `install.sh --stack <laravel|nextjs> --target <dir> [--dry-run]`: copia núcleo + stack sin pisar archivos del proyecto, crea `.ai/project/` desde su plantilla si no existe y escribe `.ai/protocol.lock` con las versiones y la suma de cada archivo copiado.
- `install.sh --upgrade --target <dir>`: muestra el diff de cada archivo del kit, no toca `.ai/project/` ni la memoria (`STATE`, `DOMAIN`, `BACKLOG`, `PROTOCOL` y épicas) y actualiza el lock.
- `core/.ai/project/`: plantilla de la capa del proyecto (decisiones vigentes, arquitectura, contrato, zonas sensibles, frentes transversales y ámbitos de commit). Las reglas del kit la citan en vez de traer decisiones de un proyecto concreto.
- `tests/structure.sh` reemplaza a `check-kits.sh`: ningún stack referencia archivos de otro stack, y cada `stack.json` lista exactamente los archivos de su carpeta.
- `CHANGELOG.md` por paquete y una sección del README sobre versiones y etiquetas.

Criterios de aceptación:

- [ ] `sh install.sh --stack laravel --target "$(mktemp -d)"` y lo mismo con `nextjs` terminan en 0 y dejan `.ai/protocol.lock`.
- [ ] Un `--upgrade` sin cambios reporta «sin cambios» y no modifica ningún archivo.
- [ ] `sh tests/structure.sh` y `sh tests/run.sh` pasan sobre la nueva estructura.
- [ ] La CI del PR está en verde.

## Fase 3 — Menos tokens

**Objetivo:** bajar el contexto de arranque al menos un 30 % y que deje de crecer con cada fase.

Entregables:

- `CLAUDE.md` mínimo: orientación, orden de lectura, prohibiciones y punteros. El ciclo de fase, las ramas, los commits y el cierre pasan a skills (`.claude/skills/phase/` y `.claude/skills/close/`, con `disable-model-invocation: true`), que reemplazan a `.claude/commands/`.
- `PLANNING.md` pasa a una skill de planificación, que completa la fase 4.
- `RULES.md` por capas: un núcleo de innegociables y secciones temáticas en `rules/` que la fase cita en «Contexto que debes leer antes»; donde convenga, una skill con `paths` que las cargue al tocar esos archivos.
- Archivo de la memoria: filas cerradas de `BACKLOG`, decisiones reemplazadas de `DOMAIN` y mejoras aplicadas o descartadas de `PROTOCOL` pasan a `.ai/archive/`; «Últimos movimientos» tiene un tope de 10 líneas. El guardián hace cumplir los topes y resuelve referencias al archivo.
- `bin/handoff.sh <NN-slug> <FF>`: imprime solo «Lo que la siguiente fase necesita saber» de esa fase.
- Las salidas de más de 40 líneas van a un archivo de evidencia junto a la fase, y el RESULTADO lo enlaza.
- Un solo reporte: el chat da cinco líneas y apunta al RESULTADO, en vez de repetirlo como hace hoy `WORKFLOW.md §Plantilla del reporte final`.

Criterios de aceptación:

- [ ] `wc -m < core/CLAUDE.md` da 6 000 o menos.
- [ ] `bin/measure-context.sh` sobre una instalación de laravel da 53 300 caracteres o menos para el ejecutor (70 % de la línea base).
- [ ] `tests/run.sh` cubre los topes de memoria y una referencia a una decisión archivada.
- [ ] La CI del PR está en verde.

## Fase 4 — Planificador, revisor y tipos de tarea

**Objetivo:** los tres roles con comando propio y entrada desde planes externos.

Entregables:

- Skills `/plan-epic` y `/plan-phase`. Aceptan un paquete de tareas en `.ai/stages/<id>.md`: una tabla con ID, tarea, repo, criterio de aceptación y dependencias, más la lista de decisiones vigentes. Cada tarea se convierte en una fase técnica del repo que la implementa, con su ID en la cabecera (`> **Tarea externa:** T1-23`) y su criterio copiado literal, más los comandos que lo prueban. Si falta una decisión, para y pregunta.
- Revisor IA: subagente de solo lectura en `.claude/agents/reviewer.md` y skill `/review`. Compara el diff de la rama contra su base con los entregables, los criterios y su evidencia, las reglas (núcleo y secciones citadas), `.ai/project/`, las zonas sensibles y el alcance. Escribe hallazgos bloqueantes y no bloqueantes en la sección «Revisión» de la fase. `/phase` lo ejecuta antes del cierre y no cierra con bloqueantes abiertos.
- Tipos de tarea en la cabecera de la fase: `código`, `operación` y `validación externa`. En operación, los entregables son scripts, configuración y un runbook versionados; las casillas de evidencia humana se marcan `[humano]` y la fase queda en `ESPERA_EVIDENCIA` hasta que la persona pega la evidencia. Cómo afecta ese estado al puntero de `STATE.md` es una decisión: propón opciones en el Paso A.
- Fases ligeras (`> **Modo:** ligero`, uno o dos entregables): sin parada en el Paso A si no hay preguntas ni supuestos rotos, y con cierre reducido.
- El guardián valida los campos nuevos, el estado `ESPERA_EVIDENCIA` y que cada tarea externa exista en un paquete.

Criterios de aceptación:

- [ ] `tests/run.sh` incluye una épica creada desde un paquete de ejemplo, con una fase de código, una de operación y una ligera, y las tres pasan el guardián.
- [ ] El PR trae la salida de `/review` sobre una rama de prueba con una violación deliberada (una dependencia nueva no autorizada) y su hallazgo bloqueante.
- [ ] La CI del PR está en verde.

## Fase 5 — Modo remoto y CI de los proyectos

**Objetivo:** que cada fase termine en un PR verificado, se ejecute en la nube o en local.

Entregables:

- «Nunca `git push`» pasa a «nunca a `main`»: la fase empuja su rama `phase/<NN-slug>/<FF>`. `settings.json` lo permite y bloquea el push a `main` y el forzado.
- Plantilla de PR (`.github/pull_request_template.md`) con la tarea externa, la fase y su checklist.
- `ci/verify.yml`, que el instalador copia a `.github/workflows/`: corre `bin/verify.sh` completo en cada PR.
- Gates nuevos en el `verify.sh` de ambos stacks: escaneo de secretos (gitleaks) y auditoría de dependencias (`composer audit` o `npm audit --audit-level=high`).
- Protección del protocolo: en una rama de fase, `verify.sh` falla si el diff contra su base toca `CLAUDE.md`, `.ai/RULES.md`, `.ai/WORKFLOW.md`, las skills o `.claude/settings.json`, salvo en commits de ámbito `protocol`.
- `docs/modos.md`: nube por defecto (script de preparación del entorno con PHP, Composer, Node y PostgreSQL con PostGIS), local con Docker Compose o Remote Control, y la regla de terminar siempre igual.

Criterios de aceptación:

- [ ] `tests/run.sh` prueba la protección: una rama de fase que edita `CLAUDE.md` falla y un commit de ámbito `protocol` pasa.
- [ ] `actionlint` no da avisos sobre `ci/` ni `.github/`.
- [ ] La CI del PR está en verde.

## Fase 6 — Stack Laravel modular por defecto

**Objetivo:** que el stack de Laravel nazca modular, con contrato OpenAPI y errores RFC 9457.

Entregables:

- `RULES.md` y plantillas con módulos en `app/Modules/<Módulo>/` (Http, Models, Actions, Contracts, Events, Policies, Providers, rutas y base de datos propios) y un núcleo compartido en `app/Shared/`. Un módulo solo usa de otro sus `Contracts` y sus `Events`.
- `bin/make-module.sh <Nombre>`: crea el esqueleto del módulo y registra su provider.
- Pruebas de arquitectura de Pest que impiden usar modelos, tablas o clases internas de otro módulo.
- Alcance reescrito: lo no listado queda fuera, y la lista incluye `bootstrap/app.php`, comandos, jobs, policies, Filament, factories y seeders.
- Contrato: OpenAPI generado desde el código como baseline en `docs/contract/openapi.json` (propuesta: dedoc/scramble), con un gate que lo regenera y falla si cambió sin actualizar el baseline. El baseline de rutas se mantiene para proteger el middleware.
- Errores RFC 9457: `application/problem+json` con `type`, `title`, `status`, `detail` y la extensión `code`; los tests de contrato lo verifican.
- Pruebas contra PostgreSQL con PostGIS en `.env.testing` y en `ci/verify.yml`; fuera las menciones a MySQL.
- Job `e2e-laravel` en la CI del kit: crea un proyecto nuevo de Laravel, instala el stack, crea un módulo y corre `verify.sh`.

Criterios de aceptación:

- [ ] El job `e2e-laravel` pasa: proyecto nuevo + stack + `bin/make-module.sh Demo` y `bin/verify.sh` en verde.
- [ ] Un caso de prueba donde un módulo usa el modelo de otro hace fallar las pruebas de arquitectura.
- [ ] Un endpoint cambiado sin actualizar el baseline hace fallar el gate de contrato.

## Fase 7 — Stack Next.js completo

**Objetivo:** que el stack de Next.js verifique el build real, sus capas y el contrato generado.

Entregables:

- `verify.sh` con `next build` en modo completo, además de tipos, ESLint y Vitest.
- `eslint.config.mjs` con `eslint-plugin-boundaries` para la regla de capas (`app → features → entities → shared`), listado en el §1 de `RULES.md`.
- Cliente generado del OpenAPI en `src/shared/api/` (propuesta: openapi-typescript con openapi-fetch) y un gate que lo regenera y falla si quedó desactualizado. Las reglas de contrato pasan de esquemas Zod escritos a mano a los tipos generados.
- El cliente interpreta problem+json y discrimina los errores por `code`.
- Playwright instalado y configurado, fuera del verify rápido; Lighthouse CI con presupuestos que se llenan desde `.ai/project/`, como job de `ci/verify.yml`.
- Job `e2e-nextjs` en la CI del kit: crea un proyecto nuevo de Next.js, instala el stack y corre `verify.sh`.

Criterios de aceptación:

- [ ] El job `e2e-nextjs` pasa, con `next build` incluido.
- [ ] Un import que viola las capas hace fallar ESLint.
- [ ] Un cambio en el OpenAPI de ejemplo sin regenerar el cliente hace fallar el gate de contrato.

## Fase 8 — Validación de punta a punta y versión 2.0.0

**Objetivo:** cumplir el criterio de la tarea 1a y publicar la versión 2.0.0.

Entregables:

- Los jobs e2e generan además una épica de prueba desde un paquete de tareas y corren en ambos stacks el guardián, `verify.sh` y los casos de fallo.
- README reescrito: tres capas, instalación y actualización, modos de ejecución, roles, tipos de tarea, versiones, cómo separar un stack con su historial (`git filter-repo --subdirectory-filter stacks/<stack>`) y migración desde 1.x.
- `CHANGELOG` de `core`, `laravel` y `nextjs` en 2.0.0. La persona crea las etiquetas al fusionar.

Criterios de aceptación:

- [ ] Los jobs e2e pasan en ambos stacks con la épica de prueba.
- [ ] La CI del kit provoca y detecta todos los casos de fallo.
- [ ] `install.sh --upgrade` sobre una instalación 1.x de prueba muestra el diff sin tocar la memoria.

---

## Registro

- **Línea base medida en la fase 1:** —
- **Fases divididas:** —
- **Decisiones tomadas durante el plan:** —
- **Lo que la siguiente fase necesita saber:** —
