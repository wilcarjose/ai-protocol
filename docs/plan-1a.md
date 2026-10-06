# Plan 1a — Adaptación del kit ai-protocol

> **Origen:** tarea 1a de la Etapa 1 del portal inmobiliario.
> **Criterio de aceptación de la tarea:** una épica de prueba pasa el guardián y `verify.sh` en ambos stacks, y la CI del kit corre sus casos de fallo.
> **Análisis completo (para la persona):** https://claude.ai/code/artifact/43b693f7-4208-4afa-b908-d09ecd623c67 — todo lo que el agente necesita está en este archivo.
> **Rutas:** hasta la fase 2 los kits viven en `laravel/` y `nextjs/`; desde la fase 2, en `core/` y `stacks/`.

## Estado

| Fase | Objetivo | Depende de | Estado | PR |
|---|---|---|---|---|
| 1 | Base de verificación e inconsistencias | — | hecha | #1 |
| 2 | Núcleo, stacks e instalador | 1 | hecha | #2 |
| 3 | Menos tokens | 2 | hecha | #3 |
| 4 | Planificador, revisor y tipos de tarea | 3 | hecha | #4 |
| 5 | Modo remoto y CI de los proyectos | 4 | hecha | #5 |
| 6 | Stack Laravel: estructura estándar por funcionalidad | 5 | en revisión | #7 |
| 7 | Stack Next.js completo | 5 | hecha | #6 |
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
5. El stack de Laravel sigue la estructura estándar de Laravel: modelos, migraciones, factories, seeders, controladores, requests, resources, policies, rutas y Filament van donde Laravel los pone. La lógica de negocio (Actions, Services, Value Objects, Contracts y demás clases de negocio) va en su carpeta por tipo y, cuando una funcionalidad tiene varias clases, en una subcarpeta con su nombre (`app/Actions/Anuncios/PublicarAnuncio.php`). No hay módulos ni `app/Modules/`, y las pruebas de arquitectura son por capas. Reemplaza a la decisión de módulos (ver «Registro», 2026-10-06).
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
- `tests/run.sh` y `tests/fixtures/`: instala cada kit en un directorio temporal (rellena los `{{RELLENAR}}`, crea `composer.json` o `package.json` con las versiones del §1 de `RULES.md` y una épica de prueba desde las plantillas), comprueba que el guardián pasa y luego provoca cada uno de los 13 fallos de la cabecera de `bin/check-docs.sh`, comprobando que falla. El fallo 5 (migraciones) no aplica en un kit cuya plantilla de fase no declara «Migraciones:» (Next.js): ahí se comprueba que el guardián acepta fases sin ese campo.
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

- [ ] `sh tests/run.sh` termina en 0 y reporta los fallos provocados y detectados: 13 en Laravel; 12 en Next.js, con el 5 como no aplicable.
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

## Fase 6 — Stack Laravel: estructura estándar por funcionalidad

**Objetivo:** que el stack de Laravel conserve la forma de trabajo de Laravel, con la lógica de negocio agrupada por funcionalidad, contrato OpenAPI y errores RFC 9457.

Entregables:

- `RULES.md` y `.ai/rules/arquitectura.md` con la estructura de la decisión 5. Lo propio del framework queda en su lugar habitual y los modelos, planos en `app/Models`. La lógica de negocio va en `app/Actions`, `app/Services`, `app/ValueObjects`, `app/Contracts`…, con subcarpeta por funcionalidad cuando tiene varias clases. El nombre de una funcionalidad es el mismo en todas las carpetas, y controladores, requests y resources pueden usar esa subcarpeta cuando ayude. Las clases se crean con los `make:` de artisan (`make:class`, `make:interface`, `make:enum`) y su ruta.
- Mapa de funcionalidades: semilla `.ai/project/FEATURES.md` (funcionalidad → carpetas y archivos clave, incluidos sus tests). Lo usa el planificador al escribir la fase y lo cita su §2; el ejecutor no lo lee al arrancar.
- Pruebas de arquitectura por capas, del kit y protegidas: la lógica de negocio no depende de `Illuminate\Http` ni de controladores, los modelos no dependen de Actions, Services ni HTTP, los Value Objects son `final` e inmutables y los Contracts son interfaces. Conserva las reglas útiles del `ArchitectureTest.php` actual. Las reglas propias del proyecto van en un archivo de tests aparte, que es semilla (decisión de la fase 5).
- Alcance reescrito: lo no listado queda fuera. La lista incluye `bootstrap/app.php`, comandos, jobs, eventos y listeners, policies, Filament, factories, seeders, rutas y las carpetas de lógica de negocio con sus subcarpetas.
- Contrato: OpenAPI generado desde el código como baseline en `docs/contract/openapi.json` (propuesta: dedoc/scramble), con un gate que lo regenera y falla si cambió sin actualizar el baseline. Es la misma ruta que usa la copia de Next.js (fase 7). El baseline de rutas se mantiene para proteger el middleware.
- Errores RFC 9457: `application/problem+json` con `type`, `title`, `status`, `detail` y la extensión `code`; los tests de contrato lo verifican.
- Pruebas contra PostgreSQL con PostGIS en `.env.testing` y en el servicio de `stacks/laravel/.github/workflows/verify.yml`; fuera las menciones a MySQL.
- Decide si `composer audit` audita solo producción (`--no-dev`), como Next.js, y anótalo en «Registro».
- Job `e2e-laravel` en la CI del kit: `tests/e2e-laravel.sh`, con la misma forma que `tests/e2e-nextjs.sh`. Crea un proyecto nuevo de Laravel, instala el stack, agrega una funcionalidad de ejemplo (una Action en `app/Actions/Demo/` con su test) y corre `verify.sh` completo.
- El ejecutor de Laravel está a 45 caracteres de su línea base: lo que crezca `RULES.md` se compensa, y el detalle va a `.ai/rules/arquitectura.md`, que no cuenta en el arranque.

