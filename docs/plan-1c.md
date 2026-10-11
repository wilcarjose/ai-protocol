# Plan 1c — Plantillas base y reglas para cualquier proyecto

> **Origen:** decisiones de la persona del 10 de octubre de 2026. El kit sirve a cualquier proyecto con API y web (y
> después Expo), no sólo al portal; todos los proyectos usan PostgreSQL; los textos para el usuario siempre son
> traducibles; y un proyecto nuevo nace de dos repos plantilla, `base-api` y `base-web`, con el protocolo instalado
> desde este repo (la opción A: este repo sigue siendo la fuente y el lock viaja con la plantilla).
> **Base:** núcleo 2.1.0, Laravel 2.0.1 y Next.js 2.0.0. Lo que cambie sube versión por paquete, con su
> `CHANGELOG.md` (README.md §Versiones y etiquetas).

## Estado

| Fase | Objetivo | Depende de | Estado | PR |
|---|---|---|---|---|
| 1 | Idiomas y PostgreSQL en las reglas | — | hecha | #17 |
| 2 | Proyecto nuevo desde una plantilla | 1 | hecha | #18 |
| 3 | Plantilla de la API (`base-api`) | 1 | en curso | |
| 4 | Plantilla web (`base-web`) | 3 | pendiente | |
| 5 | Validación de punta a punta | 2, 4 | pendiente | |

Las fases 1 y 2 cambian el kit. Las 3 y 4 crean cada plantilla y la construyen con el propio protocolo; la 4 empieza
cuando la API publica su contrato de autenticación (BA-02 del paquete).

## Cómo se ejecuta una fase

Igual que en `docs/plan-1a.md §Cómo se ejecuta una fase`, con la rama `plan-1c/fase-N`. Antes de agregar algo, busca
lo mínimo que cumple el objetivo; si no se puede comprobar con un comando o con una casilla `[humano]`, simplifícalo o
propón quitarlo.

Las fases 3 y 4 trabajan en su repo plantilla, que es un proyecto más: allí el paquete de §Paquete de las plantillas
se convierte en una épica con `/plan-epic` y cada tarea se ejecuta con `/phase`, con su rama, su PR y su CI. En este
repo, el PR de esas fases sólo actualiza la tabla de estado y el «Registro», con los enlaces a los PR de la plantilla.

## Decisiones que no se reabren

1. Siguen vigentes las decisiones de `docs/plan-1a.md` y `docs/plan-1b.md`. La decisión 3 de este plan reemplaza a
   la 11 del 1a en lo que dice del idioma de los textos para el usuario.
2. **Todos los proyectos usan PostgreSQL.** El stack de Laravel no tiene motor configurable. La CI sigue con la imagen
   de PostGIS, que es PostgreSQL con una extensión más; un proyecto la usa sólo si la necesita.
3. **Los textos para el usuario siempre pasan por las traducciones**, aunque el proyecto tenga un solo idioma. El
   idioma por defecto y los demás los fija cada proyecto en `.ai/project/CROSS-CUTTING.md §Idiomas`; el kit no da
   ninguno por hecho. La única excepción es un impacto de rendimiento medido, escrito en la fase con su medición.
   El código sigue en inglés, y la documentación del protocolo y la descripción de los PR, en español.
4. **Opción A.** El protocolo vive en cada plantilla como una instalación más, con su `.ai/protocol.lock`, y este repo
   es su única fuente. Un proyecto nacido de una plantilla recibe las mejoras del kit con `install.sh --upgrade`; las
   del código de la plantilla sólo llegan a los proyectos que nazcan después.
5. **Las plantillas:** `base-api` (Laravel) y `base-web` (Next.js), repos de GitHub marcados como *template
   repository*, cada uno hermano del otro.
6. **Autenticación de la base:** correo y contraseña, con recuperación por correo. La API sólo acepta tokens Bearer de
   Sanctum; la web guarda el token en una cookie HttpOnly detrás de su BFF. El código por SMS o WhatsApp y el inicio
   de sesión social quedan para cada proyecto.
