// vitest.config.ts — los tests unitarios (.ai/rules/tests.md). Es del proyecto: install.sh lo crea si falta.
//
// e2e/ es de Playwright: Vitest no lo recorre.
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
  resolve: {
    alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) },
  },
  test: {
    include: ["tests/**/*.test.{ts,tsx}", "src/**/*.test.{ts,tsx}"],
    exclude: ["e2e/**", "node_modules/**"],
  },
});
