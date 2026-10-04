# {{RELLENAR: nombre del proyecto y del repo, p. ej. «Acme — backend»}} · protocolo de trabajo

> Punto de entrada de cualquier sesión de IA en este repositorio. Describe **cómo se trabaja**: fases, ramas,
> commits, cierre y memoria entre sesiones.
>
> - Las reglas de **cómo se escribe código** viven en `.ai/RULES.md`.
> - El protocolo del **ejecutor** (ciclo, cuándo parar, bloque STOP & ASK, reporte) vive en `.ai/WORKFLOW.md`.
> - Cómo se **planifica** una épica o una fase vive en `.ai/PLANNING.md`, y sólo lo lee quien planifica.
>
> Jerarquía si algo choca: `.ai/RULES.md` > `.ai/WORKFLOW.md` > este archivo. Si este archivo contradice a
> `RULES.md`, gana `RULES.md` y hay que corregir este.
>
> **Cada regla vive en un solo archivo.** Los demás la citan por el nombre de su sección, nunca la copian: una
> copia envejece por su cuenta. Si una regla puede incumplirse en silencio, se le añade un chequeo a
> `bin/check-docs.sh`. `AGENTS.md` es sólo una redirección hacia aquí para herramientas que no leen este archivo.
>
> **El protocolo crece con lo que enseña cada fase.** Lo que estorbe se anota en el RESULTADO de la fase y se
> acumula en `.ai/PROTOCOL.md`; ninguna fase edita este archivo.

## Orden de lectura (sesión en frío)

1. `.ai/STATE.md` — qué fase está activa y qué la bloquea.
2. `.ai/DOMAIN.md` — lo decidido. **No se vuelve a preguntar.**
3. `.ai/RULES.md` — stack, alcance, contrato, arquitectura, lista negra.
4. `.ai/WORKFLOW.md` — ciclo del ejecutor, criterios de parada, reporte.
5. Este archivo.
6. El archivo de la fase activa (`.ai/epics/<NN-slug>/phase-<FF>.md`) y lo que cite en su §2.
7. **El código real**, antes de citar un documento como evidencia de algo: si discrepan, gana el código y lo
   reportas (`.ai/WORKFLOW.md §El ciclo obligatorio`, la regla del `grep`).

## Sincronización post-lectura

Antes de empezar a trabajar, y antes de responder al Tech Lead algo que dependa del estado del proyecto,
regenera estas zonas de `.ai/STATE.md`. Es idempotente: si nada cambió, el `git diff` sale vacío.

- **Cabecera `Decisiones abiertas: N (M bloquean la épica activa)`.** `N` = filas de
  `.ai/DOMAIN.md §Decisiones pendientes` con Estado `pendiente`. `M` = las de esas cuya columna `Bloquea` cita la
  épica activa (`NN` o `NN/FF`). Sin épica activa, `M = 0`.
- **`§Bloqueo activo`.** Las `M` de arriba, una línea cada una con su id. Si `M = 0`, dice `**Ninguno.**` y, si
  `Fase activa` es `—`, qué hay que planificar.
- **Cabecera `Pendientes en otros repos: N (M condicionan el despliegue)` y `§Pendientes en otros repos`.** Las
  filas de `.ai/BACKLOG.md` cuya Área es un repo hermano (§El otro repositorio) y cuyo Estado no empieza por
  `cerrado` ni `descartado`. `M` = las que llevan `**Despliegue:**`. Es lo que evita desplegar este repo sin un
  cambio del otro del que depende.

`bin/check-docs.sh` (chequeo «contadores») recalcula todo esto y falla si no cuadra: quien sincroniza a mano y el
guardián dan siempre el mismo número.

## Contexto operativo

{{RELLENAR: lo que una sesión en frío debe saber del entorno y que no es una regla de código ni una decisión de
negocio. Por ejemplo: «la base de datos local es un volcado de producción: antes de endurecer una validación,
comprueba que los datos históricos la cumplen», «los cron de X están comentados a propósito», «no hay tráfico real
hasta tal fecha». Si no hay nada, escribe «Nada que destacar.»}}

## El otro repositorio

