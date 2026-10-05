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
- **Cero texto visible escrito a mano en JSX** si el proyecto tiene más de un idioma: toda cadena pasa por las
  traducciones, y una clave nueva se añade a **todos** los idiomas a la vez. Los idiomas, la librería y dónde
  viven los mensajes: `.ai/project/CROSS-CUTTING.md §Idiomas`.
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
