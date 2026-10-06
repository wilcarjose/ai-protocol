---
name: plan-phase
description: Crea o cambia una fase de una épica (.ai/epics/<NN-slug>/phase-<FF>.md), con sus reglas de corte, su tipo de tarea y su coherencia. Para planificar, no para ejecutar una fase.
argument-hint: "<epica> [numero-de-fase]"
---

# /plan-phase — fases

> Para quien **crea o cambia** una fase, sea humano o IA. La épica y su tabla «Fases» se escriben con `/plan-epic`
> (`.claude/skills/plan-epic/SKILL.md`), que también dice qué leer antes de escribir
> (`.claude/skills/plan-epic/SKILL.md §Antes de escribir`). La ejecución sigue `/phase`, y esta guía no entra en su
> lectura en frío. Si choca con `.ai/RULES.md`, `.ai/WORKFLOW.md`, la skill `/phase` o `CLAUDE.md`, ganan ellos.

Argumentos: `$ARGUMENTS`: la épica (`<NN-slug>`) y, si la fase ya existe, su número.

## Fase

Archivo `.ai/epics/<NN-slug>/phase-<FF>.md`, a partir de `.ai/templates/phase.template.md`. Su número sale de la
tabla «Fases» del epic-plan (`.claude/skills/plan-epic/SKILL.md §Numeración`). Si sale de un paquete de tareas,
además `.claude/skills/plan-epic/SKILL.md §Desde un paquete de tareas`.

### Reglas de corte

- Termina con `bash bin/verify.sh` en verde. Si no puede, está mal cortada.
- Se revisa en diez minutos. Si no, pártela.
- **Un solo objetivo**, en una frase. Si necesitas dos, son dos fases.
- **Entre 3 y 7 entregables** (1 o 2 en una fase ligera, §Fases ligeras), concretos y observables, y **unos 10
  archivos como mucho**. Si el Tech Lead acepta una excepción (p. ej. un cambio mecánico en muchos archivos), se
  anota en el §7 de la fase para que nadie la parta ni lo pregunte otra vez. Calibra estos números con la sección
  «Calibración» de las fases ya cerradas.
- No depende de ninguna fase futura: su «Depende de» sólo cita fases anteriores (`bin/check-docs.sh` lo comprueba).
- **Un entregable, una viñeta.** Nunca dos en el mismo número, y menos si uno tiene gate y el otro no: el gate se
  lleva la viñeta entera. Un traspaso al otro repo escrito como «tests de contrato **y** el traspaso» se da por
  hecho en cuanto pasan los tests.
- **Ningún entregable condicional.** «X si Y» lo resuelve quien planifica, no quien ejecuta al final y con prisa por
  cerrar. Si de verdad depende de algo que sólo se sabe ejecutando, el entregable dice **quién decide y con qué
  evidencia**, y su criterio de éxito comprueba la decisión, no el resultado.

### Tipos de tarea

La cabecera dice `> **Tipo:**` (sin la línea, `código`). `bash bin/verify.sh` en verde vale para los tres.

- **`código`**: cambia el comportamiento del repo, con sus tests. Lo comprueba todo `bin/verify.sh` y los comandos
  del §5.
- **`operación`**: algo que se hace en un sistema fuera del repo (un servidor, un proveedor, el DNS, una tarea
  programada, datos de producción). Los entregables son **versionados**: los scripts, la configuración y un runbook
  en `docs/runbooks/<tema>.md` con los pasos, cómo se comprueba cada uno y cómo se deshace. La IA no los ejecuta
  contra el sistema real.
- **`validación externa`**: lo que sólo confirma un tercero o el mundo real (una revisión legal, la aceptación de un
  proveedor, una prueba con usuarios, una medición en producción). Los entregables son lo que se le entrega y cómo
  se registra su respuesta.

