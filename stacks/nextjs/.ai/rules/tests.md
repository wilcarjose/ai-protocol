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
  escribir o esperar a algo; cero esperas por tiempo (`waitForTimeout`), aserciones con reintento automático. Necesitan el backend
  levantado, así que `bin/verify.sh` sólo comprueba que cargan: se corren con `npx playwright test` si la fase lo
  pide. Si Playwright pide otro navegador tras subir `@playwright/test`, se instala con
  `npx playwright install chromium`.
- **Los servicios de un E2E** (el servidor de desarrollo del repo hermano, un buzón de correo de pruebas en un
  contenedor) los levanta y los para quien ejecuta la fase, sólo con `sh bin/e2e-services.sh up` y
  `sh bin/e2e-services.sh down`, sueltas; el visto bueno del Paso A las cubre. El script es del proyecto, y lo crea
  (en su §4) la fase que trae el primer E2E: es el único punto de entrada, con las órdenes exactas (los contenedores
  y el servidor del hermano en segundo plano, con su pid y su log fuera de ese repo), y su permiso es el único que
  hace falta. Fuera de él, la IA no arranca contenedores ni procesos del hermano. Lo que cambia el repo hermano
  (migrar, editar su `.env`) es de la persona (`CLAUDE.md §El otro repositorio`).
- **Rendimiento con Lighthouse CI**: el job `lighthouse` de `.github/workflows/verify.yml` construye la app y la mide
  contra `.ai/project/lighthouse.json`, que es del proyecto: las URL y los presupuestos de
  `.ai/project/CROSS-CUTTING.md §Rendimiento`. Un presupuesto sólo se relaja con una decisión en `.ai/DOMAIN.md`.
- **No se modifica un test existente para que pase un cambio**: si falla, el cambio está mal o es una decisión del
  Tech Lead (`.ai/WORKFLOW.md §Un test existente tendría que cambiar`). Nunca `test.skip()` condicional; para
  retirar cobertura, `test.fixme()` con el motivo, y se nombra en el reporte.
