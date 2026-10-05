# Contrato del proyecto

> Lo que el contrato HTTP de `.ai/RULES.md` deja a cada proyecto. Cómo se cambia el contrato y cómo se traspasa al
> repo hermano no se repite aquí: `.ai/RULES.md` y `CLAUDE.md §El otro repositorio`.

## Autenticación y cabeceras

{{RELLENAR: cómo se autentica quien llama a la API (token Bearer, cookie HttpOnly detrás de un BFF…) y qué
cabeceras lleva toda petición (idioma, tenant, zona horaria…). Si hay BFF, su lista blanca de rutas es la única
puerta: una ruta nueva se añade ahí, nunca se abre otro proxy.}}

## Errores

<!-- La forma del cuerpo de un error y dónde se definen sus códigos, si el proyecto los fija más allá de lo que dice
     .ai/RULES.md. -->

Lo que dice `.ai/RULES.md`.