Criterios de aceptación:

- [ ] El job `e2e-laravel` pasa: proyecto nuevo + stack + funcionalidad de ejemplo y `bin/verify.sh` completo en verde.
- [ ] Un caso de prueba donde una Action usa `Illuminate\Http\Request` hace fallar las pruebas de arquitectura.
- [ ] Un endpoint cambiado sin actualizar el baseline hace fallar el gate de contrato.
- [ ] `sh tests/run.sh` pasa, con el contexto del ejecutor dentro de `tests/context-baseline.txt`.

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

- **Línea base medida en la fase 1:** `sh laravel/bin/measure-context.sh` sobre `7d25562` (el kit antes de la fase 1) reproduce la tabla «Línea base»:

  ```
  Sesión         Caracteres  Archivos
  cualquiera         20812  1
  ejecutor           76196  8
  planificador       89300  10
  rescate            47906  5
  ```

  Después de la fase 1, las citas por nombre son más largas que las numéricas: cualquiera 21 189, ejecutor 76 911, planificador 90 170 y rescate 48 424. El objetivo de la fase 3 (53 300 para el ejecutor) sigue calculado sobre la línea base.

  Después de la fase 2 (`sh bin/measure-context.sh` sobre `install.sh --stack laravel`): cualquiera 21 017, ejecutor 78 762, planificador 92 021 y rescate 48 425. El ejecutor y el planificador leen además `.ai/project/README.md` (9 y 11 archivos), porque el contexto operativo y los repos hermanos salieron de `CLAUDE.md`.

  Después de la fase 3, sobre una instalación limpia:

  ```
  Sesión         laravel   nextjs
  cualquiera        4028     4028
  ejecutor         51830    52805
  cierre            5931     5931
  planificador     60375    61220
  rescate          35479    35473
  ```

  El ejecutor de Laravel baja un 32 % respecto a la línea base (76 196). «cierre» es lo que el ejecutor añade en el Paso C (`.claude/skills/phase/cierre.md`) y no cuenta en el arranque. Los valores del ejecutor y de `CLAUDE.md` están en `tests/context-baseline.txt`.

  Después de la fase 4, sobre una instalación limpia (el planificador se separa en épica y fase, y se mide el revisor):

  ```
  Sesión         laravel   nextjs
  cualquiera        4171     4171
  ejecutor         53080    54055
  cierre           10339    10339
  plan-epica       53337    54188
  plan-fase        55427    56402
  revisor          33063    34044
  rescate          38361    38355
  ```

  El ejecutor de Laravel sigue por debajo de 53 300 (un 30 % menos que la línea base). Sube 1 250 caracteres por el estado `ESPERA_EVIDENCIA`, el modo ligero, el tipo de tarea y la sección «Revisión» de la plantilla; `CLAUDE.md`, por las tres skills nuevas de su tabla. «cierre» incluye ahora `/review`, y el rescate lo nota porque lee `cierre.md`. `tests/context-baseline.txt` tiene los valores nuevos.

  Después de la fase 5, sobre una instalación limpia:

  ```
  Sesión         laravel   nextjs
  cualquiera        4112     4112
  ejecutor         53255    54240
  cierre           11377    11377
  plan-epica       53436    54297
  plan-fase        55526    56511
  revisor          33309    34300
  rescate          39525    39519
  ```

  El ejecutor de Laravel sube 175 caracteres y queda a 45 del tope de 53 300: `WORKFLOW.md §Archivos del protocolo` es nueva, y se compensa con lo que sale de `CLAUDE.md` y de la tabla de `WORKFLOW.md §Documentación: dónde va cada cosa`. «cierre» sube 1 038 por `cierre.md §Entrega`. `tests/context-baseline.txt` tiene los valores nuevos.

  Después de la fase 7, sobre una instalación limpia (Laravel no cambia):

  ```
  Sesión         laravel   nextjs
  cualquiera        4112     4112
  ejecutor         53255    54755
  cierre           11377    11377
  plan-epica       53436    54812
  plan-fase        55526    57026
  revisor          33309    34815
  rescate          39525    39519
  ```

  El ejecutor de Next.js sube 515 caracteres (+0,95 %) por las filas nuevas de `RULES.md §Stack y versiones exactas`, la copia del contrato en §Alcance, los principios 2 y 4 y los gates de §Verificación del stack. El detalle (cliente, problem+json, Playwright, Lighthouse) va a `.ai/rules/contrato.md` y `.ai/rules/tests.md`, que no cuentan en el arranque. `tests/context-baseline.txt` tiene el valor nuevo.

  Después de la fase 6, sobre una instalación limpia:

  ```
  Sesión         laravel   nextjs
  cualquiera        4112     4112
  ejecutor         53247    54831
  cierre           11377    11377
  plan-epica       53428    54888
  plan-fase        55649    57233
  revisor          33225    34815
  rescate          39525    39519
  ```

  El ejecutor de Laravel baja 8 caracteres y queda a 53 del tope de 53 300: `RULES.md` crece por la fila de
  `dedoc/scramble` y baja más al compactar el alcance y la verificación. El de Next.js sube 76 por la fila de
  `FEATURES.md` en `.ai/project/README.md`, del núcleo. El detalle (estructura por funcionalidad, `make:`, errores)
  va a `.ai/rules/arquitectura.md` y `.ai/rules/tests.md`, que no cuentan en el arranque. `tests/context-baseline.txt`
  tiene los dos valores nuevos.
