# Guía de planificación — épicas y fases

> Para quien **crea o cambia** un plan, sea humano o IA. **No** es para ejecutarlo: la ejecución sigue
> `CLAUDE.md §Protocolo de fases`, y esta guía no entra en su lectura en frío.
>
> No repite reglas que viven en otros archivos: dice qué comprobar y remite a donde vive cada una. Si choca con
> `.ai/RULES.md`, `.ai/WORKFLOW.md` o `CLAUDE.md`, ganan ellos y hay que corregir esta guía.
>
> Cada punto de esta guía viene de un error real de un plan anterior. Un plan mal escrito no falla al escribirlo:
> falla al ejecutarlo, y lo paga una sesión entera parada en el Paso A.

## 1. Antes de escribir

- Haz la lectura en frío de `CLAUDE.md §Orden de lectura`, y además `.ai/BACKLOG.md`, `.ai/PROTOCOL.md` y el
  epic-plan si la épica ya existe. Para una fase, el «Lo que la siguiente fase necesita saber» de la anterior.
- **Lee el código real** de la zona que se va a tocar y mide lo que se pueda medir (`grep`, conteos,
  `bash bin/verify.sh`). Un plan escrito sin mirar el código asume cosas falsas.
- Si la duda es del contrato con el otro repo, lee también su código (`CLAUDE.md §El otro repositorio`). Lo que la
  fase necesite del otro repo va escrito dentro de la fase como hecho observable, o copiado a
  `.ai/handoffs/<AAAA-MM-DD>-<tema>/`. Nunca un enlace a un documento del otro repo.

## 2. Épica

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
- **Fases**: tabla con número, qué cubre y de qué depende. Reglas de corte en §3.1; numeración en §4.
- **Riesgos conocidos**: dónde esperas que la ejecución se bloquee o se equivoque.
- **Criterio de cierre**: comandos que se pueden cumplir, probados contra el repo al escribirlos (§5). Un `grep` que
  exige que desaparezca un texto que otro entregable obliga a conservar no se cumplirá nunca. Lo comprueba, casilla
  a casilla, quien cierra la última fase: escríbelo para que se pueda comprobar sin interpretar.
- **Estado**: nace `SIN_EMPEZAR`; después lo mueve el ejecutor (`CLAUDE.md §Estado de una fase`).
- **Triaje del backlog.** Al planificar una épica, revisa las filas abiertas de `.ai/BACKLOG.md` de su área y ponles
  `Destino` (la épica que las cerrará) o déjalas en `—` a sabiendas. Cuando las filas abiertas **sin** `Destino`
  pasen de **25**, la siguiente épica que se planifique es de corrección.
- Añade una fila por fase a `.ai/STATE.md §Mapa de fases`, en estado `SIN_PLANIFICAR` mientras no exista el archivo
  de la fase.

## 3. Fase

Archivo `.ai/epics/<NN-slug>/phase-<FF>.md`, a partir de `.ai/templates/phase.template.md`.

### 3.1 Reglas de corte

- Termina con `bash bin/verify.sh` en verde. Si no puede, está mal cortada.
- Se revisa en diez minutos. Si no, pártela.
- **Un solo objetivo**, en una frase. Si necesitas dos, son dos fases.
- **Entre 3 y 7 entregables**, concretos y observables, y **unos 10 archivos como mucho**. Si el Tech Lead acepta una
  excepción (p. ej. un cambio mecánico en muchos archivos), se anota en el §7 de la fase para que nadie la parta ni
  lo pregunte otra vez. Calibra estos números con la sección «Calibración» de las fases ya cerradas.
- No depende de ninguna fase futura: su «Depende de» sólo cita fases anteriores (`bin/check-docs.sh` lo comprueba).
- **Un entregable, una viñeta.** Nunca dos en el mismo número, y menos si uno tiene gate y el otro no: el gate se
  lleva la viñeta entera. Un traspaso al otro repo escrito como «tests de contrato **y** el traspaso» se da por
  hecho en cuanto pasan los tests.
