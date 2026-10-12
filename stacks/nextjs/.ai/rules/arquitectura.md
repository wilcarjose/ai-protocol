# Reglas de arquitectura — frontend Next.js

> Dónde vive cada estado y cómo se escribe cada componente. Es un tema de `.ai/RULES.md §Reglas por tema`: tan innegociable como el
> núcleo, del kit `ai-protocol` y actualizado por `install.sh --upgrade`.

---

## 1. Estado: qué herramienta y dónde vive

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

## 2. Componentes, textos e identificadores

- **Un componente de presentación renderiza**: recibe datos y callbacks. Prohibido dentro: red, WebSockets,
  `document.cookie`, `localStorage`/`sessionStorage`, `window.location.href = …` (se usa el router) y cálculos de
  negocio.
- **Cero texto visible escrito a mano en JSX**, aunque el proyecto tenga un solo idioma: toda cadena que ve el
  usuario, también la de `alt`, `aria-label`, `placeholder`, `title` y los metadatos de la página, pasa por las
  traducciones, y una clave nueva se añade a **todos** los idiomas a la vez. Los idiomas, la librería y dónde viven
  los mensajes: `.ai/project/CROSS-CUTTING.md §Idiomas`. `react/jsx-no-literals`, en `eslint.layers.mjs`, rechaza
  el texto entre etiquetas en `src/`, salvo en los tests; el de los atributos, los metadatos y las constantes lo
  comprueba el revisor.
- **La única excepción es un impacto de rendimiento medido.** La fase la autoriza por escrito, con su medición
  (`.ai/WORKFLOW.md §Obediencia arquitectónica`), y el código la declara en su línea, con la fase como motivo:
  `eslint-disable-next-line react/jsx-no-literals -- .ai/epics/<NN-slug>/phase-<FF>.md`. La regla no se baja en
  `eslint.config.mjs`.
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

El idioma del código, en inglés y con los términos de `.ai/project/GLOSSARY.md`: `.ai/RULES.md §Lista negra`. Lo que
importa es que sea uno solo y esté escrito: la mezcla arbitraria es lo que hace alucinar a un agente.

---

## 3. Estilos y tema

El aspecto de la web se cambia en un solo sitio, el tema, sin tocar componentes. Con Tailwind 4 y shadcn/ui, el tema
es la hoja global (`src/app/globals.css`):

- **`:root`** declara los tokens del modo claro y **`.dark`** los del oscuro, si el proyecto lo tiene (con la
  variante `@custom-variant dark (&:is(.dark *))`). Los dos modos definen los mismos tokens.
- **Los tokens son los nombres semánticos de shadcn/ui**: `background`, `foreground`, `card`, `popover`, `primary`,
  `secondary`, `muted`, `accent`, `destructive` (cada uno con su `-foreground` cuando lo lleva), `border`, `input`,
  `ring`, `chart-1` a `chart-5` y `sidebar-*`. Además, las fuentes (`--font-sans`, `--font-serif`, `--font-mono`), el
  radio (`--radius`), las sombras (`--shadow-2xs` a `--shadow-2xl`) y el espaciado de letra (`--tracking-normal`). Un
  token propio del proyecto se añade en los dos modos, con su nombre en inglés y por su función, no por su color
  (`warning`, no `yellow`).
- **`@theme inline`** convierte cada token en utilidad de Tailwind (`--color-primary: var(--primary)`,
  `--shadow-md: var(--shadow-md)`…). Las fuentes que carga `next/font` llegan como variable al valor de
  `--font-sans`, nunca como `font-family` escrito en otra regla.

Así, sustituir los bloques `:root` y `.dark` por los de otro tema con los mismos nombres (los que exporta un editor
como tweakcn) cambia toda la web.

- **Cero colores escritos a mano fuera del tema**: ni clases de la paleta de Tailwind (`bg-zinc-800`, `text-white`,
  `shadow-black/50`), ni `#hex`, `rgb()`, `hsl()` u `oklch()` en componentes, estilos en línea o constantes. Un color,
  una sombra, un radio o una fuente se piden por su token (`bg-muted`, `text-primary-foreground`, `shadow-md`,
  `rounded-lg`, `font-sans`).
- **`dark:` sólo para lo que un token no expresa** (p. ej. una opacidad distinta en cada modo); el color cambia solo
  con el token.
- **Lo que genera el CLI de shadcn/ui se queda como lo genera**, aunque traiga un color de la paleta, para que se
  pueda volver a generar. El código copiado de otros bloques (Tailark, plantillas MIT…) es del proyecto: sus colores
  pasan a tokens al copiarlo.
- El revisor lo comprueba en el diff: el linter no ve las clases de Tailwind.
