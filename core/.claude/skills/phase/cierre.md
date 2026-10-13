# Cierre de una fase

> Lo lee `/phase` en su Paso C y `/close` al documentar una fase interrumpida. Se hace siempre, también si la fase
> quedó bloqueada o en rojo. Una fase ligera sigue §Cierre ligero.

## Cierre de fase

1. **Revisión**, si la fase va a quedar `HECHA` o `ESPERA_EVIDENCIA`: `/review` (sin skills,
   `.claude/skills/review/SKILL.md`), y ningún bloqueante sin marcar. Va antes de escribir nada, justo después del
   `bash bin/verify.sh` completo del Paso B: revisa el diff, no el RESULTADO. Sus arreglos cuentan entre los
   intentos de `.claude/skills/phase/SKILL.md §Verificación`. En `BLOQUEADA` o `VERIFICACION_ROJA` no hace falta.
2. **RESULTADO** del archivo de la fase, sin borrar encabezados. Lo más importante es «Lo que la siguiente fase
   necesita saber»: la próxima sesión empieza sin memoria y sólo leerá eso (`bin/handoff.sh` lo imprime).
3. **Criterios de éxito**: cada casilla se ejecuta tal como está escrita y se marca con su salida en «Verificación»
   (`.ai/WORKFLOW.md §Un criterio de éxito no se puede cumplir`). Una salida de más de **40 líneas** va entera a
   `.ai/epics/<NN-slug>/evidence/<FF>-<nombre>.txt`, y «Verificación» enlaza esa ruta entre comillas invertidas,
   con el código de salida y las líneas que deciden. `bin/check-docs.sh` comprueba que cada evidencia enlazada
   existe. Una casilla `[humano]` no la marca la IA: la evidencia la aporta la persona (§Evidencia humana).
4. Decisiones de negocio nuevas a `.ai/DOMAIN.md §Decisiones tomadas`, con fecha y fase.
5. Hallazgos fuera de alcance a `.ai/BACKLOG.md`, sin arreglarlos (`CLAUDE.md §Alcance`).
6. «Qué mejorarías del protocolo» se queda con lo anotado durante la fase: la retro se completa después de la
   entrega (§Retro del protocolo), para que también cuente lo que falle al entregar.
7. **Memoria archivada** (§Archivo de la memoria).
8. **Si la fase añade algo que hacer en producción al desplegarla** (una migración, un comando, una variable de
   entorno o de configuración, un cambio de cron o de colas, una restricción de orden), una fila por paso en
   `docs/runbooks/release.md §Pasos por fase`. Es lo que evita olvidarlo en un despliegue meses después.
9. **Si la fase deja algo para otro repo**, su traspaso (§Traspaso al otro repo).
10. **Si la fase mejoró la baseline** (más tests, menos deuda), el número en `.ai/project/verify.conf`. Nunca en la
    dirección mala. Es un cambio que endurece el gate, no que lo salta: si la herramienta lo deniega (el modo auto
    de Claude Code puede tomarlo por saltarse la CI), no lo rodees; pide a la persona que escriba la línea exacta
    (`MIN_TESTS=48`) y sigue.
11. **Zonas derivadas** de `.ai/STATE.md` (`.claude/skills/phase/SKILL.md §Sincronización post-lectura`),
    regeneradas en cuanto la memoria está escrita (pasos 4 a 9) y antes de cualquier otro `bash bin/verify.sh`: su
    `bin/check-docs.sh` falla si no cuadran con `.ai/DOMAIN.md` y `.ai/BACKLOG.md`.
12. **Estado final** en la fase y en el mapa, con la fecha en `Cerrada`, y el puntero de `.ai/STATE.md`
    (`.claude/skills/phase/SKILL.md §Estado de una fase`), después del último `bash bin/verify.sh`: es lo que la
    siguiente sesión ejecutará sin preguntar. `ESPERA_EVIDENCIA` si sólo quedan casillas `[humano]` abiertas. Añade
    el cierre, en una línea, arriba de `§Últimos movimientos`.
