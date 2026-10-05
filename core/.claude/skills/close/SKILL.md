---
name: close
description: Rescate — documenta el estado REAL de una fase que otra sesión dejó a medias
argument-hint: "[epica numero-de-fase]"
disable-model-invocation: true
---

# /close — rescatar una fase

Argumentos: `$ARGUMENTS`. Sin argumentos, la fase activa de `.ai/STATE.md`; con argumentos, `<epica>` (el slug de su
carpeta) y `<FF>` (`01`, `03b`).

La fase tiene que estar `EN_CURSO`, `BLOQUEADA` o `VERIFICACION_ROJA` en `.ai/STATE.md §Mapa de fases`. Si está
`HECHA`, `ESPERA_EVIDENCIA` o `LISTA_PARA_EJECUTAR`, dilo y para: no hay nada que rescatar.

**`/close` no implementa nada.** Averigua y documenta qué pasó de verdad, no qué se pretendía. Para retomar el
trabajo está `/phase`, que reanuda una fase `BLOQUEADA` o `VERIFICACION_ROJA`.

Hazlo en la rama de la fase (`.claude/skills/phase/SKILL.md §Rama de la fase`). Si no estás en ella, pregunta si
cambias; **no la crees**: una fase interrumpida ya tiene rama.

## Paso A — Diagnóstico

1. `git status` y `git log --oneline <base>..HEAD`: qué llegó a commitearse desde el `chore(...): start`.
2. `git diff --stat <base>...HEAD` y el diff sin commitear: qué se tocó realmente.
3. `bash bin/verify.sh`: el estado real de los gates. Su salida va entera al RESULTADO, o a un archivo de evidencia
   si pasa de 40 líneas (`.claude/skills/phase/cierre.md §Cierre de fase`).
4. Lee el archivo de la fase y compara los entregables y las filas de «Plan de commits» con lo que hay.

Si no hay commit de arranque, no hay trabajo: la fase se cierra `BLOQUEADA` con el motivo «sin commits en la rama».

## Paso B — Documentar

Rellena el RESULTADO con lo **verificable**:

- **Estado final:** `HECHA` sólo si `bin/verify.sh` está verde, todos los entregables están y todas las casillas de
  «Criterios de éxito» se cumplen tal como están escritas (`.ai/WORKFLOW.md §Un criterio de éxito no se puede
  cumplir`); `ESPERA_EVIDENCIA` si sólo faltan casillas `[humano]`. Si falta algo, `BLOQUEADA` o
  `VERIFICACION_ROJA`, con el detalle; si el motivo es una pregunta sin responder, `BLOQUEADA` y la pregunta en
  `.ai/DOMAIN.md §Decisiones pendientes`.
- «Archivos tocados realmente» sale de `git diff --stat`, no de la lista prevista.
- Si hay trabajo sin commitear, dilo y di si es reversible. No lo commitees como si fuera una fila.
- Lo que no puedas probar, déjalo vacío y márcalo como pendiente. **No escribas memoria** («se hizo X» cuando X no
  tiene commit): la próxima sesión lo lee y se lo cree.

Después, `.claude/skills/phase/cierre.md §Cierre de fase` desde su paso 3. El puntero sólo avanza si la fase queda
`HECHA`.

## Paso C — Recomendación

Tras el reporte final, di en tres líneas si conviene continuar desde donde quedó (`/phase`) o revertir y relanzar,
y por qué.

**Prohibido** completar entregables que faltan: eso es trabajo de `/phase`.
