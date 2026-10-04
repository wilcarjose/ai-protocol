#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# check-kits.sh — los archivos comunes de los kits son idénticos.
#
# El protocolo es uno solo; cada kit añade lo propio de su stack. Los archivos
# de COMMON tienen que ser byte a byte iguales en todos los kits: una mejora se
# hace en uno y se copia a los demás en el mismo commit. Los demás archivos de
# cada kit son propios de su stack (README.md §Qué hay en cada kit).
#
#   sh check-kits.sh     # sale != 0 si un archivo común difiere o falta
# ─────────────────────────────────────────────────────────────────────────────
set -u
cd "$(dirname "$0")" || exit 1

KITS="laravel nextjs"
COMMON="
CLAUDE.md
AGENTS.md
.ai/WORKFLOW.md
.ai/PLANNING.md
.ai/STATE.md
.ai/DOMAIN.md
.ai/BACKLOG.md
.ai/PROTOCOL.md
.ai/handoffs/README.md
.ai/epics/.gitkeep
.claude/commands/phase.md
.claude/commands/close.md
bin/check-docs.sh
docs/runbooks/release.md
"

FAIL=0
first=${KITS%% *}
for f in $COMMON; do
    for k in $KITS; do
        [ -f "$k/$f" ] || { printf '✗ falta %s/%s\n' "$k" "$f"; FAIL=1; continue; }
        [ "$k" = "$first" ] && continue
        cmp -s "$first/$f" "$k/$f" || { printf '✗ %s difiere entre %s y %s\n' "$f" "$first" "$k"; FAIL=1; }
    done
done

for k in $KITS; do
    printf '◆ %s — propios del stack:\n' "$k"
    ( cd "$k" && find . -type f | sed 's#^\./##' | sort ) | while read -r f; do
        printf '%s\n' "$COMMON" | grep -qxF "$f" || printf '    %s\n' "$f"
    done
done

if [ "$FAIL" -eq 0 ]; then echo '✓ los archivos comunes son idénticos en todos los kits'; fi
exit "$FAIL"
