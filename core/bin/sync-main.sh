#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# sync-main.sh — después de fusionar un PR, el repo en su rama base al día.
#
# ◆ QUÉ HACE
#   1. Comprueba que se puede: nada sin commitear en lo versionado, y trae
#      origin (git fetch --prune).
#   2. Busca el PR: el número que se le pasa o el de la rama actual. En main
#      sin número no hay PR: sólo la pone al día.
#   3. Si el PR sigue abierto, con --wait espera a que se fusione (la CI y el
#      merge, que lo decide la persona); sin --wait, dice cómo está y termina.
#      Para si la CI falla o si el PR se cierra sin fusionar.
#   4. Fusionado: cambia a su rama base (main o la de la épica), la avanza a la
#      de origin sólo en línea recta (si tiene commits que origin no, para) y
#      borra la rama local del PR si no tiene nada que el PR no llevara.
#   5. Dice en qué commit queda y, si hay .ai/STATE.md, la fase activa.
#
# ◆ USO
#   sh bin/sync-main.sh                    la rama actual, si su PR ya se fusionó
#   sh bin/sync-main.sh --wait [<min>]     espera a que se fusione (30 min)
#   sh bin/sync-main.sh <PR> [--wait]      ese PR, desde cualquier rama
#
# ◆ HERRAMIENTAS
#   git, y gh autenticado con acceso al repo (sin gh, sólo en main sin PR).
#
# ◆ CONTRATO
#   Sale 0 si la rama base queda activa y al día con origin; 3 si el PR sigue
#   sin fusionar (sin --wait, o se acabó la espera), sin tocar nada; 1 si hace
#   falta la persona: cambios sin commitear, la CI en rojo, el PR cerrado sin
#   fusionar o una rama base que no avanza en línea recta; 2 si el uso está mal.
#   No fusiona nada ni empuja nada.
# ─────────────────────────────────────────────────────────────────────────────
set -u
export LC_ALL=C

die() { printf '✗ sync-main: %s\n' "$1" >&2; exit 1; }
usage() {
    sed -n 's/^#   \(sh bin\/sync-main\.sh .*\)/\1/p' "$0" >&2
    exit 2
}

PR=''
WAIT=-1
while [ $# -gt 0 ]; do
    case "$1" in
        --wait) WAIT=30; shift
                case "${1:-}" in ''|*[!0-9]*) ;; *) WAIT=$1; shift ;; esac ;;
        -*) usage ;;
        *[!0-9]*|'') usage ;;
        *) [ -z "$PR" ] || usage; PR=$1; shift ;;
    esac
done
POLL=${SYNC_MAIN_POLL:-20}

command -v git > /dev/null 2>&1 || die 'falta git'
ROOT=$(git rev-parse --show-toplevel 2> /dev/null) || die 'no estás en un repo git'
cd "$ROOT" || exit 1

# ── 1. Se puede empezar ─────────────────────────────────────────────────────
[ -z "$(git status --porcelain --untracked-files=no)" ] \
    || die 'hay cambios sin commitear: commitéalos o guárdalos antes de cambiar de rama'
branch=$(git rev-parse --abbrev-ref HEAD)
[ "$branch" != HEAD ] || die 'no estás en ninguna rama (HEAD suelto)'
git fetch -q --prune origin || die 'no pude traer origin (git fetch)'

# ── 2. El PR ────────────────────────────────────────────────────────────────
# pr_field <campo>: un campo de texto del PR, de la última consulta.
pr_field() { sed -n "s/^$1=//p" "$INFO"; }
INFO=$(mktemp) || exit 1
trap 'rm -f "$INFO"' EXIT
pr_read() {
    gh pr view "$1" --json number,state,baseRefName,headRefName,headRefOid,url \
        --template '{{printf "number=%v\nstate=%s\nbase=%s\nhead=%s\nsha=%s\nurl=%s\n" .number .state .baseRefName .headRefName .headRefOid .url}}' \
        > "$INFO" 2> /dev/null
}

has_gh=0
command -v gh > /dev/null 2>&1 && has_gh=1
if [ -n "$PR" ]; then
    [ "$has_gh" -eq 1 ] || die 'falta gh para leer el PR'
    pr_read "$PR" || die "no encuentro el PR #$PR"
elif [ "$branch" = main ]; then
    [ "$WAIT" -lt 0 ] || { printf '✗ sync-main: en main, --wait necesita el número del PR\n' >&2; usage; }
    : > "$INFO"
