---
name: plan-epic
description: Crea o cambia una épica del plan (.ai/epics/), también desde un paquete de tareas de un plan externo (.ai/stages/). Para planificar, no para ejecutar una fase.
argument-hint: "[<NN-slug> | .ai/stages/<id>.md]"
---

# /plan-epic — épicas

> Para quien **crea o cambia** una épica, sea humano o IA. Las fases se escriben con `/plan-phase`
> (`.claude/skills/plan-phase/SKILL.md`); la ejecución sigue `/phase`, y esta guía no entra en su lectura en frío.
>
> No repite reglas que viven en otros archivos: dice qué comprobar y remite a donde vive cada una. Si choca con
> `.ai/RULES.md`, `.ai/WORKFLOW.md`, la skill `/phase` o `CLAUDE.md`, ganan ellos y hay que corregir esta guía.
>
> Cada punto viene de un error real de un plan anterior. Un plan mal escrito no falla al escribirlo: falla al
> ejecutarlo, y lo paga una sesión entera parada en el Paso A.

Argumentos: `$ARGUMENTS`. Una épica que ya existe (`<NN-slug>`), un paquete de tareas (`.ai/stages/<id>.md`,
§Desde un paquete de tareas) o nada, y entonces pregunta qué épica.

## Antes de escribir

- Haz la lectura en frío de `CLAUDE.md §Orden de lectura`, y además `.ai/BACKLOG.md`, `.ai/PROTOCOL.md` y el
  epic-plan si la épica ya existe. Para una fase, lo que dejó la anterior (`sh bin/handoff.sh <epica> <FF>`).
- **Lee el código real** de la zona que se va a tocar y mide lo que se pueda medir (`grep`, conteos,
  `bash bin/verify.sh`). Un plan escrito sin mirar el código asume cosas falsas.
- Si la duda es del contrato con el otro repo, lee también su código (`CLAUDE.md §El otro repositorio`). Lo que la
  fase necesite del otro repo va escrito dentro de la fase como hecho observable, o copiado a
  `.ai/handoffs/<AAAA-MM-DD>-<tema>/`. Nunca un enlace a un documento del otro repo.

## Épica

Archivo `.ai/epics/<NN-slug>/epic-plan.md`, a partir de `.ai/templates/epic-plan.template.md`. `NN` son dos dígitos
y el slug, kebab-case.

- **Objetivo** en lenguaje de negocio; **Por qué ahora** (el coste de no hacerlo); **Fuera de alcance** explícito:
  lo que alguien podría creer razonablemente que entra.
- **Contrato HTTP**: exactamente uno de `SIN CAMBIOS`, `CAMBIO AUTORIZADO` (campo por campo) o
  `REQUIERE DECISIÓN` (la épica se bloquea hasta decidir). Cambiar una URL, un verbo, un status, una clave o un
  mensaje **es** cambiar el contrato, aunque sea para cerrar un agujero (`.ai/RULES.md §Contrato HTTP`). Todo
  `CAMBIO AUTORIZADO` necesita antes una decisión fechada en `.ai/DOMAIN.md §Decisiones tomadas`; si contradice una
  anterior, se escribe como enmienda de esa.
- **Los campos propios del stack** que traiga la plantilla (p. ej. migraciones) se rellenan según `.ai/RULES.md`.
- **Decisiones pendientes**: cada una se crea primero como fila de `.ai/DOMAIN.md §Decisiones pendientes`, con
  `Bloquea` en la forma `NN/FF` (épica/fase) o `NN` (épica completa). El epic-plan sólo nombra los ids y, si
  aporta, la recomendación argumentada. **Nunca una tabla propia**: una copia de `DOMAIN.md` acaba contradiciéndolo.
- **Decisiones ya tomadas**: sólo lo específico de la épica; lo general vive en `.ai/DOMAIN.md`.
- **Fases**: tabla con número, qué cubre y de qué depende. Cada fase se escribe con `/plan-phase`; numeración en
  §Numeración.
- **Riesgos conocidos**: dónde esperas que la ejecución se bloquee o se equivoque.
- **Criterio de cierre**: comandos que se pueden cumplir, medidos contra el repo al escribirlos
  (`.claude/skills/plan-phase/SKILL.md §Antes de dar el plan por listo`). Un `grep` que exige que desaparezca un
  texto que otro entregable obliga a conservar no se cumplirá nunca. Lo comprueba, casilla a casilla, quien cierra la
  última fase: escríbelo para que se pueda comprobar sin interpretar.
- **Estado**: nace `SIN_EMPEZAR`; después lo mueve el ejecutor (`.claude/skills/phase/SKILL.md §Estado de una fase`).
- **Triaje del backlog.** Al planificar una épica, revisa las filas abiertas de `.ai/BACKLOG.md` de su área y ponles
  `Destino` (la épica que las cerrará) o déjalas en `—` a sabiendas. Cuando las filas abiertas **sin** `Destino`
  pasen de **25**, la siguiente épica que se planifique es de corrección.
- Añade una fila por fase a `.ai/STATE.md §Mapa de fases`, en estado `SIN_PLANIFICAR` mientras no exista el archivo
  de la fase.

## Desde un paquete de tareas

