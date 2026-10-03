---
description: Rescate — documenta el estado REAL de una fase que otra sesión dejó a medias
argument-hint: [epica numero-de-fase] (opcional)
---

Argumentos recibidos: `$ARGUMENTS`

- **Sin argumentos:** la fase activa de `.ai/STATE.md`.
- **Con argumentos:** `<epica>` (el slug de su carpeta) y `<numero-de-fase>` (`01`, `03b`).

La fase tiene que estar `EN_CURSO`, `BLOQUEADA` o `VERIFICACION_ROJA` en `.ai/STATE.md §Mapa de fases`. Si está
`HECHA` o `LISTA_PARA_EJECUTAR`, dilo y para: no hay nada que rescatar.

**`/close` no implementa nada.** Su único trabajo es averiguar y documentar qué pasó de verdad, no qué se pretendía.
Para retomar el trabajo pendiente está `/phase`, que reanuda una fase `BLOQUEADA` o `VERIFICACION_ROJA`.

Hazlo en la rama de la fase (`CLAUDE.md §Rama de la fase`). Si no estás en ella, pregunta si cambias; **no la
crees**: una fase interrumpida ya tiene rama.

## Paso A — Diagnóstico

1. `git status` y `git log --oneline <base>..HEAD`: qué llegó a commitearse desde el `chore(...): start`.
2. `git diff --stat <base>...HEAD` y el diff sin commitear: qué se tocó realmente.
3. `bash bin/verify.sh`: estado real de los gates. Pega la salida íntegra.
4. Lee el archivo de la fase y compara los entregables y las filas de §9 con lo que hay.

Si no hay commit de arranque, trátalo como si no hubiera trabajo: la fase se cierra `BLOQUEADA` con el motivo «sin
commits en la rama».

## Paso B — Documentar

Rellena `RESULTADO DE LA EJECUCIÓN` con lo **verificable**:

- **Estado final:** `HECHA` sólo si `bin/verify.sh` está verde, todos los entregables están y todas las casillas del
  §5 se cumplen tal como están escritas (`.ai/WORKFLOW.md §2.10`). Si falta algo, `BLOQUEADA` o
  `VERIFICACION_ROJA`, con el detalle; si el motivo es una pregunta sin responder, `BLOQUEADA` y la pregunta en
  `.ai/DOMAIN.md §Decisiones pendientes`.
- «Archivos tocados realmente» sale de `git diff --stat`, no de la lista prevista.
- Si hay trabajo sin commitear, dilo y di si es reversible. No lo commitees como si fuera una fila.
- Lo que no puedas probar, déjalo vacío y márcalo como pendiente. **No escribas memoria** («se hizo X» cuando X no
  tiene commit): la próxima sesión lo lee y se lo cree.

Actualiza el estado en la fase y en el mapa, con la fecha en `Cerrada`. El puntero sólo avanza si la fase queda
`HECHA` (`CLAUDE.md §Estado de una fase`). `sh bin/check-docs.sh --strict` en verde y commit
`chore(phase-<NN>-<FF>): close` (`CLAUDE.md §Commits durante la fase`).

## Paso C — Recomendación

Dime en tres líneas si conviene continuar desde donde quedó (`/phase`) o revertir y relanzar, y por qué.

**Prohibido** completar entregables que faltan: eso es trabajo de `/phase`.
