# Changelog — core

El núcleo del protocolo: lo que es igual en todos los stacks. Versiones con [SemVer](https://semver.org/lang/es/) y
etiqueta `core-vX.Y.Z` (README.md §Versiones y etiquetas). Lo más reciente, arriba.

## [2.3.0] — 2026-10-12

### Cambiado

- `.ai/WORKFLOW.md §Dependencia nueva`: una dependencia que la épica o la fase ya autorizan se instala con su
  versión exacta, sin parar; si el permiso deniega la orden, la persona la lanza con la orden exacta (#42).

## [2.2.0] — 2026-10-11

### Añadido

- `install.sh --new-project --target <dir> [--dry-run]`: deja como un proyecto nuevo un repo creado desde una
  plantilla, que trae el protocolo instalado con su lock. Las semillas del núcleo vuelven a ser las del kit, con sus
  `{{RELLENAR}}`: la memoria (`STATE`, `DOMAIN`, `BACKLOG`, `PROTOCOL`, `.ai/archive/`, `.ai/epics/` y
  `docs/runbooks/release.md`) y, de `.ai/project/`, `README.md` y `SENSITIVE-ZONES.md`. Borra lo que el kit no trae en
  `.ai/archive/`, `.ai/epics/`, `.ai/stages/` y `.ai/handoffs/`. No toca lo que el proyecto hereda de la plantilla
  (el resto de `.ai/project/`, las semillas del stack y el código), los archivos del kit ni el lock. Pide el kit en la
  versión del lock, y al terminar lista los marcadores que quedan: el guardián no deja pasar `bin/verify.sh` hasta
  rellenarlos.
- `bin/protocol-feedback.sh`: abre un issue en el kit (`AI_PROTOCOL_REPO`, por defecto `wilcarjose/ai-protocol`) por
  cada fila de `.ai/PROTOCOL.md` con alcance `núcleo` o `stack` en `propuesta`, con su origen, evidencia, propuesta
  y alcance, y deja la fila en `enviada — ai-protocol#N`. Sin `gh` o sin acceso, imprime el texto y no cambia nada
  (#34).
- `phase/cierre.md §Retro del protocolo`: la retro del ejecutor, obligatoria y al final, después de la entrega, en
  su propio commit `chore(phase-NN-FF): retro` empujado al mismo PR (#29). Por categorías fijas (fricción,
  ambigüedad, contradicción, herramientas y permisos, lo que el protocolo no cubría), cada una con evidencia y el
  archivo y la sección que propone cambiar, o «nada» justificado. Se anota cuando ocurre, en «Qué mejorarías del
  protocolo» del RESULTADO, cuyo encabezado no cambia. Termina con `bin/protocol-feedback.sh` y la sección
  «Protocolo» del PR (#34).
- `.github/pull_request_template.md`: la sección «Protocolo», con las filas nuevas de `.ai/PROTOCOL.md`.
- `install.sh --upgrade` avisa, al terminar, de las filas `enviada — ai-protocol#N` de `.ai/PROTOCOL.md` que
  resuelve la versión nueva: las que tienen su `#N` en el `CHANGELOG.md` de un paquete entre la versión del lock y
  la nueva. Sólo avisa: la fila la marca el proyecto, como `aplicada — kit core X.Y.Z + <stack> X.Y.Z`, y la archiva
  (#34).

### Cambiado

- `phase/cierre.md §Cierre de fase`, en otro orden. La revisión es el paso 1, justo después del `verify` completo y
  antes de escribir el RESULTADO o la memoria (#25). Las zonas derivadas de `.ai/STATE.md` se regeneran en cuanto la
  memoria está escrita, antes de cualquier otro `verify`, y el estado y el puntero van después del último: el
  `verify` del cierre ya no sale en rojo por un contador sin sincronizar (#31). El paso de la baseline dice que
  endurece el gate y que, si la herramienta lo deniega, se le pide la línea exacta a la persona (#26). El cierre
  ligero y `/close` citan los pasos nuevos.
- `phase/cierre.md §Entrega` y §Retro del protocolo: el push, `gh pr create` y `gh pr edit` van sueltos, sin `&&`,
  tuberías ni heredocs, escritos tal como encajan con `.claude/settings.json`, y con el cuerpo del PR en
  `.ai/epics/<NN-slug>/evidence/<FF>-pr.md` (`--body-file`), que entra en el commit de cierre y en el de la retro. Si
  una orden se deniega, se reintenta suelta antes de dar la orden a la persona (#30).
- `/review` acepta cambios sin commitear dentro de `.ai/`: la memoria del cierre y una revisión anterior no hacen
  falta guardarlas con `git stash` para revisar otra vez (#25).
- `/plan-phase`: un criterio sobre el texto de una respuesta (un error, un mensaje traducido) se mide con una
  petición real contra la aplicación (#22); si la fase retira o renombra algo, sus usos en el código y en los tests
  entran en sus «Archivos» (#24); y una fase que lee cabeceras, la IP o la identidad de quien llama lista
  `.ai/project/CONTRACT.md` en su §2 (#28).
- El revisor (`.claude/agents/reviewer.md`) sabe que corre antes del RESULTADO: comprueba que el diff permite cumplir
  cada criterio, no su evidencia, y no señala que el RESULTADO esté vacío, el no bloqueante que repetía en cada
  revisión (#32).
- La pregunta del cierre a la persona es opcional y va dirigida a su papel, después de enseñarle la retro del
  ejecutor: «Como Tech Lead, ¿falta algo, sobra algo, o algo de esta fase te costó a ti?». El paso de «Qué
  mejorarías del protocolo» de `phase/cierre.md §Cierre de fase` ya no escribe la retro: la deja para después de
  §Entrega (#34).
- `.ai/PROTOCOL.md` (semilla) y `.ai/archive/PROTOCOL.md`: la columna `Alcance` (`núcleo` · `stack` · `proyecto`)
  antes de `Estado`, y los estados `enviada — ai-protocol#N` y `aplicada — kit core X.Y.Z + <stack> X.Y.Z`. El chequeo «memoria» de
  `bin/check-docs.sh` falla con un alcance que no es ninguno de los tres; una tabla sin la columna sigue pasando
  (#34).
- `.ai/WORKFLOW.md §Archivos del protocolo`: los archivos del kit sólo cambian con `install.sh --upgrade`. Un
  archivo del kit nunca se parchea en el proyecto: el arreglo va al kit (#34).
- Los textos para el usuario ya no se dan por hechos en español: el revisor (punto 11 de
  `.claude/agents/reviewer.md`), `/plan-phase` («Nombres», en su coherencia interna) y la semilla
  `.ai/project/GLOSSARY.md` los ponen, con los slugs públicos y los datos semilla, en el idioma de
  `.ai/project/CROSS-CUTTING.md §Idiomas`. El código sigue en inglés.
- El revisor marca además un texto para el usuario fuera de las traducciones, salvo la excepción de rendimiento que
  la fase autorice con su medición: los textos pasan siempre por las traducciones, aunque el proyecto tenga un solo
  idioma.
- `.ai/project/CROSS-CUTTING.md §Idiomas` (semilla) pide el idioma por defecto, los demás, la librería, dónde viven
  las traducciones y cómo va el idioma en la URL (o cómo llega, en una API). Ya no ofrece «Un solo idioma: los
  textos van en el código».

### Corregido

- El chequeo «traspaso» de `bin/check-docs.sh` busca la fila del traspaso también en `.ai/archive/BACKLOG.md`.
  Hasta ahora sólo miraba `.ai/BACKLOG.md`, así que al cerrar un traspaso y archivar su fila, como pide el chequeo
  «memoria», la fase que lo dejó volvía a fallar («cambia el contrato y nada lo traspasa»). Visto en `base-api`
  (plan 1c, fase 3) (#21).

### Al actualizar un proyecto

- `.ai/PROTOCOL.md` es memoria y el upgrade no la toca: sin la columna `Alcance`, sus filas no se envían. Para usar
  el canal, añade la columna antes de `Estado`, con el alcance de cada fila, y pasa a `.ai/archive/PROTOCOL.md` las
  que estén aplicadas o descartadas.
- `.ai/project/` es del proyecto y el upgrade no la toca. Si `CROSS-CUTTING.md §Idiomas` dice «Un solo idioma: los
  textos van en el código», escribe lo que pide la semilla nueva y pasa esos textos a las traducciones: el revisor ya
  no los acepta en el código. El comentario de `GLOSSARY.md` que pone los textos en español queda desfasado.

## [2.1.0] — 2026-10-06

### Añadido

- `phase/cierre.md §Cierre de fase` (paso 7): una sola pregunta a la persona, con opciones, sobre lo que le estorbó,
  le faltó o le sobró del protocolo en la fase. Su respuesta va a `.ai/PROTOCOL.md` con `De` = `persona — fase NN/FF`,
  en la misma tabla que las propuestas del agente; sin respuesta, el cierre sigue. La hacen `/phase`, el cierre
  ligero y `/close`, que sigue el cierre desde su paso 3. No cambia el arranque del ejecutor.
- `.ai/PROTOCOL.md` (semilla): su cabecera dice quién escribe cada fila (`fase NN/FF` o `persona — fase NN/FF`).
  Sólo cambia en las instalaciones nuevas; en las que ya existen, la tabla sirve igual.

### Cambiado

- `bin/check-protocol.sh`: sin `PROTOCOL_BASE` ni la CI, la base es `origin/epic/<NN-slug>` u `origin/main` antes que
  la rama local del mismo nombre. En un worktree (el modo VPS de `docs/modos.md` del kit), el `main` local del
  checkout principal suele ir por detrás, y el gate «protocolo» marcaba commits ya fusionados de otras fases.

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