7. **Idiomas de la base:** español por defecto e inglés como segundo idioma, para que el multi-idioma quede probado
   desde el primer día. En la web, con `next-intl`; en la API, con las traducciones de Laravel y la cabecera
   `Accept-Language`. En la URL sólo lleva prefijo el idioma que no es el de por defecto (`localePrefix:
   'as-needed'`: `/pricing` en español, `/en/pricing` en inglés), y los segmentos de las rutas no se traducen: van
   en inglés en todos los idiomas. Los slugs que salen de los datos siguen la decisión 3.
8. **Interfaz de la base:** shadcn/ui con primitivas de Radix, instalado con su CLI en `src/shared/ui`; el panel parte
   de los bloques `sidebar-07` y `dashboard-01`, y la página de inicio pública de bloques de Tailark. Nada de
   plantillas de pago. El código MIT que se copie conserva su aviso de licencia.
9. **El kit no depende de las plantillas:** sus e2e siguen creando proyectos con `laravel new` y `create-next-app`, y
   el camino manual del README sigue valiendo para los proyectos que ya existen.
10. **El arranque del ejecutor no crece más de lo que permite `tests/context-baseline.txt`:** la fase 1 reescribe
    frases en su sitio, no añade secciones.
11. Expo queda fuera de este plan.

---

## Fase 1 — Idiomas y PostgreSQL en las reglas

**Objetivo:** que las reglas del kit no den por hecho el idioma del usuario y que exijan traducciones siempre.

Entregables:

- Las reglas que dicen «en español» para los textos del usuario, los slugs públicos y los datos semilla pasan a
  decir «en el idioma de `.ai/project/CROSS-CUTTING.md §Idiomas`»: la lista negra de los dos `RULES.md`, el punto 11
  de `.claude/agents/reviewer.md`, `.ai/rules/arquitectura.md` de Laravel, `.claude/skills/plan-phase/SKILL.md` y
  la semilla `.ai/project/GLOSSARY.md`.
- `.ai/rules/arquitectura.md` de Next.js: cero texto visible escrito a mano en JSX, siempre, no sólo con más de un
  idioma; con la excepción de la decisión 3 y cómo se declara sin bajar la regla.
- Una comprobación ejecutable de esa regla en Next.js, si es viable sin dependencias nuevas (por ejemplo,
  `react/jsx-no-literals` en la configuración de ESLint del kit). Si no lo es, STOP & ASK con las opciones.
- La semilla `.ai/project/CROSS-CUTTING.md §Idiomas` pide el idioma por defecto, los demás idiomas, la librería,
  dónde viven las traducciones y cómo va el idioma en la URL; desaparece la opción «Un solo idioma: los textos van
  en el código».
- Laravel: `.ai/rules/tests.md` y los comentarios de `.github/workflows/verify.yml` y `.env.testing` dicen
  «PostgreSQL», con PostGIS disponible y opcional.
- `CHANGELOG.md` de cada paquete tocado, con la versión que corresponda (README.md §Versiones y etiquetas: si añade
  un chequeo que antes no fallaba, sube la mayor) y su «Al actualizar un proyecto».

Criterios de aceptación:

- [ ] `grep -rni 'español' core stacks --exclude=CHANGELOG.md` sólo encuentra la prohibición de escribir el código
      en español y la descripción de los PR: ninguna línea dice que los textos del usuario, los slugs o las semillas
      van en español.
- [ ] Si hay comprobación ejecutable, `tests/e2e-nextjs.sh` provoca un texto escrito en el JSX y el gate falla.
- [ ] `sh tests/run.sh` pasa, con el arranque del ejecutor dentro de `tests/context-baseline.txt`.
- [ ] La CI del PR está en verde.

## Fase 2 — Proyecto nuevo desde una plantilla

**Objetivo:** que un repo creado desde una plantilla quede, con un comando, como un proyecto nuevo que el guardián
obliga a rellenar.

Entregables:

- Un modo del instalador (propuesta: `install.sh --new-project --target <dir>`, porque el instalador ya tiene las
  semillas; la fase lo confirma en su resumen) que, sobre un proyecto con lock:
  - deja la memoria como la semilla del kit: `STATE`, `DOMAIN`, `BACKLOG`, `PROTOCOL`, `.ai/archive/`, `.ai/epics/`
    vacía, `.ai/stages/` y `.ai/handoffs/` sólo con su README, y `docs/runbooks/release.md`;
  - vuelve a la semilla, con sus `{{RELLENAR}}`, lo que describe el negocio: `.ai/project/README.md` (nombre,
    contexto y repos hermanos), `GLOSSARY.md`, `FEATURES.md`, `SENSITIVE-ZONES.md` y `COMMIT-SCOPES.md`;
  - conserva lo técnico que la plantilla ya decidió (`DECISIONS.md`, `ARCHITECTURE.md`, `CONTRACT.md`,
    `CROSS-CUTTING.md`, `verify.conf`, `lighthouse.json`), los archivos del kit, el lock y el código;
  - con `--dry-run`, dice qué haría; al terminar, lista los `{{RELLENAR}}` que quedan.
- README: §Proyecto nuevo desde una plantilla, con los pasos que GitHub no copia (la protección de `main` y los
  secretos). `docs/guia.md` la enlaza como el camino recomendado para proyectos nuevos.

Criterios de aceptación:

- [ ] `tests/run.sh` instala cada stack, rellena la capa del proyecto, crea una épica y corre el modo nuevo: el
      guardián falla en «instalación» hasta rellenar los marcadores, la memoria es la semilla y los archivos del kit
      y el lock no cambian.
- [ ] Un `install.sh --upgrade` justo después dice «sin cambios».
- [ ] `shellcheck -s sh install.sh` no da avisos y la CI del PR está en verde.

## Fase 3 — Plantilla de la API (`base-api`)

**Objetivo:** un repo Laravel listo para usar como plantilla, con autenticación, idiomas y contrato.

Entregables:

- `[humano]` El repo `base-api` en GitHub, marcado como *template repository*, con la protección de `main`
  (`docs/modos.md §Proteger main en GitHub`).
- El proyecto creado e instalado según README.md §Instalación en un proyecto nuevo, con la capa del proyecto
  rellena y `base-web` como repo hermano.
- §Paquete de las plantillas copiado a `.ai/stages/plan-1c.md`, su épica planificada con `/plan-epic` y las tareas
  BA ejecutadas con `/phase`.

Criterios de aceptación:

- [ ] `bash bin/verify.sh` en verde en `base-api`, en local y en su CI.
- [ ] La épica de las tareas BA está cerrada en `base-api`; sus PR, enlazados en «Registro».

## Fase 4 — Plantilla web (`base-web`)

**Objetivo:** un repo Next.js listo para usar como plantilla, con páginas públicas, sesión, panel e idiomas.

Entregables:

- `[humano]` El repo `base-web` en GitHub, marcado como *template repository*, con la protección de `main`.
- El proyecto creado e instalado según README.md §Instalación en un proyecto nuevo, con la capa del proyecto
  rellena, `base-api` como repo hermano y la copia de su contrato.
- El mismo paquete en `.ai/stages/plan-1c.md`, su épica y las tareas BW ejecutadas.

Criterios de aceptación:

- [ ] `bash bin/verify.sh` en verde en `base-web`, en local y en su CI, con Lighthouse sobre la página de inicio.
- [ ] La épica de las tareas BW está cerrada en `base-web`; sus PR, enlazados en «Registro».

## Fase 5 — Validación de punta a punta

**Objetivo:** comprobar que un proyecto nuevo nace de las dos plantillas, se rellena y sigue recibiendo el kit.

Entregables:

- `[humano]` Dos repos de prueba creados con «Use this template» desde `base-api` y `base-web`.
- En cada uno, el modo de proyecto nuevo de la fase 2, la capa del proyecto rellena y `bash bin/verify.sh`.
- Las versiones del plan publicadas: sin sufijo `-dev`, con su fecha en cada `CHANGELOG.md`.