13. **Si la fase queda `HECHA` y era la última sin `HECHA` de su épica**, §Cierre de épica.
14. `sh bin/check-docs.sh --strict` en verde.
15. **El cuerpo del PR** en `.ai/epics/<NN-slug>/evidence/<FF>-pr.md` (§Entrega), y commit
    `chore(phase-<NN>-<FF>): close` con él, el RESULTADO, la evidencia, la revisión, la memoria y, si cambiaron, el
    manifiesto de despliegue, el epic-plan y la baseline de `.ai/project/verify.conf`. `git status` limpio.
16. §Entrega.
17. §Retro del protocolo.
18. §Reporte final.

## Cierre ligero

Una fase con `> **Modo:** ligero` hace los pasos 1 a 3, el 7, el 11, el 12 y del 14 al 18 de §Cierre de fase; los
demás, sólo si tienen algo que escribir (una decisión, un hallazgo, un paso de despliegue, un traspaso). Los
encabezados del RESULTADO se quedan, y los que no aplican dicen «—».

## Evidencia humana

Una fase de operación o de validación externa cierra en `ESPERA_EVIDENCIA` cuando todo está hecho salvo sus casillas
`[humano]`: entregables commiteados, `bin/verify.sh` en verde, las demás casillas marcadas y la revisión sin
bloqueantes. El puntero la salta (`.claude/skills/phase/SKILL.md §Estado de una fase`) y
`.ai/STATE.md §Esperando evidencia` la nombra con lo que falta. Cuando la persona aporta la evidencia,
`/phase <epica> <FF>`:

1. En la rama de la fase si su PR sigue abierto. Si ya se integró, en una rama nueva,
   `phase/<NN-slug>/<FF>-evidence`, creada desde la base donde se integró (tras `git fetch`), con su propio PR.
2. Cada evidencia va a «Verificación», o a su archivo de `evidence/`, con quién la aportó y cuándo, y su casilla se
   marca. Si no muestra lo que la casilla pide, dilo y para: la fase sigue esperando.
3. Con todas marcadas, `HECHA` en la fase y en el mapa, con la fecha de hoy en `Cerrada`; fuera de
   `§Esperando evidencia`, una línea en `§Últimos movimientos` y, si era la última sin `HECHA` de su épica,
   §Cierre de épica.
4. `sh bin/check-docs.sh --strict` en verde, commit `chore(phase-<NN>-<FF>): evidence`, §Entrega y §Reporte final.

## Archivo de la memoria

La memoria activa sólo guarda lo vigente. Lo cerrado pasa entero, sin reescribirlo, al archivo del mismo nombre de
`.ai/archive/` (lo más reciente arriba), en el cierre de la fase que lo cierra:

- `.ai/BACKLOG.md`: las filas `cerrado — …` y `descartado — …`. Sus `#` no se reutilizan.
- `.ai/DOMAIN.md`: las entradas de §Decisiones tomadas que llevan `**Reemplazada por:**` y las filas `respondida` de
  §Decisiones pendientes. Sus ids se pueden seguir citando: el guardián los busca también en el archivo.
- `.ai/PROTOCOL.md`: las filas `aplicada — …` y `descartada — …`.
- `.ai/STATE.md §Últimos movimientos`: como mucho **10 líneas**; las más viejas se borran, porque el detalle vive en
  el RESULTADO de cada fase.

El chequeo «memoria» de `bin/check-docs.sh` falla si queda algo por archivar.

## Cierre de épica

Lo hace quien deja en `HECHA` la última fase de la épica que no lo estaba, en su mismo commit: al cerrarla o al
completar su evidencia (§Evidencia humana). Mientras una fase de la épica no esté `HECHA`, no hay cierre de épica:
sigue `EN_CURSO`.