> **Repos hermanos:** {{RELLENAR: el nombre de la carpeta de cada repo hermano entre comillas invertidas y
> separados por comas, p. ej. `frontend` o `backend`, `mobile`; o «—» si este proyecto no tiene ninguno}}

Cada repo hermano vive en su propia carpeta, al lado de esta (`../<repo>/`), con su propio protocolo. Cada sesión se
abre en el repo en el que va a trabajar. Si no hay repos hermanos, esta sección no se dispara nunca.

- **Leer el código del otro repo está permitido y es lo esperado** cuando hay una duda real sobre el contrato: la
  forma de una respuesta, un código de error, un status. Es más fiable que suponer.
- **Citar su código vale** (una clase, un método, `../<repo>/app/...`), como evidencia de algo que comprobaste.
  Escribe también el hecho observable por HTTP, que es lo que no envejece.
- **Escribir en el otro repo, no.** Ni sus archivos, ni sus documentos, ni comandos que lo cambien.
- **Sus documentos no se citan** (su `CLAUDE.md`, su `.ai/`, su `docs/`), ni al revés: son repos distintos y esos
  enlaces se rompen o mienten. Lo vigila el chequeo «cross-repo» de `bin/check-docs.sh`.
- **Lo que el otro repo entrega** para una fase (la descripción de un cambio, respuestas de ejemplo) llega
  **copiado** a `.ai/handoffs/`, no enlazado.

### Traspaso al otro repo

Una fase **traspasa** cuando cambia algo que el otro repo consume (el contrato HTTP, un campo nuevo que debería
leer, un status, un mensaje) o cuando necesita que el otro repo cambie algo. El traspaso es parte del trabajo de
la fase, no un bloqueo:

1. Si el cambio **rompe el contrato** y la cabecera de la fase no lo autorizaba (`Contrato HTTP: SIN CAMBIOS`):
   STOP & ASK (`.ai/WORKFLOW.md §Contrato`). Si ya venía planificado (`CAMBIO AUTORIZADO`), empiezas en el paso 2.
2. Escribe en «Lo que la siguiente fase necesita saber» qué afecta al otro repo y por qué.
3. Crea su fila en `.ai/BACKLOG.md`, con Área = el repo hermano y, en el texto: `**Cambio:**` (qué hay que hacer
   allí), `**Origen:**` (`fase NN/FF` y el commit que lo exige) y, si un repo no puede desplegarse sin el otro,
   `**Despliegue:**` con la restricción. La fila aparece en `.ai/STATE.md §Pendientes en otros repos` hasta que el
   Tech Lead confirma que el otro repo está desplegado y la cierra.
4. Nómbralo en el reporte final.

La fila se escribe **en la fase que causa el cambio**, no se deja para la planificación ni para una fase
posterior. `bin/check-docs.sh` no deja cerrar `HECHA` una fase con `Contrato HTTP: CAMBIO AUTORIZADO` sin una fila
de `BACKLOG` que diga `fase NN/FF`, o sin `> **Traspaso:** ninguno — <motivo>` en su cabecera. Saltarse el
traspaso se puede, con motivo escrito; saltarlo en silencio, no.

## Protocolo de fases

El trabajo se organiza en **épicas** con **fases**. Cada fase vive en `.ai/epics/<NN-slug>/phase-<FF>.md` y es a la
vez el encargo y el registro de lo que pasó. Planificar (crear o cambiar una épica o una fase, incluida su
numeración) sigue `.ai/PLANNING.md`.

Dos comandos (`.claude/commands/`), una sesión por fase:

- `/phase [<epica> <FF>]` — ejecuta: rama → orientación → visto bueno → implementación → cierre. Sin argumentos,
  la fase activa de `.ai/STATE.md` (§Qué fase se ejecuta).
- `/close [<epica> <FF>]` — rescata una fase que otra sesión dejó a medias: documenta su estado real, no completa
  nada.

En herramientas sin comandos, «ejecuta la siguiente fase» equivale a `/phase` sin argumentos.

### El ciclo

1. **Paso 0 — qué fase y en qué rama.** Lee `.ai/STATE.md`, ejecuta `sh bin/check-docs.sh --strict` y resuelve la
   fase (§Qué fase se ejecuta). Ponte en su rama (§Rama de la fase).