Criterios de aceptación:

- [ ] `bash bin/verify.sh` en verde en los dos repos de prueba.
- [ ] El E2E de BW-05 pasa en el repo web de prueba contra el de la API levantado en local.
- [ ] `install.sh --upgrade` lleva a los dos repos de prueba la versión publicada sin conflictos.
- [ ] `[humano]` La persona arranca el proyecto de prueba siguiendo sólo `docs/guia.md` y confirma que no le faltó
      nada. Después borra los repos de prueba o los conserva, a su elección, y lo anota en «Registro».

---

## Paquete de las plantillas

Se copia tal cual a `.ai/stages/plan-1c.md` en `base-api` y en `base-web` (`.ai/stages/README.md §Formato`). Cada
repo convierte sólo sus tareas.

```markdown
# Paquete plan-1c — Plantillas base

> **Origen:** ai-protocol, docs/plan-1c.md (10 de octubre de 2026)

## Objetivo

Dos plantillas, API y web, de las que nace cualquier proyecto nuevo con registro, inicio de sesión, recuperación de
contraseña, panel, página de inicio pública y dos idiomas.

## Tareas

| ID | Tarea | Repo | Criterio de aceptación | Depende de |
|---|---|---|---|---|
| BA-01 | Convenciones de la API: prefijo /api/v1, errores problem+json traducidos e idioma por la cabecera Accept-Language, con español por defecto e inglés | base-api | Un error de ejemplo bajo /api/v1 sale como problem+json en español sin cabecera y en inglés con Accept-Language en | — |
| BA-02 | Registro, inicio y cierre de sesión con tokens Bearer de Sanctum, y consulta del usuario actual | base-api | Un usuario se registra, inicia sesión, consulta /api/v1/auth/me con su token y, después de cerrar sesión, ese token recibe 401 | BA-01 |
| BA-03 | Recuperación de contraseña por correo, con el enlace hacia la web | base-api | Con el enlace del correo el usuario fija una contraseña nueva y la anterior deja de servir | BA-02 |
| BA-04 | Límites de tasa en registro, inicio de sesión y recuperación | base-api | El sexto intento fallido de inicio de sesión en un minuto recibe 429 como problem+json | BA-02 |
| BW-01 | Idiomas con next-intl: español por defecto e inglés, y el cliente único enviando Accept-Language | base-web | La página de inicio se ve en español en / y en inglés en /en, sin redirección en / y sin texto escrito en el JSX | — |
| BW-02 | Sistema de diseño con shadcn/ui (Radix), instalado por su CLI en src/shared/ui, y una página de muestra | base-web | La página de muestra enseña botón, campo, selector, tarjeta, diálogo y aviso con textos traducidos, y lo que genera el CLI pasa la regla de capas | BW-01 |
| BW-03 | Grupos de rutas (public), (auth) y (panel) con layouts separados, y una página de inicio pública con bloques de Tailark | base-web | La página de inicio cumple el presupuesto de Lighthouse y no carga JavaScript del panel | BW-02 |
| BW-04 | Sesión por el BFF: Route Handlers con lista blanca, token en cookie HttpOnly y protección del panel | base-web | Después de iniciar sesión el token sólo existe en una cookie HttpOnly, y sin ella el panel redirige al inicio de sesión | BW-03, BA-02 |
| BW-05 | Pantallas de registro, inicio de sesión y recuperación de contraseña con Server Actions | base-web | Un E2E, con base-api levantada en local, registra un usuario, entra al panel, cierra sesión y recupera su contraseña | BW-04, BA-03 |
| BW-06 | Shell del panel a partir de los bloques sidebar-07 y dashboard-01, sin sus datos de ejemplo | base-web | En móvil y en escritorio el panel muestra el nombre que devuelve /api/v1/auth/me y su navegación funciona con teclado | BW-04 |

## Decisiones vigentes

- Todos los proyectos usan PostgreSQL.
- Los textos para el usuario siempre pasan por las traducciones; la única excepción es un impacto de rendimiento medido y escrito en la fase.
- Español por defecto e inglés como segundo idioma: next-intl en la web, traducciones de Laravel y Accept-Language en la API.
- La API sólo acepta tokens Bearer de Sanctum; la web guarda el token en una cookie HttpOnly detrás de su BFF.
- Autenticación de la base: correo y contraseña con recuperación; SMS, WhatsApp e inicio de sesión social quedan para cada proyecto.
- Interfaz: shadcn/ui con Radix en src/shared/ui; panel desde sidebar-07 y dashboard-01; página de inicio con bloques de Tailark; el código MIT copiado conserva su aviso.
- En la URL sólo lleva prefijo el idioma que no es el de por defecto (localePrefix as-needed: /pricing y /en/pricing), y los segmentos de las rutas no se traducen: van en inglés en todos los idiomas.
```

