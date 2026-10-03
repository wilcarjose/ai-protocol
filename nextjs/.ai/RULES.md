# RULES — {{RELLENAR: nombre del proyecto}} · frontend Next.js

> Las reglas de **cómo se escribe código** en este repositorio, para cualquier agente de IA y para cualquier humano.
> Léelo completo antes de escribir una sola línea. Si algo aquí contradice tu instinto, gana este archivo.
>
> Tres reglas que aplican a todo lo demás:
>
> 1. Si crees que una regla está mal o desactualizada: **STOP & ASK** (`.ai/WORKFLOW.md §3`). Nadie edita este
>    archivo sin el visto bueno del Tech Lead, y nunca desde una fase.
> 2. Las reglas de **cómo se trabaja** (qué reportar, cuándo parar, cómo verificar) viven en `.ai/WORKFLOW.md` y en
>    `CLAUDE.md`. Jerarquía si chocan: este archivo > `.ai/WORKFLOW.md` > `CLAUDE.md`.
> 3. Lo que cambia con el estado del proyecto (decisiones de negocio, contrato vigente del backend, fase activa) vive
>    en `.ai/DOMAIN.md` y `.ai/STATE.md`. Aquí sólo hay reglas **estables**.
>
> Son las convenciones por defecto del kit de protocolo. Al instalarlo se ajustan al proyecto; después, sólo las
> cambia el Tech Lead.

---

## 1. Stack y versiones exactas

Verificadas contra `package.json`: el chequeo «stack» de `bin/check-docs.sh` compara esta tabla, versión a versión,
con lo que declara el manifiesto. Una fila por paquete (varios en una fila, separados por « / »; una sola versión
vale para todos).

| Paquete | Versión | Nota |
|---|---|---|
| `next` | {{RELLENAR: p. ej. 16.1.0}} | App Router. ⚠️ La semántica de caché cambia entre versiones mayores |
| `react` / `react-dom` | {{RELLENAR: p. ej. 19.2.3}} | |
| `typescript` | {{RELLENAR: p. ej. ^5}} | `strict: true` en `tsconfig.json` |
| `zod` | {{RELLENAR: p. ej. ^4.3.6}} | Toda frontera se valida (§4) |
| `@tanstack/react-query` | {{RELLENAR: p. ej. ^5.90.0}} | Datos del servidor en el cliente (§6) |
| `zustand` | {{RELLENAR: p. ej. ^5.0.9}} | Estado de cliente compartido (§6) |
| `vitest` | {{RELLENAR: p. ej. ^4.0.0}} | Tests unitarios (§11) |
| `eslint` | {{RELLENAR: p. ej. ^9}} | Config plana, con la regla de capas (§5) |

> **Antes de usar una API de cualquiera de estas librerías, lee `docs/vendor/INDEX.md`** (§8). Tu memoria de
> entrenamiento corresponde probablemente a otra versión.

---

## 2. Alcance — qué puedes tocar

### ✅ Dentro de alcance (con autorización de la fase activa)

```
src/**
tests/**
e2e/**
```

### ⛔ Fuera de alcance salvo autorización explícita de la fase

```
package.json, lockfile     ← ninguna dependencia nueva sin preguntar
tsconfig.json              ← nunca se relaja
eslint.config.*            ← nunca se bajan reglas; una regla nueva, con la fase
next.config.*              ← sólo si la fase lo pide
.env*                      ← nunca se leen ni se escriben secretos
el repo hermano            ← nunca se escribe en él (CLAUDE.md §El otro repositorio)
```

{{RELLENAR: lo que este proyecto deja fuera además, o «Nada más.»}}

Si un cambio *parece* requerir tocar algo de fuera de alcance: **detente y repórtalo**. Es una señal de que el
alcance de la fase está mal, no un obstáculo que sortear.

---

## 3. Contrato HTTP — cómo se habla con el backend

El contrato es la API del backend tal como la ve este repo: URLs, verbos, status, claves de entrada y salida, su
forma, cabeceras y el texto de los mensajes. Este repo **lo consume, no lo define**. Una fase que consume un cambio
del backend ya decidido lleva `Contrato HTTP: CAMBIO AUTORIZADO` con la decisión que lo respalda; lo que necesite que
cambie el backend es un traspaso (`CLAUDE.md §El otro repositorio`), nunca una suposición.

### 3.1 Una sola capa HTTP