else
    [ "$has_gh" -eq 1 ] || die "falta gh para saber si se fusionó el PR de «$branch»"
    pr_read "$branch" || die "«$branch» no tiene PR: no sé a qué rama volver (git switch main)"
fi
num=$(pr_field number)

# ── 3. Fusionado, o la espera ───────────────────────────────────────────────
if [ -n "$num" ]; then
    url=$(pr_field url)
    state=$(pr_field state)
    if [ "$state" = OPEN ]; then
        if [ "$WAIT" -lt 0 ]; then
            gh pr checks "$num" > /dev/null 2>&1; ci=$?
            case $ci in 0) ci='en verde' ;; 8) ci='en marcha' ;; *) ci='en rojo o sin CI' ;; esac
            printf '… sync-main: el PR #%s sigue sin fusionar (CI %s): %s\n' "$num" "$ci" "$url"
            printf '  Cuando lo fusiones, vuelve a lanzarlo, o con --wait para que espere.\n'
            exit 3
        fi
        printf '◆ sync-main: espero hasta %s min a que se fusione el PR #%s: %s\n' "$WAIT" "$num" "$url"
        end=$(( $(date +%s) + WAIT * 60 ))
        said=''
        while [ "$state" = OPEN ]; do
            [ "$(date +%s)" -lt "$end" ] || {
                printf '… sync-main: el PR #%s sigue sin fusionar tras %s min: vuelve a lanzarlo cuando lo fusiones.\n' "$num" "$WAIT"
                exit 3
            }
            out=$(gh pr checks "$num" 2>&1); ci=$?
            if [ "$ci" -eq 1 ] && ! printf '%s\n' "$out" | grep -qi 'no checks'; then
                printf '%s\n' "$out" | grep -iw 'fail' | sed 's/^/  │ /'
                die "la CI del PR #$num falla: así no se fusiona ($url)"
            fi
            if [ "$ci" -eq 0 ] && [ -z "$said" ]; then
                printf '  CI en verde: falta que lo fusiones.\n'
                said=1
            fi
            sleep "$POLL"
            pr_read "$num" || die "no pude volver a leer el PR #$num"
            state=$(pr_field state)
        done
    fi
    [ "$state" = MERGED ] || die "el PR #$num se cerró sin fusionar: la rama se queda como está ($url)"
    base=$(pr_field base)
    head=$(pr_field head)
    sha=$(pr_field sha)
    git fetch -q --prune origin || die 'no pude traer origin (git fetch)'
else
    base=main
fi

# ── 4. La rama base, al día ─────────────────────────────────────────────────
git rev-parse -q --verify "origin/$base" > /dev/null || die "origin no tiene «$base»"
# Antes de cambiar de rama: si la base local no avanza en línea recta, el repo se queda donde está.
if git rev-parse -q --verify "refs/heads/$base" > /dev/null; then
    git merge-base --is-ancestor "refs/heads/$base" "origin/$base" \
        || die "«$base» tiene commits que origin no tiene: no avanza en línea recta; para y pregunta"
fi
if [ "$branch" != "$base" ]; then
    git switch -q "$base" 2> /dev/null || die "no pude cambiar a «$base»"
fi
git merge -q --ff-only "origin/$base" > /dev/null || die "no pude avanzar «$base» a origin/$base"

# La rama del PR se borra sólo si no tiene nada que el PR no llevara: su punta es la del PR o una anterior.
gone=''
kept=''
if [ -n "$num" ] && [ "$head" != "$base" ] && git rev-parse -q --verify "refs/heads/$head" > /dev/null; then
    git fetch -q origin "pull/$num/head" 2> /dev/null
    if git cat-file -e "$sha^{commit}" 2> /dev/null && git merge-base --is-ancestor "refs/heads/$head" "$sha"; then
        git branch -q -D "$head" && gone=$head
    else
        kept=$head
    fi
fi

# ── 5. Dónde queda ──────────────────────────────────────────────────────────
printf '✓ sync-main: %s en %s, al día con origin' "$base" "$(git rev-parse --short HEAD)"
[ -z "$num" ] || printf ' (PR #%s fusionado)' "$num"
printf '\n'
[ -z "$gone" ] || printf '  Borrada la rama local «%s».\n' "$gone"
[ -z "$kept" ] || printf '  La rama «%s» se queda: tiene commits que el PR no llevó.\n' "$kept"
if [ -f .ai/STATE.md ]; then
    active=$(sed -n 's/^- \*\*Fase activa:\*\* //p' .ai/STATE.md | head -n 1)
    case $active in ''|—*) ;; *) printf '  Fase activa: %s (/phase)\n' "$active" ;; esac
fi
exit 0
