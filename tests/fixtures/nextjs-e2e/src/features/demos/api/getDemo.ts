import { api, request, type ApiResult, type components } from "@/shared/api";

export type Demo = components["schemas"]["Demo"];

export function getDemo(id: number): Promise<ApiResult<Demo>> {
  return request(api.GET("/demos/{id}", { params: { path: { id } } }));
}