`fetch` y cualquier cliente HTTP sólo existen dentro de `src/shared/api/`: el cliente único, la unión de errores, los
esquemas del contrato y las factorías de claves de caché viven ahí. Toda petición sale de ese cliente, que es el
único sitio que construye las cabeceras (autenticación, idioma, tenant, zona horaria…). Perder una cabecera devuelve
datos equivocados **sin error**.

{{RELLENAR: cómo se autentica el cliente (token Bearer, cookie HttpOnly detrás de un BFF en `src/app/api/`…) y qué
cabeceras lleva toda petición. Si hay BFF: su lista blanca de rutas es la única puerta; una ruta nueva se añade ahí,
nunca se abre otro proxy.}}

### 3.2 Cómo se conoce el contrato

Por este orden:

1. **Los esquemas Zod** del contrato (`src/shared/api/` y los `api/` de cada feature o entidad). Se actualizan
   **cuando cambia el backend**, no antes.
2. **Los fixtures y snapshots** de respuestas reales anonimizadas (`tests/contract-snapshots/`).
3. **`.ai/DOMAIN.md §Contrato con el otro repositorio`**: lo ya cambiado por el backend que este repo da por hecho.
4. **`.ai/handoffs/`**: las entregas del backend, copiadas.
5. **El código del backend**, cuando haga falta una clase, un método o un enum (`CLAUDE.md §El otro repositorio`).

### 3.3 La forma de una respuesta NO se adivina

Se lee de los esquemas o de los snapshots. Si ninguno la fija: **detente y pregunta** (`.ai/WORKFLOW.md §2.1`). No la
infieras del código del frontend, que puede llevar formas equivocadas.

### 3.4 Los errores son datos

- El cliente **nunca lanza** hacia arriba: devuelve una unión discriminada (`{ ok: true, data } | { ok: false,
  error }`), y los errores cruzan fronteras de módulo como datos.
- Se discrimina por el **código de error** del envelope, nunca por el texto del mensaje.
- Tres clases, tres comportamientos:

| Clase | Status | Qué hacer | Reintentar |
|---|---|---|---|
| De usuario | 400, 403, 404, 409, 422 | Mostrar el mensaje **literal del backend**: no se reescribe ni se traduce | Nunca |
| De sesión | 401 | Limpiar la sesión y llevar al login | Nunca |
| De servidor o de red | 5xx, fallo de conexión | Mensaje genérico y reintento con espera creciente | Sí, salvo límite de peticiones (429) |

### 3.5 Claves de caché: tenant y usuario, siempre

**Toda clave de TanStack Query y todo `next.tags` empieza por el tenant (si lo hay) y, si la respuesta depende del
usuario, por el usuario.** Se construyen con factorías en `src/shared/api/` y en el `api/` de cada feature, nunca a
mano. Una clave que no discrimina usuario sirve los datos de uno a otro: es la misma fuga que un valor cacheado
compartido en el backend, una capa más arriba.

### 3.6 Lo que el backend manda de varias formas se lee en UN solo sitio

Un backend PHP entrega una misma cosa con formas distintas según el dato o el motor: un JSON-objeto vacío llega como
`{}`, `[]` o `null`; un booleano, como `true`/`false` o `1`/`0`. Cada **variación** se resuelve una vez, en
`src/shared/api/`, con una función que acepta todas las formas y entrega una sola, y un único test guardián que
sustituye cada campo de cada variación en los snapshots y comprueba que su esquema las acepta. Una variación nueva es
una entrada más de ese registro, nunca un arreglo en el esquema que la sufre.

---

## 4. Principios rectores

Cuando dos choquen, gana el de número menor.

1. **El código es la fuente de verdad.** Ante una duda sobre la forma de un dato se lee el contrato (§3.2), no se
   adivina.
2. **Ningún dato cruza una frontera sin validarse** con Zod: respuestas HTTP, `formData`, `searchParams`, variables
   de entorno, cookies.
3. **`any` está prohibido.** Lo desconocido es `unknown` y se estrecha con un esquema.
4. **Los tipos se derivan, no se escriben**: todo tipo de datos externos es `z.infer<typeof schema>`.
5. **Un solo cliente HTTP** (§3.1).
6. **Los componentes renderizan; no orquestan.** Nada de red, WebSockets, cookies, storage ni cálculos de negocio en
   un `.tsx` de presentación.
7. **Un dominio es una carpeta** (§5).
8. **Nada es global e implícito.** Tenant, idioma y usuario viajan explícitos por las firmas y por las claves de
   caché.
9. **Los errores son datos** (§3.4).
10. **Todo cambio tiene una verificación ejecutable**: `bash bin/verify.sh`.

