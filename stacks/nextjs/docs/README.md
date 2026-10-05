# `docs/` — documentación del proyecto

> Lo que no es protocolo de trabajo: decisiones de arquitectura, notas de librerías, procedimientos. El protocolo de
> la IA vive en `CLAUDE.md` y `.ai/`.

| Carpeta | Qué contiene | Quién escribe |
|---|---|---|
| `adr/` | Decisiones de arquitectura **vigentes**, una por archivo (`NNNN-titulo-en-kebab.md`): contexto, decisión, consecuencias y alternativas descartadas. Una que se sustituye lo dice en su cabecera y enlaza a la nueva. | El Tech Lead; la IA propone |
| `vendor/` | Notas de las APIs de las librerías en la versión instalada, con su índice (`docs/vendor/INDEX.md`). | La fase que necesita la nota, leyendo los tipos instalados |
| `runbooks/` | Procedimientos operativos: despliegue (`docs/runbooks/release.md`), puesta en marcha, incidencias. | El Tech Lead; el manifiesto de despliegue, quien cierra cada fase |

## Reglas de escritura

1. Una decisión de arquitectura vive en `adr/` y no se reescribe: si cambia, se escribe otra que la sustituye.
2. Una nota de `vendor/` dice de dónde sale (los `.d.ts` instalados, la documentación de esa versión) y qué versión
   cubre; si la versión instalada cambia, la nota se revisa en la misma fase.
3. Un procedimiento operativo va a `runbooks/<procedimiento>.md`.
4. Las referencias se verifican con `grep`: nombre de función, componente o sección, nunca número de línea
   (`.ai/WORKFLOW.md §Documentación`).