---

## Registro

- **Decisiones tomadas durante el plan:**
  - **La regla de los textos, en `eslint.layers.mjs` (fase 1).** Es del kit y todo proyecto ya lo importa (lo vigila
    el gate «capas»), así que la regla llega con `--upgrade` sin tocar `eslint.config.mjs` ni `bin/verify.sh`.
    `react/jsx-no-literals` con `noStrings` e `ignoreProps`, en `src/**/*.{jsx,tsx}` salvo los tests; falla en el
    gate «estilo». Sin dependencias nuevas: el plugin `react` lo registra `eslint-config-next`.
  - **La excepción de rendimiento (fase 1, aprobada en el resumen).** La fase la autoriza por escrito, con su
    medición, y el código la declara en su línea con `eslint-disable-next-line react/jsx-no-literals -- <ruta de la
    fase>`. La regla no se baja en la configuración, y un `grep` encuentra cada excepción.
  - **Lo que el linter no ve lo mira el revisor (fase 1).** El texto de los atributos (`alt`, `placeholder`…), los
    metadatos, las constantes, los ternarios y los textos de Laravel: el punto 11 de `.claude/agents/reviewer.md`
    marca un texto para el usuario fuera de las traducciones.
  - **Fuera de la lista de la fase (fase 1, aprobado en el resumen).** README §Instalación y `docs/guia.md`, porque
    la página de ejemplo de create-next-app no pasa la regla y porque decían «PostgreSQL con PostGIS». Y el ejemplo
    de Value Object de `stacks/laravel/.ai/rules/arquitectura.md`, que lanzaba un texto en español en vez de una
    clave de traducción.
  - **Versiones (fase 1).** `core` 2.2.0-dev y `laravel` 2.1.0-dev, menores; `nextjs` 3.0.0-dev, mayor, porque
    `react/jsx-no-literals` es un chequeo que antes no fallaba. Los rangos del núcleo no cambian.
  - **Contexto (fase 1).** El ejecutor sube 77 caracteres en cada stack (Laravel 53 304, Next.js 54 934, un 0,14 %):
    `RULES.md §Lista negra` cita `.ai/project/CROSS-CUTTING.md §Idiomas`. `tests/context-baseline.txt` tiene los
    valores nuevos.
  - **Lo que hereda el proyecto se conserva (fase 2, opción A del resumen).** Además de `DECISIONS.md`,
    `ARCHITECTURE.md`, `CONTRACT.md` y `CROSS-CUTTING.md`, el modo de proyecto nuevo conserva `FEATURES.md`,
    `GLOSSARY.md` y `COMMIT-SCOPES.md`: en una plantilla describen la autenticación, los idiomas y el panel, que
    siguen en el código del proyecto nuevo. Vuelven a la semilla `README.md` (nombre, contexto y repos hermanos) y
    `SENSITIVE-ZONES.md`; la autenticación ya es zona sensible en el `RULES.md` de cada stack. Las filas del negocio
    las añade cada fase antes de usarlas, como piden esas semillas.
  - **El modo, en `install.sh` (fase 2).** `install.sh --new-project --target <dir> [--dry-run]`, como proponía el
    plan. La regla vive en el instalador: vuelven a la semilla las del núcleo, salvo las siete de `.ai/project/` que
    hereda el proyecto, así que una semilla nueva del núcleo vuelve por defecto. Sin lista nueva en `core.json`.
  - **El kit, en la versión del lock (fase 2, aprobado en el resumen).** El modo copia semillas y deja los archivos
    del kit como estaban, así que unas y otros tienen que ser de la misma versión: si el lock dice otra, para sin
    tocar nada y pide `--upgrade`.
  - **Sin confirmación (fase 2, aprobado en el resumen).** El repo recién creado está en git y `--dry-run` dice antes
    qué borra. Los marcadores que quedan los lista la ejecución real, no `--dry-run`.
  - **`CLAUDE.md` y la semilla `.ai/project/README.md` no cambian (fase 2, aprobado en el resumen).** Dicen que el
    instalador no toca `.ai/project/`, pero hablan del upgrade, y cambiarlos movería el arranque del ejecutor.
  - **El CHANGELOG (fase 2).** El modo va en `core/CHANGELOG.md` («Sin publicar», Añadido): el instalador no es de
    ningún paquete y el modo usa las semillas del núcleo. El núcleo sigue en 2.2.0-dev.
  - **La API, bajo `/api/v1` (fase 3, elegido en el resumen).** El paquete decía `/v1`, pero
    `scripts/normalize-routes.php`, que es del kit, sólo mira las rutas bajo `api/`, igual que `ProblemDetails` y
    Scramble por defecto: con `/v1` en la raíz, el gate «rutas» no vería ninguna ruta y pasaría siempre. BA-01, BA-02
    y BW-06 dicen ahora `/api/v1`. Un prefijo configurable sería un cambio del kit, fuera de esta fase.
  - **`main` de `base-api` sin proteger (fase 3, aceptado por la persona).** El repo es privado y la cuenta no tiene
    GitHub Pro: la API de GitHub responde 403 a los *rulesets* y a la protección de ramas. Queda pendiente; hasta
    entonces, la única barrera es `.claude/settings.json`.
  - **Las fases BA, cada una en su sesión (fase 3, elegido en el resumen).** Esta sesión crea el proyecto, instala el
    kit y planifica la épica; cada tarea se ejecuta con `/phase` en una sesión abierta en `base-api`, que arranca en
    frío y con sus permisos (la skill no la invoca el agente: `disable-model-invocation`).
  - **`base-api`, instalado (fase 3).** En `Repositories/base/base-api`, donde `base-web` irá al lado: el paquete y el
    guardián usan el nombre de la carpeta. Laravel 13 (esqueleto 13.11.0, framework 13.35.0), PHP 8.4, Pest 5.3,
    Larastan 3.13, Scramble 0.13.47 y Sanctum 4.3 por `install:api`, con PostgreSQL en `.env.example`. El lock dice
    núcleo 2.2.0-dev y Laravel 2.1.0-dev. `MIN_TESTS=6` desde la instalación (los dos ejemplos de Pest y los cuatro
    de `ProblemDetailsTest`). Commits `e99b3c4` (instalación) y `63a2917` (planificación), directos a `main`.
  - **El contrato de la API, aprobado por la persona (fase 3).** Va en `.ai/DOMAIN.md` de `base-api` (2026-10-11 —
    El contrato de la API de la plantilla), y las fases lo citan: JSON plano; registro e inicio de sesión dan
    `{token, user}`; unas credenciales que no valen, 422 `INVALID_CREDENTIALS`; `forgot-password`, siempre 204; el
    correo de recuperación, en cola y en el idioma de la petición; `reset-password` revoca todos los tokens; cinco
    intentos por minuto. La caducidad de los tokens y la verificación del correo, para cada proyecto.
  - **La épica `01-api-base` (fase 3).** Una fase por tarea, BA-01 a BA-04. La 04 depende de la 03 y no sólo de la
    02, porque limita también las rutas de la recuperación. La persona aceptó que las fases 01, 02 y 03 pasen de unos
    diez archivos: las tareas de un paquete no se parten, y lo que sobra son traducciones, baselines generados y
    tablas de `.ai/project/`.
  - **Las tareas BA, hechas (fase 3).** Una sesión por fase en `base-api`, cada una con su PR fusionado y su CI en
    verde: BA-01 en [base-api#1](https://github.com/wilcarjose/base-api/pull/1), BA-02 en
    [#4](https://github.com/wilcarjose/base-api/pull/4), BA-03 en [#5](https://github.com/wilcarjose/base-api/pull/5)
    y BA-04 en [#6](https://github.com/wilcarjose/base-api/pull/6). La épica `01-api-base` está `CERRADA` con su
    criterio de cierre marcado, y `bash bin/verify.sh` sale en verde en local sobre `main` (88 tests).
  - **El gate «contrato» en la CI (fase 3).** En BA-01, la CI fallaba también en `main`: el `.env` que fabrica el
    paso «entorno» no conecta con el Postgres del servicio, y Scramble lee el esquema de `users`. Se arregló en
    `base-api` ([#2](https://github.com/wilcarjose/base-api/pull/2), con la memoria archivada en
    [#3](https://github.com/wilcarjose/base-api/pull/3)) y en el kit,
    [#19](https://github.com/wilcarjose/ai-protocol/pull/19). Los dos `verify.yml` son iguales:
    `install.sh --upgrade` sobre `base-api` sólo reescribe la suma del lock.
- **Lo que la siguiente fase necesita saber:**
  - (fase 1) `.ai/project/CROSS-CUTTING.md §Idiomas` (semilla) es una lista con cinco marcadores: idioma por
    defecto, los demás, librería, dónde viven las traducciones y cómo va el idioma en la URL (o cómo llega, en una
    API). La fase 2 la conserva, porque es técnica: cada plantilla la deja rellena.
  - (fase 1) Para las fases 3 y 4: shadcn/ui genera en `src/shared/ui` textos para lectores de pantalla («Close»,
    «Toggle Sidebar»…), y los bloques `sidebar-07`, `dashboard-01` y los de Tailark traen textos de ejemplo. El gate
    «estilo» los rechaza hasta que pasan por las traducciones (por props o con la librería).
  - (fase 1) El e2e de Next.js sustituye la página de inicio de create-next-app por
    `tests/fixtures/nextjs-e2e/src/app/page.tsx`, con su texto en `src/shared/i18n/`, un sustituto de la librería
    de traducciones. Provoca además un `<p>Hello</p>` y comprueba que el gate «estilo» falla.
  - (fase 1) Un `export default [...]` en un `.mjs` de configuración da `import/no-anonymous-default-export`, un
    aviso de `eslint-config-next` que con `--max-warnings=0` tumba el gate «estilo»: se asigna a una constante
    antes de exportarlo.
  - (fase 1) Un proyecto que ya tiene textos en el JSX los congela como deuda con
    `npx eslint . --suppress-rule react/jsx-no-literals` y `MAX_SUPPRESSIONS` (`stacks/nextjs/CHANGELOG.md`,
    «Al actualizar un proyecto»); probado con ESLint 9.39.
  - (fase 2) Para las fases 3 y 4: lo que cada plantilla lega al proyecto nuevo va en lo que el modo conserva:
    `.ai/project/` salvo `README.md` y `SENSITIVE-ZONES.md`, las semillas del stack (`verify.conf`,
    `lighthouse.json`…) y el código. Lo que escriba en la memoria, en esos dos archivos, en `.ai/stages/` (su copia
    del paquete) o en `.ai/handoffs/` no llega al proyecto nuevo, y `docs/runbooks/release.md` vuelve vacío.
  - (fase 2) Para la fase 5: el modo pide el kit en la versión del lock de la plantilla. Si las plantillas siguen en
    `-dev` cuando el kit ya publicó, primero `--upgrade` y después `--new-project`.
  - (fase 2) El modo no cambia lo que lleva el nombre de la plantilla en el código (el `README.md` del repo, el
    nombre de `composer.json` o `package.json`): README §Proyecto nuevo desde una plantilla lo pide a mano. La fase 5
    dirá si falta algo más.
  - (fase 2) `tests/run.sh` (`test_new_project`) prueba el modo sobre una copia de la instalación de prueba; los e2e
    no lo corren.
  - (fase 3) Para la fase 4: el paquete que se copia en `base-web` es el de este plan con `/api/v1`. Si la fase 4
    empieza antes de que se fusione el PR de la fase 3, lo copia de la rama `plan-1c/fase-3`.
  - (fase 3) Para la fase 4: cada fase BA deja en `.ai/BACKLOG.md` de `base-api` su traspaso, con Área `base-web` y
    lo que hay que hacer allí, y el contrato es `docs/contract/openapi.json` de `base-api`, que `base-web` copia. El
    enlace del correo es `<FRONTEND_URL>/reset-password?token=…&email=…`, con `/en` delante en inglés, y
    `FRONTEND_URL` vale `http://localhost:3000` por defecto.
  - (fase 3) **Un fallo del kit:** el chequeo «traspaso» de `bin/check-docs.sh` sólo busca la fila en
    `.ai/BACKLOG.md`. Cuando la persona cierra un traspaso y la fila pasa a `.ai/archive/BACKLOG.md`, como exige el
    chequeo «memoria», la fase `HECHA` que la dejó vuelve a fallar («cambia el contrato y nada lo traspasa»);
    reproducido sobre una copia de `base-api`. Hasta que el kit lo arregle, los traspasos de `base-api` no se
    cierran. El arreglo es del kit, en su propio PR: fuera de esta fase.
  - (fase 3) Para la fase 4: los traspasos abiertos son las filas 1, 4, 8 y 15 de `.ai/BACKLOG.md` de `base-api`
    (prefijo e idioma; registro y sesión; recuperación; límites). Sin `Accept-Language`, la API responde en español.
    El OpenAPI generado no documenta `INVALID_CREDENTIALS`, `INVALID_RESET_TOKEN` ni el 429: el cliente ramifica por
    `code`, nunca por `detail`.
  - (fase 3) Para la fase 4: la decisión D2 de `base-api` sigue pendiente. Detrás del BFF, la API ve la IP del BFF, y
    los límites por IP dejan de ser por persona: el registro se agota para todo el sitio con cinco altas en un minuto.
    BW-04 (el BFF) tiene que saber cómo reenvía la IP del navegador, así que conviene decidirlo antes de planificar
    esa tarea. La D1 (comparar el correo sin distinguir mayúsculas) también está pendiente.
  - (fase 3) Para la fase 5: `install.sh --new-project` devuelve la memoria a la semilla, y con ella se pierden los
    hallazgos abiertos de la plantilla y sus decisiones pendientes. En `base-api` son D1, D2 y las filas 2, 5 a 7 y
    9 a 14 de su `.ai/BACKLOG.md`, algunas de seguridad: el token de recuperación viaja sin cifrar en la cola (fila
    9), y la IP detrás del BFF (fila 14). O se resuelven en la plantilla antes de usarla, o el kit decide cómo llegan
    al proyecto nuevo.
  - (fase 3) Mejoras del protocolo que propusieron las fases BA (`.ai/PROTOCOL.md` de `base-api`, filas 1, 2 y 4 a 8):
    medir contra el kernel el mensaje real de un error antes de planificar su traducción; mirar las cabeceras que
    pone el cliente de test (`Accept-Language: en-us`); buscar en `tests/` la URI de una ruta que se retira; `/review`
    exige el árbol limpio, pero el cierre ya escribe la memoria; el modo auto bloquea subir `MIN_TESTS`;
    `strict_types` en el esqueleto, que una regla pide y la prueba de arquitectura excluye; citar `CONTRACT.md` en
    toda fase que lea cabeceras o la IP de quien llama. Llegan al kit como issues (README §Principios).
