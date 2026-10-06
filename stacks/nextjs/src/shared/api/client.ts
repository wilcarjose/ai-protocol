// The only HTTP client (.ai/RULES.md §Una sola capa HTTP).
//
// Its types come from the contract: schema.d.ts is generated from docs/contract/openapi.json by
// `sh bin/contract.sh` and never edited by hand. The headers every request carries are the project's
// (.ai/project/CONTRACT.md §Autenticación y cabeceras): add them here, in one place.
import createClient from "openapi-fetch";
import { z } from "zod";

import { networkError, toApiError, type ApiError } from "./errors";
import type { paths } from "./schema";

const env = z.object({ NEXT_PUBLIC_API_URL: z.string().default("") }).parse({
  NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
});

export const api = createClient<paths>({ baseUrl: env.NEXT_PUBLIC_API_URL });

export type ApiResult<T> = { ok: true; data: T } | { ok: false; error: ApiError };

// An openapi-fetch call resolves to `{ data, response }` on success and `{ error, response }` otherwise (`error` is
// the parsed body). Success<R> is the type of `data` in the success member only: inferring it from the whole union
// would add the `undefined` of the error member.
type Success<R> = R extends { data: infer D; error?: never } ? D : never;

function succeeded<R extends { response: Response }>(result: R): result is R & { data: Success<R> } {
  return "data" in result && result.response.ok;
}

// request never throws: the call's result or its error, as data.
//
//   const result = await request(api.GET("/demos/{id}", { params: { path: { id } } }));
//   if (!result.ok && result.error.code === "demo_not_found") …
export async function request<R extends { response: Response }>(call: Promise<R>): Promise<ApiResult<Success<R>>> {
  let result: R;
  try {
    result = await call;
  } catch {
    return { ok: false, error: networkError() };
  }
  if (succeeded(result)) return { ok: true, data: result.data };
  return { ok: false, error: toApiError(result.response, "error" in result ? result.error : undefined) };
}