2. **Paso A — orientación (sin escribir código).** Lectura en frío (§Orden de lectura), más `.ai/BACKLOG.md` y
   `.ai/DOMAIN.md §Decisiones pendientes`: ¿algo abierto afecta a esta fase? **Revalida la fase**: pudo
   redactarse antes de que cerrara su predecesora, así que contrasta cada supuesto (rutas, nombres,
   comportamiento) con «Lo que la siguiente fase necesita saber» de la anterior y con el código actual. Lo
   mecánico lo corriges en el archivo de la fase (entra en el commit de arranque); lo que requiera decisión va a
   su §8 como pregunta. Responde con:
   - tres viñetas de lo que vas a construir;
   - los archivos que vas a crear y modificar;
   - lo que la fase da por hecho y ya no es cierto;
   - las preguntas abiertas, si las hay.

   **Para y espera el visto bueno.** Lo que está en `.ai/DOMAIN.md` ya está decidido. Lo que no determinan ni el
   código ni `DOMAIN.md` **no se inventa**: STOP & ASK (`.ai/WORKFLOW.md §STOP & ASK`). En el Paso A una pregunta no
   cambia el estado: la fase sigue `LISTA_PARA_EJECUTAR`, con la pregunta en su §8.
3. **Paso B — ejecución (sólo con visto bueno explícito).** Pon la fase en `EN_CURSO` (§Estado de una fase) y haz
   el commit de arranque. Después, **una fila de §9 «Plan de commits» a la vez**, un commit por fila en cuanto pasa
   `bash bin/verify.sh --fast` (§Commits durante la fase). Si te bloqueas: STOP & ASK y `BLOQUEADA`.
4. **Verificación.** `bash bin/verify.sh` completo en verde (§Verificación).
5. **Paso C — cierre, siempre**, también si la fase queda bloqueada o en rojo (§Cierre de fase). Una fase sin
   cerrar no ha terminado.
6. **Revisión.** La rama se queda en local. El Tech Lead la revisa con `git log --oneline <base>..HEAD` y
   `git diff <base>...HEAD`, y decide el merge. **Nunca `git push`.**

### Estado de una fase

`SIN_PLANIFICAR` · `LISTA_PARA_EJECUTAR` · `EN_CURSO` · `BLOQUEADA` · `VERIFICACION_ROJA` · `HECHA`.

Vive en **dos** sitios que se escriben siempre juntos, en el mismo commit: la cabecera `> **Estado:**` del archivo
de la fase y su fila en `.ai/STATE.md §Mapa de fases`. Transiciones (las ejecuta la IA; no son opcionales):

- **Al iniciar** (visto bueno del Paso A): `EN_CURSO` en los dos sitios y la fecha en `Última actualización` de
  `STATE.md`. Si es la primera fase de la épica, la cabecera del epic-plan pasa de `SIN_EMPEZAR` a `EN_CURSO`.
- **Al bloquear** (sólo desde `EN_CURSO`): `BLOQUEADA` en los dos sitios. Al recibir la respuesta, vuelve a
  `EN_CURSO`.
- **Al cerrar**: `HECHA`, `BLOQUEADA` o `VERIFICACION_ROJA` en los dos sitios, y la fecha en la columna `Cerrada` del
  mapa, sea cual sea el estado. Si la fase queda `BLOQUEADA` o `VERIFICACION_ROJA`, el puntero **se queda en
  ella**: las siguientes dependen de ella.
- **El puntero** (`Épica activa`, `Fase activa`, `Archivo de la fase` de `STATE.md`) es siempre la **primera fila
  sin `HECHA` del mapa**, aunque sea de otra épica. Si esa fila está `SIN_PLANIFICAR`, `Épica activa` es la suya y
  `Fase activa` y `Archivo de la fase` quedan en `—`; si no queda ninguna, las tres quedan en `—`.
- **El estado de la épica** (cabecera `Estado:` del epic-plan) pasa a `EN_CURSO` con su primera fase y a `CERRADA`
  sólo por §Cierre de épica. Es lo único del epic-plan que mantiene el ejecutor.