En los dos últimos, lo que sólo la persona puede comprobar va en su casilla `- [ ] [humano] <qué evidencia>`:
quién la aporta, qué tiene que mostrar (una salida, una captura, un enlace) y dónde se pega. La IA no la marca: la
fase cierra en `ESPERA_EVIDENCIA` hasta que la persona la aporta
(`.claude/skills/phase/cierre.md §Evidencia humana`). En una fase de código, `bin/check-docs.sh` rechaza
`[humano]`.

### Fases ligeras

`> **Modo:** ligero` para un cambio pequeño y previsible: **uno o dos entregables**, `Contrato HTTP: SIN CAMBIOS`,
sin migraciones, sin dependencia nueva y sin tocar una zona sensible. El ejecutor no se para en el Paso A si no hay
preguntas ni supuestos rotos, y el cierre es reducido (`.claude/skills/phase/cierre.md §Cierre ligero`). Si dudas
de que sea ligera, no lo es. `bin/check-docs.sh` exige uno o dos entregables, el contrato sin cambios y, si la
plantilla lo pide, «Migraciones: ninguna».

### Coherencia interna

- **Archivos.** Todo archivo que toque un entregable está en «Crear», «Modificar» o «Borrar». Si una regla de
  arquitectura prohíbe algo que otros archivos hacen hoy, esos archivos entran en la fase o la regla sale de ella.
- **Tests donde puedan ejecutarse.** Cada test va en la suite que puede ejecutarlo (`.ai/rules/tests.md`). Nunca
  expresiones regulares sobre el código fuente (`.ai/WORKFLOW.md §Obediencia arquitectónica`).
- **Criterios de éxito (§5).** Cada uno es un comando, y todos pueden cumplirse a la vez: no pidas «sin modificar el
  archivo» y «añadirle un caso» en la misma fase. Mídelos al escribirlos (§Antes de dar el plan por listo).
- **Todo entregable que ningún gate ve tiene su propio criterio en §5.** `bin/verify.sh` comprueba lo que comprueba;
  lo que no cae ahí dentro —un traspaso a otro repo, una fila de un runbook, una tabla de un documento— no lo
  comprueba nadie si §5 no lo nombra con un comando. Una instrucción que está en el §3 de seis fases y en ningún §5
  se pierde cuatro veces de seis.
- **Contrato** de la fase igual al que dicen el epic-plan y `.ai/DOMAIN.md`.
- **Plan de commits (§9).** Cada entregable que cambia archivos se mapea a una fila; una fila puede cubrir varios
  entregables relacionados; los que no cambian archivos no llevan fila. **Excepción:** un entregable que ningún
  gate ve va en su fila propia; agrupado, no tiene dónde aterrizar y se pierde sin que falle nada. Los commits de
  arranque y de cierre no van en §9 (`.claude/skills/phase/SKILL.md §Commits durante la fase`).
- **Referencias** a clases, métodos o secciones, nunca a números de línea (`.ai/WORKFLOW.md §Documentación`).
- **Contexto que debes leer antes (§2).** Rutas concretas: siempre `sh bin/handoff.sh` de la fase anterior, los
  temas de `.ai/rules/` que toca la fase (el índice está en `.ai/RULES.md`) y las filas de
  `.ai/project/FEATURES.md` de las funcionalidades que toca; si crea una o le añade una carpeta, §4 lista ese
  archivo. `.ai/RULES.md` y `.ai/WORKFLOW.md` se leen siempre; no los listes. El revisor lee lo mismo
  (`.claude/agents/reviewer.md`): un tema que no está aquí no lo revisa nadie.
- **Nombres.** Lo que crea la fase (carpetas, clases, tablas, rutas, claves de traducción, códigos de error) se
  nombra en inglés con los términos de `.ai/project/GLOSSARY.md` (`.ai/RULES.md §Lista negra`). Un término nuevo es
  una fila más, y §4 lista ese archivo; los textos para el usuario siguen en español.
