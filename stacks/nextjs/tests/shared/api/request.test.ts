import { describe, expect, it } from "vitest";

import { request } from "@/shared/api";

const problemJson = { "content-type": "application/problem+json" };

function failed(status: number, body: unknown, headers: Record<string, string> = problemJson) {
  return Promise.resolve({ error: body, response: new Response(null, { status, headers }) });
}

describe("request", () => {
  it("returns the data of a successful call", async () => {
    const result = await request(Promise.resolve({ data: { id: 1 }, response: new Response(null, { status: 200 }) }));

    expect(result).toEqual({ ok: true, data: { id: 1 } });
  });

  it("reads problem+json and keeps the code and the literal detail", async () => {
    const problem = { type: "https://example.test/problems/demo-not-found", title: "Not Found", status: 404, detail: "No existe la demo 7.", code: "DEMO_NOT_FOUND" };

    const result = await request(failed(404, problem));

    expect(result).toEqual({
      ok: false,
      error: { class: "user", status: 404, code: "DEMO_NOT_FOUND", detail: "No existe la demo 7.", problem, retry: false },
    });
  });

  it("classifies by status: 401 is session, 5xx server with retry, 429 server without retry", async () => {
    const codes = async (status: number) => {
      const result = await request(failed(status, { title: "x", status, code: "x" }));
      return result.ok ? null : [result.error.class, result.error.retry];
    };

    expect(await codes(401)).toEqual(["session", false]);
    expect(await codes(503)).toEqual(["server", true]);
    expect(await codes(429)).toEqual(["server", false]);
  });

  it("gives no code when the body is not problem+json", async () => {
    const result = await request(failed(422, { code: "looks_like_one" }, { "content-type": "application/json" }));

    expect(result.ok).toBe(false);
    expect(result.ok ? null : result.error.code).toBeNull();
  });

  it("turns a network failure into a retriable server error", async () => {
    const result = await request(Promise.reject(new TypeError("fetch failed")));

    expect(result).toEqual({
      ok: false,
      error: { class: "server", status: null, code: null, detail: null, problem: null, retry: true },
    });
  });
});
