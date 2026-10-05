# `docs/` — documentación del proyecto

> Lo que no es protocolo de trabajo: decisiones de arquitectura, contrato, procedimientos. El protocolo de la IA
> vive en `CLAUDE.md` y `.ai/`.

| Carpeta | Qué contiene | Quién escribe |
|---|---|---|
| `architecture/` | Decisiones de arquitectura **vigentes**. Las que se sustituyen van a `archive/`. | El Tech Lead; la IA propone |
| `features/` | Una página por funcionalidad con semántica no obvia. | La IA propone; el Tech Lead acepta |
| `contract/` | La red del contrato HTTP: `routes-baseline.txt` y, si los hay, snapshots de respuestas. | Se regenera con un cambio de contrato autorizado; nunca a mano |
| `runbooks/` | Procedimientos operativos: despliegue (`docs/runbooks/release.md`), puesta en marcha, incidencias. | El Tech Lead; el manifiesto de despliegue, quien cierra cada fase |
| `archive/` | Material cerrado. **No es guía vigente.** | Histórico |

## Reglas de escritura

1. Una decisión de arquitectura vive en `architecture/` mientras está vigente; cuando se invalida, se mueve a
   `archive/` con una nota de qué la sustituyó.
2. Un detalle de producto con semántica no obvia va a `features/<tema>.md`, no a un docblock.
3. Un procedimiento operativo va a `runbooks/<procedimiento>.md`.
4. Las referencias se verifican con `grep`: nombre de clase, método o sección, nunca número de línea
   (`.ai/WORKFLOW.md §Documentación`).
