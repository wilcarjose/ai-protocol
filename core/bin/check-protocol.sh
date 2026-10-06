#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# check-protocol.sh — en una rama de fase, el protocolo sólo cambia en commits
# de ámbito protocol.
#
# ◆ QUÉ COMPRUEBA
#   En una rama phase/<NN-slug>/<FF>, cada commit de <base>..HEAD (sin los
#   merges) que toca un archivo del protocolo lleva ámbito protocol en su
#   primera línea: «chore(protocol): …» (.ai/WORKFLOW.md §Archivos del
#   protocolo). Archivos del protocolo son los que .ai/protocol.lock marca
#   «kit» y el propio lock; lo que marca «project» (la memoria, .ai/project/ y
#   la configuración que el proyecto ajusta) es del proyecto y no se mira.
#   Fuera de una rama de fase, o fuera de un repositorio git, no aplica.
#
# ◆ LA RAMA Y SU BASE
#   La rama es GITHUB_HEAD_REF en la CI de un PR; si no, la actual. La base,
#   por orden: PROTOCOL_BASE; origin/$GITHUB_BASE_REF en la CI de un PR;
#   origin/epic/<NN-slug> o epic/<NN-slug> si existe; origin/main o main. La
#   del remoto va primero porque es la base del PR: en un worktree, la rama
#   local del checkout principal suele ir por detrás. Se compara desde su
#   merge-base con HEAD.
#
# ◆ CÓMO PROVOCAR EL FALLO
#   En una rama phase/01-demo/01, commitea un cambio de CLAUDE.md con el
#   mensaje «docs(x): …»: falla. Con «chore(protocol): …», pasa.
#
# ◆ PORTABILIDAD
#   POSIX sh, como el resto de scripts del kit: corre en busybox (Alpine), con
#   git instalado.
#
# ◆ USO
#   sh bin/check-protocol.sh       (bin/verify.sh lo corre en su gate «protocolo»)
#
# ◆ CONTRATO
#   Sale 0 si no aplica o si todo commit que toca el protocolo es de ámbito
#   protocol, y != 0 si no, o si no puede saberlo (sin git, sin lock o sin
#   base). Sólo lee el repo.
# ─────────────────────────────────────────────────────────────────────────────
set -u
export LC_ALL=C

cd "$(dirname "$0")/.." || exit 1
LOCK=.ai/protocol.lock

command -v git > /dev/null 2>&1 || { echo 'protocolo: falta git, y sin él no puedo ver los commits de la rama'; exit 1; }
if ! err=$(git rev-parse --git-dir 2>&1 > /dev/null); then
    [ -e .git ] || { echo 'protocolo: no aplica fuera de un repositorio git'; exit 0; }
    printf 'protocolo: git no puede leer el repositorio:\n%s\n' "$err"
    exit 1
fi

branch=${GITHUB_HEAD_REF:-}
[ -n "$branch" ] || branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || branch=''
case "$branch" in
    phase/*/*) ;;
    *) echo "protocolo: no aplica fuera de una rama de fase (${branch:-HEAD suelta})"; exit 0 ;;
esac
[ -f "$LOCK" ] || { echo "protocolo: falta $LOCK; sin él no sé qué archivos son del kit (lo escribe install.sh)"; exit 1; }

has_commit() { git rev-parse --verify --quiet "$1^{commit}" > /dev/null 2>&1; }
base=${PROTOCOL_BASE:-}
[ -n "$base" ] || [ -z "${GITHUB_BASE_REF:-}" ] || base=origin/$GITHUB_BASE_REF
if [ -z "$base" ]; then
    epic=epic/$(printf '%s' "$branch" | cut -d / -f 2)
    for c in "origin/$epic" "$epic" origin/main main; do
        if has_commit "$c"; then base=$c; break; fi
    done
fi
if [ -z "$base" ] || ! has_commit "$base"; then
    echo "protocolo: no encuentro la rama base (${base:-ni epic/…, ni main}); dila con PROTOCOL_BASE=<rama>"
    exit 1
fi
from=$(git merge-base "$base" HEAD) || { echo "protocolo: $branch no tiene historia en común con $base"; exit 1; }

TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT
{ awk '$1 == "file" && $2 == "kit" { print $4 }' "$LOCK"; echo "$LOCK"; } > "$TMPD/protected"

git log --no-merges --format='%H %s' "$from..HEAD" > "$TMPD/commits"
: > "$TMPD/bad"
while read -r sha subject; do
    printf '%s\n' "$subject" | grep -qE '^[a-z]+\(protocol\)!?: ' && continue
    git diff-tree --root --no-commit-id --name-only -r "$sha" | grep -xF -f "$TMPD/protected" | while read -r f; do
        printf '  %s «%s» toca %s\n' "$(printf '%s' "$sha" | cut -c 1-7)" "$subject" "$f"
    done >> "$TMPD/bad"
done < "$TMPD/commits"

n=$(grep -c . "$TMPD/commits")
if [ -s "$TMPD/bad" ]; then
    echo "protocolo: $branch cambia archivos del protocolo fuera de un commit (protocol), contra $base:"
    cat "$TMPD/bad"
    echo 'Una fase no los toca (.ai/WORKFLOW.md §Archivos del protocolo): STOP & ASK, y la propuesta a .ai/PROTOCOL.md.'
    exit 1
fi
echo "protocolo: $n commit(s) de $branch contra $base, ninguno toca el protocolo fuera de un commit (protocol)"
