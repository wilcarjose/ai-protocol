# Reglas de tests — frontend Next.js

> Qué se prueba, con qué y contra qué. Es un tema de `.ai/RULES.md §Reglas por tema`: tan innegociable como el
> núcleo, del kit `ai-protocol` y actualizado por `install.sh --upgrade`.

---

## 1. Tests

- **Unitarios con Vitest** en `tests/` o junto al código (`*.test.ts`). Sin red real: el cliente se sustituye por
  fixtures.
- **Contrato:** cada snapshot de `tests/contract-snapshots/` se importa en un test tipado con su tipo generado
  (`satisfies components["schemas"]["…"]`), así que `tsc` lo comprueba contra la copia del OpenAPI
  (`.ai/rules/contrato.md`). El cliente y sus errores problem+json tienen su test en `tests/shared/api/`.
- **E2E con Playwright** en `e2e/` (`playwright.config.ts`): sólo `getByTestId()` (la interfaz cambia de idioma, los
  testids no), cero esperas por tiempo (`waitForTimeout`), aserciones con reintento automático. Necesitan el backend
  levantado, así que `bin/verify.sh` sólo comprueba que cargan: se corren con `npx playwright test` si la fase lo
  pide, y sus «Criterios de éxito» dicen quién provee el backend.
- **Rendimiento con Lighthouse CI**: el job `lighthouse` de `.github/workflows/verify.yml` construye la app y la mide
  contra `.ai/project/lighthouse.json`, que es del proyecto: las URL y los presupuestos de
  `.ai/project/CROSS-CUTTING.md §Rendimiento`. Un presupuesto sólo se relaja con una decisión en `.ai/DOMAIN.md`.
- **No se modifica un test existente para que pase un cambio**: si falla, el cambio está mal o es una decisión del
  Tech Lead (`.ai/WORKFLOW.md §Un test existente tendría que cambiar`). Nunca `test.skip()` condicional; para
  retirar cobertura, `test.fixme()` con el motivo, y se nombra en el reporte.
