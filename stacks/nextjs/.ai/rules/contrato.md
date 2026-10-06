# Reglas del contrato — frontend Next.js

> Cómo se conoce lo que manda el backend y cómo se trata. Es un tema de `.ai/RULES.md §Reglas por tema`: tan innegociable como el
> núcleo, del kit `ai-protocol` y actualizado por `install.sh --upgrade`.

---

## 1. Cómo se conoce el contrato

Por este orden:

1. **El OpenAPI del backend**, copiado en `docs/contract/openapi.json`, y los tipos que `sh bin/contract.sh` genera
   de él en `src/shared/api/schema.d.ts`. Ninguno de los dos se edita a mano. La copia cambia cuando cambia el
   backend, no antes: en una fase con `Contrato HTTP: CAMBIO AUTORIZADO`, y los tipos se regeneran en el mismo
   commit (el gate «contrato» falla si no). Las rutas salen de `.ai/project/verify.conf`.
2. **Los fixtures y snapshots** de respuestas reales anonimizadas (`tests/contract-snapshots/`).
3. **`.ai/DOMAIN.md §Contrato con el otro repositorio`**: lo ya cambiado por el backend que este repo da por hecho.
4. **`.ai/handoffs/`**: las entregas del backend, copiadas.
5. **El código del backend**, cuando haga falta una clase, un método o un enum (`CLAUDE.md §El otro repositorio`).

Toda petición sale de `request(api.GET(…))` (`src/shared/api/`): `api` es el cliente de `openapi-fetch` tipado con
`paths`, y la ruta, los parámetros y la respuesta se comprueban al compilar. Un tipo de datos del backend se toma de
`components["schemas"]`, nunca se reescribe. Zod queda para lo que el contrato no tipa
(`.ai/RULES.md §Principios rectores`).

---

## 2. Los errores son datos

- El cliente **nunca lanza** hacia arriba: `request` devuelve una unión discriminada
  (`{ ok: true, data } | { ok: false, error }`), y los errores cruzan fronteras de módulo como datos. Un fallo de
  red también.
- El backend responde los errores en `application/problem+json` (RFC 9457): `type`, `title`, `status`, `detail` y la
  extensión `code`. El cliente lo lee en `error.code`, `error.detail` y `error.problem`.
- Se discrimina por **`error.code`**, nunca por el texto del mensaje ni por `title`. Si la copia del OpenAPI enumera
  los códigos, se usan sus literales.
- Tres clases, tres comportamientos, en `error.class` (y `error.retry`):

| Clase | Status | Qué hacer | Reintentar |
|---|---|---|---|
| `user` | 400, 403, 404, 409, 422 (4xx salvo 401 y 429) | Mostrar `error.detail` **literal**: no se reescribe ni se traduce | Nunca |
| `session` | 401 | Limpiar la sesión y llevar al login | Nunca |
| `server` | 5xx, 429, fallo de conexión (`status: null`) | Mensaje genérico y reintento con espera creciente | Sí, salvo 429 |

---

## 3. Claves de caché: tenant y usuario, siempre

**Toda clave de TanStack Query y todo `next.tags` empieza por el tenant (si lo hay:
`.ai/project/CROSS-CUTTING.md §Tenant`) y, si la respuesta depende del usuario, por el usuario.** Se construyen con
factorías en `src/shared/api/` y en el `api/` de cada feature, nunca a mano. Una clave que no discrimina usuario sirve los datos de uno a otro: es la misma fuga que un valor cacheado
compartido en el backend, una capa más arriba.

---

## 4. Lo que el backend manda de varias formas se lee en UN solo sitio

Un backend PHP entrega una misma cosa con formas distintas según el dato o el motor: un JSON-objeto vacío llega como
`{}`, `[]` o `null`; un booleano, como `true`/`false` o `1`/`0`. Si el OpenAPI no lo recoge, los tipos generados
mienten: es un traspaso al backend. Mientras tanto, cada **variación** se resuelve una vez, en `src/shared/api/`, con
una función que acepta todas las formas y entrega la que dicen los tipos, y un único test guardián que sustituye cada
campo de cada variación en los snapshots y comprueba que la función las normaliza. Una variación nueva es una entrada
más de ese registro, nunca un arreglo en el código que la sufre.
