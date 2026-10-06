# RULES — frontend Next.js

> Las reglas de **cómo se escribe código** en este repositorio, para cualquier agente de IA y para cualquier humano.
> Este archivo es el núcleo y se lee entero antes de escribir una línea; los temas de `.ai/rules/` se leen cuando la
> fase los cita (§Reglas por tema). Si algo aquí contradice tu instinto, gana este archivo.
>
> 1. Si crees que una regla está mal o desactualizada: **STOP & ASK** (`.ai/WORKFLOW.md §STOP & ASK`). Quién la
>    cambia y cómo: `.ai/WORKFLOW.md §Archivos del protocolo`.
> 2. Son las reglas **estables** del stack del kit `ai-protocol`, y las actualiza `install.sh --upgrade` (si el
>    proyecto cambia este archivo, el upgrade lo enseña como conflicto). Cómo se trabaja: `.ai/WORKFLOW.md` y las
>    skills; lo que decide el proyecto: `.ai/project/`, que aquí se cita. Si chocan, gana este archivo.

---

## 1. Stack y versiones exactas

Los paquetes que el stack da por hechos. Su versión exacta, en `.ai/project/DECISIONS.md §Stack y versiones exactas`,
que el chequeo «stack» de `bin/check-docs.sh` compara con `package.json`. Varios en una fila, separados por « / ».

| Paquete | Nota |
|---|---|
| `next` | App Router. ⚠️ La semántica de caché cambia entre versiones mayores |
| `react` / `react-dom` | |
| `typescript` | `strict: true` en `tsconfig.json` |
| `zod` | Las fronteras que no tipa el contrato (§4) |
| `openapi-fetch` / `openapi-typescript` | El cliente y sus tipos, generados del contrato (§3) |
| `@tanstack/react-query` | Datos del servidor en el cliente (`.ai/rules/arquitectura.md §Estado`) |
| `zustand` | Estado de cliente compartido (`.ai/rules/arquitectura.md §Estado`) |
| `vitest` / `@playwright/test` | Unitarios y E2E (`.ai/rules/tests.md`) |
| `eslint` / `eslint-plugin-boundaries` / `eslint-import-resolver-typescript` | Config plana, con la regla de capas (§5) |

