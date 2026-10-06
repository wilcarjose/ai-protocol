# Changelog — core

El núcleo del protocolo: lo que es igual en todos los stacks. Versiones con [SemVer](https://semver.org/lang/es/) y
etiqueta `core-vX.Y.Z` (README.md §Versiones y etiquetas). Lo más reciente, arriba.

## Sin publicar

### Añadido

- `phase/cierre.md §Cierre de fase` (paso 7): una sola pregunta a la persona, con opciones, sobre lo que le estorbó,
  le faltó o le sobró del protocolo en la fase. Su respuesta va a `.ai/PROTOCOL.md` con `De` = `persona — fase NN/FF`,
  en la misma tabla que las propuestas del agente; sin respuesta, el cierre sigue. La hacen `/phase`, el cierre
  ligero y `/close`, que sigue el cierre desde su paso 3. No cambia el arranque del ejecutor.
- `.ai/PROTOCOL.md` (semilla): su cabecera dice quién escribe cada fila (`fase NN/FF` o `persona — fase NN/FF`).
  Sólo cambia en las instalaciones nuevas; en las que ya existen, la tabla sirve igual.

## [2.0.0] — 2026-10-06

### Añadido

- `.ai/project/GLOSSARY.md` (semilla): cada término del negocio y su nombre en el código, que va en inglés. Lo leen
  `/plan-epic` y `/plan-phase` para nombrar lo que crea una fase, y el revisor comprueba que el diff usa esos nombres
  y que no hay código en español (punto 11 de `.claude/agents/reviewer.md`).
- El PR de una fase lleva el título en inglés y en Conventional Commits, porque al fusionar con squash es el mensaje
  del commit, y la descripción en español (`phase/cierre.md §Entrega` y `.github/pull_request_template.md`).
- `.ai/project/FEATURES.md` (semilla): el mapa de funcionalidades, con sus carpetas, archivos clave y tests. Lo usa
  quien planifica: `/plan-phase` pide que la fase cite en su §2 las filas que toca. El ejecutor no lo lee al arrancar.
- `bin/check-protocol.sh`: en una rama `phase/<NN-slug>/<FF>`, falla si un commit sin ámbito `protocol` toca un
  archivo que `.ai/protocol.lock` marca `kit` (o el propio lock), contra la base de la rama (la del PR en la CI,
  `epic/<NN-slug>` o `main` en local, o `PROTOCOL_BASE`). Los `verify.sh` de los stacks lo corren en su gate
  «protocolo». La regla vive en `.ai/WORKFLOW.md §Archivos del protocolo`.
- `.github/pull_request_template.md`: la plantilla del PR de cada fase (fase, tarea externa, estado, checklist,
  evidencia pendiente y lo que el Tech Lead tiene que mirar).
- `phase/cierre.md §Entrega`: toda fase termina con el push de su rama y un PR (en borrador si cierra
  `BLOQUEADA` o `VERIFICACION_ROJA`); `/close` también, porque sigue el cierre desde su paso 3.
- `.claude/skills/`: `/phase` (`phase/SKILL.md`: pasos, rama, estados, sincronización, commits y verificación;
  `phase/cierre.md`: cierre de fase y de épica, archivo de la memoria, traspaso, evidencia humana y reporte final),
  `/close`, `/plan-epic` (épicas, numeración, rama base y entrada desde un paquete de tareas), `/plan-phase` (corte,
  tipos de tarea, fases ligeras y coherencia) y `/review`. `/phase` y `/close` llevan
  `disable-model-invocation: true`.
- Revisor IA: `.claude/agents/reviewer.md`, subagente de solo lectura que compara el diff de la rama con los
  entregables, los criterios y su evidencia, las reglas, `.ai/project/`, las zonas sensibles y el alcance. `/review`
  lo lanza y escribe sus hallazgos, bloqueantes (`- [ ] **B<n>**`) y no bloqueantes, en la sección «Revisión» de la
  fase. `/phase` lo ejecuta en el cierre (`phase/cierre.md`, paso 3) y no cierra con bloqueantes abiertos.
- Paquetes de tareas: `.ai/stages/README.md` con el formato (tabla de ID, tarea, repo, criterio de aceptación y
  dependencias, y las decisiones vigentes). Cada fase que sale de uno lleva `> **Tarea externa:** <ID>` y su criterio
  literal.
- Tipos de tarea (`> **Tipo:** código | operación | validación externa`), con casillas `[humano]` para la evidencia
  que sólo aporta la persona, y el estado `ESPERA_EVIDENCIA`: el puntero lo salta y `STATE.md §Esperando evidencia`
  (semilla) lo nombra. `/phase <epica> <FF>` completa la evidencia (`phase/cierre.md §Evidencia humana`) con el
  commit `chore(phase-<NN>-<FF>): evidence`.
- Fases ligeras (`> **Modo:** ligero`): uno o dos entregables, sin parada en el Paso A si no hay preguntas ni
  supuestos rotos, y cierre reducido (`phase/cierre.md §Cierre ligero`).
- `bin/check-docs.sh`, chequeo 14 «tareas»: toda «Tarea externa» es una fila de un paquete de `.ai/stages/` y su
  criterio está, literal, en «Criterios de éxito» de la fase.
- `bin/check-docs.sh`, chequeo «fases»: «Tipo» y «Modo» válidos (sin ellos, código y modo normal); una fase ligera,
  con uno o dos entregables, sin cambio de contrato ni migraciones; `[humano]` sólo fuera del tipo código; una
  `ESPERA_EVIDENCIA`, de operación o validación externa y con sólo casillas `[humano]` abiertas; una `HECHA` o
  `ESPERA_EVIDENCIA` con sección «Revisión», revisada y sin bloqueantes abiertos.
- `bin/check-docs.sh`: el puntero salta las fases en `ESPERA_EVIDENCIA`, y el chequeo «contadores» cuadra
  `STATE.md §Esperando evidencia` con el mapa.
- `bin/handoff.sh <NN-slug> <FF>`: imprime sólo «Lo que la siguiente fase necesita saber» de una fase.
- `.ai/archive/` (semilla): `BACKLOG.md`, `DOMAIN.md` y `PROTOCOL.md` con lo cerrado de la memoria. La fila «Protocolo
  instalado» de `PROTOCOL.md` nace ya archivada.
- `bin/check-docs.sh`, chequeo 13 «memoria»: ni filas cerradas o descartadas en `BACKLOG.md`, ni decisiones
  reemplazadas o respondidas en `DOMAIN.md`, ni mejoras aplicadas o descartadas en `PROTOCOL.md`, ni más de 10 líneas
  en `STATE.md §Últimos movimientos`, ni ids de `BACKLOG.md` o `DOMAIN.md` repetidos en el archivo.
- `bin/check-docs.sh`, chequeo «fases»: cada evidencia enlazada (`.ai/epics/<NN-slug>/evidence/…`) existe.
- `core.json`: nombre, versión y archivos del núcleo, en dos listas: `files` (los del kit, que `install.sh --upgrade`
  actualiza) y `seed` (los que sólo se copian si faltan: memoria, capa del proyecto, manifiesto de despliegue).
- `.ai/project/`: la capa del proyecto, que el instalador nunca toca. `README.md` (contexto operativo y repos
  hermanos), `DECISIONS.md` (versiones del stack e infraestructura), `ARCHITECTURE.md`, `CONTRACT.md`,
  `SENSITIVE-ZONES.md`, `CROSS-CUTTING.md` y `COMMIT-SCOPES.md`.

### Cambiado

- «Nunca `git push`» pasa a «nunca a `main`, forzado ni borrando ramas»: la fase empuja su rama
  (`phase/SKILL.md §Commits durante la fase`).
- La evidencia humana de una fase cuyo PR ya se fusionó va en una rama nueva, `phase/<NN-slug>/<FF>-evidence`, con
  su PR (`phase/cierre.md §Evidencia humana`).
- La baseline que mueven las fases pasa de `bin/verify.sh` a `.ai/project/verify.conf` (`phase/cierre.md`, pasos 11
  y 14).
- «No modificar el protocolo desde una fase» vive sólo en `.ai/WORKFLOW.md §Archivos del protocolo`; `CLAUDE.md`,
  las cabeceras de `RULES.md`, `PROTOCOL.md` y el revisor la citan.
- `.ai/protocol.lock` marca cada archivo como `kit` o `project` (antes, `seed`, que se sigue leyendo).
- `CLAUDE.md` mínimo (de 21 017 a 4 028 caracteres): orden de lectura, qué hace cada skill, alcance, el otro
  repositorio, prohibiciones y punteros. El ciclo de fase, las ramas, los commits y el cierre pasan a las skills.
- `.ai/WORKFLOW.md` sin `§Plantilla del reporte final` ni el resumen de cinco frases: el RESULTADO de la fase es el
  único reporte, y el chat lo resume en cinco líneas (`phase/cierre.md §Reporte final`). Una salida de más de 40
  líneas va a un archivo de evidencia que el RESULTADO enlaza.
- `bin/check-docs.sh` busca los ids `D<n>` también en `.ai/archive/DOMAIN.md`, cuenta como normativos `.ai/rules/` y
  las skills, y valida las citas a sus secciones.
- `bin/measure-context.sh` mide la sesión «cierre» (lo que añade el Paso C, con `/review`) aparte del arranque del
  ejecutor, separa al planificador en «plan-epica» y «plan-fase», y mide la sesión «revisor».
- Las semillas `BACKLOG.md`, `DOMAIN.md`, `PROTOCOL.md` y `STATE.md` explican qué pasa a `.ai/archive/` y el tope de
  «Últimos movimientos».
- `CLAUDE.md` deja de tener `{{RELLENAR}}`: el título es genérico, y el contexto operativo y los repos hermanos pasan
  a `.ai/project/README.md`, que entra en `§Orden de lectura`.
- `bin/check-docs.sh` lee los repos hermanos de `.ai/project/README.md` y las versiones de
  `.ai/project/DECISIONS.md §Stack y versiones exactas`; exige una versión por cada paquete de
  `.ai/RULES.md §Stack y versiones exactas`, busca marcadores en `.ai/project/` y valida las citas a sus secciones.
- `bin/measure-context.sh` cuenta `.ai/project/README.md` en las sesiones de ejecutor y planificador.
- `.ai/WORKFLOW.md §Documentación` lista `.ai/project/` y quién la escribe.

### Retirado

- `.claude/commands/phase.md` y `.claude/commands/close.md`: ahora son skills. `install.sh --upgrade` los retira, con
  su carpeta si queda vacía.
- `.ai/PLANNING.md`: ahora son las skills `/plan-epic` y `/plan-phase`.

## 1.x

El kit antes de separarse en paquetes: una carpeta completa por stack que se copiaba con `cp -Rn`, con la «Versión del
kit» como fecha (la última, 2026-10-04). Los proyectos instalados así se actualizan con `install.sh --upgrade --stack
<stack>`.
