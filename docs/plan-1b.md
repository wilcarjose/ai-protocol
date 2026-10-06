# Plan 1b — Retroalimentación, modo VPS y guía práctica

> **Origen:** decisiones del 6 de octubre de 2026 en la Etapa 1 del portal (preguntas 15 y 22) y dos principios de la persona: nada de sobreingeniería, solo lo necesario, simple y comprobable; y cada fase pide retroalimentación para mejorar el protocolo.
> **Base:** el kit 2.0.0 del plan 1a. Lo que cambie sube versión menor por paquete (2.1.0), con su `CHANGELOG.md`.

## Estado

| Fase | Objetivo | Depende de | Estado | PR |
|---|---|---|---|---|
| 1 | Retroalimentación de la persona en cada cierre | — | hecha | #9 |
| 2 | Modo VPS por defecto | 1 | en revisión | #10 |
| 3 | Guía práctica de inicio a fin | 2 | pendiente | — |

La guía va al final para describir el kit ya con la retroalimentación y el modo VPS.

## Cómo se ejecuta una fase

Igual que en `docs/plan-1a.md §Cómo se ejecuta una fase`, con la rama `plan-1b/fase-N`. Una regla más: antes de agregar algo, busca lo mínimo que cumple el objetivo. Si no se puede comprobar con un comando o con una casilla `[humano]`, simplifícalo o propón quitarlo.

## Decisiones que no se reabren

1. Siguen vigentes las decisiones de `docs/plan-1a.md`.
2. Por defecto, las fases corren en un VPS propio con Remote Control en modo servidor, cada sesión en su worktree, y se manejan desde la app de Claude. La nube queda de respaldo y el local, como opción; el final es el mismo.
3. Nada de bot propio en este plan: primero la app de Claude y, si falta algo, Channels con Telegram.
4. Staging y producción de los proyectos van sin Docker. El kit no despliega, pero `bin/verify.sh` corre igual en el VPS sin Docker.
5. Nada de este plan entra al arranque del ejecutor: el de Laravel está a 73 caracteres de su línea base.

---

## Fase 1 — Retroalimentación de la persona en cada cierre

**Objetivo:** que cada cierre pregunte a la persona cómo le fue con el protocolo y lo deje anotado para mejorarlo.

Entregables:

- En el cierre de `/phase` y en `/close`, una sola pregunta a la persona: «¿Algo del protocolo te estorbó, te faltó o te sobró en esta fase?», con las opciones «Nada» y «Sí», más su texto. Con respuesta, una fila en `.ai/PROTOCOL.md` con origen `persona` y la fase; sin respuesta, el cierre sigue.
- Las propuestas del agente y las de la persona quedan en la misma tabla, que `/plan-phase` ya revisa.
- README §Principios, corta: simple, comprobable y mejorado con retroalimentación. Incluye cómo llega al kit una mejora que sirve a todos los proyectos: un issue en ai-protocol con la fila de `PROTOCOL.md`.
- `docs/plan-1a.md`: la fase 8 queda `hecha`.

Criterios de aceptación:

- [ ] `tests/run.sh` incluye un `PROTOCOL.md` con una fila de origen `persona`, y el guardián la acepta.
- [ ] `bin/measure-context.sh` da para el ejecutor lo mismo que `tests/context-baseline.txt`: la pregunta vive en el cierre, que no cuenta en el arranque.
- [ ] La CI del PR está en verde.

## Fase 2 — Modo VPS por defecto

**Objetivo:** que las fases corran en un VPS propio, manejadas desde el teléfono, y terminen igual que en cualquier otro modo.

Entregables:

- `docs/modos.md`, con el VPS como modo por defecto:
  - Preparación: un usuario propio para los agentes, `claude auth login` con la cuenta de claude.ai (Remote Control no acepta API keys), `gh auth login`, la identidad de git y las herramientas del stack sin Docker (PHP, Composer, Node, PostgreSQL con PostGIS y gitleaks).
  - Arranque de `claude remote-control --spawn worktree` como servicio de systemd (unidad de ejemplo en `docs/vps/`) o dentro de tmux, y los avisos push desde `/config`.
  - El día a día desde el teléfono: abrir una sesión en el repo, `/phase`, responder y revisar el PR.
  - Aislamiento con staging: usuarios distintos, el `.env` de staging ilegible para los agentes, ningún secreto de producción y datos ficticios.
  - Cuándo usar la nube o el local.
- `docs/vps/doctor.sh`: dice qué le falta al VPS (comandos, versiones mínimas, sesión de `gh`) y si el usuario de los agentes puede leer el `.env` de staging que se le indique.
- `/phase` y los gates funcionan dentro de un worktree de git.

Criterios de aceptación:

- [ ] `tests/run.sh` corre `docs/vps/doctor.sh` con un `PATH` al que le falta una herramienta, y la reporta.
- [ ] `tests/run.sh` corre el guardián y la protección del protocolo dentro de un `git worktree`, y pasan.
- [ ] `shellcheck -s sh docs/vps/*.sh` no da avisos.
- [ ] `[humano]` La persona arranca una fase desde el teléfono en su VPS y llega al PR; pega el enlace como evidencia. Puede marcarse después de fusionar, y se anota en «Registro».

