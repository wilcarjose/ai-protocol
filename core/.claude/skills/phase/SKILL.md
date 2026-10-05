---
name: phase
description: Ejecuta una fase del plan de principio a fin, con cierre y memoria (sin argumentos, la activa)
argument-hint: "[epica numero-de-fase]"
disable-model-invocation: true
---

# /phase — ejecutar una fase

Argumentos: `$ARGUMENTS`. Sin argumentos, la fase activa de `.ai/STATE.md`. Con argumentos, `<epica>` (el slug de su
carpeta, `01-auth`) y `<FF>` (`01`, o `03b` si es una fase insertada): la activa o una en `ESPERA_EVIDENCIA`; si
no, dilo y para.
El archivo de la fase es `.ai/epics/<epica>/phase-<FF>.md`.

Una sesión por fase: rama → orientación → visto bueno → ejecución → verificación → cierre. Una fase sin cerrar no ha
terminado. El cierre vive en `.claude/skills/phase/cierre.md` y se lee al llegar al Paso C.

## Paso 0 — Qué fase y en qué rama

1. Lee `.ai/STATE.md`, ejecuta `sh bin/check-docs.sh --strict` y resuelve la fase (§Qué fase se ejecuta). Si el
   guardián falla, el puntero no es fiable: STOP & ASK (`.ai/WORKFLOW.md §Sin sentido lógico`).
2. Ponte en su rama (§Rama de la fase) y vuelve a leer `.ai/STATE.md`: manda el de esa rama. Si sale otra fase,
   dilo y para.

## Paso A — Orientación (sin escribir código)

Lectura en frío (`CLAUDE.md §Orden de lectura`), más `.ai/BACKLOG.md` y `.ai/DOMAIN.md §Decisiones pendientes`:
¿algo abierto afecta a esta fase? Sincroniza `.ai/STATE.md` (§Sincronización post-lectura).

**Revalida la fase**: pudo redactarse antes de que cerrara su predecesora. Contrasta cada supuesto (rutas, nombres,
comportamiento) con lo que dejó la anterior (`sh bin/handoff.sh <epica> <FF anterior>`) y con el código actual. Lo
mecánico lo corriges en el archivo de la fase (entra en el commit de arranque); lo que requiera decisión va a sus
«Preguntas abiertas».

Responde con tres viñetas de lo que vas a construir, los archivos que crearás y modificarás, lo que la fase da por
hecho y ya no es cierto, y las preguntas abiertas. **Para y espera el visto bueno.** Lo que está en `.ai/DOMAIN.md`
ya está decidido; lo que no determinan ni el código ni `DOMAIN.md` no se inventa: STOP & ASK
(`.ai/WORKFLOW.md §STOP & ASK`), escrito también en la fase. Una pregunta en el Paso A no cambia el estado. Una fase
ligera sin preguntas ni supuestos rotos no espera: da las viñetas y sigue.

## Paso B — Ejecución (sólo con visto bueno explícito)

1. `EN_CURSO` (§Estado de una fase) y commit de arranque.
2. **Una fila de «Plan de commits» a la vez**, con su commit en cuanto pasa `bash bin/verify.sh --fast`
   (§Commits durante la fase). Si un cambio te saca de los «Archivos» de la fase: `CLAUDE.md §Alcance`.
3. Si te bloqueas: STOP & ASK y `BLOQUEADA`.
4. Al terminar las filas, `bash bin/verify.sh` completo (§Verificación).

## Paso C — Cierre (siempre, también bloqueada o en rojo)

`.claude/skills/phase/cierre.md`, entero y en orden.

## Qué fase se ejecuta

| Estado de la fase activa | Qué haces |
|---|---|
| `LISTA_PARA_EJECUTAR` | Desde el Paso A. Si su «Depende de» no está `HECHA` en el mapa, dilo y para. |
| `EN_CURSO` | Otra sesión la dejó a medias: no la retomes; remite a `/close`. |
| `BLOQUEADA` o `VERIFICACION_ROJA` | Si el motivo es una pregunta suya sin respuesta en `.ai/DOMAIN.md`, muéstrala y para. Si no, **reanúdala**. |
| `ESPERA_EVIDENCIA` | Con argumentos: `.claude/skills/phase/cierre.md §Evidencia humana`. |
| `HECHA` | El puntero no avanzó al cerrarla: STOP & ASK. |
| `—` | Nada listo: di qué épica sigue en el mapa y que hay que planificarla (`/plan-epic`). |

**Reanudar** es un Paso A abreviado: revalida la fase contra el código, di qué filas de «Plan de commits» ya tienen
commit en la rama y cuáles faltan, y espera el visto bueno. Con él, `EN_CURSO` (y `Cerrada` a `—`), commit de
reanudación, y sigues por la primera fila pendiente.

## Rama de la fase

Cada fase se ejecuta en **`phase/<NN-slug>/<FF>`**, y se resuelve antes del Paso A, porque la revalidación lee el
código de esa rama.

- **Ya estás en ella:** sigue. **Existe y estás en otra:** pregunta si cambias.
- **No existe:** pregunta desde qué rama se crea, con la recomendada primero. Candidatas, en este orden: la rama base
  de la épica (`.claude/skills/plan-epic/SKILL.md §Rama base de la épica`), `main`, la de la fase anterior y la
  actual. **Sólo valen las ramas cuyo `git show <rama>:.ai/STATE.md` apunta ya a esta fase.** Si no vale ninguna,
  dilo y para.