---

## 5. Estructura y regla de dependencias

```
src/
├── app/         ← rutas de Next (App Router): composición, layouts, Route Handlers
├── features/    ← un dominio de negocio por carpeta: <dominio>/{api,model,ui,lib,index.ts}
├── entities/    ← lo que comparten varias features: <entidad>/{api,ui,index.ts}
└── shared/      ← sin dominio: api/ (cliente, errores, contrato, claves), ui/, lib/, config/
```

```
app  →  features  →  entities  →  shared
```

- Las flechas van en **un solo sentido**: `shared` no importa de `entities`, `entities` no importa de `features`,
  `features` no importa de `app`.
- **Las features no se importan entre sí.** Si dos dominios necesitan lo mismo, baja a `entities` o a `shared`.
- Cada carpeta expone su API pública por su `index.ts`; nadie importa de sus tripas.
- La regla la aplica el linter (`eslint-plugin-boundaries` o equivalente): un import que la rompe es un error de
  lint, no una convención que alguien recuerda.

---

## 6. Estado: qué herramienta y dónde vive

| Tipo de estado | Herramienta | Dónde vive |
|---|---|---|
| Datos del servidor en un Server Component | `fetch` del cliente único con `next.tags` | `src/shared/api/` y el `api/` de la feature |
| Datos del servidor en el cliente | TanStack Query | `src/features/<dominio>/model/` |
| Estado de cliente compartido | Zustand | `src/features/<dominio>/model/` |
| Estado en la URL (filtros, página, fecha) | `searchParams` validados con Zod | la página |
| Formulario | Server Action + `useActionState`, entrada validada con Zod | `src/features/<dominio>/` |
| Estado efímero de un componente | `useState` | el propio componente |
| Sesión y token | cookie HttpOnly, nunca `localStorage` | `src/shared/` y el BFF si lo hay |

Una Server Action valida su entrada con Zod y, si cambia datos, invalida sus tags (con la firma de la versión de
Next instalada: `docs/vendor/INDEX.md`).

---

## 7. Componentes, textos e identificadores

- **Un componente de presentación renderiza**: recibe datos y callbacks. Prohibido dentro: red, WebSockets,
  `document.cookie`, `localStorage`/`sessionStorage`, `window.location.href = …` (se usa el router) y cálculos de
  negocio.
- **Cero texto visible escrito a mano en JSX** si el proyecto tiene más de un idioma: toda cadena pasa por las
  traducciones, y una clave nueva se añade a **todos** los idiomas a la vez. {{RELLENAR: librería de i18n y
  ubicación de los mensajes, o «Un solo idioma: los textos van en el componente.»}}
- **Todo elemento interactivo lleva `data-testid`** con el formato `<dominio>-<elemento>[-<variante>]`, en
  kebab-case y en inglés (`auth-login-email`, `orders-row-${id}`). Cambiar uno rompe sus E2E: se cambian en el mismo
  commit o no se cambia.

| Elemento | Formato | Ejemplo |
|---|---|---|
| Carpeta de dominio | kebab-case | `features/order-history/` |
| Componente | PascalCase, archivo igual al export, en `ui/` | `OrderCard.tsx` |
| Hook | `use` + PascalCase | `useCreateOrder` |
| Server Action | verbo + sustantivo + `Action` | `createOrderAction` |
| Esquema Zod | camelCase + `Schema` | `orderSchema` |
| Tipo derivado | PascalCase, sin sufijo | `type Order = z.infer<typeof orderSchema>` |
| Store de Zustand | `use` + dominio + `Store` | `useCartStore` |
| Factoría de claves | dominio + `Keys` | `orderKeys` |

Identificadores y comentarios del código, en inglés; la documentación para agentes, en español. Lo que importa es que
sea uno solo y esté escrito: la mezcla arbitraria es lo que hace alucinar a un agente.

---

## 8. Documentación vendorizada

`docs/vendor/` guarda notas de las APIs de las librerías **en la versión instalada**, sacadas de sus `.d.ts` y de
su documentación de esa versión, con un índice de preguntas en `docs/vendor/INDEX.md`. **Antes de usar una API de
una librería del stack, consulta el índice; nunca tu memoria.** Si la pregunta no está, la fase que la necesita
añade la nota (y su fila en el índice) leyendo los tipos instalados.

---

## 9. Frontera de seguridad en pagos

El frontend **nunca** maneja datos de tarjeta ni secretos de la pasarela de pago:

