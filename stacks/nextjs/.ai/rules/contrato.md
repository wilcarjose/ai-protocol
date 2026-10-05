# Reglas del contrato — frontend Next.js

> Cómo se conoce lo que manda el backend y cómo se trata. Es un tema de `.ai/RULES.md §Reglas por tema`: tan innegociable como el
> núcleo, del kit `ai-protocol` y actualizado por `install.sh --upgrade`.

---

## 1. Cómo se conoce el contrato

Por este orden:

1. **Los esquemas Zod** del contrato (`src/shared/api/` y los `api/` de cada feature o entidad). Se actualizan
   **cuando cambia el backend**, no antes.
2. **Los fixtures y snapshots** de respuestas reales anonimizadas (`tests/contract-snapshots/`).
3. **`.ai/DOMAIN.md §Contrato con el otro repositorio`**: lo ya cambiado por el backend que este repo da por hecho.
4. **`.ai/handoffs/`**: las entregas del backend, copiadas.
5. **El código del backend**, cuando haga falta una clase, un método o un enum (`CLAUDE.md §El otro repositorio`).

---

## 2. Los errores son datos

- El cliente **nunca lanza** hacia arriba: devuelve una unión discriminada (`{ ok: true, data } | { ok: false,
  error }`), y los errores cruzan fronteras de módulo como datos.
- Se discrimina por el **código de error** del envelope, nunca por el texto del mensaje.
- Tres clases, tres comportamientos:

| Clase | Status | Qué hacer | Reintentar |
|---|---|---|---|
| De usuario | 400, 403, 404, 409, 422 | Mostrar el mensaje **literal del backend**: no se reescribe ni se traduce | Nunca |
| De sesión | 401 | Limpiar la sesión y llevar al login | Nunca |
| De servidor o de red | 5xx, fallo de conexión | Mensaje genérico y reintento con espera creciente | Sí, salvo límite de peticiones (429) |

---

## 3. Claves de caché: tenant y usuario, siempre

**Toda clave de TanStack Query y todo `next.tags` empieza por el tenant (si lo hay:
`.ai/project/CROSS-CUTTING.md §Tenant`) y, si la respuesta depende del usuario, por el usuario.** Se construyen con
factorías en `src/shared/api/` y en el `api/` de cada feature, nunca a mano. Una clave que no discrimina usuario sirve los datos de uno a otro: es la misma fuga que un valor cacheado
compartido en el backend, una capa más arriba.

---

## 4. Lo que el backend manda de varias formas se lee en UN solo sitio

Un backend PHP entrega una misma cosa con formas distintas según el dato o el motor: un JSON-objeto vacío llega como
`{}`, `[]` o `null`; un booleano, como `true`/`false` o `1`/`0`. Cada **variación** se resuelve una vez, en
`src/shared/api/`, con una función que acepta todas las formas y entrega una sola, y un único test guardián que
sustituye cada campo de cada variación en los snapshots y comprueba que su esquema las acepta. Una variación nueva es
una entrada más de ese registro, nunca un arreglo en el esquema que la sufre.
