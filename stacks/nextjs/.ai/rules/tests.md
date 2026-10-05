# Reglas de tests — frontend Next.js

> Qué se prueba, con qué y contra qué. Es un tema de `.ai/RULES.md §Reglas por tema`: tan innegociable como el
> núcleo, del kit `ai-protocol` y actualizado por `install.sh --upgrade`.

---

## 1. Tests

- **Unitarios con Vitest** en `tests/` o junto al código (`*.test.ts`). Sin red real: el cliente se sustituye por
  fixtures.
- **Contrato:** cada esquema se prueba contra los snapshots de `tests/contract-snapshots/` (`.ai/rules/contrato.md`).
- **E2E con Playwright** en `e2e/`: sólo `getByTestId()` (la interfaz cambia de idioma, los testids no), cero esperas
  por tiempo (`waitForTimeout`), aserciones con reintento automático. Necesitan el backend levantado: sólo cuentan
  si la fase lo pide, y sus «Criterios de éxito» dicen quién provee el backend.
- **No se modifica un test existente para que pase un cambio**: si falla, el cambio está mal o es una decisión del
  Tech Lead (`.ai/WORKFLOW.md §Un test existente tendría que cambiar`). Nunca `test.skip()` condicional; para
  retirar cobertura, `test.fixme()` con el motivo, y se nombra en el reporte.
