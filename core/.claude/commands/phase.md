---
description: Ejecuta una fase del plan de principio a fin, con cierre y memoria (sin argumentos, la activa)
argument-hint: [epica numero-de-fase] (opcional)
---

Argumentos recibidos: `$ARGUMENTS`

- **Sin argumentos:** la fase activa de `.ai/STATE.md`.
- **Con argumentos:** `<epica>` = primer token (el slug de su carpeta, p. ej. `01-auth`) y `<numero-de-fase>` =
  segundo token (dos dígitos, más la letra si es una fase insertada: `01`, `03b`). Esa fase tiene que ser la
  activa; si no, dilo y para.

El archivo de la fase es `.ai/epics/<epica>/phase-<numero-de-fase>.md`.

**El protocolo vive en `CLAUDE.md §Protocolo de fases`.** Este comando no lo repite ni lo adapta: dice qué hacer en
cada paso y cuándo parar.

## Paso 0 — Qué fase y en qué rama

1. Lee `.ai/STATE.md`, ejecuta `sh bin/check-docs.sh --strict` y resuelve la fase según
   `CLAUDE.md §Qué fase se ejecuta`. Aplica la fila de su estado: ejecutarla, reanudarla, remitir a `/close` o
   parar.
2. Ponte en su rama según `CLAUDE.md §Rama de la fase`. Si no existe, **pregunta desde qué rama la creas**, con las
   candidatas que apuntan a esta fase y la recomendada primero.
3. Ya en la rama, vuelve a leer `.ai/STATE.md` y a resolver. Si sale otra fase, dilo y para.

## Paso A — Orientación (no escribas código todavía)

Lo que pide `CLAUDE.md §Protocolo de fases` (el ciclo, paso 2): lectura en frío, revalidación de la fase y
sincronización de `.ai/STATE.md` (`CLAUDE.md §Sincronización post-lectura`). Aplica la regla del `grep`
(`.ai/WORKFLOW.md §El ciclo obligatorio`): antes de citar un documento como justificación, verifícalo contra el código.

Responde con las cuatro cosas de ese paso y **para**. Si hay preguntas abiertas, STOP & ASK
(`.ai/WORKFLOW.md §STOP & ASK`), escritas también en el §8 de la fase. No sigas hasta tener respuesta.

Si la fase se **reanuda**, el Paso A es el abreviado de `CLAUDE.md §Qué fase se ejecuta`.

## Paso B — Ejecución (sólo con visto bueno explícito)

`CLAUDE.md §Protocolo de fases` (pasos 3 y 4) y `CLAUDE.md §Commits durante la fase`: estado a `EN_CURSO`, commit
de arranque, una fila de §9 a la vez con su commit en cuanto pasa `bash bin/verify.sh --fast`. Si un cambio te
obliga a salirte del §4 de la fase, `CLAUDE.md §Alcance`.

Al terminar todas las filas, `bash bin/verify.sh`. Si sale rojo: léelo, corrige (cada corrección es su propio
commit) y repite. Máximo tres intentos; al tercero, para y ve al Paso C con `VERIFICACION_ROJA`.

## Paso C — Cierre (obligatorio, siempre)

`CLAUDE.md §Cierre de fase`, entero y en orden; si la fase queda `HECHA` y era la última de su épica, también
`CLAUDE.md §Cierre de épica`. Pon especial cuidado en «Lo que la siguiente fase necesita saber»: es lo único que la
próxima sesión leerá de ésta.

Termina con el reporte de `.ai/WORKFLOW.md §Plantilla del reporte final`.
