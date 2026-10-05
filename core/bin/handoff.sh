#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# handoff.sh — lo que una fase dejó dicho para la siguiente.
#
# ◆ QUÉ HACE
#   Imprime sólo la sección «### Lo que la siguiente fase necesita saber» del
#   RESULTADO de .ai/epics/<NN-slug>/phase-<FF>.md, sin los comentarios de la
#   plantilla. Es lo que lee el Paso A de la fase siguiente
#   (.claude/skills/phase/SKILL.md §Paso A — Orientación), en vez del archivo
#   entero de la fase anterior.
#
# ◆ USO
#   sh bin/handoff.sh <NN-slug> <FF>     # p. ej. sh bin/handoff.sh 01-auth 02
#
# ◆ CONTRATO
#   Sale 0 e imprime la sección; != 0 si la fase no existe o la sección está
#   vacía (la fase no se ha cerrado). Sólo lee.
# ─────────────────────────────────────────────────────────────────────────────
set -u
export LC_ALL=C

[ $# -eq 2 ] || { echo 'uso: sh bin/handoff.sh <NN-slug> <FF>' >&2; exit 2; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)
f="$ROOT/.ai/epics/$1/phase-$2.md"
[ -f "$f" ] || { printf '✗ handoff: no existe .ai/epics/%s/phase-%s.md\n' "$1" "$2" >&2; exit 1; }

# La sección, sin los comentarios HTML (de una línea o de varias) y sin las líneas en blanco de los extremos.
out=$(awk '
    index($0, "### Lo que la siguiente fase necesita saber") == 1 { f = 1; next }
    f && /^#{1,3} / { exit }
    f { print }' "$f" \
    | awk '
        { line = $0 }
        c { e = index(line, "-->"); if (e == 0) next; line = substr(line, e + 3); c = 0 }
        {
            while ((s = index(line, "<!--")) > 0) {
                rest = substr(line, s + 4); e = index(rest, "-->")
                if (e > 0) { line = substr(line, 1, s - 1) substr(rest, e + 3) }
                else       { line = substr(line, 1, s - 1); c = 1; break }
            }
            print line
        }' \
    | awk 'NF { started = 1 } started { buf = buf $0 "\n"; if (NF) { printf "%s", buf; buf = "" } }')

[ -n "$out" ] || { printf '✗ handoff: la fase %s/%s no tiene «Lo que la siguiente fase necesita saber» (¿no se ha cerrado?)\n' "$1" "$2" >&2; exit 1; }
printf '%s\n' "$out"