Si el estado de la fase no coincide en los dos sitios, el guardián falla en el Paso 0: no toques nada y pregunta
(`.ai/WORKFLOW.md §Sin sentido lógico`). La inconsistencia es un bug del cierre anterior; la recomendación por
defecto es que gane el archivo de la fase, que es el que lleva el RESULTADO.

### Alcance

- Lo que encuentres de más y no haga falta tocar va a `.ai/BACKLOG.md`. **No lo arregles.**
- Si para dejar tu cambio **coherente** tienes que tocar algo contiguo (el resto del comentario que reescribes, un
  import que queda huérfano, la línea de al lado que contradice lo que acabas de escribir), hazlo y decláralo en el
  RESULTADO. Es alcance mínimo, no ampliación.
- Si el cambio obliga a tocar **otro archivo** que no está en el §4 de la fase, o a cambiar un comportamiento que
  la fase no nombra: **para y pregunta** antes de tocarlo.

## Qué fase se ejecuta

`/phase` sin argumentos ejecuta la **fase activa**: la de la cabecera de `.ai/STATE.md`. Antes de fiarte de ella,
`sh bin/check-docs.sh --strict`: comprueba que es la primera fila sin terminar del mapa y que su estado coincide en
el archivo y en el mapa. Si falla, el puntero no es fiable: STOP & ASK (`.ai/WORKFLOW.md §Sin sentido lógico`).
Con argumentos, la fase pedida tiene que ser la activa; si no, dilo y para.

| Estado de la fase activa | Qué haces |
|---|---|
| `LISTA_PARA_EJECUTAR` | La ejecutas desde el Paso A. Si su «Depende de» no está `HECHA` en el mapa, dilo y para. |
| `EN_CURSO` | Otra sesión la dejó a medias. No la retomes: dilo y remite a `/close`. |
| `BLOQUEADA` o `VERIFICACION_ROJA` | Si el motivo es una pregunta de su §8 que sigue sin respuesta en `.ai/DOMAIN.md`, muéstrala y para. Si no, **reanúdala**. |
| `HECHA` | El puntero no avanzó al cerrarla: STOP & ASK. |
| `—` | No hay nada listo. Di qué épica sigue en el mapa y que hay que planificarla (`.ai/PLANNING.md`). |

**Reanudar** es un Paso A abreviado: revalida la fase contra el código actual, di qué filas de §9 ya tienen commit
en la rama (las que siguen al de arranque) y cuáles faltan, y espera el visto bueno. Con él, la fase y su fila del
mapa vuelven a `EN_CURSO` (y `Cerrada` a `—`), commit de reanudación, y sigues por la primera fila pendiente.

## Rama de la fase

Cada fase se ejecuta en su rama, **`phase/<NN-slug>/<FF>`**, que refleja la ruta de su archivo. Se resuelve antes
del Paso A, porque la revalidación lee el código y tiene que ser el de la rama donde vas a trabajar:

- **Ya estás en ella:** sigue.
- **Existe y estás en otra:** pregunta si cambias a ella.
- **No existe:** pregunta desde qué rama se crea. Candidatas, en este orden: la rama base de la épica
  (`epic/<NN-slug>`) si su epic-plan la declara (`.ai/PLANNING.md §Rama base de la épica`); `main`; la rama de la
  fase anterior (la fila anterior del mapa); la rama actual. **Sólo se ofrecen ramas cuyo
  `git show <rama>:.ai/STATE.md` apunte ya a esta fase**: eso prueba que la anterior está cerrada en esa base. Si
  descartas alguna, di por qué; si no vale ninguna, dilo y para.

Para crear la rama o cambiar a ella, el árbol de trabajo tiene que estar limpio; si no, dilo y para. Ya en la rama,
vuelve a leer `.ai/STATE.md` (manda el de esa rama) y a resolver la fase: si sale otra, dilo y para. Sólo ramas
locales: nada de `git fetch` ni `git push`.

Los merges los decide el Tech Lead tras revisar la rama, y la IA sólo los ejecuta si él lo pide. Si la épica
declara rama base, las fases se mergean con `--no-ff` a `epic/<NN-slug>`, y ésta a `main` sólo al cerrar la épica.

