# Plan 1b — Retroalimentación, modo VPS y guía práctica

> **Origen:** decisiones del 6 de octubre de 2026 en la Etapa 1 del portal (preguntas 15 y 22) y dos principios de la persona: nada de sobreingeniería, solo lo necesario, simple y comprobable; y cada fase pide retroalimentación para mejorar el protocolo.
> **Base:** el kit 2.0.0 del plan 1a. Lo que cambie sube versión menor por paquete (2.1.0), con su `CHANGELOG.md`.

## Estado

| Fase | Objetivo | Depende de | Estado | PR |
|---|---|---|---|---|
| 1 | Retroalimentación de la persona en cada cierre | — | pendiente | — |
| 2 | Modo VPS por defecto | 1 | pendiente | — |
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

- **Decisiones tomadas durante el plan:** —
- **Lo que la siguiente fase necesita saber:** —
