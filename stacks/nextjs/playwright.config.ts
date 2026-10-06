// playwright.config.ts — los E2E de e2e/ (.ai/rules/tests.md). Es del proyecto: install.sh lo crea si falta.
//
// No corren en bin/verify.sh, que sólo comprueba que la configuración y los specs cargan: necesitan el backend
// levantado, y los corre la fase que los pide (`npx playwright test`). Contra un entorno ya levantado,
// E2E_BASE_URL; sin ella, Playwright construye y arranca la app.
import { defineConfig, devices } from "@playwright/test";

const baseURL = process.env.E2E_BASE_URL ?? "http://localhost:3000";

export default defineConfig({
  testDir: "e2e",
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 2 : 0,
  use: { baseURL, testIdAttribute: "data-testid", trace: "on-first-retry" },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: process.env.E2E_BASE_URL
    ? undefined
    : { command: "npm run build && npm run start", url: baseURL, reuseExistingServer: !process.env.CI },
});
