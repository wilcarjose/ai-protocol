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