- **Fases divididas:** —
- **Decisiones tomadas durante el plan:**
  - 2026-10-04 (fase 1): el fallo 5 del guardián (migraciones) solo se provoca en kits cuya plantilla de fase declara «Migraciones:». En Next.js no aplica, y `tests/run.sh` comprueba en su lugar que el guardián acepta fases sin ese campo. El criterio de la fase 1 pasa a «13 fallos en Laravel; 12 en Next.js, con el 5 como no aplicable».
  - 2026-10-04 (fase 1): la rama `plan-1a/fase-1` sale de `plan-1a/fase-0`, que tiene el plan y aún no está en `main`, y su PR va contra `main`.
  - 2026-10-05 (fase 2): la fase va en un solo PR, sin dividirla en 2a y 2b.
  - 2026-10-05 (fase 2): las versiones exactas del stack son del proyecto y viven en `.ai/project/DECISIONS.md §Stack y versiones exactas`. `RULES.md §Stack y versiones exactas` se queda con el paquete y su nota, y el chequeo «stack» exige una versión en la capa del proyecto por cada paquete de esa tabla (caso `9n` de `tests/run.sh`).
  - 2026-10-05 (fase 2): hasta la fase 8, los tres paquetes van en `2.0.0-dev`, y cada stack pide el núcleo `>=2.0.0-dev <3.0.0`. Los CHANGELOG acumulan en «Sin publicar».
  - 2026-10-05 (fase 2): en `--upgrade`, un archivo del kit que el proyecto cambió no se pisa: se enseña el diff como conflicto. El lock conserva la suma anterior, así que el conflicto se repite en cada upgrade hasta que el archivo coincide con el kit.
  - 2026-10-05 (fase 2): el núcleo tiene su manifiesto, `core/core.json`, con el formato de `stack.json`. Cada manifiesto separa `files` (del kit, se actualizan) de `seed` (se copian si faltan y después son del proyecto: memoria, `.ai/project/`, `docs/runbooks/release.md`, `docs/vendor/INDEX.md`).
  - 2026-10-05 (fase 3): la fase va en un solo PR.
  - 2026-10-05 (fase 3): el cierre (de fase y de épica, traspaso, archivo de la memoria y reporte final) vive en `.claude/skills/phase/cierre.md`, que la skill lee en el Paso C. `measure-context.sh` lo mide en su propia fila, «cierre», fuera del arranque del ejecutor; `/close` también lo usa.
  - 2026-10-05 (fase 3): no hay skill con `paths` para cargar `.ai/rules/`. La fase los cita en su §2, que funciona en cualquier herramienta; la carga por rutas queda pendiente hasta que se verifique cómo se comporta.
  - 2026-10-05 (fase 3): `tests/context-baseline.txt` guarda lo que leen al arrancar el ejecutor de cada stack y `CLAUDE.md`. `tests/run.sh` falla si una sesión supera su línea base en más de un 3 % y avisa si baja más de un 3 %. Subir la línea base es cambiar ese archivo en un PR que diga por qué.
  - 2026-10-05 (fase 3): al archivo de `DOMAIN.md` van, además de las decisiones con `**Reemplazada por:**`, las filas `respondida` de §Decisiones pendientes. Lo que sobra de «Últimos movimientos» se borra, sin archivarlo: el detalle vive en el RESULTADO de cada fase.
  - 2026-10-05 (fase 3): la evidencia de una fase vive en `.ai/epics/<NN-slug>/evidence/<FF>-<nombre>.txt`, fuera del patrón `phase-*.md` que recorre el guardián.
  - 2026-10-05 (fase 3): reglas que cambian de casa con `CLAUDE.md` mínimo. Commits y `git push`: `.claude/skills/phase/SKILL.md §Commits durante la fase`. Traspaso: `.claude/skills/phase/cierre.md §Traspaso al otro repo`. No arreglar de paso: sigue en `CLAUDE.md §Alcance`.
  - 2026-10-05 (fase 4): la fase va en un solo PR, sin dividirla en 4a y 4b.
  - 2026-10-05 (fase 4): `ESPERA_EVIDENCIA` no retiene el puntero: es la primera fila sin `HECHA` ni `ESPERA_EVIDENCIA`. `STATE.md §Esperando evidencia` (sección derivada, que cuadra el chequeo «contadores») nombra las que esperan; una instalación anterior puede no tenerla mientras no haya ninguna. La fase que depende de una que espera se para en su Paso A, porque su «Depende de» no está `HECHA`. La épica no se cierra mientras una fase espere. La evidencia se completa con `/phase <epica> <FF>` y el commit `chore(phase-<NN>-<FF>): evidence` (`cierre.md §Evidencia humana`).
  - 2026-10-05 (fase 4): «Tipo» y «Modo» son opcionales en la cabecera: sin ellos, código y modo normal, para que las fases escritas con la plantilla anterior sigan pasando tras el upgrade. Una fase ligera exige, además de uno o dos entregables, `Contrato HTTP: SIN CAMBIOS` y, si la plantilla lo pide, `Migraciones: ninguna`.
  - 2026-10-05 (fase 4): la sección «Revisión» es el `## 10.` de la plantilla, fuera del RESULTADO. El guardián sólo la exige en las fases `HECHA` o `ESPERA_EVIDENCIA` que la tienen, así que las fases antiguas no fallan. `/review` corre en el paso 3 de `cierre.md`, después de ejecutar los criterios (el revisor comprueba su evidencia) y antes del estado final; en `BLOQUEADA` o `VERIFICACION_ROJA` no hace falta.
  - 2026-10-05 (fase 4): el chequeo 14 «tareas» comprueba, además de que la tarea existe en un paquete, que su criterio está literal en «Criterios de éxito». Una tarea es una fase: si no cabe en una, STOP & ASK, porque partirla es cambiar el plan externo.
  - 2026-10-05 (fase 4): el criterio de `/review` se probó lanzando un subagente `general-purpose` con `reviewer.md` como instrucciones. Un agente definido en una instalación temporal no se puede cargar como tipo propio desde esta sesión. La revisión encontró, además del bloqueante esperado, dos defectos reales del fixture: el comando de cada tarea (corregido en `tests/run.sh`) y el ámbito `web` del commit de prueba.
  - 2026-10-06 (fase 5): la fase va en un solo PR.
  - 2026-10-06 (fase 5): el workflow de los proyectos es uno por stack, `stacks/<stack>/.github/workflows/verify.yml`, en su `stack.json` como cualquier archivo: Laravel y Next.js necesitan pasos distintos, y el stack se separa entero con `filter-repo`. `ci/` desaparece. Donde las fases 6 y 7 dicen `ci/verify.yml`, es ese archivo de su stack, y el criterio de `actionlint` de esta fase se cumple sobre `.github/` y `stacks/*/.github/`.
  - 2026-10-06 (fase 5): la protección cubre todo lo que `.ai/protocol.lock` marca `kit`, más el propio lock, así que `bin/verify.sh`, `bin/check-docs.sh` y el propio `bin/check-protocol.sh` también quedan protegidos. Lo que el proyecto tiene que poder editar es semilla, y el lock lo marca `project` (antes `seed`, que se sigue leyendo): la memoria, `.ai/project/` (con `verify.conf`), `phpstan.neon` y los `docs/README.md` de los stacks. Las reglas de arquitectura del kit siguen protegidas; las propias del proyecto irán en un archivo aparte en la fase 6.
  - 2026-10-06 (fase 5): la evidencia humana de una fase cuyo PR ya se fusionó va en una rama nueva, `phase/<NN-slug>/<FF>-evidence`, creada desde la base donde se integró, con su propio PR.
  - 2026-10-06 (fase 5): la baseline (`MIN_TESTS` y la deuda congelada) y, en Laravel, `VERIFY_SERVICE` y `COMPOSE_CMD` pasan a `.ai/project/verify.conf` (semilla de cada stack). `bin/verify.sh` queda entero del kit y falla si ese archivo no existe.
  - 2026-10-06 (fase 5): el gate «secretos» corre `gitleaks git` sobre todo el historial, también con `--fast`, y falla si gitleaks no está instalado. Un aviso no basta, porque lo que se escanea tiene que estar limpio antes del push. «dependencias» va sólo en el verify completo, porque consulta la red. «protocolo» corre en los dos modos.
  - 2026-10-06 (fase 5): la fase empuja su rama al cerrar en cualquier estado, y abre el PR con `gh pr create`, en borrador si cierra `BLOQUEADA` o `VERIFICACION_ROJA`. Nunca lo fusiona. `settings.json` permite empujar sólo `phase/*` y bloquea el push a `main`, con `:` en el refspec, forzado y con borrado.
  - 2026-10-06 (fase 5): en la nube, el proxy de GitHub de Claude Code no limita a qué rama se empuja (sólo rechaza borrados y etiquetas), y una regla de permisos no es una barrera de seguridad. `docs/modos.md` pide un *ruleset* de GitHub sobre `main`. Las releases de GitHub de un repo que no está en la sesión dan 403, así que el script de preparación instala gitleaks con `go install`.
  - 2026-10-04 (fase 1): dónde vive cada regla que estaba repetida. Exenciones a un gate: `WORKFLOW.md §Obediencia arquitectónica`. No arreglar de paso: `CLAUDE.md §Alcance`. Dependencias nuevas: `WORKFLOW.md §Dependencia nueva`. `git push`: `CLAUDE.md §Commits durante la fase`. Las listas negras de `RULES.md` quedan solo con lo propio del stack.
  - 2026-10-06 (fase 7): la fase va en un solo PR. Son unos 12 archivos con lógica, pero casi todos son configuraciones cortas.
  - 2026-10-06 (fase 7): `eslint-plugin-boundaries` 7.2.0 sólo trae el resolver de Node y no entiende el alias `@/`, así que se añade `eslint-import-resolver-typescript`, que el plan no listaba (aprobado en el Paso A). Los dos van en la misma fila de `RULES.md §Stack y versiones exactas` que `eslint`. La regla va entera en `boundaries/dependencies`: `boundaries/entry-point` está obsoleta en la 7, y la entrada por `index.ts` se expresa con `fileInternalPath`.
  - 2026-10-06 (fase 7): `eslint.layers.mjs` es del kit (protegido) y `eslint.config.mjs`, semilla que lo importa. El gate «capas» lee la configuración efectiva (`eslint --print-config`) de un archivo de una feature y falla si `boundaries/dependencies` no está como error: un proyecto que ya tenía su `eslint.config.mjs` (el instalador no lo pisa) se entera.
  - 2026-10-06 (fase 7): Playwright no corre en `verify.sh`. El verify completo sólo corre `playwright test --list --pass-with-no-tests` (gate «e2e»), y los E2E los corre la fase que los pide, porque necesitan el backend.
  - 2026-10-06 (fase 7): el gate «dependencias» de Next.js pasa a `npm audit --audit-level=high --omit=dev` (aprobado). GHSA-vfj7-8cjw-p6xm (`braces`, sin arreglo publicado) entra por `eslint-config-next`, que trae el propio create-next-app, y por eslint-plugin-boundaries, y dejaba en rojo cualquier proyecto nuevo. Con `--omit=dev` da 0.
  - 2026-10-06 (fase 7): la copia del OpenAPI vive en `docs/contract/openapi.json` (la misma ruta que el baseline del backend de la fase 6) y los tipos en `src/shared/api/schema.d.ts`; los dos se versionan y sus rutas se pueden cambiar en `.ai/project/verify.conf` (`CONTRACT_SPEC`, `CONTRACT_TYPES`). La semilla trae un OpenAPI sin rutas y sus tipos ya generados: el proyecto compila nada más instalarse y el chequeo «rutas» del guardián no avisa. Si otra versión de openapi-typescript genera distinto, el gate «contrato» pide regenerar.
  - 2026-10-06 (fase 7): los presupuestos de Lighthouse son semilla en `.ai/project/lighthouse.json` (la configuración de LHCI entera: URL, `startServerCommand`, aserciones). `CROSS-CUTTING.md` es del núcleo y no puede citarlo, así que es `.ai/rules/tests.md` quien une los dos.
  - 2026-10-06 (fase 7): el e2e es `tests/e2e-nextjs.sh`, propio del stack, y usa `tests/lib.sh` para rellenar la capa del proyecto como `tests/run.sh`.
  - 2026-10-06 (replanificación de la fase 6, decidida por la persona): la decisión 5 deja los módulos en `app/Modules/` y pasa a la estructura estándar de Laravel, con la lógica de negocio agrupada por funcionalidad. No hay `bin/make-module.sh`. Las fases 1 a 5 y 7 no cambian: no construyeron nada modular. En la Etapa 1 del portal, la decisión 7 cambia en el mismo sentido.
  - 2026-10-06 (fase 6, decidido por la persona en el Paso A): la fase va en un solo PR, aunque pasa de 10 archivos
    con lógica. Las Actions se llaman `{Verbo}{Sustantivo}`, sin sufijo, como el ejemplo de la decisión 5; ninguna
    prueba lo exige, así que las que ya lo llevan siguen pasando. Las Actions de Laravel Fortify
    (`App\Actions\Fortify`) las excluye la prueba del kit, por nombre y con su motivo. `.ai/project/FEATURES.md` es
    semilla del núcleo (los dos stacks la reciben) y `/plan-phase` pide citar sus filas en el §2 de la fase.
  - 2026-10-06 (fase 6): `composer audit` audita sólo producción (`--no-dev`), como Next.js.
  - 2026-10-06 (fase 6): «la lógica de negocio no depende de `Illuminate\Http`» deja fuera `Illuminate\Http\Client`:
    la implementación de un contrato que llama a un servicio externo captura su `ConnectionException`
    (`.ai/rules/rendimiento.md`). La capa HTTP es `App\Http`, `Illuminate\Http`, `Illuminate\Routing`,
    `Illuminate\Foundation\Http` y `request()`, `response()`, `redirect()`. La lógica de negocio son Actions,
    Services, Value Objects, Contracts, Data y Enums; `App\Exceptions` no entra.
  - 2026-10-06 (fase 6): los errores RFC 9457 son semillas: `App\Exceptions\ApiException` (mensaje, `errorCode`,
    contexto y status, en ese orden, el del ejemplo de `arquitectura.md`) y `App\Http\ProblemDetails`, que se registra
    con una línea en `bootstrap/app.php`, porque ese archivo es del proyecto. `type` es `about:blank`, `title` es el
    texto del status, y los códigos de lo que no es negocio son `VALIDATION_FAILED` (con `errors`), `UNAUTHENTICATED`,
    `FORBIDDEN`, `NOT_FOUND`, `METHOD_NOT_ALLOWED`, `TOO_MANY_REQUESTS`, `SERVER_ERROR`… Una `ApiException` 4xx no se
    reporta (un callback de `report` que devuelve `false`), lo que sustituye la regla de `dontReport` y su trampa de
    namespace.
  - 2026-10-06 (fase 6): `docs/contract/openapi.json` es también semilla de Laravel, la de un proyecto sin rutas de
    API. Sin ella, `tests/structure.sh` (chequeo «referencias») rechaza que Laravel cite una ruta que sólo lista
    Next.js. En un proyecto que ya tiene rutas, el gate «contrato» falla hasta que se genera con `sh bin/contract.sh`.
  - 2026-10-06 (fase 6): scramble toma el título y el servidor del documento de `APP_NAME` y `APP_URL`, así que el
    OpenAPI cambiaría entre la máquina de cada uno y la CI. `bin/contract.sh` los fija con `CONTRACT_APP_NAME` (`API`)
    y `CONTRACT_APP_URL` (`http://localhost`) de `.ai/project/verify.conf`.
  - 2026-10-06 (fase 6): el gate «arquitectura» corre en los dos modos de `bin/verify.sh`. La fase 1 lo quitó del modo
    completo dando por hecho que iba en la suite, pero las suites del `phpunit.xml` de Laravel son Unit y Feature: las
    pruebas de arquitectura no corrían nunca en el verify completo.
  - 2026-10-06 (fase 6): `.env.testing` es semilla, sin secretos y con `APP_KEY` vacía: cada proyecto la genera con
    `php artisan key:generate --env=testing` y la versiona (gitleaks 8.30.1 no marca una `APP_KEY` versionada:
    probado). El workflow la genera si está vacía. El gate «suite» falla si `phpunit.xml` fija `DB_CONNECTION` o
    `DB_DATABASE`, como hace el del esqueleto con SQLite en memoria, que le ganaría a `.env.testing`.
