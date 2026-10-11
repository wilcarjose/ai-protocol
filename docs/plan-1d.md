# Plan 1d — Ciclo de mejora del protocolo

> **Origen:** la retrospectiva de las fases BA de `base-api` (plan 1c, fase 3) y el encargo de la persona del 11 de
> octubre de 2026 (#34). El protocolo captura mejoras, pero no tiene camino de vuelta al kit: `.ai/PROTOCOL.md` de
> `base-api` acumula siete filas en `propuesta` y nadie las aplica. Además, la pregunta del cierre hace creer a la
> persona que la retrospectiva le toca a ella, y la del ejecutor, escrita antes de la entrega y de memoria, deja
> fuera las fricciones reales.
> **Base:** lo que está en «Sin publicar»: núcleo 2.2.0-dev, Laravel 2.1.0-dev y Next.js 3.0.0-dev (fases 1 y 2 del
> plan 1c y el arreglo del chequeo «traspaso», #21). Va **antes de la fase 4 del plan 1c**, para que `base-web` nazca
> con el kit mejorado y sus fases estrenen la retro nueva.

## Estado

| Fase | Objetivo | Depende de | Estado | PR |
|---|---|---|---|---|
| 1 | El canal | — | pendiente | |
| 2 | El primer lote | 1 | pendiente | |
| 3 | Versión y upgrade | 2 | pendiente | |

## Cómo se ejecuta una fase

Igual que en `docs/plan-1a.md §Cómo se ejecuta una fase`, con la rama `plan-1d/fase-N`. Antes de agregar algo,
busca lo mínimo que cumple el objetivo; si no se puede comprobar con un comando o con una casilla `[humano]`,
simplifícalo o propón quitarlo.

## Decisiones que no se reabren

1. **El kit es la única fuente.** Nunca se parchea un archivo del kit dentro de un proyecto, ni con urgencia, porque
   el upgrade lo dejaría como conflicto para siempre. Lo urgente sigue el mismo camino, más rápido: el arreglo en el
   kit, una versión de parche y el upgrade.
2. **Lo que es propio de un proyecto va a su `.ai/project/`**, no al kit. Por eso cada mejora lleva su alcance:
   núcleo, stack o proyecto.
3. **El upgrade se hace entre fases**, en un PR `chore(protocol): upgrade ai-protocol to vX.Y` a `main`, sin ninguna
   fase `EN_CURSO`. Una fase termina con las reglas con las que empezó.
4. **Mejorar el protocolo es tarea del ejecutor**, que es quien lo recorre. La persona sólo añade o corrige lo que
   vio desde su papel.
5. Siguen vigentes las decisiones de `docs/plan-1a.md`, `docs/plan-1b.md` y `docs/plan-1c.md`. La decisión 4 de este
   plan reemplaza la pregunta única de la fase 1 del plan 1b.
6. **El arranque del ejecutor no crece:** lo nuevo vive en el cierre, en el planificador y en el revisor, que no
   cuentan en él (`tests/context-baseline.txt`).

---

## Fase 1 — El canal

**Objetivo:** que cada mejora que encuentra una fase llegue al kit como un issue y vuelva al proyecto con una versión.

Entregables:

- `core/.claude/skills/phase/cierre.md §Cierre de fase`, paso 7, rehecho (y `/close`, que sigue el mismo cierre):
  - **La retro del ejecutor**, obligatoria y **al final, después de la entrega**, en su propio commit
    `chore(phase-NN-FF): retro` empujado al mismo PR. Categorías fijas, cada una con evidencia y con el archivo y la
    sección que propone cambiar, o «nada» justificado: fricción (reintentos, tiempo perdido), ambigüedad (lo que
    tuvo que interpretar), contradicción, herramientas y permisos, lo que el protocolo no cubría y los rodeos que
    usó (#29).
  - **Anotar en el momento:** el ejecutor escribe la fricción cuando ocurre, en la sección de la retro de su fase, no
    la reconstruye de memoria al final. Los encabezados del RESULTADO no se renombran: el guardián los compara con la
    plantilla, y las fases ya cerradas tienen que seguir pasando.
  - **La pregunta a la persona, opcional y dirigida a su papel**, después de enseñarle la lista del ejecutor: «Como
    Tech Lead, ¿falta algo, sobra algo, o algo de esta fase te costó a ti (preguntas mal planteadas, el visto bueno,
    la revisión del PR)?».
- `core/.ai/PROTOCOL.md` (la semilla): una columna `Alcance` (núcleo · stack · proyecto) justo antes de «Estado», y los
  estados `enviada — ai-protocol#N` y `aplicada — kit vX.Y`. El chequeo «memoria» de `bin/check-docs.sh` ya lee el
  estado como la última columna y archiva las aplicadas; la fase le añade el `Alcance` válido. Una tabla sin la
  columna, la de antes, sigue pasando, y sus filas no se envían: así la versión del núcleo es menor.
- `core/bin/protocol-feedback.sh`: lee las filas con alcance núcleo o stack que aún no se han enviado, abre un issue
  por fila con `gh` en el repo del kit (`AI_PROTOCOL_REPO`, por defecto `wilcarjose/ai-protocol`), con su origen,
  evidencia, propuesta y alcance, y deja cada fila en `enviada — ai-protocol#N`. Sin `gh` o sin acceso, imprime el
  texto de cada issue y no cambia nada. Entra en `core/core.json` como archivo del kit.
- `core/.github/pull_request_template.md`: una sección «Protocolo» con las filas nuevas de `.ai/PROTOCOL.md`.
- README §Principios, «Mejorado con retroalimentación»: el ciclo nuevo (retro del ejecutor, issue, versión,
  upgrade) y las decisiones 1 a 4.

Criterios de aceptación:

- [ ] `sh tests/run.sh` acepta un `PROTOCOL.md` con la columna `Alcance` y filas `propuesta` y
      `enviada — ai-protocol#N`, y la tabla sin `Alcance`; y falla con una fila `aplicada — kit vX.Y` sin archivar y
      con un alcance que no es núcleo, stack ni proyecto.
- [ ] `sh tests/run.sh` corre `bin/protocol-feedback.sh` con un `gh` de mentira en el `PATH`: un issue por fila de
      núcleo o stack sin enviar, cada una en `enviada — ai-protocol#N`, y las de proyecto y las ya enviadas, igual.
      Sin `gh`, imprime el texto y el archivo no cambia.
- [ ] `sh tests/run.sh` pasa con el arranque del ejecutor dentro de `tests/context-baseline.txt`, sin subirla.
- [ ] `shellcheck -s sh` sobre el script nuevo no da avisos, y la CI del PR está en verde.

## Fase 2 — El primer lote

**Objetivo:** aplicar en el kit las mejoras que vinieron de `base-api`.

Entregables, por archivo (los issues del #22 al #33, salvo el #29, que es de la fase 1):

- `core/.claude/skills/phase/cierre.md`: revisar antes de escribir la memoria (#25); el paso 11 sube la baseline
  aunque el modo auto lo tome por saltarse la CI (#26); el push y `gh pr create` como comandos sueltos, con
  `--body-file`, y reintentarlos sueltos antes de dar la orden a la persona (#30); y las zonas derivadas de
  `STATE.md`, sincronizadas antes del `verify` final, con el estado y el puntero después (#31).
- `core/.claude/skills/plan-phase/SKILL.md`: medir con una petición real el texto de una respuesta (#22); buscar en
  `tests/` los usos de lo que se retira o se renombra (#24); citar `.ai/project/CONTRACT.md` en una fase que lee
  cabeceras o la IP de quien llama (#28).
- `core/.claude/agents/reviewer.md`: corre antes del RESULTADO y sólo comprueba que cada criterio se puede cumplir
  con el diff (#32).
- `stacks/*/.claude/settings.json`: editar `.ai/project/verify.conf` (#26), y los patrones del push y del PR tal como
  los escribe `cierre.md` (#30).
- `stacks/laravel/.ai/rules/tests.md`: las cabeceras que pone el cliente de test (#23) y la orden de Pest para la
  evidencia, `PAO_DISABLE=1 ./vendor/bin/pest … --colors=never` (#33).
- `stacks/laravel/.ai/rules/arquitectura.md §Tipado estricto y Value Objects`: la excepción del esqueleto, citando
  `tests/Architecture/ArchitectureTest.php` (#27).
- El `CHANGELOG.md` de cada paquete, en «Sin publicar», con el issue que cierra cada cambio.

Lo que puede incumplirse en silencio lleva su chequeo, probado en las dos direcciones. Al menos uno: los comandos de
`cierre.md §Entrega` encajan con los patrones `allow` del `settings.json` de cada stack (#30). Si la fase ve otro, lo
propone en su resumen.

Criterios de aceptación:

- [ ] Cada issue del lote tiene su cambio: el PR lo cierra con `Closes #N`, uno por línea.
- [ ] `sh tests/run.sh` falla si un comando de `cierre.md §Entrega` no encaja con un `settings.json`, y pasa con los
      de hoy.
- [ ] `sh tests/run.sh` pasa con el arranque del ejecutor dentro de `tests/context-baseline.txt`.
- [ ] La CI del PR está en verde.

## Fase 3 — Versión y upgrade

**Objetivo:** publicar la versión y comprobar el ciclo de punta a punta en `base-api`.

Entregables:

- Las versiones de los paquetes, publicadas: sin `-dev`, con la fecha en su `CHANGELOG.md`, que cita los issues que
  cierra. Se publica todo lo que está en «Sin publicar», también lo de las fases 1 y 2 del plan 1c y el #21; la fase
  5 del plan 1c publicará lo que quede. Las etiquetas las crea quien fusiona (README §Versiones y etiquetas).
- `install.sh --upgrade` avisa de qué filas `enviada — ai-protocol#N` del proyecto resuelve la versión nueva: las que
  tienen su `#N` en el `CHANGELOG.md` de un paquete entre la versión del lock y la nueva. Sólo avisa: la fila la
  marca el proyecto.
- En `base-api`, sin ninguna fase `EN_CURSO`:
  - la columna `Alcance` en su `.ai/PROTOCOL.md`, y sus filas en `enviada`, con los issues que ya existen: la #1 es el
    #22, la #2 el #23, la #4 el #24, la #5 el #25, la #6 el #26, la #7 el #27 y la #8 el #28;
  - `install.sh --upgrade --dry-run` y, después, el upgrade en su PR
    `chore(protocol): upgrade ai-protocol to vX.Y`;
  - sus filas, en `aplicada — kit vX.Y`, archivadas.

Criterios de aceptación:

- [ ] `sh tests/run.sh` hace un upgrade de una instalación con una fila `enviada` cuyo issue cita el `CHANGELOG.md`
      de la versión nueva, y el aviso la nombra; con otra que no cita, no la nombra.
- [ ] En `base-api`, el `--upgrade --dry-run` nombra las siete filas, y la CI de su PR de upgrade está en verde.
- [ ] En `base-api`, `.ai/PROTOCOL.md` no tiene filas `enviada` de este lote, y `.ai/archive/PROTOCOL.md` las tiene
      como `aplicada — kit vX.Y`.
- [ ] La CI del PR está en verde.

---

## Registro

- **Decisiones tomadas durante el plan:**
  - (al escribir el plan) Los issues de las mejoras ya están abiertos: del #22 al #28, las filas de `PROTOCOL.md` de
    `base-api`; del #29 al #33, las cinco fricciones de su fase 01/03 que no llegaron a `PROTOCOL.md`; y el #34, el
    que los agrupa. El arreglo del chequeo «traspaso» va aparte, en el #21.
- **Lo que la siguiente fase necesita saber:**
  - (al escribir el plan) Hasta que la fase 3 publique el #21, la persona no cierra los traspasos de `base-api`.
  - (al escribir el plan) `base-api` no cambia hasta la fase 3: sus filas pasan a `enviada` y `aplicada` con el
    upgrade.