1. **Comprueba cada casilla del «Criterio de cierre»** del epic-plan igual que las de una fase, con su salida en
   «Verificación» del RESULTADO de esta última fase.
2. **Marca las que se cumplen.** No reescribas un criterio para que se cumpla: cambiarlo es planificar.
3. **Si se cumplen todas**, el epic-plan pasa a `Estado: CERRADA` y `§Últimos movimientos` lo dice en una línea. Si
   la épica declaró rama base, di en el reporte que `epic/<NN-slug>` está lista para `main`.
4. **Si alguna no se cumple**, la épica sigue `EN_CURSO` con esa casilla sin marcar: STOP & ASK con cada criterio
   que falla y su salida (una fase nueva, corregir el criterio o aceptar el cierre). La fase se cierra `HECHA`
   igualmente: sus entregables están hechos.

`bin/check-docs.sh` falla si el estado de una épica no cuadra con su mapa o si `Épica activa` es una `CERRADA`
mientras queda otra abierta.

## Traspaso al otro repo

Una fase **traspasa** cuando cambia algo que un repo hermano consume (el contrato HTTP, un campo, un status, un
mensaje) o necesita que cambie algo allí. Es parte del trabajo de la fase, no un bloqueo:

1. Si el cambio **rompe el contrato** y la fase no lo autorizaba (`Contrato HTTP: SIN CAMBIOS`): STOP & ASK
   (`.ai/WORKFLOW.md §Contrato`). Si venía planificado (`CAMBIO AUTORIZADO`), empiezas en el paso 2.
2. «Lo que la siguiente fase necesita saber» dice qué afecta al otro repo y por qué.
3. Una fila en `.ai/BACKLOG.md` con Área = el repo hermano y, en el texto, `**Cambio:**` (qué hacer allí),
   `**Origen:**` (`fase NN/FF` y el commit que lo exige) y, si un repo no puede desplegarse sin el otro,
   `**Despliegue:**`. Aparece en `.ai/STATE.md §Pendientes en otros repos` hasta que el Tech Lead la cierra.
4. Nómbralo en el reporte final.

La fila se escribe en la fase que causa el cambio. `bin/check-docs.sh` no deja cerrar `HECHA` una fase con
`CAMBIO AUTORIZADO` sin esa fila o sin `> **Traspaso:** ninguno — <motivo>` en su cabecera.

## Entrega

Toda fase termina igual, se ejecute en la nube o en local: su rama en GitHub y un PR que la CI verifica
(`.github/workflows/verify.yml`, que corre `bin/verify.sh` completo).

**Cada orden, suelta**: sin `&&`, `;`, tuberías ni heredocs, y escrita como aquí. Así encaja con los permisos de
`.claude/settings.json`; una orden encadenada no encaja con ninguno y, sin preguntar, se deniega.

1. `git push -u origin <rama de la fase>`. Nunca a `main` ni forzado
   (`.claude/skills/phase/SKILL.md §Commits durante la fase`).
2. El PR, si no existe, con el cuerpo que commiteó el paso 15 de §Cierre de fase:
   `gh pr create --base <rama base> --title "<título>" --body-file .ai/epics/<NN-slug>/evidence/<FF>-pr.md`.
   - **La rama base**, `epic/<NN-slug>` si la épica la declara y `main` si no.
   - **El título, en inglés y en Conventional Commits** (`feat(listings): publish listings with photos`), con los
     ámbitos de `.ai/RULES.md §Ámbitos de commit`: al fusionar con squash es el mensaje del commit.
   - **El cuerpo, en español**: el de `.github/pull_request_template.md` relleno desde el RESULTADO, que nombra la
     fase.
   - `HECHA` o `ESPERA_EVIDENCIA`, listo para revisar; `BLOQUEADA` o `VERIFICACION_ROJA`, con `--draft` al final.
     Si el PR ya existe, el push lo actualiza.
