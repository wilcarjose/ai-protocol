# Arquitectura del proyecto

> Lo que la arquitectura del stack (`.ai/RULES.md`) deja a cada proyecto. Las reglas generales no se repiten aquí:
> esta página sólo las completa (`.ai/project/README.md`).

## Fuera de alcance

<!-- Lo que este proyecto deja fuera además de lo que excluye .ai/RULES.md en su alcance: un backoffice que se
     refactoriza aparte, un namespace que pertenece a un paquete, código generado. Rutas o globs, uno por línea. -->

{{RELLENAR: lo que este proyecto deja fuera además, o «Nada más.»}}

## Autorización

<!-- Un solo mecanismo: dos conviviendo es una segunda fuente de verdad. -->

{{RELLENAR: el único mecanismo de autorización del proyecto. Por ejemplo: «Policies de Laravel, invocadas desde
`FormRequest::authorize()`», «middleware con alias por recurso + comprobación explícita en la Action», o, en un
cliente, «la decide el backend; este repo sólo oculta lo que el usuario no puede hacer».}}

## Dominios

<!-- Las áreas del negocio y dónde vive cada una en el código. Se añade una fila en la fase que crea el dominio. -->

| Dominio | Qué cubre | Dónde vive |
|---|---|---|