Para crear la rama o cambiar a ella, el árbol tiene que estar limpio. Sólo ramas locales: nada de `git fetch` ni de
push. Los merges los decide el Tech Lead; si la épica declara rama base, las fases van con `--no-ff` a
`epic/<NN-slug>`, y ésta a `main` al cerrar la épica.

## Estado de una fase

`SIN_PLANIFICAR` · `LISTA_PARA_EJECUTAR` · `EN_CURSO` · `BLOQUEADA` · `VERIFICACION_ROJA` · `ESPERA_EVIDENCIA` ·
`HECHA`. Vive en la cabecera `> **Estado:**` de la fase y en su fila de `.ai/STATE.md §Mapa de fases`, que se
escriben siempre juntas.

- **Al iniciar:** `EN_CURSO` y la fecha en `Última actualización`. Con la primera fase de la épica, su epic-plan
  pasa de `SIN_EMPEZAR` a `EN_CURSO`.
- **Al bloquear** (desde `EN_CURSO`): `BLOQUEADA`; con la respuesta, vuelve a `EN_CURSO`.
- **Al cerrar:** `HECHA`, `ESPERA_EVIDENCIA` (sólo quedan casillas `[humano]`), `BLOQUEADA` o `VERIFICACION_ROJA`,
  con la fecha en `Cerrada`.
- **El puntero** (`Épica activa`, `Fase activa`, `Archivo de la fase`) es la **primera fila sin `HECHA` ni
  `ESPERA_EVIDENCIA` del mapa**, aunque sea de otra épica. Si está `SIN_PLANIFICAR`, las dos últimas quedan en `—`;
  sin filas pendientes, las tres.
- **La épica** pasa a `CERRADA` sólo por `.claude/skills/phase/cierre.md §Cierre de épica`.

Si el estado no coincide en los dos sitios, el guardián falla: no toques nada y pregunta. La recomendación por
defecto es que gane el archivo de la fase, que lleva el RESULTADO.

## Sincronización post-lectura

Antes de trabajar, y antes de responder algo que dependa del estado, regenera estas zonas de `.ai/STATE.md`. Es
idempotente, y el chequeo «contadores» de `bin/check-docs.sh` las recalcula igual:

- **`Decisiones abiertas: N (M bloquean la épica activa)`.** `N`, las filas `pendiente` de
  `.ai/DOMAIN.md §Decisiones pendientes`; `M`, las que en `Bloquea` citan la épica activa (`NN` o `NN/FF`).
- **`§Bloqueo activo`.** Esas `M`, una línea con su id cada una. Si no hay, `**Ninguno.**` y, sin fase activa, qué
  hay que planificar.
- **`Pendientes en otros repos: N (M condicionan el despliegue)` y su sección.** Las filas abiertas de
  `.ai/BACKLOG.md` cuya Área es un repo hermano; `M`, las que llevan `**Despliegue:**`.
- **`§Esperando evidencia`.** Las fases `ESPERA_EVIDENCIA`, con `NN-slug/FF` y lo que falta; si no hay,
  `**Ninguna.**`

## Commits durante la fase

La **única** regla sobre commits; los demás archivos la citan.

- **La IA commitea sola** mientras avanza: el visto bueno del Paso A cubre todos los commits de la fase.
- **Mensajes:** Conventional Commits **en inglés**, con los ámbitos de `.ai/RULES.md §Ámbitos de commit`. La primera
  línea dice qué cambia; el porqué que no es obvio, en el cuerpo. Termina con la atribución que pida la herramienta.
- **Arranque**, `chore(phase-<NN>-<FF>): start`, con `EN_CURSO`, `STATE.md` y lo escrito en el Paso A.
  **Reanudación**, `chore(phase-<NN>-<FF>): resume`. **Cierre**, `chore(phase-<NN>-<FF>): close`
  (`.claude/skills/phase/cierre.md §Cierre de fase`), y `…: evidence` al completar la evidencia humana. Ninguno va
  en «Plan de commits».
- **Una fila, un commit**, en cuanto pasa `bash bin/verify.sh --fast`. **Atómico:** `git add` sólo con sus archivos;
  si se coló algo, `git reset --soft HEAD~1` y rehazlo.
- **Retoques** que necesita un entregable, y cada `fix(...)` tras un `verify` rojo: su propio commit, listado en el
  RESULTADO. Lo que es alcance nuevo no se commitea: STOP & ASK.
- **Pruebas en rojo** («falla si quito X»): sobre trabajo commiteado o en una copia fuera del repo. `git restore`
  sobre un archivo se lleva lo que no estaba commiteado.
- **Nunca** `git push`, `git reset --hard` ni reescribir commits que no sean de esta fase.
- **Fuera de una fase**, sólo si el Tech Lead lo pide: `chore(planning): …` o `chore(protocol): …`.

## Verificación

`bash bin/verify.sh` es el único árbitro: sus gates y su baseline los define el script, y no se repiten en ningún
documento. `--fast` es el de cada fila; **el cierre exige el completo**. Hay como mucho **3 intentos** de ponerlo
en verde, cada corrección en su commit; al tercero, la fase se cierra `VERIFICACION_ROJA` con los fallos en el
RESULTADO. Si se pone rojo por algo ajeno: `.ai/WORKFLOW.md §Cuando un gate se pone rojo por algo ajeno a la fase`.