- **Ningún entregable condicional.** «X si Y» lo resuelve quien planifica, no quien ejecuta al final y con prisa por
  cerrar. Si de verdad depende de algo que sólo se sabe ejecutando, el entregable dice **quién decide y con qué
  evidencia**, y su criterio de éxito comprueba la decisión, no el resultado.

### 3.2 Coherencia interna

- **Archivos.** Todo archivo que toque un entregable está en «Crear», «Modificar» o «Borrar». Si una regla de
  arquitectura prohíbe algo que otros archivos hacen hoy, esos archivos entran en la fase o la regla sale de ella.
- **Tests donde puedan ejecutarse.** Cada test va en la suite que puede ejecutarlo (`.ai/RULES.md §Tests`). Nunca
  expresiones regulares sobre el código fuente (`.ai/WORKFLOW.md §Obediencia arquitectónica`).
- **Criterios de éxito (§5).** Cada uno es un comando, y todos pueden cumplirse a la vez: no pidas «sin modificar el
  archivo» y «añadirle un caso» en la misma fase. Mídelos al escribirlos (§5 de esta guía).
- **Todo entregable que ningún gate ve tiene su propio criterio en §5.** `bin/verify.sh` comprueba lo que comprueba;
  lo que no cae ahí dentro —un traspaso a otro repo, una fila de un runbook, una tabla de un documento— no lo
  comprueba nadie si §5 no lo nombra con un comando. Una instrucción que está en el §3 de seis fases y en ningún §5
  se pierde cuatro veces de seis.
- **Contrato** de la fase igual al que dicen el epic-plan y `.ai/DOMAIN.md`.
- **Plan de commits (§9).** Cada entregable que cambia archivos se mapea a una fila; una fila puede cubrir varios
  entregables relacionados; los que no cambian archivos no llevan fila. **Excepción:** un entregable que ningún
  gate ve va en su fila propia; agrupado, no tiene dónde aterrizar y se pierde sin que falle nada. Los commits de
  arranque y de cierre no van en §9 (`CLAUDE.md §Commits durante la fase`).
- **Referencias** a clases, métodos o secciones, nunca a números de línea (`.ai/WORKFLOW.md §Documentación`).
- **Contexto que debes leer antes (§2).** Rutas concretas, y siempre el «Lo que la siguiente fase necesita saber» de
  la anterior. `.ai/RULES.md` y `.ai/WORKFLOW.md` se leen siempre; no los listes.
- **No tocar (§4).** Sólo exclusiones específicas de esta fase. Los mínimos del proyecto viven en
  `.ai/RULES.md §Alcance` y en `CLAUDE.md §Cosas que no se hacen`; no los repitas.
- **Restricciones (§6).** Sólo las de esta fase; las generales no se copian.
- **Decisiones ya tomadas (§7).** Cita cada una con su id de `.ai/DOMAIN.md` o su fecha y una línea de resumen, para
  que la ejecución no pregunte lo que ya está resuelto.
- **Preguntas abiertas (§8).** Vacía al empezar; el formato está en la plantilla.
- **Topes numéricos.** Un criterio con un tope («≤ 130 líneas») dice contra qué se midió y si alcanza a lo que ya
  existía o sólo a lo nuevo. Otra fase que toque el archivo lo deja caducado, que no es lo mismo que incumplido.

### 3.3 Fases redactadas por adelantado

Se puede redactar una fase antes de que cierre la anterior: sirve para planificar. Anota en su §2 o en su §8 qué
supuestos dependen de la fase anterior. El ejecutor la revalida en el Paso A (`CLAUDE.md §Protocolo de fases`).

## 4. Numeración

**Las fases no se renumeran.** Una fase nueva se añade al final de su épica o, si tiene que ir entre dos existentes,
con sufijo de letra (`02b`). Nunca se cambia ni se reutiliza el número de una fase existente: todo lo que la cita
(`.ai/DOMAIN.md`, `.ai/BACKLOG.md`, otras fases) quedaría apuntando a otra cosa. `bin/check-docs.sh` falla si una
referencia `NN/FF` o «fase FF» no existe en la tabla de su épica.

