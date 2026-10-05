#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# measure-context.sh — cuánto lee cada sesión antes de empezar a trabajar.
#
# ◆ QUÉ MIDE
#   Los caracteres de los archivos del protocolo que carga cada tipo de sesión
#   al arrancar:
#     cualquiera    CLAUDE.md
#     ejecutor      CLAUDE.md, la skill /phase, STATE, project/README, DOMAIN,
#                   RULES, WORKFLOW, BACKLOG y la plantilla de fase
#     cierre        lo que el ejecutor añade en el Paso C: phase/cierre.md y
#                   la skill /review
#     plan-epica    CLAUDE.md, STATE, project/README, DOMAIN, RULES, WORKFLOW,
#                   la skill /plan-epic, BACKLOG, PROTOCOL, el formato de los
#                   paquetes (stages/README) y la plantilla de épica
#     plan-fase     CLAUDE.md, STATE, project/README, DOMAIN, RULES, WORKFLOW,
#                   la skill /plan-phase, BACKLOG, PROTOCOL y la plantilla de
#                   fase
#     revisor       el subagente reviewer, RULES, WORKFLOW y lo que lee de
#                   .ai/project/ (ARCHITECTURE, CONTRACT, SENSITIVE-ZONES y
#                   DECISIONS); empieza sin CLAUDE.md ni la conversación
#     rescate       CLAUDE.md, la skill /close, phase/cierre.md, STATE,
#                   WORKFLOW y la plantilla de fase
#   No cuenta lo que la fase cita aparte (los temas de .ai/rules/, la fase
#   anterior con bin/handoff.sh), ni la fase o el paquete con que se trabaja,
#   ni el diff que lee el revisor, ni .ai/archive/, que no se lee en frío. Es la
#   línea base para reducir el contexto: si un cambio del protocolo mueve qué
#   lee una sesión, la lista de abajo se cambia con él, y la del kit en
#   tests/context-baseline.txt.
#
# ◆ CÓMO CUENTA
#   Caracteres UTF-8, no bytes, y sin depender del locale: cuenta los bytes que
#   no son de continuación (10xxxxxx). Da lo mismo que `wc -m` con un locale
#   UTF-8.
#
# ◆ USO
#   sh bin/measure-context.sh          # sobre la instalación de este script
#   sh bin/measure-context.sh <dir>    # sobre otra instalación
#
# ◆ CONTRATO
#   Sale 0 e imprime una línea por sesión; != 0 si falta algún archivo. Sólo lee.
# ─────────────────────────────────────────────────────────────────────────────
set -u

ROOT=${1:-"$(dirname "$0")/.."}
cd "$ROOT" || exit 1

SESSIONS='cualquiera:CLAUDE.md
ejecutor:CLAUDE.md .claude/skills/phase/SKILL.md .ai/STATE.md .ai/project/README.md .ai/DOMAIN.md .ai/RULES.md .ai/WORKFLOW.md .ai/BACKLOG.md .ai/templates/phase.template.md
cierre:.claude/skills/phase/cierre.md .claude/skills/review/SKILL.md
plan-epica:CLAUDE.md .ai/STATE.md .ai/project/README.md .ai/DOMAIN.md .ai/RULES.md .ai/WORKFLOW.md .claude/skills/plan-epic/SKILL.md .ai/BACKLOG.md .ai/PROTOCOL.md .ai/stages/README.md .ai/templates/epic-plan.template.md
plan-fase:CLAUDE.md .ai/STATE.md .ai/project/README.md .ai/DOMAIN.md .ai/RULES.md .ai/WORKFLOW.md .claude/skills/plan-phase/SKILL.md .ai/BACKLOG.md .ai/PROTOCOL.md .ai/templates/phase.template.md
revisor:.claude/agents/reviewer.md .ai/RULES.md .ai/WORKFLOW.md .ai/project/ARCHITECTURE.md .ai/project/CONTRACT.md .ai/project/SENSITIVE-ZONES.md .ai/project/DECISIONS.md
rescate:CLAUDE.md .claude/skills/close/SKILL.md .claude/skills/phase/cierre.md .ai/STATE.md .ai/WORKFLOW.md .ai/templates/phase.template.md'

chars() { LC_ALL=C tr -d '\200-\277' < "$1" | wc -c | tr -d ' '; }

FAIL=0
printf 'Sesión         Caracteres  Archivos\n'    # literal: printf rellena por bytes y «ó» ocupa dos
printf '%s\n' "$SESSIONS" | while IFS=: read -r name files; do
    total=0
    for f in $files; do
        [ -f "$f" ] || { printf '✗ %s: falta %s\n' "$name" "$f" >&2; exit 1; }
        total=$((total + $(chars "$f")))
    done
    printf '%-13s %10s  %s\n' "$name" "$total" "$(printf '%s' "$files" | wc -w | tr -d ' ')"
done || FAIL=1
exit "$FAIL"
