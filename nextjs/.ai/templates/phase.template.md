# Fase FF — <título corto en imperativo>

> **Épica:** `NN-slug` · **Depende de:** — | fase FF-1
> **Estado:** LISTA_PARA_EJECUTAR
> **Contrato HTTP:** SIN CAMBIOS

<!-- Cómo se rellena cada sección: .ai/PLANNING.md §3.

     Cabecera:
     · «Estado:» va solo en su línea y se escribe a la vez aquí y en .ai/STATE.md §Mapa de fases
       (CLAUDE.md §Estado de una fase).
     · «Contrato HTTP:» SIN CAMBIOS | CAMBIO AUTORIZADO (qué cambia, campo por campo, y su decisión de DOMAIN.md).
       Con CAMBIO AUTORIZADO, la fase deja su traspaso como entregable propio (CLAUDE.md §El otro repositorio) o
       añade la línea «> **Traspaso:** ninguno — <motivo>». bin/check-docs.sh lo comprueba al cerrar.
     · Si la fase deja un paso que hacer en producción (una variable de entorno, una orden de despliegue), el cierre lo
       anota en docs/runbooks/release.md (CLAUDE.md §Cierre de fase). -->

## 1. Objetivo

<Una frase.>

## 2. Contexto que debes leer antes

<!-- Rutas concretas. .ai/RULES.md y .ai/WORKFLOW.md se leen siempre: no los listes. -->

- `.ai/epics/<NN-slug>/phase-<FF-1>.md` → «Lo que la siguiente fase necesita saber»
-

## 3. Entregables

<!-- 3 a 7, observables. Un entregable por número: nunca «A y B» en la misma línea, y nunca «X si Y».
     Si un entregable no lo ve ningún gate de bin/verify.sh, dale su criterio en §5 y su fila propia en §9,
     o no se hará (.ai/PLANNING.md §3.2). -->

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

<!-- Cada uno es un comando, y todos se pueden cumplir a la vez. Ejecútalos contra el árbol de hoy al
     escribirlos (.ai/PLANNING.md §5). Al cerrar, cada casilla se ejecuta tal como está escrita, su salida se
     pega en «Verificación» y se marca (.ai/WORKFLOW.md §2.10). -->

- [ ] `bash bin/verify.sh` en verde
- [ ] `npx vitest run <archivo>` cubre <comportamiento concreto>
- [ ] <un criterio por cada entregable que no vea ningún gate: el traspaso, la fila del manifiesto…>

## 6. Restricciones

<!-- Sólo las de esta fase: las generales viven en `CLAUDE.md §Cosas que no se hacen` y no se copian.
     Si no hay ninguna: «Sólo las generales». -->

Sólo las generales.

## 7. Decisiones ya tomadas

<!-- Cada una con su id de .ai/DOMAIN.md o su fecha y una línea de resumen. Incluye las excepciones que
     autorizó el Tech Lead (p. ej. pasar de ~10 archivos). -->

-

## 8. Preguntas abiertas

<!-- Vacío al empezar. Si te bloqueas, aquí va el bloque STOP & ASK completo (.ai/WORKFLOW.md §3).
     Formato de cada pregunta: **Pn · AAAA-MM-DD · Paso A|B** — qué pasa · opciones · recomendación ·
     Estado: pendiente | respondida (respuesta, quién y cuándo).
     No se borran al resolverse: son el porqué de las decisiones de la fase. Si cruzan su alcance, también van
     a .ai/DOMAIN.md §Decisiones pendientes (regla de traza). -->

Ninguna.

## 9. Plan de commits

<!-- Cada fila es un commit que la IA hace ella misma durante la fase (CLAUDE.md §Commits durante la fase).
     Una fila puede cubrir varios entregables relacionados; un entregable que ningún gate ve, en su fila
     propia. Los commits de arranque y cierre no van aquí. -->

| # | Commit |
|---|---|
| 1 | `feat(<ámbito>): …` |

---

## RESULTADO DE LA EJECUCIÓN

<!-- Se rellena al cerrar, también si la fase queda bloqueada o en rojo. No borres los encabezados.
     Las cifras se copian de la salida de un comando, no de memoria. -->

**Estado final:** ⬜ HECHA ⬜ BLOQUEADA ⬜ VERIFICACION_ROJA
**Fecha:**

### Qué se hizo

### Archivos tocados realmente

<!-- `git diff --stat` desde el commit de arranque: los de verdad, no los previstos. La diferencia es información. -->

### Verificación

<!-- La salida de `bash bin/verify.sh` y la de cada criterio del §5, enteras. Si algo quedó rojo, los fallos
     concretos; si un gate falló por algo ajeno, cómo se comprobó que también falla en la rama base. -->

### Commits aplicados

<!-- `git log --oneline <arranque>^..HEAD`, uno por línea; el de cierre se añade al hacerlo. -->

### Divergencias documentación ↔ código

<!-- .ai/WORKFLOW.md §1: lo que un documento decía y el código no cumple. -->

### Decisiones tomadas durante la ejecución

<!-- Las de negocio, copiadas también a .ai/DOMAIN.md.
     Un entregable de §3 que NO se hizo no es una decisión de ejecución y no va aquí: es un criterio incumplido.
     O se hace, o se para con STOP & ASK antes de cerrar. Justificarlo aquí deja la fase HECHA con trabajo sin
     hacer. -->

### Hallazgos fuera de alcance

<!-- Copiados a .ai/BACKLOG.md, sin arreglarlos. -->

### Calibración

<!-- Para afinar las reglas de corte de .ai/PLANNING.md §3.1: entregables y archivos previstos frente a reales,
     cuánto costó, y si la fase estaba partida por donde tocaba. -->

### Qué mejorarías del protocolo

<!-- Copiado a .ai/PROTOCOL.md al cerrar. Una línea por cosa: qué estorbó y qué propones. -->

### Lo que la siguiente fase necesita saber

<!-- EL CAMPO MÁS IMPORTANTE. La próxima sesión empieza sin memoria y es lo único que leerá de ésta. En orden:
     1. Qué quedó hecho y dónde vive (nombres reales de clases, métodos y archivos).
     2. Qué quedó a medias o como deuda a propósito, con su fila de .ai/BACKLOG.md.
     3. Supuestos de la siguiente fase que ya no valen.
     4. Trampas encontradas y qué no volver a intentar. -->