- **Lo que la siguiente fase necesita saber:**
  - **Dónde vive cada cosa.** El núcleo, en `core/` (manifiesto `core/core.json`); cada stack, en `stacks/<stack>/` (`stack.json`). Instalados, los archivos conservan sus rutas (`CLAUDE.md`, `.ai/…`, `.claude/skills/…`, `bin/…`). `install.sh` está en la raíz.
  - **Las skills.** `/phase` es `.claude/skills/phase/SKILL.md` (pasos, rama, estados, sincronización, commits, verificación) más `phase/cierre.md` (cierre con revisión, cierre ligero, evidencia humana, épica, archivo de la memoria, traspaso, reporte final). `/close`, `/plan-epic`, `/plan-phase` y `/review` son una `SKILL.md` cada una; `/phase` y `/close` llevan `disable-model-invocation: true`, y `/review` no, para que `/phase` la invoque. El revisor es `.claude/agents/reviewer.md` (Read, Grep, Glob y Bash sólo para git y el guardián). Una skill o un agente nuevo entra en `core/core.json` (`files`) y en las listas de `core/bin/measure-context.sh`, y si la lee el ejecutor al arrancar, mueve su línea en `tests/context-baseline.txt`. El upgrade desde la fase 3 retira `/planning` sola (probado).
  - **La CI de los proyectos (fases 6 y 7).** Cada stack trae `.github/workflows/verify.yml`, que corre `sh bin/verify.sh` completo con `fetch-depth: 0` y gitleaks 8.30.1. Laravel toma PHP de `.php-version`, y la fase 6 le añade el servicio de PostgreSQL con PostGIS. Next.js toma Node de `engines.node`, y la fase 7 le añade el job de Lighthouse. `actionlint` (con `actionlint-py==1.7.12.25`) revisa en la CI del kit esos workflows y los del kit. Los workflows y los gates «dependencias» y «secretos» sólo se han probado con `actionlint`, `shellcheck` y a mano sobre una instalación (gitleaks sí: detecta un token y pasa sin él). La primera ejecución real es el e2e de las fases 6 y 7.
  - **La protección del protocolo.** `bin/check-protocol.sh` lee del lock qué archivos son `kit`: todo archivo nuevo que un stack liste en `files` queda protegido sin hacer nada más. Lo que el proyecto tenga que editar va en `seed` (las reglas de arquitectura del proyecto y `.ai/project/FEATURES.md`, de la fase 6, son semilla). La rama base se resuelve así: `PROTOCOL_BASE`, `origin/$GITHUB_BASE_REF`, `epic/<NN-slug>`, `main`. `tests/run.sh` (`test_protocol`) lo prueba en un repo git, y en Alpine la CI instala `git` con `apk`.
  - **`bin/verify.sh` es del kit.** Lo del proyecto está en `.ai/project/verify.conf` (semilla). Un gate nuevo entra en el `verify.sh` y en `gates` del `stack.json` (`tests/structure.sh` lo cuadra), y si necesita una herramienta, la instalan el workflow del stack y el script de `docs/modos.md`.
  - **El script de preparación de la nube** (`docs/modos.md`) no se ha probado en una sesión real. Se comprobó `go install` de gitleaks con `GOTOOLCHAIN=auto` y que el script pasa `shellcheck`. PHP 8.4 necesita el PPA de ondrej, que no está en la lista Trusted. Desde aquí no se pudo resolver `archive.ubuntu.com` para confirmar `postgresql-16-postgis-3`.
  - **El revisor** necesita Bash para `git diff` y puede correr `sh bin/check-protocol.sh`. En la CI no corre: lo lanza `/phase` en la sesión.
  - **Las citas a una skill van con la ruta completa** (`.claude/skills/phase/SKILL.md §Estado de una fase`): el chequeo «secciones» valida `.claude/skills/*.md`, `.ai/rules/*.md` y `.ai/archive/*.md`. Una cita a `cierre.md` a secas no se valida.
  - **Las reglas por capas.** `.ai/RULES.md` es el núcleo y su `§Reglas por tema` indexa `.ai/rules/`. Los dos stacks tienen `arquitectura.md` y `tests.md` (el núcleo puede citarlos); Laravel tiene además `rendimiento.md` y Next.js, `contrato.md` (el núcleo no puede citarlos: `tests/structure.sh`). El revisor de la fase 4 lee el núcleo y los temas que cita la fase.
  - **Un solo reporte.** El RESULTADO es el reporte; el chat da cinco líneas (`cierre.md §Reporte final`). La sección «Revisión» que añade la fase 4 va en la plantilla de fase: un encabezado nuevo del RESULTADO hace fallar el guardián en las fases vivas escritas con la plantilla vieja (chequeo «fases»), así que conviene que vaya fuera del RESULTADO o que se diga en el CHANGELOG.
  - **La memoria tiene topes.** El chequeo 13 «memoria» del guardián exige que lo cerrado esté en `.ai/archive/`. Un estado nuevo (`ESPERA_EVIDENCIA`, fase 4) se añade también a las listas de estados del chequeo «puntero» y «fases», y a `.claude/skills/phase/SKILL.md §Estado de una fase`.
  - **`tests/run.sh`.** Un caso con número en `provoke` es un fallo de la cabecera de `bin/check-docs.sh` (15 en Laravel; 14 en Next.js); uno con letra, una variante. `accept` prueba lo que tiene que pasar. La épica de prueba es 01-demo (CERRADA) y 02-paquete, creada desde `tests/fixtures/stages/E1.md` con helpers `task`, `header` y `criterion`; el puntero está en `02-paquete/03` (ligera) y `02-paquete/02` espera evidencia. El bloque `test_installer` usa `kit_copy` para simular un kit nuevo; `test_context` mide una instalación limpia contra `tests/context-baseline.txt`.
  - **Todo archivo nuevo entra en un manifiesto,** en `files` o en `seed`, o `tests/structure.sh` falla. Los manifiestos y el lock se leen sin jq: un valor por línea.
  - **El contexto del ejecutor de Laravel está a 53 caracteres del tope de 53 300** (fase 6). Lo que se añada a `CLAUDE.md`, a `.claude/skills/phase/SKILL.md`, a `WORKFLOW.md`, a `RULES.md`, a `.ai/project/README.md` o a la plantilla de fase hay que compensarlo. Lo que sólo hace falta al cerrar va en `cierre.md`, que no cuenta en el arranque.
  - **Proyectos que suben a 2.0.** El upgrade no toca la memoria: lo cerrado que ya tuvieran se mueve a mano a `.ai/archive/` (README.md §Actualizar un proyecto). La fase 8 lo prueba con una instalación 1.x.
  - **El e2e de Next.js (fases 6 y 8).** `tests/e2e-nextjs.sh` fija las versiones (create-next-app 16.3.8 y los paquetes del stack), borra los `AGENTS.md`, `CLAUDE.md` y `eslint.config.mjs` que crea create-next-app antes de instalar, rellena la capa con `tests/lib.sh` (`fill_stack`, `fill_markers`), versiona el proyecto en git y corre `bin/verify.sh` completo. Después provoca los dos fallos del criterio. En la CI corre además Lighthouse (`E2E_LIGHTHOUSE=1`; el runner trae Chrome; en Docker, Chrome necesita `--no-sandbox`). La fase 6 puede escribir `tests/e2e-laravel.sh` con la misma forma, y la fase 8 añade a los dos la épica de prueba. En local se probó dentro de `node:22` con gitleaks 8.30.1.
  - **npm 10 y las peers de Vite 8.** Con el `@types/node@^20` de create-next-app, `npm install vitest@4.1.x` revienta (`Cannot read properties of null (reading 'edgesOut')`) por la cadena de peers opcionales de Vite 8. Con `@types/node@22` (el proyecto declara Node 22) y Vitest 5.0.3, instala. Vitest 4.0.0 instala, pero no arranca con Vite 8.
  - **Next 16.3 y `AGENTS.md`.** create-next-app crea `AGENTS.md` y `CLAUDE.md`, y `next dev`, lanzado por un agente, vuelve a escribir su bloque en `AGENTS.md` (`node_modules/next/dist/server/lib/generate-agent-files.js`), que es del kit. `RULES.md §Alcance` pide `agentRules: false` en `next.config.*`, y `stacks/nextjs/CHANGELOG.md` dice qué hacer al actualizar un proyecto que ya los tiene. La fase 8 lo lleva al README (migración).
  - **El e2e de Laravel (fase 8).** `tests/e2e-laravel.sh` tiene la forma del de Next.js. Fija las versiones
    (laravel/laravel 13.10.1, laravel/framework 13.34.0, dedoc/scramble 0.13.47, Pest 5.3.0 con pest-plugin-laravel
    5.0.1, Larastan 3.12.3 y Pint 1.32.1) y cambia PHPUnit por Pest. Borra el `AGENTS.md`, el `CLAUDE.md` y los tests
    de ejemplo que crea create-project, quita de `phpunit.xml` la conexión SQLite, copia
    `tests/fixtures/laravel-e2e/` (Action `App\Actions\Demo\ShowDemo`, su endpoint `GET /api/demos/{id}`, sus tests,
    un `bootstrap/app.php` que registra las rutas de la API y `ProblemDetails`, y una migración que activa PostGIS),
    genera la clave de tests y los dos baselines, y corre `bin/verify.sh` completo contra PostgreSQL con PostGIS
    (`DB_HOST`, 127.0.0.1 por defecto). Luego provoca los dos fallos del criterio. En la CI, con el servicio
    `postgis/postgis:17-3.5`. En local se probó en un contenedor `php:8.4-cli` con `pdo_pgsql`, Composer y gitleaks
    8.30.1, en la misma red que `postgis/postgis:17-3.5`. La fase 8 le añade la épica de prueba.
  - **Pest 5 y su plugin de arquitectura.** Un `expect([...])` con varios namespaces da la regla por buena si uno de
    ellos no existe, y `->ignoring()` sólo vale para la última expectativa de la cadena. Por eso
    `ArchitectureTest.php` lleva una regla por namespace y una expectativa por `arch()`. Un `use` que no se usa no
    cuenta como dependencia.
  - **laravel/pao.** El esqueleto de Laravel 13 lo trae en `require-dev`. Cuando detecta un agente (`CLAUDECODE`,
    `AI_AGENT`…), cambia la salida de Pest, PHPStan y Pint por JSON. `bin/verify.sh` y el e2e exportan
    `PAO_DISABLE=1`, y un script que lea la salida de Pest tiene que hacer lo mismo.
  - **scramble no documenta los errores problem+json.** Documenta las respuestas que infiere del código, no las que
    salen de `ProblemDetails`. El cliente de Next.js los reconoce por la cabecera `Content-Type`, así que funciona,
    pero el OpenAPI no los lista.
  - **Los tipos de rutas de Next.** `tsc --noEmit` falla en un clon limpio (`LayoutProps`, `PageProps`) hasta que `next typegen` los genera en `.next/types`; el gate «tipos» lo corre antes. Un script que compile fuera de `verify.sh` tiene que hacer lo mismo.
  - **Cada cambio va al `CHANGELOG.md` de su paquete,** en «Sin publicar». La CI usa `shellcheck-py==0.11.0.1` sobre `install.sh core/bin/*.sh stacks/*/bin/*.sh tests/*.sh`, y `actionlint-py==1.7.12.25`.
