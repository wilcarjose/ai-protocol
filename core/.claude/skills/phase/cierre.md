# Cierre de una fase

> Lo lee `/phase` en su Paso C y `/close` al documentar una fase interrumpida. Se hace siempre, también si la fase
> quedó bloqueada o en rojo. Una fase ligera sigue §Cierre ligero.

## Cierre de fase

1. **RESULTADO** del archivo de la fase, sin borrar encabezados. Lo más importante es «Lo que la siguiente fase
   necesita saber»: la próxima sesión empieza sin memoria y sólo leerá eso (`bin/handoff.sh` lo imprime).
2. **Criterios de éxito**: cada casilla se ejecuta tal como está escrita y se marca con su salida en «Verificación»
   (`.ai/WORKFLOW.md §Un criterio de éxito no se puede cumplir`). Una salida de más de **40 líneas** va entera a
   `.ai/epics/<NN-slug>/evidence/<FF>-<nombre>.txt`, y «Verificación» enlaza esa ruta entre comillas invertidas,
   con el código de salida y las líneas que deciden. `bin/check-docs.sh` comprueba que cada evidencia enlazada
   existe. Una casilla `[humano]` no la marca la IA: la evidencia la aporta la persona (§Evidencia humana).
3. **Revisión**, si la fase va a quedar `HECHA` o `ESPERA_EVIDENCIA`: `/review` (sin skills,
   `.claude/skills/review/SKILL.md`), y ningún bloqueante sin marcar. Sus arreglos cuentan entre los intentos de
   `.claude/skills/phase/SKILL.md §Verificación`. En `BLOQUEADA` o `VERIFICACION_ROJA` no hace falta.
4. **Estado final** en la fase y en el mapa, con la fecha en `Cerrada`, y el puntero de `.ai/STATE.md`
   (`.claude/skills/phase/SKILL.md §Estado de una fase`). `ESPERA_EVIDENCIA` si sólo quedan casillas `[humano]`
   abiertas. Regenera las zonas derivadas (`.claude/skills/phase/SKILL.md §Sincronización post-lectura`) y añade
   el cierre, en una línea, arriba de `§Últimos movimientos`.
5. Decisiones de negocio nuevas a `.ai/DOMAIN.md §Decisiones tomadas`, con fecha y fase.
6. Hallazgos fuera de alcance a `.ai/BACKLOG.md`, sin arreglarlos (`CLAUDE.md §Alcance`).
7. «Qué mejorarías del protocolo» a `.ai/PROTOCOL.md`, y una sola pregunta a la persona, con opciones (en Claude
   Code, `AskUserQuestion`): «¿Algo del protocolo te estorbó, te faltó o te sobró en esta fase?», «Nada» o «Sí»,
   con su texto. Con texto, una fila más con `De` = `persona — fase NN/FF`; sin respuesta, el cierre sigue.
8. **Memoria archivada** (§Archivo de la memoria).
9. **Si la fase añade algo que hacer en producción al desplegarla** (una migración, un comando, una variable de
   entorno o de configuración, un cambio de cron o de colas, una restricción de orden), una fila por paso en
   `docs/runbooks/release.md §Pasos por fase`. Es lo que evita olvidarlo en un despliegue meses después.
10. **Si la fase deja algo para otro repo**, su traspaso (§Traspaso al otro repo).
11. **Si la fase mejoró la baseline** (más tests, menos deuda), el número en `.ai/project/verify.conf`. Nunca en la
    dirección mala.
12. **Si la fase queda `HECHA` y era la última sin `HECHA` de su épica**, §Cierre de épica.
13. `sh bin/check-docs.sh --strict` en verde: el puntero se escribe después del último `bin/verify.sh`, y es lo que
    la siguiente sesión ejecutará sin preguntar.
14. Commit `chore(phase-<NN>-<FF>): close` con el RESULTADO, la evidencia, la revisión, la memoria y, si cambiaron,
    el manifiesto de despliegue, el epic-plan y la baseline de `.ai/project/verify.conf`. `git status` limpio.
15. §Entrega.
16. §Reporte final.

## Cierre ligero

Una fase con `> **Modo:** ligero` hace los pasos 1 a 4, la pregunta del 7, el 8 y 13 a 16 de §Cierre de fase; los
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

1. `git push -u origin <rama de la fase>`. Nunca a `main` ni forzado
   (`.claude/skills/phase/SKILL.md §Commits durante la fase`).
2. El PR, si no existe: `gh pr create` contra `epic/<NN-slug>` si la épica declara rama base o contra `main` si no.
   **El título, en inglés y en Conventional Commits** (`feat(listings): publish listings with photos`), con los
   ámbitos de `.ai/RULES.md §Ámbitos de commit`: al fusionar con squash es el mensaje del commit. **La descripción,
   en español**: el cuerpo de `.github/pull_request_template.md` relleno desde el RESULTADO, que nombra la fase.
   `HECHA` o `ESPERA_EVIDENCIA`, listo para revisar; `BLOQUEADA` o `VERIFICACION_ROJA`, con `--draft`. Si ya existe,
   el push lo actualiza.
3. Sin `gh` o sin acceso al remoto, dilo en el reporte con la orden que falta: la rama queda commiteada en local.
4. El merge lo decide el Tech Lead: la fase nunca fusiona su PR.

## Reporte final

El RESULTADO es el reporte: el chat no lo repite. Cinco líneas:

1. La fase (`NN/FF`) y su estado final; en `ESPERA_EVIDENCIA`, qué evidencia falta y quién la aporta.
2. `bash bin/verify.sh`: verde, o el gate que falla.
3. Los commits: cuántos y el rango (`<arranque>^..HEAD`).
4. Lo que el Tech Lead tiene que decidir o mirar (preguntas abiertas, decisiones tomadas, traspasos), o «nada».
5. El PR (o la orden que falta para abrirlo) y dónde está el RESULTADO.