## Commits durante la fase

Esta es la **única** regla sobre commits del repositorio; los demás archivos remiten aquí.

- **La IA commitea ella misma mientras avanza la fase.** No propone mensajes ni espera confirmación: el visto bueno
  del Paso A cubre todos los commits de la fase.
- **Mensajes:** Conventional Commits **en inglés**, con los ámbitos de `.ai/RULES.md §Ámbitos de commit`. La primera
  línea dice qué cambia; si el porqué no es obvio, va en el cuerpo. Termina con la línea de atribución que indique
  la herramienta, si la indica.
- **Arranque.** Al recibir el visto bueno: `chore(phase-<NN>-<FF>): start`, con el cambio a `EN_CURSO`,
  `.ai/STATE.md` y lo escrito en la fase durante el Paso A (§8, correcciones de la revalidación).
- **Reanudación.** `chore(phase-<NN>-<FF>): resume`, con el cambio a `EN_CURSO`, `STATE.md` y lo escrito en el Paso
  A abreviado. Las filas ya commiteadas no se rehacen.
- **Una fila de §9 = un commit**, en cuanto su trabajo está terminado y pasa `bash bin/verify.sh --fast`. Una fila
  puede cubrir varios entregables relacionados; los que no cambian archivos no llevan fila.
- **Atómico.** `git add` sólo con los archivos de esa fila: `git show --stat HEAD` no lista nada más. Si se coló
  algo, `git reset --soft HEAD~1` y rehazlo.
- **Retoques.** Lo que no encaja en ninguna fila pero es parte necesaria de un entregable (o una corrección tras un
  `verify` rojo, que es un `fix(...)` por corrección) va en su propio commit y se lista en el RESULTADO. Lo que es
  alcance nuevo no se commitea: STOP & ASK (`.ai/WORKFLOW.md §Sin sentido lógico`).
- **Pruebas en rojo** («el test falla si quito X»): sobre trabajo ya commiteado o sobre una copia fuera del repo.
  `git restore` sobre un archivo con cambios sin commitear se los lleva.
- **Cierre.** `chore(phase-<NN>-<FF>): close`, con el RESULTADO, `STATE.md`, `DOMAIN.md`, `BACKLOG.md`,
  `PROTOCOL.md` y, si cambiaron, el manifiesto de despliegue, el epic-plan y la baseline de `bin/verify.sh`.
- Los commits de arranque, reanudación y cierre **no** van en §9: son siempre aparte.
- **Nunca** `git push`, `git reset --hard` ni reescribir commits que no sean de esta fase.
- **Fuera de una fase**, la IA sólo commitea si el Tech Lead lo pide: planificación (`chore(planning): …`) o cambios
  al protocolo (`chore(protocol): …`).

## Cierre de fase

Siempre, también si la fase se bloqueó o la verificación quedó roja:

1. Rellena `RESULTADO DE LA EJECUCIÓN` en el archivo de la fase, sin borrar encabezados. El campo más importante es
   **«Lo que la siguiente fase necesita saber»**: la próxima sesión empieza sin memoria y es lo único que leerá de
   esta.
2. Marca las casillas del §5 como dice `.ai/WORKFLOW.md §Un criterio de éxito no se puede cumplir`: ejecutadas tal
   como están escritas y con su salida pegada en «Verificación».
3. Estado final en la fase y en el mapa, con la fecha en `Cerrada`, y el puntero de `.ai/STATE.md` según §Estado de
   una fase. Regenera las zonas de §Sincronización post-lectura y añade el cierre a `§Últimos movimientos`.
4. Decisiones de negocio nuevas a `.ai/DOMAIN.md §Decisiones tomadas`, con fecha y fase.
5. Hallazgos fuera de alcance a `.ai/BACKLOG.md`. **No los arregles.**
6. Lo que estorbó del protocolo (la sección «Qué mejorarías del protocolo» del RESULTADO) a `.ai/PROTOCOL.md`.
7. **Si la fase añade algo que hay que hacer en producción al desplegarla** —una migración, un comando, una
   variable de entorno o de configuración, un cambio de cron o de colas, una restricción de orden—, una fila por
   paso en `docs/runbooks/release.md §Pasos por fase`. Es lo que evita olvidarlo en el despliegue, que puede
   llegar meses después.
