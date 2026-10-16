# Reglas de tests — frontend Next.js

> Qué se prueba, con qué y contra qué. Es un tema de `.ai/RULES.md §Reglas por tema`: tan innegociable como el
> núcleo, del kit `ai-protocol` y actualizado por `install.sh --upgrade`.

---

## 1. Tests

- **Unitarios con Vitest** en `tests/` o junto al código (`*.test.ts`). Sin red real: el cliente se sustituye por
  fixtures. Vitest se instala o se sube en su **último parche publicado** (`npm view vitest version`): sus peers
  opcionales traen `@vitest/browser` en su última versión, que exige esa misma de `vitest`, y con una anterior npm 10
  revienta con `Cannot read properties of null (reading 'edgesOut')`. Un paquete que importa `next/server` o
  `next/navigation` sin extensión (next-intl) va en `test.server.deps.inline` de `vitest.config.ts`: fuera del bundle
  de Vite, Node no lo resuelve (`Cannot find module '…/next/server'`).
- **Contrato:** cada snapshot de `tests/contract-snapshots/` se importa en un test tipado con su tipo generado
  (`satisfies components["schemas"]["…"]`), así que `tsc` lo comprueba contra la copia del OpenAPI
  (`.ai/rules/contrato.md`). El cliente y sus errores problem+json tienen su test en `tests/shared/api/`.
- **E2E con Playwright** en `e2e/` (`playwright.config.ts`): sólo `getByTestId()` (la interfaz cambia de idioma, los
  testids no), salvo `page.locator("html")` y `page.locator("body")` sólo para leer el documento: sus atributos, sus
  clases y sus estilos calculados (`lang`, `dir`, la clase del modo oscuro, el color de fondo), nunca para pulsar,
  escribir o esperar a algo; cero esperas por tiempo (`waitForTimeout`), aserciones con reintento automático. Un
  recorrido con el teclado parte de un elemento enfocado con `focus()` y no de la carga de la página, que deja el foco
  en la interfaz del navegador (decenas de Tab para volver al documento), y se reintenta entero con
  `expect(…).toPass()`, porque antes de hidratar el foco puede caer en el `body`. Necesitan el backend
  levantado, así que `bin/verify.sh` sólo comprueba que cargan: se corren con `npx playwright test` si la fase lo
  pide. Lo que necesitan del entorno (la URL de la API…) lo fija el proyecto en un solo sitio que la orden lee sola,
  `webServer.env` de `playwright.config.ts`, y no delante de la orden: así `npx playwright test` es la misma en el
  §5 de una fase y en el criterio de cierre de su épica, y encaja con su permiso. Si Playwright pide otro navegador
  tras subir `@playwright/test`, se instala con `npx playwright install chromium`.
- **Los servicios de un E2E** (el servidor de desarrollo del repo hermano, un buzón de correo de pruebas en un
  contenedor) los levanta y los para quien ejecuta la fase, sólo con `sh bin/e2e-services.sh up` y
  `sh bin/e2e-services.sh down`, sueltas; el visto bueno del Paso A las cubre. El script es del proyecto, y lo crea
  (en su §4) la fase que trae el primer E2E: es el único punto de entrada, con las órdenes exactas (los contenedores
  y el servidor del hermano en segundo plano, con su pid y su log fuera de ese repo), y su permiso es el único que
  hace falta. Fuera de él, la IA no arranca contenedores ni procesos del hermano. Lo que cambia el repo hermano
  (migrar, editar su `.env`) es de la persona (`CLAUDE.md §El otro repositorio`).
  - **`up` fija por variable de entorno todo lo que el E2E da por hecho** de la configuración de cada servicio (el
    idioma por defecto, el correo, las URL), sin depender de su `.env`, que no se puede leer y pudo quedarse viejo.
    En un hermano Laravel lanza `php artisan serve --no-reload`: sin esa opción y con un `.env` presente,
    `ServeCommand` quita del `php -S` hijo cada variable de `$_ENV` que no está en su lista de pasadas
    (`$passthroughVariables`), y las que `up` fija no llegan al servidor o llegan según el `variables_order`. Con
    ella, además, un `.env` editado no reinicia el servidor.
  - **`sh bin/e2e-services.sh check`, antes de cada `npx playwright test`**, sólo lee: la salud de cada servicio
    (`curl -s`) y la configuración efectiva que el E2E da por hecha, y, si aplica, que sus migraciones están al día.
    Falla con lo que no cuadra, para que un entorno mal configurado se vea como tal y no como un test en rojo. La
    configuración efectiva se lee **de lo que el servidor responde** (en un hermano Laravel, el idioma de un mensaje
    de error sin `Accept-Language`) y se comprueba que el proceso es el que arrancó `up`; no con una orden que relee
    el `.env` en un proceso nuevo, como `php artisan config:show app.locale`, que puede dar otro valor que el del
    servidor levantado.
- **Rendimiento con Lighthouse CI**: el job `lighthouse` de `.github/workflows/verify.yml` construye la app y la mide
  contra `.ai/project/lighthouse.json`, que es del proyecto: las URL y los presupuestos de
  `.ai/project/CROSS-CUTTING.md §Rendimiento`. Un presupuesto sólo se relaja con una decisión en `.ai/DOMAIN.md`.
- **No se modifica un test existente para que pase un cambio**: si falla, el cambio está mal o es una decisión del
  Tech Lead (`.ai/WORKFLOW.md §Un test existente tendría que cambiar`). Nunca `test.skip()` condicional; para
  retirar cobertura, `test.fixme()` con el motivo, y se nombra en el reporte.
