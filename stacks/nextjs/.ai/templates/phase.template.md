# Fase FF — <título corto en imperativo>

> **Épica:** `NN-slug` · **Depende de:** — | fase FF-1
> **Estado:** LISTA_PARA_EJECUTAR
> **Tipo:** código
> **Contrato HTTP:** SIN CAMBIOS

<!-- Cómo se rellena cada sección: .claude/skills/plan-phase/SKILL.md §Fase. En la cabecera:
     · «Estado:» va solo en su línea, y se escribe a la vez aquí y en .ai/STATE.md §Mapa de fases.
     · «Tipo:» código | operación | validación externa (.claude/skills/plan-phase/SKILL.md §Tipos de tarea).
     · Opcionales: «> **Modo:** ligero» y «> **Tarea externa:** <ID>» (de un paquete de .ai/stages/).
     · «Contrato HTTP:» SIN CAMBIOS | CAMBIO AUTORIZADO (qué cambia, campo por campo, y su decisión de DOMAIN.md).
       Con CAMBIO AUTORIZADO, la fase deja su traspaso o la línea «> **Traspaso:** ninguno — <motivo>».
     · Un paso que hacer en producción (una variable de entorno, una orden de despliegue) lo anota el cierre en
       docs/runbooks/release.md. -->

## 1. Objetivo

<Una frase.>

## 2. Contexto que debes leer antes

<!-- Rutas concretas. .ai/RULES.md y .ai/WORKFLOW.md se leen siempre: no los listes. -->

- `sh bin/handoff.sh NN-slug FF-1`: lo que dejó la fase anterior
- `.ai/rules/<tema>.md`: cada tema de las reglas que toca la fase (`.ai/RULES.md §Reglas por tema`)
-

## 3. Entregables

<!-- 3 a 7, observables. Uno por número: nunca «A y B» en la misma línea, ni «X si Y». Si ningún gate de
     bin/verify.sh lo ve, lleva su criterio en §5 y su fila propia en §9. -->

1.
2.
3.

## 4. Archivos

### Crear

-

### Modificar

-

### Borrar

<!-- Lo que esta fase retira del repo, ligado a un entregable. -->

-

### No tocar

<!-- Sólo exclusiones de esta fase; los mínimos viven en .ai/RULES.md §Alcance. -->

-

## 5. Criterios de éxito

<!-- Cada uno es un comando, y todos se pueden cumplir a la vez; se ejecutan contra el árbol de hoy al escribirlos.
     Al cerrar, cada casilla se ejecuta tal como está escrita, su salida va a «Verificación» y se marca. Lo que sólo
     puede comprobar la persona lleva «[humano]» tras la casilla. -->

- [ ] `bash bin/verify.sh` en verde
- [ ] `npx vitest run <archivo>` cubre <comportamiento concreto>
- [ ] <un criterio por cada entregable que no vea ningún gate: el traspaso, la fila del manifiesto…>

## 6. Restricciones

<!-- Sólo las de esta fase: las generales (CLAUDE.md §Cosas que no se hacen) no se copian. -->

Sólo las generales.

## 7. Decisiones ya tomadas

<!-- Cada una con su id de .ai/DOMAIN.md o su fecha y una línea de resumen, incluidas las excepciones que autorizó
     el Tech Lead (p. ej. pasar de ~10 archivos). -->

-

## 8. Preguntas abiertas

<!-- Vacío al empezar. Formato: **Pn · AAAA-MM-DD · Paso A|B** — qué pasa · opciones · recomendación ·
     Estado: pendiente | respondida (respuesta, quién y cuándo). No se borran al resolverse. Si cruzan el alcance
     de la fase, también van a .ai/DOMAIN.md §Decisiones pendientes (.ai/WORKFLOW.md §STOP & ASK). -->

Ninguna.

## 9. Plan de commits

<!-- Una fila, un commit (.claude/skills/phase/SKILL.md §Commits durante la fase). Un entregable que ningún gate
     ve, en su fila propia. El arranque y el cierre no van aquí. -->

| # | Commit |
|---|---|
| 1 | `feat(<ámbito>): …` |

## 10. Revisión

<!-- La escribe /review (.claude/skills/review/SKILL.md). -->

Sin revisar.

---

## RESULTADO DE LA EJECUCIÓN

<!-- Se rellena al cerrar, también si la fase queda bloqueada o en rojo, sin borrar los encabezados. Las cifras se
     copian de la salida de un comando. Es el único reporte de la fase: el chat sólo lo resume. -->

**Estado final:** ⬜ HECHA ⬜ BLOQUEADA ⬜ VERIFICACION_ROJA
**Fecha:**

### Qué se hizo

<!-- Incluye los tests añadidos y, si el contrato cambió, el traspaso (fila de BACKLOG o «ninguno — motivo»). -->

### Archivos tocados realmente

<!-- `git diff --stat` desde el commit de arranque: los de verdad, no los previstos. -->

### Verificación

<!-- La salida de `bash bin/verify.sh` y la de cada criterio del §5, enteras. Una de más de 40 líneas va a
     `.ai/epics/<NN-slug>/evidence/<FF>-<nombre>.txt`, enlazada aquí con su código de salida. Si un gate falló por
     algo ajeno, cómo se comprobó que también falla en la rama base. -->

### Commits aplicados

<!-- `git log --oneline <arranque>^..HEAD`, uno por línea; el de cierre se añade al hacerlo. -->

### Divergencias documentación ↔ código

### Decisiones tomadas durante la ejecución

<!-- Las de negocio, copiadas también a .ai/DOMAIN.md. Un entregable que NO se hizo no es una decisión: es un
     criterio incumplido, y se para con STOP & ASK antes de cerrar. -->

### Hallazgos fuera de alcance

<!-- Copiados a .ai/BACKLOG.md, sin arreglarlos. -->

### Calibración

<!-- Entregables y archivos previstos frente a reales, cuánto costó y si la fase estaba bien partida
     (.claude/skills/plan-phase/SKILL.md §Reglas de corte). -->

### Qué mejorarías del protocolo

<!-- Copiado a .ai/PROTOCOL.md al cerrar. Una línea por cosa: qué estorbó y qué propones. -->

### Lo que la siguiente fase necesita saber

<!-- EL CAMPO MÁS IMPORTANTE: la próxima sesión sólo lee esto de ésta (bin/handoff.sh). En orden:
     1. Qué quedó hecho y dónde vive (nombres reales de clases, métodos y archivos).
     2. Qué quedó a medias o como deuda a propósito, con su fila de .ai/BACKLOG.md.
     3. Supuestos de la siguiente fase que ya no valen.
     4. Trampas encontradas y qué no volver a intentar. -->