3. **Si una orden se deniega**, reinténtala suelta, tal como está escrita aquí, antes de nada más. Si sigue
   denegada, o no hay `gh` o acceso al remoto, dilo en el reporte con la orden exacta que falta: la rama queda
   commiteada en local.
4. El merge lo decide el Tech Lead: la fase nunca fusiona su PR.

## Retro del protocolo

Mejorar el protocolo es tarea de quien lo recorre: el ejecutor. Va al final, después de la entrega, y es obligatoria,
también en una fase ligera, bloqueada o en rojo.

1. **Anotada en el momento.** Cada fricción se escribe en «Qué mejorarías del protocolo» del RESULTADO cuando
   ocurre, no de memoria al final. Aquí sólo se completa, con lo que haya pasado al entregar.
2. **Por categorías**, una línea cada una, con su evidencia (el comando, el error, el reintento) y el archivo y la
   sección que propones cambiar, o «nada — <por qué>»:
   - **Fricción:** reintentos y tiempo perdido.
   - **Ambigüedad:** lo que tuviste que interpretar.
   - **Contradicción:** dos reglas, o una regla y el código, que chocan.
   - **Herramientas y permisos:** lo que se denegó, faltó o hubo que pedir.
   - **Sin cubrir:** lo que el protocolo no cubría, y el rodeo que usaste.
3. **Cada mejora, una fila de `.ai/PROTOCOL.md`**: `De` = `fase NN/FF`; «Qué», la evidencia y, tras
   `**Propuesta:**`, `` `<archivo> §<sección>` `` y el cambio; `Alcance`: `núcleo` o `stack` si sirve a todo
   proyecto con el kit, `proyecto` si es sólo de éste (va a `.ai/project/`); `Estado`: `propuesta`.
4. **La persona, desde su papel.** Enséñale la lista y pregúntale, con opciones (en Claude Code,
   `AskUserQuestion`): «Como Tech Lead, ¿falta algo, sobra algo, o algo de esta fase te costó a ti (preguntas mal
   planteadas, el visto bueno, la revisión del PR)?». Lo que añade, una fila con `De` = `persona — fase NN/FF`; lo
   que corrige, en su fila. Es opcional: sin respuesta, la retro sigue.
5. `sh bin/protocol-feedback.sh`: abre en el kit un issue por fila de `núcleo` o `stack` y la deja en
   `enviada — ai-protocol#N`. Si no puede (sin `gh` o sin acceso), las filas siguen en `propuesta` y lo dices en el
   reporte.
6. La sección «Protocolo» del cuerpo del PR, `.ai/epics/<NN-slug>/evidence/<FF>-pr.md`, con las filas nuevas
   (y su issue).
7. `sh bin/check-docs.sh --strict` en verde, y commit `chore(phase-<NN>-<FF>): retro` con el RESULTADO,
   `.ai/PROTOCOL.md` y el cuerpo del PR.
8. Sueltas, como en §Entrega: `git push origin <rama de la fase>` y
   `gh pr edit --body-file .ai/epics/<NN-slug>/evidence/<FF>-pr.md`.

Un archivo del kit no se parchea en la fase, aunque urja: el arreglo va al kit y vuelve con `install.sh --upgrade`,
entre fases.

## Reporte final

El RESULTADO es el reporte: el chat no lo repite. Cinco líneas:

1. La fase (`NN/FF`) y su estado final; en `ESPERA_EVIDENCIA`, qué evidencia falta y quién la aporta.
2. `bash bin/verify.sh`: verde, o el gate que falla.
3. Los commits: cuántos y el rango (`<arranque>^..HEAD`).
4. Lo que el Tech Lead tiene que decidir o mirar (preguntas abiertas, decisiones tomadas, traspasos, filas de la
   retro sin enviar), o «nada».
5. El PR (o la orden que falta para abrirlo) y dónde está el RESULTADO. Cuando se fusione, `/sync-main` deja la rama
   base al día.
