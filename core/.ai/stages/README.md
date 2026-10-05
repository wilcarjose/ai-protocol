# Paquetes de tareas

> Un **paquete** es la parte de un plan externo (una etapa, un tramo de otro documento) que llega a este repo ya
> planificada. La persona lo copia aquí como `.ai/stages/<id>.md`, con el formato de abajo, y `/plan-epic` lo
> convierte en una épica con una fase por tarea (`.claude/skills/plan-epic/SKILL.md §Desde un paquete de tareas`).
> Las tareas no se vuelven a planificar: cada fase lleva el ID de su tarea y copia su criterio literal, y
> `bin/check-docs.sh` (chequeo «tareas») falla si no cuadran.

## Formato

```markdown
# Paquete <id> — <nombre>

> **Origen:** <el plan externo, con su versión o su fecha>

## Objetivo

<Qué deja hecho el paquete, en lenguaje de negocio.>

## Tareas

| ID | Tarea | Repo | Criterio de aceptación | Depende de |
|---|---|---|---|---|
| T1-23 | Alta de anuncios con fotos | backend | Un anuncio con tres fotos se publica y se lista | T1-20 |

## Decisiones vigentes

- <Lo que el plan externo ya decidió, una línea cada una. No se vuelve a preguntar.>
```

- **ID:** único entre todos los paquetes y nunca se reutiliza.
- **Repo:** la carpeta del repo que implementa la tarea: éste o un repo hermano
  (`.ai/project/README.md §Repos hermanos`). `/plan-epic` sólo convierte las de éste.
- **Criterio de aceptación:** una frase observable, sin «|». La fase lo copia tal cual en sus «Criterios de éxito».
- **Depende de:** IDs de tareas, de éste o de otro paquete, o «—».
- **Decisiones vigentes:** la épica las cita (`.ai/stages/<id>.md §Decisiones vigentes`) en vez de copiarlas.

Si el plan externo cambia una tarea, se actualiza el paquete y se replanifica su fase con `/plan-phase`.