> **Antes de usar una API de cualquiera de estas librerías, lee `docs/vendor/INDEX.md`** (§7). Tu memoria de
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
package.json, lockfile     ← dependencias nuevas: .ai/WORKFLOW.md §Dependencia nueva
tsconfig.json              ← nunca se relaja
eslint.config.*            ← nunca se bajan reglas; una regla nueva, con la fase
next.config.*              ← sólo si la fase lo pide; con `agentRules: false` (AGENTS.md es del kit)
docs/contract/             ← la copia del contrato: .ai/rules/contrato.md §Cómo se conoce el contrato
.env*                      ← nunca se leen ni se escriben secretos
el repo hermano            ← nunca se escribe en él (CLAUDE.md §El otro repositorio)
```

Lo que este proyecto deja fuera además: `.ai/project/ARCHITECTURE.md §Fuera de alcance`.

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
tipos generados del contrato y las factorías de claves de caché viven ahí. Toda petición sale de ese cliente, que es el
único sitio que construye las cabeceras (autenticación, idioma, tenant, zona horaria…). Perder una cabecera devuelve
datos equivocados **sin error**.

Cómo se autentica el cliente y qué cabeceras lleva toda petición: `.ai/project/CONTRACT.md §Autenticación y
cabeceras`. Si hay un BFF (en `src/app/api/`), su lista blanca de rutas es la única puerta.

### 3.2 La forma de una respuesta NO se adivina

Se lee de los tipos generados del contrato o de los snapshots. Si ninguno la fija: **detente y pregunta**
(`.ai/WORKFLOW.md §Contrato`). No la infieras del código del frontend, que puede llevar formas equivocadas.

Cómo se conoce el contrato, los errores, las claves de caché y las formas que varían: `.ai/rules/contrato.md`.

---

## 4. Principios rectores

Cuando dos choquen, gana el de número menor.

1. **El código es la fuente de verdad.** Ante una duda sobre la forma de un dato se lee el contrato (`.ai/rules/contrato.md §Cómo se conoce el contrato`), no se
   adivina.
2. **Ningún dato cruza una frontera sin validarse**: las respuestas HTTP, con los tipos del contrato (§3);
   `formData`, `searchParams`, variables de entorno y cookies, con Zod.
3. **`any` está prohibido.** Lo desconocido es `unknown` y se estrecha con un esquema.
4. **Los tipos se derivan, no se escriben**: de los generados (`components["schemas"][…]`) o con `z.infer`.
5. **Un solo cliente HTTP** (§3.1).
6. **Los componentes renderizan; no orquestan.** Nada de red, WebSockets, cookies, storage ni cálculos de negocio en
   un `.tsx` de presentación.
7. **Un dominio es una carpeta** (§5).
8. **Nada es global e implícito.** Tenant, idioma y usuario viajan explícitos por las firmas y por las claves de
   caché.
9. **Los errores son datos** (`.ai/rules/contrato.md §Los errores son datos`).
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
- La aplica el linter con `eslint.layers.mjs`, del kit, que `eslint.config.mjs` importa (el gate «capas» lo
  comprueba): un import que la rompe es un error de lint, no una convención que alguien recuerda.

---

## 6. Reglas por tema

Cada tema vive en su archivo de `.ai/rules/` y es tan innegociable como este. La fase lista en «Contexto que debes
leer antes» los que toca; si vas a tocar algo de un tema que la fase no cita, léelo igual antes de escribir.

| Archivo | Qué cubre | Se lee si la fase toca |
|---|---|---|
| `.ai/rules/contrato.md` | Cómo se conoce el contrato y se genera el cliente, errores problem+json, claves de caché, formas variables | `src/shared/api/`, el `api/` de una feature o entidad, o los datos del servidor |
| `.ai/rules/arquitectura.md` | Qué herramienta de estado y dónde vive; componentes, textos, testids y nombres | Cualquier componente, hook, store o Server Action |
| `.ai/rules/tests.md` | Vitest, tests de contrato, E2E con Playwright y Lighthouse | `tests/` o `e2e/` (casi siempre) |

---

## 7. Documentación vendorizada

`docs/vendor/` guarda notas de las APIs de las librerías **en la versión instalada**, sacadas de sus `.d.ts` y de
su documentación de esa versión, con un índice de preguntas en `docs/vendor/INDEX.md`. **Antes de usar una API de
una librería del stack, consulta el índice; nunca tu memoria.** Si la pregunta no está, la fase que la necesita
añade la nota (y su fila en el índice) leyendo los tipos instalados.

---

## 8. Frontera de seguridad en pagos

El frontend **nunca** maneja datos de tarjeta ni secretos de la pasarela de pago:

- Cero campos de número de tarjeta o CVV en un formulario propio: sólo redirección a un checkout alojado por la
  pasarela, o su componente embebido oficial.
- Cero secretos de la pasarela (claves privadas, secretos de webhook) bajo `NEXT_PUBLIC_*` ni en el bundle.

---

## 9. Zonas sensibles

Tocar estas zonas de una forma que la fase no describe con precisión es motivo de parada
(`.ai/WORKFLOW.md §Zona sensible`):

- Autenticación, sesión, cookies y tokens.
- Pagos y planes.
- Las del proyecto: `.ai/project/SENSITIVE-ZONES.md`.

---

## 10. Verificación del stack

`bash bin/verify.sh` corre los gates en su orden (contrato, tipos, estilo, capas, deuda de lint, tests, build); aquí
sólo lo que no cabe en el script:

- **TypeScript** con `strict: true`; `tsconfig.json` nunca se relaja. Cero `@ts-ignore` y `@ts-expect-error` sin
  motivo escrito al lado; cero casts sobre datos de red (se validan).
- **ESLint** con `--max-warnings=0`. Las reglas no se bajan ni se desactivan por archivo para que algo pase.
- **Supresiones congeladas** (`eslint-suppressions.json`, si existe): **sólo menguan**. Una supresión nueva no se
  añade; `MAX_SUPPRESSIONS` de `.ai/project/verify.conf` lo vigila.

---

## 11. Lista negra

Las prohibiciones que valen para cualquier stack no se repiten aquí: no arreglar de paso (`CLAUDE.md §Alcance`),
dependencias nuevas (`.ai/WORKFLOW.md §Dependencia nueva`) y exenciones a un gate
(`.ai/WORKFLOW.md §Obediencia arquitectónica`). Éstas son las de Next.js:

1. ⛔ **No inventes funcionalidad** ni formas de respuesta.
2. ⛔ **No uses `fetch` ni un cliente HTTP fuera de `src/shared/api/`.**
3. ⛔ **No uses `any`**, ni casts sobre datos externos.
4. ⛔ **No traduzcas ni reescribas los mensajes de error del backend.**
5. ⛔ **No compares códigos de error por su texto ni en otra capitalización** que la del contrato.
6. ⛔ **No construyas claves de caché a mano** (`.ai/rules/contrato.md §Claves de caché`).
7. ⛔ **No guardes tokens en `localStorage` ni `sessionStorage`.**
8. ⛔ **No escribas en el repo hermano** ni cites sus documentos (`CLAUDE.md §El otro repositorio`).
9. ⛔ **No dejes llamadas de depuración**: `console.log`, `debugger`.
10. ⛔ **No cites catálogos mutables** (`P<n>-<m>`, `§X` de una lista que se renumera) desde código, tests ni
    documentos. El porqué que debe sobrevivir va a `.ai/DOMAIN.md` o a `docs/adr/`.
11. ⛔ **No escribas el código en español**: nombres (archivos, clases, métodos, tablas, rutas…), claves de
    traducción, códigos de error, logs, tests y comentarios, en inglés y con los términos de
    `.ai/project/GLOSSARY.md`. En español, sólo los textos para el usuario, los slugs públicos y los datos semilla.

### Archivos que NO se usan como referencia

<!-- Código que existe y lleva una forma, un patrón o una comparación equivocada que un agente podría copiar. Una
     fila por archivo, con por qué es veneno. Cuando el archivo se borra, la fila se borra (el chequeo «rutas» de
     bin/check-docs.sh avisa de la ruta que ya no existe). -->

Ninguno todavía.

---

## 12. Ámbitos de commit

Conventional Commits en inglés (`.claude/skills/phase/SKILL.md §Commits durante la fase`). Ámbitos:

- Transversales: `api`, `auth`, `i18n`, `e2e`, `ci`, `deps`, `docs`, `tests`, `planning`, `protocol`, y
  `phase-<NN>-<FF>` para los commits de arranque, reanudación y cierre de una fase.
- Del dominio: los de `.ai/project/COMMIT-SCOPES.md`, donde se añade uno nuevo antes de usarlo.