### 4.1 Insertar una fase entre dos existentes

1. **Número y orden.** Sufijo de letra tras la anterior (`03b`, `03c`). Su fila va **justo detrás** de la anterior,
   en la tabla «Fases» del epic-plan y en `.ai/STATE.md §Mapa de fases`. El orden de las filas es el orden de
   ejecución, y la rama de una fase sale de la de la fila anterior (`CLAUDE.md §Rama de la fase`).
2. **La fase siguiente.** Su «Depende de» pasa a la fase nueva, y su §2 pasa a leer el «Lo que la siguiente fase
   necesita saber» de la nueva. Revisa lo que su texto daba por hecho de la anterior.
3. **La épica.** Si la fase nueva cambia el contrato o lo que el stack obliga a declarar, añádelo al epic-plan, con
   su decisión en `.ai/DOMAIN.md`, y sus riesgos. El criterio de cierre no cuenta fases: dice «todas las fases de
   la tabla».
4. **El puntero.** Si la fase nueva queda antes de la activa, la cabecera de `.ai/STATE.md` pasa a apuntar a ella.
5. **Dónde se commitea**, cuando el Tech Lead lo pida: en la rama que va a servir de base a la fase nueva (la de la
   fase anterior, o `main` si ya está mergeada). `/phase` sólo ofrece bases cuyo `.ai/STATE.md` apunta ya a la fase.

## 5. Antes de dar el plan por listo

1. **Mide lo que el plan da por hecho**, que es de donde salen las preguntas del Paso A:
   - **Cada criterio de §5, ejecutado contra el árbol de hoy.** Lo que imprime ahora es lo que la fase tiene que
     mover: si ya da el resultado pedido, o imprime líneas que la fase no va a tocar, está mal escrito. Un `grep` se
     escribe contra la línea que se espera en **cada** archivo que busca.
   - **Un criterio que busca dentro de `.ai/` excluye `.ai/PROTOCOL.md` y `.ai/epics/`**: los dos narran lo que se
     quitó y por qué, así que contienen las cadenas que el criterio persigue.
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
     sustituirlo por otra prueba (`.ai/WORKFLOW.md §Un criterio de éxito no se puede cumplir`).
2. `sh bin/check-docs.sh --strict` en verde.
3. La fila de la fase en `.ai/STATE.md §Mapa de fases` pasa a `LISTA_PARA_EJECUTAR`, y el puntero de `STATE.md`
   queda donde dice `CLAUDE.md §Estado de una fase`: es la fase que ejecutará `/phase` sin argumentos.
   `bin/check-docs.sh` falla si no.
4. Revisa `.ai/PROTOCOL.md`: si alguna fase cerrada propuso algo que afecta a lo que acabas de escribir, aplícalo
   ahora o anota por qué no.
5. Di qué dejaste fuera a propósito, y dónde esperas que la ejecución se bloquee y por qué.

Planificar no se commitea solo: fuera de una fase, la IA sólo commitea si el Tech Lead lo pide
(`CLAUDE.md §Commits durante la fase`).

## 6. Rama base de la épica (opcional)

Una épica puede declarar una **rama base propia** con el campo ``> **Rama base:** `epic/<NN-slug>` `` de su cabecera.
Sirve para una épica estructural (migración de motor, refactor mayor, reescritura de un módulo) que prevé varios
merges intermedios que no se quieren en `main`.

- Se declara al planificar, mientras la épica está `SIN_EMPEZAR`. Una vez arranca su primera fase, no se añade ni se
  cambia: obligaría a rebasear las ramas abiertas.
- La rama se crea desde `main` al empezar la primera fase, y las fases cuelgan de ella
  (`CLAUDE.md §Rama de la fase`). Los merges entre fases van a `epic/<NN-slug>`; `main` recibe el merge de la rama
  base sólo al cerrar la épica.
- Si la épica no la declara, cada fase parte de la rama de la fase anterior o de `main`.
