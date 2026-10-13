// next-intl imports "next/server" without its extension: this test only loads if vitest.config.ts inlines the
// package (.ai/rules/tests.md §Tests).
import { describe, expect, it } from "vitest";

import createMiddleware from "next-intl/middleware";

describe("next-intl under Vitest", () => {
  it("loads its middleware", () => {
    expect(typeof createMiddleware).toBe("function");
  });
});