Un **paquete** es la parte de un plan externo (una etapa, un tramo) que la persona copia en `.ai/stages/<id>.md`, con
el formato de `.ai/stages/README.md`. Sus tareas **ya están planificadas**: aquí no se discuten ni se parten, se
convierten.

1. **Las tareas de este repo.** Las filas cuyo `Repo` es este repo. Las de un repo hermano no entran: si una tarea de
   aquí depende de una de allí, la fase lo dice en su §2 como condición, con el hecho observable que espera.
2. **Una épica por paquete**, con el `Objetivo` del paquete y, en «Decisiones ya tomadas», la cita
   `.ai/stages/<id>.md §Decisiones vigentes`: no se copian a `.ai/DOMAIN.md` ni se vuelven a preguntar.
3. **Una fase por tarea**, en el orden de sus dependencias, con `/plan-phase`. En su cabecera,
   `> **Tarea externa:** <ID>`; su objetivo es la tarea; en su §5, el criterio de aceptación **copiado literal**
   seguido del comando o los comandos que lo prueban (`- [ ] <criterio> — \`<comando>\``). El chequeo «tareas» de
   `bin/check-docs.sh` falla si el ID no está en un paquete o el criterio no aparece tal cual.
4. **El tipo de cada fase** sale de la tarea (`.claude/skills/plan-phase/SKILL.md §Tipos de tarea`): lo que se
   hace fuera del repo es operación; lo que confirma un tercero, validación externa.
5. **Si falta una decisión** que ni el paquete ni `.ai/DOMAIN.md` resuelven, o una tarea no cabe en una fase
   (`.claude/skills/plan-phase/SKILL.md §Reglas de corte`): STOP & ASK (`.ai/WORKFLOW.md §STOP & ASK`). No se
   inventa la respuesta ni se parte la tarea por tu cuenta: partirla es cambiar el plan externo.

Si el plan externo cambia una tarea, la persona actualiza el paquete y la fase se replanifica: mientras el criterio
de la fase no coincida con el del paquete, el guardián falla.

## Numeración

**Las fases no se renumeran.** Una fase nueva se añade al final de su épica o, si tiene que ir entre dos existentes,
con sufijo de letra (`02b`). Nunca se cambia ni se reutiliza el número de una fase existente: todo lo que la cita
(`.ai/DOMAIN.md`, `.ai/BACKLOG.md`, otras fases) quedaría apuntando a otra cosa. `bin/check-docs.sh` falla si una
referencia `NN/FF` o «fase FF» no existe en la tabla de su épica.

### Insertar una fase entre dos existentes

1. **Número y orden.** Sufijo de letra tras la anterior (`03b`, `03c`). Su fila va **justo detrás** de la anterior,
   en la tabla «Fases» del epic-plan y en `.ai/STATE.md §Mapa de fases`. El orden de las filas es el orden de
   ejecución, y la rama de una fase sale de la de la fila anterior (`.claude/skills/phase/SKILL.md §Rama de la fase`).
2. **La fase siguiente.** Su «Depende de» pasa a la fase nueva, y su §2 pasa a leer el «Lo que la siguiente fase
   necesita saber» de la nueva. Revisa lo que su texto daba por hecho de la anterior.
3. **La épica.** Si la fase nueva cambia el contrato o lo que el stack obliga a declarar, añádelo al epic-plan, con
   su decisión en `.ai/DOMAIN.md`, y sus riesgos. El criterio de cierre no cuenta fases: dice «todas las fases de
   la tabla».
4. **El puntero.** Si la fase nueva queda antes de la activa, la cabecera de `.ai/STATE.md` pasa a apuntar a ella.
5. **Dónde se commitea**, cuando el Tech Lead lo pida: en la rama que va a servir de base a la fase nueva (la de la
   fase anterior, o `main` si ya está mergeada). `/phase` sólo ofrece bases cuyo `.ai/STATE.md` apunta ya a la fase.

## Rama base de la épica

Opcional. Una épica puede declarar una **rama base propia** con el campo ``> **Rama base:** `epic/<NN-slug>` `` de su
cabecera. Sirve para una épica estructural (migración de motor, refactor mayor, reescritura de un módulo) que prevé
varios merges intermedios que no se quieren en `main`.

- Se declara al planificar, mientras la épica está `SIN_EMPEZAR`. Una vez arranca su primera fase, no se añade ni se
  cambia: obligaría a rebasear las ramas abiertas.
- La rama se crea desde `main` al empezar la primera fase, y las fases cuelgan de ella
  (`.claude/skills/phase/SKILL.md §Rama de la fase`). Los merges entre fases van a `epic/<NN-slug>`; `main` recibe el
  merge de la rama base sólo al cerrar la épica.
- Si la épica no la declara, cada fase parte de la rama de la fase anterior o de `main`.

## Antes de dar la épica por lista

1. Cada fase con `/plan-phase`, hasta su propio «Antes de dar el plan por listo».
2. El criterio de cierre, medido como un criterio de fase.
3. `sh bin/check-docs.sh --strict` en verde.
4. Di qué dejaste fuera a propósito, y dónde esperas que la ejecución se bloquee y por qué.

Planificar no se commitea solo: fuera de una fase, la IA sólo commitea si el Tech Lead lo pide
(`.claude/skills/phase/SKILL.md §Commits durante la fase`).
