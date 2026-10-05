#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# measure-context.sh — cuánto lee cada sesión antes de empezar a trabajar.
#
# ◆ QUÉ MIDE
#   Los caracteres de los archivos del protocolo que carga cada tipo de sesión:
#     cualquiera    CLAUDE.md
#     ejecutor      CLAUDE.md, /phase, STATE, project/README, DOMAIN, RULES,
#                   WORKFLOW, BACKLOG y la plantilla de fase
#     planificador  CLAUDE.md, STATE, project/README, DOMAIN, RULES, WORKFLOW,
#                   PLANNING, BACKLOG, PROTOCOL y las dos plantillas
#     rescate       CLAUDE.md, /close, STATE, WORKFLOW y la plantilla de fase
#   Es la línea base para reducir el contexto: si un cambio del protocolo
#   mueve qué lee una sesión, la lista de abajo se cambia con él.
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
ejecutor:CLAUDE.md .claude/commands/phase.md .ai/STATE.md .ai/project/README.md .ai/DOMAIN.md .ai/RULES.md .ai/WORKFLOW.md .ai/BACKLOG.md .ai/templates/phase.template.md
planificador:CLAUDE.md .ai/STATE.md .ai/project/README.md .ai/DOMAIN.md .ai/RULES.md .ai/WORKFLOW.md .ai/PLANNING.md .ai/BACKLOG.md .ai/PROTOCOL.md .ai/templates/epic-plan.template.md .ai/templates/phase.template.md
rescate:CLAUDE.md .claude/commands/close.md .ai/STATE.md .ai/WORKFLOW.md .ai/templates/phase.template.md'

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