## Fase 3 — Guía práctica de inicio a fin

**Objetivo:** que alguien arranque un proyecto desde cero leyendo una sola guía.

Entregables:

- `docs/guia.md`, corta y en lenguaje simple:
  1. Qué es el protocolo, en diez líneas y con un diagrama del ciclo.
  2. Cómo iniciar un proyecto nuevo, Laravel o Next.js, con sus comandos.
  3. El ciclo completo: planificar, `/phase`, PR, revisión, fusión, siguiente fase y cierre de la épica.
  4. Para qué sirve cada pieza, en una línea cada una.
  5. Un ejemplo práctico pequeño de inicio a fin: la épica de prueba que ya corre el e2e.
  6. Recomendaciones.
- El README enlaza la guía al principio.

Criterios de aceptación:

- [ ] `tests/run.sh` comprueba que cada ruta y cada script que cita la guía existen en el kit o en una instalación.
- [ ] `[humano]` La persona confirma que la guía responde sus siete preguntas: visión macro, uso paso a paso, proyecto nuevo, ciclo de fases, para qué sirve cada cosa, ejemplo y recomendaciones.
- [ ] La CI del PR está en verde.

---

## Registro

- **Decisiones tomadas durante el plan:**
  - **Versión (fase 1).** Mientras dura el plan, los paquetes que cambian llevan el sufijo `-dev` (`core` está en
    `2.1.0-dev`) y su `CHANGELOG.md` acumula en «Sin publicar». Al cerrar la fase 3 pasan a `2.1.0`, con su
    etiqueta (README.md §Versiones y etiquetas).
  - **Proveedor (fase 1).** Claude Code es la herramienta por defecto, pero el protocolo debe poder usarse con
    agentes de otros proveedores: lenguaje neutro y lo propio de Claude Code como nota entre paréntesis («una
    pregunta con opciones (en Claude Code, `AskUserQuestion`)»), sin adaptadores nuevos. Vive en README.md
    §Principios y se aplica a todo lo que se toque.
  - **Base de datos de los tests en el VPS (fase 2).** Un rol `agentes` sin superusuario, dueño sólo de `testing`,
    con PostGIS creado una vez como `postgres`. Sus credenciales van en `DB_USERNAME` y `DB_PASSWORD` de la unidad
    de systemd, que ganan a `.env.testing`: el stack no cambia. Con `postgres`/`postgres`, los agentes llegarían a la
    base de staging. `docs/vps/doctor.sh` avisa si el rol es superusuario.
  - **`/phase` no cambia (fase 2).** Por la decisión 5. En un worktree de Remote Control ya funciona: la rama del
    worktree sale de `origin/main` y «la actual» es una candidata válida en §Rama de la fase. Lo que fallaba era la
    base del gate «protocolo», que tomaba el `main` local del checkout principal, casi siempre atrasado: ahora
    `bin/check-protocol.sh` prueba antes `origin/…` (`core/CHANGELOG.md`, «Cambiado»).
  - **Los gates no esquivan `.claude/worktrees/` (fase 2).** La sesión que el servidor crea en la carpeta del repo
    no ejecuta fases (`docs/modos.md §El día a día desde el teléfono`); así no hace falta tocar el guardián, ESLint
    ni Vitest.
  - **El servicio, dentro de tmux (fase 2).** El servidor de Remote Control necesita un terminal y, la primera vez,
    aceptar la confianza en el directorio a mano; la unidad lanza tmux y systemd la reinicia si el servidor se cierra.
- **Lo que la siguiente fase necesita saber:**
  - La pregunta de retroalimentación vive en el paso 7 de `core/.claude/skills/phase/cierre.md §Cierre de fase`;
    `/close` la hereda porque sigue el cierre desde su paso 3, y el cierre ligero la incluye. No cuenta en el
    arranque del ejecutor (el de Laravel sigue a 73 caracteres de su línea base).
  - Las filas de la persona llevan `De` = `persona — fase NN/FF`; el guardián no mira esa columna, y
    `tests/lib.sh` lo prueba con el caso `accept 13p`.
  - `core` está en `2.1.0-dev`. La fase 2 sigue en «Sin publicar» de cada `CHANGELOG.md` que toque; si toca un
    stack, ese `stack.json` también pasa a `2.1.0-dev`.
  - (fase 2) `docs/modos.md` tiene `§VPS` (con `§Preparación`, `§Arranque`, `§El día a día desde el teléfono` y
    `§Aislamiento con staging`), `§Nube`, `§Local` y `§Qué elegir`. La guía los cita; no los repite.
  - (fase 2) `docs/vps/doctor.sh` y `docs/vps/remote-control@.service` son del kit y no se instalan en el proyecto.
    El chequeo de rutas de la guía (fase 3) tiene que distinguir las del kit de las de una instalación.
  - (fase 2) Ningún stack cambió: siguen en `2.0.0`. El arranque del ejecutor sigue igual (Laravel, 53227).
  - (fase 2) Queda abierta la casilla `[humano]`: una fase arrancada desde el teléfono en el VPS que llegue al PR.
    Su enlace se anota aquí cuando la persona lo aporte.