- **No tocar (§4).** Sólo exclusiones específicas de esta fase. Los mínimos del proyecto viven en
  `.ai/RULES.md §Alcance` y en `CLAUDE.md §Cosas que no se hacen`; no los repitas.
- **Restricciones (§6).** Sólo las de esta fase; las generales no se copian.
- **Decisiones ya tomadas (§7).** Cita cada una con su id de `.ai/DOMAIN.md` o su fecha y una línea de resumen, para
  que la ejecución no pregunte lo que ya está resuelto.
- **Preguntas abiertas (§8)** y **Revisión (§10)**: vacías al planificar, con el texto de la plantilla.
- **Topes numéricos.** Un criterio con un tope («≤ 130 líneas») dice contra qué se midió y si alcanza a lo que ya
  existía o sólo a lo nuevo. Otra fase que toque el archivo lo deja caducado, que no es lo mismo que incumplido.

### Fases redactadas por adelantado

Se puede redactar una fase antes de que cierre la anterior: sirve para planificar. Anota en su §2 o en su §8 qué
supuestos dependen de la fase anterior. El ejecutor la revalida en el Paso A (`.claude/skills/phase/SKILL.md §Paso A — Orientación`).

## Antes de dar el plan por listo

1. **Mide lo que el plan da por hecho**, que es de donde salen las preguntas del Paso A:
   - **Cada criterio de §5, ejecutado contra el árbol de hoy.** Lo que imprime ahora es lo que la fase tiene que
     mover: si ya da el resultado pedido, o imprime líneas que la fase no va a tocar, está mal escrito. Un `grep` se
     escribe contra la línea que se espera en **cada** archivo que busca.
   - **Un criterio que busca dentro de `.ai/` excluye `.ai/PROTOCOL.md`, `.ai/archive/` y `.ai/epics/`**: narran lo
     que se quitó y por qué, así que contienen las cadenas que el criterio persigue.
   - **Un criterio sobre lo que hace un proceso** (arrancar, instalar, desplegar, fallar) se ejecuta, no se deduce
     leyendo el código del framework. Si no se puede ejecutar sin el cambio, el §2 lo dice para que el Paso A lo
     mida lo primero.
   - **Si la fase cambia la versión de una herramienta** (lenguaje, gestor de paquetes, runner), mide los artefactos
     del repo (lockfile, build) con esa versión.
   - **Si la fase cambia cómo se llega a un sistema** (despliegue, CI), mira desde dónde conecta cada paso en la
     versión fijada de cada acción. Una acción de terceros que recibe un secreto se fija por commit, y el
     entregable lo dice.
   - **Un criterio que necesita algo que la fase no levanta** (un servicio, otro repo, un motor de base de datos
     concreto, unos datos) lo nombra, con el motor si importa, y el §2 dice quién lo provee: quien ejecuta no puede
     sustituirlo por otra prueba (`.ai/WORKFLOW.md §Un criterio de éxito no se puede cumplir`). Si sólo lo puede
     comprobar la persona, es una casilla `[humano]` y la fase no es de código (§Tipos de tarea).
2. `sh bin/check-docs.sh --strict` en verde.
3. La fila de la fase en `.ai/STATE.md §Mapa de fases` pasa a `LISTA_PARA_EJECUTAR`, y el puntero de `STATE.md`
   queda donde dice `.claude/skills/phase/SKILL.md §Estado de una fase`: es la fase que ejecutará `/phase` sin
   argumentos. `bin/check-docs.sh` falla si no.
4. Revisa `.ai/PROTOCOL.md`: si alguna fase cerrada propuso algo que afecta a lo que acabas de escribir, aplícalo
   ahora o anota por qué no.
5. Di qué dejaste fuera a propósito, y dónde esperas que la ejecución se bloquee y por qué.

Planificar no se commitea solo: fuera de una fase, la IA sólo commitea si el Tech Lead lo pide
(`.claude/skills/phase/SKILL.md §Commits durante la fase`).