- Cero campos de número de tarjeta o CVV en un formulario propio: sólo redirección a un checkout alojado por la
  pasarela, o su componente embebido oficial.
- Cero secretos de la pasarela (claves privadas, secretos de webhook) bajo `NEXT_PUBLIC_*` ni en el bundle.

---

## 10. Zonas sensibles

Tocar estas zonas de una forma que la fase no describe con precisión es motivo de parada
(`.ai/WORKFLOW.md §2.9`):

- Autenticación, sesión, cookies y tokens.
- Pagos y planes.
- {{RELLENAR: los cálculos o reglas de los que depende el negocio, o bórralo}}

---

## 11. Tests

- **Unitarios con Vitest** en `tests/` o junto al código (`*.test.ts`). Sin red real: el cliente se sustituye por
  fixtures.
- **Contrato:** cada esquema se prueba contra los snapshots de `tests/contract-snapshots/` (§3.2, §3.6).
- **E2E con Playwright** en `e2e/`: sólo `getByTestId()` (la interfaz cambia de idioma, los testids no), cero esperas
  por tiempo (`waitForTimeout`), aserciones con reintento automático. Necesitan el backend levantado: sólo cuentan
  si la fase lo pide, y su §5 dice quién provee el backend.
- **No se modifica un test existente para que pase un cambio**: si falla, el cambio está mal o es una decisión del
  Tech Lead (`.ai/WORKFLOW.md §2.7`). Nunca `test.skip()` condicional; para retirar cobertura, `test.fixme()` con el
  motivo, y se nombra en el reporte.

---

## 12. Verificación del stack

`bash bin/verify.sh` corre los gates en su orden (tipos, estilo, deuda de lint, tests); aquí sólo lo que no cabe en
el script:

- **TypeScript** con `strict: true`; `tsconfig.json` nunca se relaja. Cero `@ts-ignore` y `@ts-expect-error` sin
  motivo escrito al lado; cero casts sobre datos de red (se validan).
- **ESLint** con `--max-warnings=0`. Las reglas no se bajan ni se desactivan por archivo para que algo pase.
- **Supresiones congeladas** (`eslint-suppressions.json`, si existe): **sólo menguan**. Una supresión nueva no se
  añade; `MAX_SUPPRESSIONS` en `bin/verify.sh` lo vigila.

---

## 13. Lista negra

1. ⛔ **No inventes funcionalidad** ni formas de respuesta.
2. ⛔ **No arregles bugs que encuentres de paso**: a `.ai/BACKLOG.md`.
3. ⛔ **No uses `fetch` ni un cliente HTTP fuera de `src/shared/api/`.**
4. ⛔ **No uses `any`**, ni casts sobre datos externos.
5. ⛔ **No traduzcas ni reescribas los mensajes de error del backend.**
6. ⛔ **No compares códigos de error por su texto ni en otra capitalización** que la del contrato.
7. ⛔ **No construyas claves de caché a mano** (§3.5).
8. ⛔ **No guardes tokens en `localStorage` ni `sessionStorage`.**
9. ⛔ **No instales dependencias** sin que la fase lo pida.
10. ⛔ **No escribas en el repo hermano** ni cites sus documentos (`CLAUDE.md §El otro repositorio`).
11. ⛔ **No dejes llamadas de depuración**: `console.log`, `debugger`.
12. ⛔ **No cites catálogos mutables** (`P<n>-<m>`, `§X` de una lista que se renumera) desde código, tests ni
    documentos. El porqué que debe sobrevivir va a `.ai/DOMAIN.md` o a `docs/adr/`.

### Archivos que NO se usan como referencia

<!-- Código que existe y lleva una forma, un patrón o una comparación equivocada que un agente podría copiar. Una
     fila por archivo, con por qué es veneno. Cuando el archivo se borra, la fila se borra (el chequeo «rutas» de
     bin/check-docs.sh avisa de la ruta que ya no existe). -->

Ninguno todavía.

---

## 14. Ámbitos de commit

Conventional Commits en inglés (`CLAUDE.md §Commits durante la fase`). Ámbitos:

- Transversales: `api`, `auth`, `i18n`, `e2e`, `ci`, `deps`, `docs`, `tests`, `planning`, `protocol`, y
  `phase-<NN>-<FF>` para los commits de arranque, reanudación y cierre de una fase.
- Del dominio: {{RELLENAR: un ámbito por área del negocio, p. ej. `orders`, `catalog`, `profile`}}.

Un ámbito nuevo se añade aquí antes de usarlo.
