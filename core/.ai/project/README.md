# Capa del proyecto — {{RELLENAR: nombre del proyecto y del repo, p. ej. «Acme — backend»}}

> Lo que este proyecto decide y las reglas del kit dan por supuesto. `CLAUDE.md`, `.ai/RULES.md` y `.ai/WORKFLOW.md`
> son del kit `ai-protocol` y se actualizan con `install.sh --upgrade`; esta carpeta es del proyecto y **el
> instalador nunca la toca**. Las reglas del kit no traen decisiones de un proyecto concreto: citan la sección de
> aquí que las completa.
>
> La escribe el Tech Lead, o la fase que lista el archivo en su §4 (`CLAUDE.md §Alcance`). Una decisión que cambia
> se anota primero en `.ai/DOMAIN.md §Decisiones tomadas`, con fecha, y luego se reescribe aquí: esta carpeta dice
> lo vigente y `DOMAIN.md` guarda la historia.

| Archivo | Qué dice |
|---|---|
| `DECISIONS.md` | Decisiones técnicas vigentes: stack y versiones, infraestructura |
| `ARCHITECTURE.md` | Lo que el proyecto deja fuera de alcance, autorización, dominios |
| `FEATURES.md`, `GLOSSARY.md` | Cada funcionalidad y dónde vive; cada término del negocio y su nombre en el código |
| `CONTRACT.md` | Cómo se autentica quien llama y qué cabeceras viajan |
| `SENSITIVE-ZONES.md` | Las zonas sensibles propias del negocio |
| `CROSS-CUTTING.md` | Idiomas, tenant, accesibilidad, rendimiento, observabilidad |
| `COMMIT-SCOPES.md` | Los ámbitos de commit del dominio |

## Contexto operativo

{{RELLENAR: lo que una sesión en frío debe saber del entorno y que no es una regla de código ni una decisión de
negocio. Por ejemplo: «la base de datos local es un volcado de producción: antes de endurecer una validación,
comprueba que los datos históricos la cumplen», «los cron de X están comentados a propósito», «no hay tráfico real
hasta tal fecha». Si no hay nada, escribe «Nada que destacar.»}}

## Repos hermanos

<!-- bin/check-docs.sh lee esta línea (chequeos «traspaso» y «cross-repo»): no la renombres. Las reglas entre
     repos viven en CLAUDE.md §El otro repositorio. -->

> **Repos hermanos:** {{RELLENAR: el nombre de la carpeta de cada repo hermano entre comillas invertidas y
> separados por comas, p. ej. `frontend` o `backend`, `mobile`; o «—» si este proyecto no tiene ninguno}}
