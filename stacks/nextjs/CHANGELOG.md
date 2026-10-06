# Changelog — nextjs

El stack Next.js: lo que añade al núcleo. Versiones con [SemVer](https://semver.org/lang/es/) y etiqueta
`nextjs-vX.Y.Z` (README.md §Versiones y etiquetas). Lo más reciente, arriba.

## [Sin publicar] — 2.0.0-dev

Compatible con el núcleo `>=2.0.0-dev <3.0.0`.

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
