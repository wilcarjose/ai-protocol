// eslint.config.mjs — la configuración de ESLint del proyecto.
//
// Es del proyecto: install.sh la crea si falta y --upgrade no la toca. Puede añadir reglas, nunca bajarlas
// (.ai/RULES.md §Verificación del stack). La regla de capas viene del kit en eslint.layers.mjs y no se quita: el gate
// «capas» de bin/verify.sh falla si deja de estar activa.
import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";
import layers from "./eslint.layers.mjs";

export default defineConfig([
  ...nextVitals,
  ...nextTs,
  ...layers,
  globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts", "playwright-report/**", "test-results/**", ".lighthouseci/**"]),
]);
