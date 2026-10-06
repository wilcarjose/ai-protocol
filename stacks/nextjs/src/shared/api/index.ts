// The public API of src/shared/api: import from here, never from its files (.ai/RULES.md §Estructura y regla de
// dependencias).
export { api, request, type ApiResult } from "./client";
export { toApiError, type ApiError, type ApiErrorClass, type Problem } from "./errors";
export type { components, paths } from "./schema";