8. **Si la fase deja algo para otro repo**, su traspaso (§El otro repositorio).
9. **Si la fase mejoró la baseline** (más tests, menos deuda), sube o baja el número en `bin/verify.sh`. Nunca en la
   dirección mala.
10. **Si la fase queda `HECHA` y era la última de su épica**, §Cierre de épica.
11. `sh bin/check-docs.sh --strict` en verde: el puntero se escribe después del último `bin/verify.sh`, y es lo que
    la siguiente sesión ejecutará sin preguntar.
12. Commit de cierre (§Commits durante la fase) y `git status` limpio.

## Cierre de épica

Lo hace quien cierra con `HECHA` la última fase de la épica, dentro del cierre de esa fase y en su mismo commit. Si
la última fase queda `BLOQUEADA` o `VERIFICACION_ROJA`, no hay cierre de épica: sigue `EN_CURSO` y el puntero se
queda en esa fase.

1. **Comprueba cada casilla del «Criterio de cierre»** del epic-plan igual que las del §5 de una fase
   (`.ai/WORKFLOW.md §Un criterio de éxito no se puede cumplir`), con su salida en «Verificación» del RESULTADO de
   esta última fase.
2. **Marca las que se cumplen.** No reescribas un criterio para que se cumpla: cambiarlo es planificar y lo decide
   el Tech Lead.
3. **Si se cumplen todas**, la cabecera del epic-plan pasa a `Estado: CERRADA` y `.ai/STATE.md §Últimos movimientos`
   lo dice en una línea. Si la épica declaró rama base, di en el reporte que `epic/<NN-slug>` está lista para
   mergearse a `main`.
4. **Si alguna no se cumple**, la épica sigue `EN_CURSO` con esa casilla sin marcar: STOP & ASK con cada criterio
   que falla y su salida. Las opciones son una fase nueva, corregir el criterio o aceptar el cierre tal cual. La
   fase se cierra `HECHA` igualmente: sus entregables están hechos.

`bin/check-docs.sh` falla si el estado de una épica no cuadra con su mapa (`SIN_EMPEZAR` con fases empezadas,
`CERRADA` con fases sin `HECHA` o con casillas sin marcar) o si `Épica activa` es una épica `CERRADA` mientras
queda otra abierta.

## Verificación

`bash bin/verify.sh` es el único árbitro. Qué gates corre, en qué orden y con qué baseline (los números que nunca
empeoran) lo define el propio script, y no se repite en ningún documento. Su primer gate es `bin/check-docs.sh`,
el guardián de los documentos.

- `bash bin/verify.sh --fast` corre sólo los gates baratos: es el de cada fila de §9. **El cierre de una fase exige
  el `bash bin/verify.sh` completo.**
- Máximo **3 intentos** de ponerlo en verde dentro de la fase; cada corrección es su propio commit. Si al tercero
  sigue rojo, la fase se cierra `VERIFICACION_ROJA` con los fallos concretos pegados en el RESULTADO.
- Si se pone rojo por algo ajeno a la fase: `.ai/WORKFLOW.md §Cuando un gate se pone rojo por algo ajeno a la fase`.

## Cosas que no se hacen

- Instalar dependencias sin preguntar.
- Ampliar el alcance de la fase más allá de §Alcance.
- Modificar, saltar o debilitar un test para que pase un cambio; bajar el nivel de un linter o de un analizador; añadir
  exenciones a un gate. Lo que no pasa la barandilla está mal.
- Dejar llamadas de depuración en el código (las de `.ai/RULES.md §Lista negra`).
- Tocar los archivos de «No tocar» de la fase o lo que `.ai/RULES.md §Alcance` deja fuera.
- Escribir en el otro repositorio o citar sus documentos (§El otro repositorio).
- Modificar este archivo, `.ai/RULES.md` o `.ai/WORKFLOW.md` desde una fase. Si crees que están mal: STOP & ASK, y
  la propuesta a `.ai/PROTOCOL.md`.
- `git push`.
