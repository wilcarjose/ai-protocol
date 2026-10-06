// eslint.config.mjs — the project's ESLint config.
//
// It belongs to the project: install.sh creates it when missing and --upgrade leaves it alone. It may add rules,
// never lower them (.ai/RULES.md §Verificación del stack). The layer rule comes from the kit in eslint.layers.mjs and
// stays: the «capas» gate of bin/verify.sh fails if it is no longer active.
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
