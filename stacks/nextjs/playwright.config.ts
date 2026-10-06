// playwright.config.ts — the E2E tests in e2e/ (.ai/rules/tests.md). It belongs to the project: install.sh creates
// it when missing.
//
// They do not run in bin/verify.sh, which only checks that the config and the specs load: they need the backend up,
// and the phase that asks for them runs them (`npx playwright test`). Against an environment already up,
// E2E_BASE_URL; without it, Playwright builds and starts the app.
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
