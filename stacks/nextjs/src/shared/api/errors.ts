// The error union of the HTTP client (.ai/rules/contrato.md §Los errores son datos).
//
// The backend answers errors as RFC 9457 problem+json with the `code` extension. Code branches on `code`, never on
// the message text, and shows `detail` as the backend wrote it.
import { z } from "zod";

const problemSchema = z.object({
  type: z.string().default("about:blank"),
  title: z.string(),
  status: z.number().int(),
  detail: z.string().optional(),
  code: z.string(),
});

export type Problem = z.infer<typeof problemSchema>;

// What the caller does with the error: show the backend message (user), send to login (session), or a generic
// message with retries (server, network included).
export type ApiErrorClass = "user" | "session" | "server";

export type ApiError = {
  class: ApiErrorClass;
  // null: there was no response (network failure).
  status: number | null;
  // The problem+json `code`; null when the response was not problem+json.
  code: string | null;
  // The backend message, literal; null when it sent none.
  detail: string | null;
  problem: Problem | null;
  retry: boolean;
};

const PROBLEM_JSON = "application/problem+json";

function classify(status: number): ApiErrorClass {
  if (status === 401) return "session";
  if (status >= 400 && status < 500 && status !== 429) return "user";
  return "server";
}

// toApiError turns a failed response into data. `body` is what openapi-fetch read from it: the parsed JSON, or the
// text when it was not JSON.
export function toApiError(response: Response, body: unknown): ApiError {
  const errorClass = classify(response.status);
  const isProblem = (response.headers.get("content-type") ?? "").toLowerCase().startsWith(PROBLEM_JSON);
  const parsed = isProblem ? problemSchema.safeParse(body) : null;
  const problem = parsed?.success ? parsed.data : null;
  return {
    class: errorClass,
    status: response.status,
    code: problem?.code ?? null,
    detail: problem?.detail ?? null,
    problem,
    retry: errorClass === "server" && response.status !== 429,
  };
}

export function networkError(): ApiError {
  return { class: "server", status: null, code: null, detail: null, problem: null, retry: true };
}
