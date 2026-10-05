# Épica NN — <nombre>

> **Slug:** `NN-slug`
> **Estado:** SIN_EMPEZAR

<!-- Cómo se rellena cada sección: .claude/skills/plan-epic/SKILL.md §Épica.

     Campos opcionales de la cabecera (bórralos si no aplican):
     > **Rama base:** `epic/NN-slug`        ← sólo mientras la épica está SIN_EMPEZAR
                                               (.claude/skills/plan-epic/SKILL.md §Rama base de la épica)
     > **Espejo de:** <repo hermano> <NN-slug>  ← si sigue a una épica del otro repo, y qué entrega éste antes

     El «Estado:» va solo en su línea y sin nada detrás: SIN_EMPEZAR | EN_CURSO | CERRADA. Lo mueve el ejecutor
     (.claude/skills/phase/SKILL.md §Estado de una fase, .claude/skills/phase/cierre.md §Cierre de épica). -->

## Objetivo

<Qué podrá hacer un usuario, o qué garantía tendrá el sistema, cuando esto esté terminado. En lenguaje de negocio.>

## Por qué ahora

<!-- El coste de no hacerlo, o la ventana que se cierra. -->

## Fuera de alcance

<!-- Lo que alguien podría creer razonablemente que entra. -->

-

## Contrato HTTP

<!-- SIN CAMBIOS | CAMBIO AUTORIZADO (campo por campo, con su decisión de DOMAIN.md) | REQUIERE DECISIÓN. -->

**SIN CAMBIOS**

## Decisiones ya tomadas

<!-- Sólo lo específico de la épica, con su id o su fecha; lo general vive en .ai/DOMAIN.md. -->

-

## Decisiones pendientes

<!-- Nunca una tabla propia: viven sólo en .ai/DOMAIN.md §Decisiones pendientes. Aquí, sus ids y, si aporta, la
     recomendación argumentada. -->

Ninguna.

## Fases

<!-- Reglas de corte y numeración (nunca se renumera): .claude/skills/plan-phase/SKILL.md §Reglas de corte y
     .claude/skills/plan-epic/SKILL.md §Numeración. Cada fila tiene su fila en .ai/STATE.md §Mapa de fases, en el
     mismo orden. -->

| Fase | Qué cubre | Depende de |
|---|---|---|
| 01 |  | — |
| 02 |  | 01 |

## Riesgos conocidos

<!-- Dónde esperas que la ejecución se bloquee o se equivoque. -->

-

## Criterio de cierre

<!-- Comandos que se pueden cumplir, probados contra el repo al escribirlos
     (.claude/skills/plan-phase/SKILL.md §Antes de dar el plan por listo). Lo comprueba, casilla a casilla, quien
     cierra la última fase. -->

- [ ] Todas las fases de la tabla en `HECHA`
- [ ] `bash bin/verify.sh` en verde
- [ ]
