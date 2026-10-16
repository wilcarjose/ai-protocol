# Changelog — nextjs

El stack Next.js: lo que añade al núcleo. Versiones con [SemVer](https://semver.org/lang/es/) y etiqueta
`nextjs-vX.Y.Z` (README.md §Versiones y etiquetas). Lo más reciente, arriba.

## Sin publicar

### Cambiado

- `.ai/rules/tests.md §Tests`: en un hermano Laravel, `up` lanza `php artisan serve --no-reload`. Sin la opción y con
  un `.env` en el hermano, `ServeCommand::startProcess` (Laravel 13.17) pasa como `false` al `php -S` hijo cada clave de
  `$_ENV` que no está en `$passthroughVariables`, así que las variables que `up` fija en la orden no llegan al
  servidor, o llegan según el `variables_order` (#85).

## [3.8.0] — 2026-10-15

Compatible con el núcleo `>=2.0.0 <3.0.0`.

### Cambiado

- `.ai/rules/tests.md §Tests`: lo que los E2E necesitan del entorno (la URL de la API…) lo fija el proyecto en
  `webServer.env` de `playwright.config.ts`, no delante de la orden, para que `npx playwright test` sea la misma en
  la fase y en el criterio de cierre de la épica y encaje con su permiso (#79).
- `.ai/RULES.md §Estructura y regla de dependencias`: `package.json` declara `"sideEffects": ["*.css"]`, y cada
  módulo que se importa sólo por su efecto. Con Next 16.3.8 (Turbopack), un Server Component que importa un
  componente `"use client"` del barril de `shared/ui` manda al navegador también los que no usa; con la
  declaración, no, y el CSS global sigue cargando. En base-web, `/` cargaba `select`, `dialog` y `sidebar` (#77).
- `.ai/rules/arquitectura.md §Estilos y tema`: de lo que genera shadcn/ui sólo se toca lo que choca con una regla o
  un gate, y lo justo (los textos, lo que el linter rechaza, lo que rompe §Componentes, textos e identificadores),
  nunca con una exención; cada retoque se declara en el RESULTADO. El sidebar generado traía
  `react-hooks/set-state-in-effect`, `react-hooks/purity` y `document.cookie`, y la revisión lo marcó bloqueante sin
  una regla que dijera qué se podía tocar (#76).
- `.ai/rules/tests.md §Tests`: un recorrido con el teclado en un E2E parte de un elemento enfocado con `focus()` y
  se reintenta entero con `expect(…).toPass()`. Tras `page.goto`, el foco está en la interfaz del navegador (de 33 a
  40 Tab para volver al documento, medido en base-web con `document.hasFocus()`) y, antes de hidratar, `focus()`
  puede caer en el `body`: el E2E de teclado del panel falló tres veces sin que fallara el código (#75).

### Al actualizar un proyecto

- `playwright.config.ts` es del proyecto y el upgrade no lo toca: si sus E2E necesitan una variable (`API_URL`…) que
  hoy se pasa delante de `npx playwright test`, pásala a `webServer.env` (#79).
- Añade `"sideEffects": ["*.css"]` a `package.json` (y cada módulo del proyecto que se importe sólo por su efecto),
  y comprueba con `next build` que el CSS global sigue cargando (#77).

## [3.7.0] — 2026-10-13

Compatible con el núcleo `>=2.0.0 <3.0.0`.

### Cambiado

- `.ai/templates/phase.template.md`: el RESULTADO tiene un encabezado nuevo, «Entorno local», entre «Archivos tocados
  realmente» y «Verificación»: lo que la persona cambia en su `.env` local si la fase cambia `.env.example`. Lo pide
  el chequeo «entorno» del núcleo (`phase/cierre.md §Cierre de fase`, #73).
- `.ai/rules/tests.md §Tests`: los servicios de un E2E (el servidor del repo hermano, un buzón de correo de pruebas)
  los levanta y los para quien ejecuta la fase, sólo con `sh bin/e2e-services.sh up` y `… down`, cubiertas por el
  visto bueno del Paso A. El script es del proyecto y lo crea la fase que trae el primer E2E; migrar el hermano o
  editar su `.env` sigue siendo de la persona. Antes, «la IA no arranca contenedores» y cada arranque o rearranque
  costaba una sesión aparte y una espera del Tech Lead (#72).
- `.claude/settings.json`: permite `sh bin/e2e-services.sh*`, el único permiso que necesitan esos servicios (#72).
- `.ai/rules/tests.md §Tests`: `up` fija por variable de entorno todo lo que el E2E da por hecho de cada servicio,
  sin depender de su `.env`; y `sh bin/e2e-services.sh check`, de sólo lectura, va antes de cada
  `npx playwright test`: la salud de cada servicio, su configuración efectiva y sus migraciones. Un `.env` del
  hermano con el idioma de antes hizo fallar el E2E de base-web como si fuera un test en rojo (#69).

### Al actualizar un proyecto

- Cada fase sin cerrar (`LISTA_PARA_EJECUTAR`, redactada por adelantado) escrita con la plantilla anterior necesita
  el encabezado `### Entorno local` en su RESULTADO, entre «Archivos tocados realmente» y «Verificación», con el
  comentario de la plantilla: el guardián lo pide a toda fase viva, y sin él `bin/protocol-upgrade.sh` para con «el
  guardián falla tras el upgrade». Se añade en la rama del upgrade. Las `HECHA` no cambian.
- Sin `bin/e2e-services.sh`, la IA no levanta los servicios de un E2E y lo hace la persona, como hasta ahora. Para
  que los levante el ejecutor, una fase del proyecto crea el script con `up`, `down` y `check` (#69) y sus órdenes
  exactas.

## [3.6.0] — 2026-10-13

Compatible con el núcleo `>=2.0.0 <3.0.0`.

### Cambiado

- `.claude/settings.json`: permite `sh bin/sync-main.sh*`, la vuelta a la rama base tras un merge del núcleo
  2.7.0. El script no fusiona ni empuja: `gh pr merge` y el push a `main` siguen denegados.

## [3.5.0] — 2026-10-13

Compatible con el núcleo `>=2.0.0 <3.0.0`.

### Cambiado

- `.claude/settings.json`: permite `sh bin/protocol-upgrade.sh*`, el upgrade del protocolo del núcleo 2.6.0. Es el
  único permiso nuevo: `gh pr merge` y el push a `main` siguen denegados.
- `.ai/project/verify.conf` (semilla): `PROTOCOL_AUTO_MERGE=minor`, la política de fusión de
  `bin/protocol-upgrade.sh`. Una semilla no llega a un proyecto que ya existe: sin la línea, vale `minor`.

## [3.4.0] — 2026-10-13

Compatible con el núcleo `>=2.0.0 <3.0.0`.

### Cambiado

- `.claude/settings.json`: permite `sh bin/protocol-feedback.sh*`, que la retro del núcleo ejecuta para subir sus
  filas al kit (`phase/cierre.md §Retro del protocolo`, #64).
- `.ai/rules/tests.md §Tests`: un paquete que importa `next/server` o `next/navigation` sin extensión (next-intl)
  va en `test.server.deps.inline` de `vitest.config.ts`, o Vitest no lo carga (#59).
- La semilla `vitest.config.ts` trae `server.deps.inline: ["next-intl"]`, que no hace nada sin next-intl (#59).

### Al actualizar un proyecto

- La semilla `vitest.config.ts` es del proyecto y `--upgrade` no la toca: si usa next-intl y aún no lo tiene, añade
  `server: { deps: { inline: ["next-intl"] } }` a su `test` (#59).

## [3.3.0] — 2026-10-12

Compatible con el núcleo `>=2.0.0 <3.0.0`.

### Añadido

- `stack.json`, «gitignore»: `/test-results/` y `/playwright-report/` (#46), y `/.lighthouseci/`, donde Lighthouse
  CI deja sus informes (#56), que `install.sh` añade al `.gitignore` del proyecto si faltan.

### Cambiado

- `.ai/rules/tests.md §Tests`: el E2E puede usar `page.locator("html")` y `page.locator("body")` sólo para leer
  el documento: sus atributos, sus clases y sus estilos calculados (`lang`, `dir`, la clase del modo oscuro, el
  color de fondo), nunca para interactuar. Es la única excepción a «sólo `getByTestId()`» (#44, #52).
- `.ai/rules/contrato.md §Cómo se conoce el contrato`: toda petición pasa por `request(…)` con el cliente único que
  exporta `src/shared/api/`, sin fijar su nombre ni cómo se construye (un cliente por idioma ya no deja la regla
  desfasada); `request(api.GET(…))` queda como el ejemplo de la semilla (#45).
- `bin/verify.sh`, gate «tipos»: borra `.next/dev/types` antes de compilar. Lo deja `next dev`, el `tsconfig.json`
  de create-next-app lo incluye y `next typegen` no lo regenera, así que tras mover una ruta citaba la que ya no
  existe y ponía en rojo «tipos» y «build»; la CI nunca lo tiene, y `next dev` lo vuelve a escribir (#53).
- `.claude/settings.json`: permite `git pull --ff-only*`, que pide el núcleo para traer la rama base antes de crear
  la rama de una fase (`phase/SKILL.md §Rama de la fase`, #50).

### Al actualizar un proyecto

- `install.sh --upgrade` añade a `.gitignore` las líneas de `test-results/`, `playwright-report/` y `.lighthouseci/`
  que falten; si el proyecto ya las ignoraba con otra forma (`/x`, `x/`), no las repite. Lo que ya estuviera
  commiteado en esas carpetas sigue versionado: se quita con `git rm -r --cached <carpeta>`.
- Con `next dev` en marcha, el editor pierde los tipos de `.next/dev/types` tras cada `bin/verify.sh` hasta el
  siguiente cambio de rutas o reinicio de `next dev`.

## [3.2.0] — 2026-10-12

Compatible con el núcleo `>=2.0.0 <3.0.0`.

### Añadido

- `.ai/rules/arquitectura.md §Estilos y tema`: el aspecto se cambia sólo en el tema (`src/app/globals.css`):
  `:root` para el modo claro, `.dark` para el oscuro si lo hay, los tokens semánticos de shadcn/ui más las fuentes,
  el radio, las sombras y el espaciado de letra, y `@theme inline` para las utilidades. Así, sustituir `:root` y
  `.dark` por los de otro tema con los mismos nombres (p. ej. uno exportado de tweakcn) cambia toda la web. Cero
  colores escritos a mano fuera del tema (clases de la paleta de Tailwind, `#hex`, `rgb()`, `oklch()`…); lo que
  genera el CLI de shadcn/ui se queda como lo genera, y el código copiado de otros bloques pasa a tokens. Lo
  comprueba el revisor: sin gate nuevo.

### Cambiado

- `.ai/RULES.md §Reglas por tema`: `arquitectura.md` se lee también cuando la fase toca estilos.

### Al actualizar un proyecto

- Nada falla: la regla no tiene gate. Si `src/app/globals.css` conserva el `body` de create-next-app
  (`font-family: Arial, Helvetica, sans-serif` y sus `background` y `color`), pisa la fuente y los colores del tema:
  la fase que toque estilos lo quita. Los colores escritos a mano que ya haya en el código se pasan a tokens en la
  fase que toque ese componente, o van a `.ai/BACKLOG.md`.

## [3.1.0] — 2026-10-12

Compatible con el núcleo `>=2.0.0 <3.0.0`.

### Cambiado

- `.claude/settings.json`: permite `npm i --save-exact *` (y lo saca de `deny`; `npm install*` sigue denegado),
  `npx shadcn@*`, `npx playwright install chromium`, `npx --yes @lhci/cli@*` (#42, #43) y `npm view *`, que sólo
  lee el registro.
- `.ai/rules/tests.md`: los servicios del E2E los levanta la persona, y cómo se instala el navegador de
  Playwright tras subir de versión (#43); y que Vitest va en su último parche, porque con uno anterior npm 10
  revienta resolviendo las peers opcionales.

## [3.0.0] — 2026-10-11

Compatible con el núcleo `>=2.0.0 <3.0.0`. Versión mayor: un chequeo que antes no fallaba.

### Añadido

- `eslint.layers.mjs`: `react/jsx-no-literals` en `src/**/*.{jsx,tsx}`, salvo los tests, con `noStrings` e
  `ignoreProps`. Rechaza el texto escrito entre etiquetas, también entre llaves, en una plantilla o concatenado, y
  deja pasar las props, `t("…")`, los espacios y los números. Falla en el gate «estilo». Sin dependencias nuevas: el
  plugin `react` lo registra `eslint-config-next`.

### Cambiado

- `.claude/settings.json`: permite `gh pr edit *`, que usa la retro del núcleo para la sección «Protocolo» del PR
  (#30), y `Edit(./.ai/project/verify.conf)`, para que el cierre suba la baseline aunque el modo auto de Claude Code
  lo tome por saltarse la CI (#26). El kit comprueba que cada orden de `phase/cierre.md §Entrega` encaja con estos
  patrones.
- `.ai/templates/phase.template.md`: el comentario de «Qué mejorarías del protocolo» pide anotar cada fricción
  cuando ocurre, con su evidencia; la retro la completa después de la entrega (núcleo,
  `phase/cierre.md §Retro del protocolo`). El encabezado no cambia (#29).
- `.ai/rules/arquitectura.md §Componentes, textos e identificadores`: cero texto visible escrito a mano en el JSX
  aunque el proyecto tenga un solo idioma (antes, sólo con más de uno), también en `alt`, `aria-label`,
  `placeholder`, `title` y los metadatos. El linter ve el texto entre etiquetas; los atributos, los metadatos y las
  constantes, el revisor. La única excepción es un impacto de rendimiento medido: la fase la autoriza por escrito,
  con su medición, y la línea lleva `eslint-disable-next-line react/jsx-no-literals -- <la fase>`.
- `.ai/RULES.md §Lista negra`: los textos para el usuario van siempre en las traducciones y, con los slugs públicos y
  los datos semilla, en el idioma de `.ai/project/CROSS-CUTTING.md §Idiomas`, no en español.

### Al actualizar un proyecto

- El gate «estilo» falla con cada texto escrito en el JSX de `src/`, también con la página de ejemplo de
  create-next-app. Pásalos a las traducciones de `.ai/project/CROSS-CUTTING.md §Idiomas`. Si son muchos, congélalos
  como deuda con `npx eslint . --suppress-rule react/jsx-no-literals` y pon en `MAX_SUPPRESSIONS` de
  `.ai/project/verify.conf` el total de `eslint-suppressions.json`, que sólo puede bajar.
- La regla necesita que `eslint.config.mjs` cargue `eslint-config-next`, como la semilla: sin él, ESLint no encuentra
  el plugin `react` y falla entero.

## [2.0.1] — 2026-10-10

Compatible con el núcleo `>=2.0.0 <3.0.0`.

### Cambiado

- `.ai/project/lighthouse.json` (semilla): Lighthouse corre 3 veces por URL (`numberOfRuns`) y cada aserción se
  evalúa contra la mediana (`aggregationMethod: "median"`), no contra una sola corrida. Con una, el ruido de
  rendimiento del runner hacía fallar la CI sin cambios en el código: en el kit, `e2e-nextjs` falló tres veces en
  cuatro días en `total-blocking-time` (hasta 753 ms con un presupuesto de 300) y pasó al relanzarlo. Los
  presupuestos no cambian. Sólo afecta a las instalaciones nuevas: la semilla no se copia si el proyecto ya tiene el
  archivo, y un proyecto que la quiera aplica los dos campos a mano.

## [2.0.0] — 2026-10-06

Compatible con el núcleo `>=2.0.0 <3.0.0`.

### Añadido

- `bin/verify.sh`, gates nuevos: «contrato» (`sh bin/contract.sh --check`, antes de «tipos»), «capas» (la regla de
  `eslint.layers.mjs` sigue activa en la configuración efectiva de ESLint) y, sólo en el verify completo, «e2e»
  (`playwright test --list`: la configuración y los specs cargan, sin correrlos) y «build» (`next build`).
- `eslint.layers.mjs` (del kit): la regla de capas `app → features → entities → shared` con
  `eslint-plugin-boundaries` (`boundaries/dependencies`) y `eslint-import-resolver-typescript` para el alias `@/`.
  Entre carpetas se entra por su `index.ts`. `eslint.config.mjs` (semilla) la importa junto a la de Next.
- `bin/contract.sh [--check]`: genera con openapi-typescript `src/shared/api/schema.d.ts` desde la copia del OpenAPI
  del backend en `docs/contract/openapi.json` (rutas en `.ai/project/verify.conf`: `CONTRACT_SPEC` y
  `CONTRACT_TYPES`). La semilla trae un OpenAPI vacío y sus tipos.
- `src/shared/api/` (semilla): el cliente único con openapi-fetch y `request()`, que nunca lanza y devuelve
  `{ ok, data } | { ok: false, error }`; `errors.ts` lee problem+json (RFC 9457) y da `class`, `status`, `code`,
  `detail` y `retry`. Su test, en `tests/shared/api/request.test.ts`.
- `vitest.config.ts` (semilla, con el alias `@/` y sin `e2e/`) y `playwright.config.ts` (semilla, `testIdAttribute`
  `data-testid`, `E2E_BASE_URL` o la app construida y arrancada).
- `.ai/project/lighthouse.json` (semilla) y el job `lighthouse` del workflow: Lighthouse CI (`@lhci/cli` fijado, por
  `npx`) contra las URL y los presupuestos del proyecto.
- `.github/workflows/verify.yml`: la CI del proyecto, que corre `bin/verify.sh` completo en cada PR con todo el
  historial (los gates «protocolo» y «secretos» lo necesitan) y gitleaks en versión fija.
  La versión de Node sale de `engines.node` de `package.json`.
- `bin/verify.sh`, gates «protocolo», «secretos» y «dependencias» (`npm audit --audit-level=high`). «secretos» corre
  `gitleaks git` sobre el historial, también con `--fast`, y falla si falta gitleaks; «dependencias» va sólo en el
  verify completo, porque consulta la red.
- `.ai/project/verify.conf` (semilla): la baseline (`MIN_TESTS` y `MAX_SUPPRESSIONS`), que sale de `bin/verify.sh`.
- `stack.json`: nombre, versión, rango compatible del núcleo, archivos que aporta y gates de su `bin/verify.sh`.
- `.ai/rules/`: las reglas por tema que la fase cita cuando las toca: `contrato.md` (cómo se conoce el contrato,
  errores, claves de caché, formas variables), `arquitectura.md` (estado y componentes) y `tests.md`.

### Cambiado

- `.ai/RULES.md §Lista negra`: el código va en inglés (nombres, rutas, claves de traducción, códigos de error, logs,
  tests y comentarios) y con los términos de `.ai/project/GLOSSARY.md`. En español quedan los textos para el usuario,
  los slugs públicos y los datos semilla. `.ai/rules/arquitectura.md` la cita en vez de repetirla. Los comentarios de
  las semillas (`playwright.config.ts`, `vitest.config.ts`, `eslint.config.mjs`) y el título del OpenAPI semilla pasan
  a inglés. El código de error del ejemplo es `DEMO_NOT_FOUND`, en mayúsculas como el del backend.
- El gate «dependencias» audita sólo lo que se despliega (`npm audit --audit-level=high --omit=dev`): un aviso alto
  sin arreglo en `braces`, que traen `eslint-config-next` y `eslint-plugin-boundaries`, dejaba en rojo cualquier
  proyecto nuevo.
- El gate «tipos» corre antes `next typegen`: los tipos de las rutas (`LayoutProps`…) no existen en un clon limpio.
- El contrato pasa de esquemas Zod escritos a mano a los tipos generados del OpenAPI (`.ai/RULES.md`,
  `.ai/rules/contrato.md` y `.ai/rules/tests.md`). Zod queda para `formData`, `searchParams`, entorno y cookies.
- `.ai/RULES.md §Stack y versiones exactas` añade `openapi-fetch`, `openapi-typescript`, `@playwright/test`,
  `eslint-plugin-boundaries` y `eslint-import-resolver-typescript`: un proyecto que sube tiene que declarar sus
  versiones en `.ai/project/DECISIONS.md` (chequeo «stack»).
- `.ai/RULES.md §Alcance`: `next.config.*` lleva `agentRules: false`. Desde Next 16.3, `next dev` lanzado por un
  agente escribe su bloque en `AGENTS.md`, que es del kit, y el gate «protocolo» fallaría.
- `.claude/settings.json` permite `sh bin/contract.sh`, `npx next build` y `npx next typegen`.
- `bin/verify.sh` es entero del kit: lee la configuración del proyecto de `.ai/project/verify.conf` y falla si no
  existe.
- `docs/README.md` pasa de `files` a `seed`: son del proyecto, el upgrade no los toca y el gate «protocolo» no los
  protege.
- `.claude/settings.json`: permite `git push [-u] origin phase/*`, `git fetch`, `gh pr create|view|checks|list`,
  `npm audit`, `gitleaks git` y `sh bin/check-protocol.sh`; bloquea el push a `main`, con `:` en el refspec,
  forzado, con borrado, `--mirror`, `--all` y `--tags`, y `gh pr merge`.
- Plantilla de fase: `> **Tipo:**` en la cabecera (código por defecto), los campos opcionales `Modo` y
  `Tarea externa`, las casillas `[humano]` en «Criterios de éxito» y la sección `## 10. Revisión`, fuera del
  RESULTADO, que escribe `/review`. Las plantillas citan `/plan-epic` y `/plan-phase` en vez de `/planning`.
- `.ai/RULES.md` queda como núcleo de innegociables (stack, alcance, contrato, zonas sensibles, verificación, lista
  negra y ámbitos), con `§Reglas por tema` como índice de `.ai/rules/`.
- Plantillas: la fase cita en su §2 la anterior con `sh bin/handoff.sh` y los temas de `.ai/rules/`; el RESULTADO
  enlaza la evidencia de las salidas largas y es el único reporte. Las citas a `.ai/PLANNING.md` y a las secciones
  que salieron de `CLAUDE.md` apuntan a las skills.
- `.claude/settings.json` permite `sh bin/handoff.sh` y `sh bin/measure-context.sh`.
- `.ai/RULES.md` deja de tener `{{RELLENAR}}`. La tabla `§Stack y versiones exactas` queda con el paquete y su
  nota; la versión de cada uno es del proyecto y vive en `.ai/project/DECISIONS.md`, contra `package.json`.
- `.ai/RULES.md`: la autenticación y las cabeceras del cliente, los idiomas, el tenant, el alcance adicional, las
  zonas sensibles del negocio y los ámbitos del dominio pasan a `.ai/project/` y aquí se citan.

### Al actualizar un proyecto que ya existe

`install.sh` no pisa archivos del proyecto, así que en uno que ya tiene `eslint.config.mjs`, `AGENTS.md` o
`CLAUDE.md` (create-next-app 16.3 crea los tres):

- `eslint.config.mjs`: añade `import layers from "./eslint.layers.mjs"` y `...layers`; el gate «capas» falla hasta
  que esté.
- `AGENTS.md` y `CLAUDE.md`: los del kit son los que valen. Si eran los de create-next-app, bórralos antes de
  instalar.
- Instala los paquetes nuevos de `.ai/RULES.md §Stack y versiones exactas` y corre `sh bin/contract.sh`.

## 1.x

La carpeta `nextjs/` del kit, copiada entera con `cp -Rn`. Se actualiza con `install.sh --upgrade --stack nextjs`.
