#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# protocol-upgrade.sh — el protocolo del proyecto, a la última versión del kit.
#
# ◆ QUÉ HACE
#   1. Comprueba que se puede: el árbol limpio, en main, main al día con
#      origin (git pull --ff-only; si no avanza en línea recta, para) y
#      ninguna fase EN_CURSO ni BLOQUEADA en .ai/STATE.md: el upgrade va entre
#      fases.
#   2. Trae el kit: lo clona de GitHub (AI_PROTOCOL_REPO, la rama por defecto
#      o --ref) en un directorio temporal, o usa la copia local de
#      AI_PROTOCOL_DIR. Si la copia de este script que trae el kit es otra, le
#      pasa el control: el upgrade lo hace siempre la versión nueva.
#   3. Compara las versiones con .ai/protocol.lock. Si son las mismas, termina.
#      El kit tiene que estar publicado (sin -dev) y no ser más viejo. Imprime
#      lo que cada versión nueva pide al proyecto («Al actualizar un proyecto»
#      de su CHANGELOG.md), que el upgrade no hace.
#   4. `install.sh --upgrade --dry-run` del kit: con un conflicto, para sin
#      tocar nada y enseña el diff.
#   5. En la rama protocol/upgrade-core-X.Y.Z-<stack>-X.Y.Z: el upgrade; las
#      filas de .ai/PROTOCOL.md que resuelve, marcadas «aplicada — kit core
#      X.Y.Z + <stack> X.Y.Z» y pasadas enteras a .ai/archive/PROTOCOL.md; el
#      guardián (bin/check-docs.sh --strict); el commit
#      `chore(protocol): upgrade ai-protocol to core X.Y.Z + <stack> X.Y.Z`;
#      el push y el PR a main.
#   6. Espera a la CI del PR y, si pasa, lo fusiona (squash) y deja main
#      activa y al día con origin. No lo fusiona, y lo deja para la persona,
#      si la versión es mayor (obliga a cambiar el proyecto: su CHANGELOG.md,
#      «Al actualizar un proyecto»), si PROTOCOL_AUTO_MERGE no lo permite, con
#      --no-merge, si la CI falla o si el PR no tiene CI.
#
# ◆ USO
#   sh bin/protocol-upgrade.sh                  hasta main fusionado
#   sh bin/protocol-upgrade.sh --dry-run        qué haría, sin escribir nada
#   sh bin/protocol-upgrade.sh --no-merge       deja el PR para revisarlo
#   sh bin/protocol-upgrade.sh --ref <etiqueta> una versión concreta del kit
#   AI_PROTOCOL_DIR=<copia del kit> sh bin/protocol-upgrade.sh   sin red
#   AI_PROTOCOL_REPO=<dueño>/<repo> sh bin/protocol-upgrade.sh   otro kit
#
# ◆ CONFIGURACIÓN DEL PROYECTO
#   PROTOCOL_AUTO_MERGE en .ai/project/verify.conf (o en el entorno, que gana):
#   minor (por defecto: fusiona las versiones menores y los parches), patch
#   (sólo los parches) o never.
#
# ◆ HERRAMIENTAS
#   git, y gh autenticado con acceso al repo del kit y al del proyecto.
#
# ◆ CONTRATO
#   Sale 0 si el proyecto ya estaba al día, si el upgrade queda fusionado o si
#   el PR queda abierto a propósito (versión mayor, PROTOCOL_AUTO_MERGE o
#   --no-merge); != 0 si hace falta la persona: no se puede empezar, hay un
#   conflicto, el guardián falla tras el upgrade (la rama queda sin
#   commitear), la CI falla o no hay CI. Termina en main salvo en el caso del
#   guardián.
# ─────────────────────────────────────────────────────────────────────────────
set -u
export LC_ALL=C

die() { printf '✗ protocol-upgrade: %s\n' "$1" >&2; exit 1; }
usage() {
    sed -n 's/^#   \(sh bin\/protocol-upgrade\.sh .*\)/\1/p' "$0" >&2
    exit 2
}

REF=''
DRY=0
MERGE=1
while [ $# -gt 0 ]; do
    case "$1" in
        --ref)      [ $# -ge 2 ] || usage; REF=$2; shift 2 ;;
        --dry-run)  DRY=1; shift ;;
        --no-merge) MERGE=0; shift ;;
        *) usage ;;
    esac
done

REPO=${AI_PROTOCOL_REPO:-wilcarjose/ai-protocol}
ROOT=${PROTOCOL_UPGRADE_TARGET:-$(cd "$(dirname "$0")/.." && pwd)}
cd "$ROOT" || exit 1
LOCK=.ai/protocol.lock
TMPD=${PROTOCOL_UPGRADE_TMP:-$(mktemp -d)}
trap 'rm -rf "$TMPD"' EXIT

# json_str <archivo> <clave>: el valor de una clave de texto («"clave": "valor"» en su línea).
json_str() { sed -n "s/^ *\"$2\": *\"\\(.*\\)\",\\{0,1\\} *\$/\\1/p" "$1" | head -n 1; }
# locked <paquete>: su versión en el lock.
locked() { awk -v p="$1" '$1 == "package" && $2 == p { print $3; exit }' "$LOCK"; }

# level <antes> <ahora>: major, minor, patch, same u older.
level() {
    a=${1%%-*}; b=${2%%-*}
    am=${a%%.*}; bm=${b%%.*}; a=${a#*.}; b=${b#*.}
    an=${a%%.*}; bn=${b%%.*}; ap=${a#*.}; bp=${b#*.}
    if [ "$bm" -ne "$am" ]; then [ "$bm" -gt "$am" ] && echo major || echo older
    elif [ "$bn" -ne "$an" ]; then [ "$bn" -gt "$an" ] && echo minor || echo older
    elif [ "$bp" -ne "$ap" ]; then [ "$bp" -gt "$ap" ] && echo patch || echo older
    else echo same; fi
}

# to_main: de vuelta a main, al día con origin.
to_main() {
    git switch -q main 2> /dev/null || return 1
    git pull -q --ff-only 2> /dev/null || return 1
    [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ]
}

# ── 1. Se puede empezar ─────────────────────────────────────────────────────
[ -f "$LOCK" ] || die "no hay $LOCK: el protocolo no está instalado con install.sh"
command -v git > /dev/null 2>&1 || die 'falta git'
[ -z "$(git status --porcelain)" ] || die 'el árbol no está limpio: commitea o guarda los cambios antes'
branch=$(git rev-parse --abbrev-ref HEAD)
[ "$branch" = main ] || die "estás en «$branch»: el upgrade sale de main (git switch main)"
git fetch -q origin || die 'no pude traer origin (git fetch)'
git rev-parse -q --verify origin/main > /dev/null || die 'origin no tiene main'
git merge-base --is-ancestor HEAD origin/main \
    || die 'main tiene commits que origin no tiene: no avanza en línea recta; para y pregunta'
if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
    if [ "$DRY" -eq 1 ]; then echo '  (main va por detrás de origin: el upgrade de verdad lo trae primero)'
    else git pull -q --ff-only || die 'git pull --ff-only falla'; fi
fi
busy=$(awk -F'|' '/^\|/ { s = $4; gsub(/^ +| +$/, "", s)
           if (s == "EN_CURSO" || s == "BLOQUEADA") { e = $2 "/" $3; gsub(/ /, "", e); printf "%s ", e } }' .ai/STATE.md)
[ -z "$busy" ] || die "hay fases a medias (${busy% }): el upgrade va entre fases, con ninguna EN_CURSO ni BLOQUEADA"

# ── 2. El kit ───────────────────────────────────────────────────────────────
if [ -n "${AI_PROTOCOL_DIR:-}" ]; then
    [ -z "$REF" ] || die '--ref no va con AI_PROTOCOL_DIR: esa copia del kit se usa tal como está'
    KIT=$(cd "$AI_PROTOCOL_DIR" 2> /dev/null && pwd) || die "AI_PROTOCOL_DIR no existe: $AI_PROTOCOL_DIR"
    FROM=${PROTOCOL_UPGRADE_FROM:-$KIT}
else
    KIT=$TMPD/kit
    if [ -n "$REF" ]; then set -- --branch "$REF"; else set --; fi
    if command -v gh > /dev/null 2>&1; then
        gh repo clone "$REPO" "$KIT" -- --quiet --depth 1 "$@" > "$TMPD/clone.log" 2>&1
    else
        git clone --quiet --depth 1 "$@" "https://github.com/$REPO.git" "$KIT" > "$TMPD/clone.log" 2>&1
    fi || { sed 's/^/  │ /' "$TMPD/clone.log"; die "no pude descargar el kit $REPO${REF:+ en $REF}"; }
    FROM="$REPO${REF:+@$REF} ($(git -C "$KIT" rev-parse --short HEAD))"
fi
[ -f "$KIT/install.sh" ] && [ -f "$KIT/core/core.json" ] || die "$FROM no es el kit ai-protocol"

# La versión nueva de este script hace el upgrade: el de ahora puede no saber lo que pide el kit, y el upgrade lo
# reescribe mientras corre.
self=$KIT/core/bin/protocol-upgrade.sh
if [ -z "${PROTOCOL_UPGRADE_DELEGATED:-}" ] && [ -f "$self" ] && ! cmp -s "$self" "$0"; then
    trap - EXIT
    set --
    [ "$DRY" -eq 1 ] && set -- "$@" --dry-run
    [ "$MERGE" -eq 0 ] && set -- "$@" --no-merge
    PROTOCOL_UPGRADE_DELEGATED=1 PROTOCOL_UPGRADE_TARGET="$ROOT" PROTOCOL_UPGRADE_TMP="$TMPD" \
        PROTOCOL_UPGRADE_FROM="$FROM" AI_PROTOCOL_DIR="$KIT" exec sh "$self" "$@"
fi

# ── 3. Las versiones ────────────────────────────────────────────────────────
STACK=$(awk '$1 == "package" && $2 != "core" { print $2; exit }' "$LOCK")
[ -n "$STACK" ] || die "$LOCK no dice qué stack hay instalado"
was_core=$(locked core); was_stack=$(locked "$STACK")
now_core=$(json_str "$KIT/core/core.json" version)
[ -f "$KIT/stacks/$STACK/stack.json" ] || die "el kit de $FROM no trae el stack $STACK"
now_stack=$(json_str "$KIT/stacks/$STACK/stack.json" version)
case "$now_core $now_stack" in
    *-*) die "el kit de $FROM no está publicado (core $now_core, $STACK $now_stack): usa main o una etiqueta" ;;
esac
lc=$(level "$was_core" "$now_core"); ls=$(level "$was_stack" "$now_stack")
case "$lc $ls" in *older*) die "el kit de $FROM (core $now_core + $STACK $now_stack) es más viejo que el lock (core $was_core + $STACK $was_stack)" ;; esac
if [ "$lc $ls" = 'same same' ]; then
    echo "✓ al día: core $now_core + $STACK $now_stack ($FROM)"
    exit 0
fi
case "$lc $ls" in *major*) lvl='major' ;; *minor*) lvl='minor' ;; *) lvl='patch' ;; esac
echo "◆ protocol-upgrade: core $was_core → $now_core + $STACK $was_stack → $now_stack ($lvl), desde $FROM"
# Lo que cada versión nueva pide al proyecto («### Al actualizar un proyecto» de su CHANGELOG.md): el upgrade no lo
# hace, y en el PR, que se fusiona solo, nadie lo lee. Se dice aquí para que se planifique.
for p in "core $was_core" "stacks/$STACK $was_stack"; do
    # shellcheck disable=SC2086  # «carpeta versión», partido a propósito
    set -- $p
    awk -v was="$2" -v pkg="${1#stacks/}" '
        index($0, "## [" was "]") == 1 { exit }
        /^## \[/ { v = $2; gsub(/\[|\]/, "", v); f = 0; next }
        /^### / { f = ($0 == "### Al actualizar un proyecto"); if (f) print "  " pkg " " v ":"; next }
        f && NF { print "    " $0 }' "$KIT/$1/CHANGELOG.md"
done > "$TMPD/todo"
if [ -s "$TMPD/todo" ]; then
    echo "◆ al actualizar un proyecto (lo que el upgrade no hace; si es trabajo del proyecto, se planifica):"
    cat "$TMPD/todo"
fi

policy=$(sed -n 's/^PROTOCOL_AUTO_MERGE=\([a-z]*\).*/\1/p' .ai/project/verify.conf 2> /dev/null | tail -n 1)
policy=${PROTOCOL_AUTO_MERGE:-${policy:-minor}}
case "$policy" in minor|patch|never) ;; *) die "PROTOCOL_AUTO_MERGE=«$policy»: vale minor, patch o never" ;; esac
hold=''
if [ "$MERGE" -eq 0 ]; then hold='--no-merge'
elif [ "$lvl" = major ]; then hold='versión mayor: revisa «Al actualizar un proyecto» en el CHANGELOG.md de cada paquete'
elif [ "$policy" = never ]; then hold='PROTOCOL_AUTO_MERGE=never'
elif [ "$policy" = patch ] && [ "$lvl" != patch ]; then hold='PROTOCOL_AUTO_MERGE=patch y la versión es menor'
fi

# ── 4. Sin conflictos ───────────────────────────────────────────────────────
sh "$KIT/install.sh" --upgrade --target "$ROOT" --dry-run > "$TMPD/dry.log" 2>&1 \
    || { sed 's/^/  │ /' "$TMPD/dry.log"; die 'install.sh --upgrade --dry-run falla'; }
B="protocol/upgrade-core-$now_core-$STACK-$now_stack"
conflicts=$(grep -c '^  ! ' "$TMPD/dry.log")
if [ "$DRY" -eq 1 ] || [ "$conflicts" -gt 0 ]; then
    cat "$TMPD/dry.log"
    [ "$conflicts" -eq 0 ] || die "$conflicts conflicto(s): el proyecto cambió archivos del kit. Lo propio va a .ai/project/; después, borra el archivo y vuelve a lanzarlo (README del kit, §Actualizar un proyecto)"
    echo "  Haría la rama $B, archivaría las filas que resuelve, el commit y el PR,"
    if [ -n "$hold" ]; then echo "  sin fusionarlo: $hold."
    else echo "  y lo fusionaría con la CI en verde."; fi
    exit 0
fi

# ── 5. El upgrade, en su rama ───────────────────────────────────────────────
git rev-parse -q --verify "refs/heads/$B" > /dev/null && die "ya existe la rama $B: bórrala o termina ese upgrade"
git ls-remote --exit-code --heads origin "$B" > /dev/null 2>&1 \
    && die "origin ya tiene $B: un upgrade anterior sin fusionar"
git switch -q -c "$B" || die "no pude crear la rama $B"
sh "$KIT/install.sh" --upgrade --target "$ROOT" > "$TMPD/up.log" 2>&1 \
    || { sed 's/^/  │ /' "$TMPD/up.log"; die "install.sh --upgrade falla; la rama $B queda como esté"; }
grep -E '^  [~+!=·-] |^✓' "$TMPD/up.log"

# Las filas que resuelve la versión, de la lista con la que termina install.sh: «#id  enviada — <kit>#N».
awk '/^  Filas de \.ai\/PROTOCOL\.md que resuelve/ { f = 1; next }
     f && /^    #[0-9]+  enviada — / { sub(/^ +/, ""); print }' "$TMPD/up.log" > "$TMPD/resolved"
ids=$(sed 's/^#\([0-9]*\) .*/\1/' "$TMPD/resolved" | tr '\n' ' ')
mark="aplicada — kit core $now_core + $STACK $now_stack"
: > "$TMPD/archived"
if [ -n "$ids" ]; then
    awk -v ids=" $ids" -v mark="$mark" -v out="$TMPD/archived" '
        /^\| *[0-9]+ *\|/ { id = $0; sub(/^\| */, "", id); sub(/ *\|.*/, "", id)
            if (index(ids, " " id " ")) { sub(/\|[^|]*\|[ \t]*$/, "| " mark " |"); print > out; next } }
        { print }' .ai/PROTOCOL.md > "$TMPD/protocol"
    awk -v rows="$TMPD/archived" '{ print }
        !d && /^\|[-| :]+\|[ \t]*$/ { while ((getline l < rows) > 0) print l; d = 1 }
        END { exit !d }' .ai/archive/PROTOCOL.md > "$TMPD/archive" \
        || die "$B: .ai/archive/PROTOCOL.md no tiene la tabla donde archivar las filas $ids"
    cp "$TMPD/protocol" .ai/PROTOCOL.md && cp "$TMPD/archive" .ai/archive/PROTOCOL.md
    echo "  Filas de .ai/PROTOCOL.md archivadas como «$mark»: #$(printf '%s' "${ids% }" | sed 's/ /, #/g')"
fi

sh bin/check-docs.sh --strict > "$TMPD/docs.log" 2>&1 \
    || { tail -n 30 "$TMPD/docs.log" | sed 's/^/  │ /'; die "el guardián falla tras el upgrade: la rama $B queda sin commitear para arreglarlo"; }

title="chore(protocol): upgrade ai-protocol to core $now_core + $STACK $now_stack"
{
    printf '%s\n\nFrom core %s + %s %s, with the kit from %s.\n' "$title" "$was_core" "$STACK" "$was_stack" "$FROM"
    if [ -s "$TMPD/archived" ]; then
        printf '\nRows of .ai/PROTOCOL.md this version applies, now archived:\n'
        sed 's/^\(#[0-9]*\)  enviada — \(.*\)$/- \1 (\2)/' "$TMPD/resolved"
    fi
} > "$TMPD/msg"
git add -A || die "no pude preparar el commit en $B"
git commit -q -F "$TMPD/msg" || die "no pude commitear en $B"
git push -q -u origin "$B" > "$TMPD/push.log" 2>&1 \
    || { sed 's/^/  │ /' "$TMPD/push.log"; die "no pude empujar $B; el commit queda en local"; }

# El cuerpo del PR: las versiones, lo que cambia, las filas archivadas y la fusión.
# shellcheck disable=SC2016  # las comillas invertidas son las del Markdown
{
    printf 'Upgrade del protocolo: **core %s → %s** y **%s %s → %s** (%s), con el kit de %s. Lo ha hecho `bin/protocol-upgrade.sh`.\n\n' \
        "$was_core" "$now_core" "$STACK" "$was_stack" "$now_stack" "$lvl" "$FROM"
    printf '## Archivos\n\n'
    grep -E '^  [~+!-] ' "$TMPD/up.log" | sed 's/^  \(.\) \([^ ]*\) *\(.*\)$/- `\2`: \3/'
    if [ -s "$TMPD/archived" ]; then
        printf '\n## Filas de `.ai/PROTOCOL.md` archivadas como «%s»\n\n' "$mark"
        sed 's/^\(#[0-9]*\)  enviada — \(.*\)$/- \1, que resuelve \2/' "$TMPD/resolved"
    fi
    # Lo que dice el CHANGELOG.md de cada paquete desde la versión del lock, un nivel por debajo de los títulos del PR.
    for p in "core $was_core" "stacks/$STACK $was_stack"; do
        # shellcheck disable=SC2086  # «carpeta versión», partido a propósito
        set -- $p
        printf '\n## %s\n\n' "$(sed -n '1s/^# //p' "$KIT/$1/CHANGELOG.md")"
        awk -v was="$2" 'index($0, "## [" was "]") == 1 { exit } f || /^## \[/ { f = 1; print }' "$KIT/$1/CHANGELOG.md" \
            | sed 's/^### /#### /; s/^## /### /'
    done
    if [ -n "$hold" ]; then printf '\n## Fusión\n\nQueda para revisar: %s.\n' "$hold"
    else printf '\n## Fusión\n\nSe fusiona sola si la CI pasa (`PROTOCOL_AUTO_MERGE=%s`).\n' "$policy"; fi
} > "$TMPD/pr.md"
command -v gh > /dev/null 2>&1 || die "falta gh: $B está en origin; abre el PR a main a mano"
pr=$(gh pr create --base main --head "$B" --title "$title" --body-file "$TMPD/pr.md" 2> "$TMPD/pr.err" | tail -n 1)
[ -n "$pr" ] || { sed 's/^/  │ /' "$TMPD/pr.err"; die "no pude abrir el PR de $B"; }
echo "  PR: $pr"

if [ -n "$hold" ]; then
    to_main || die "el PR queda abierto ($hold), pero no pude volver a main al día"
    echo "✓ PR abierto para revisar ($hold): $pr. main sigue en core $was_core + $STACK $was_stack."
    exit 0
fi

# ── 6. La CI y la fusión ────────────────────────────────────────────────────
# gh pr checks sale 0 con todo en verde, 8 con algo en curso y 1 si algo falla o aún no hay checks.
echo "◆ esperando a la CI de $pr"
n=0
while :; do
    gh pr checks "$pr" > "$TMPD/checks.log" 2>&1
    rc=$?
    if [ "$rc" -ne 1 ] || ! grep -qi 'no checks' "$TMPD/checks.log"; then break; fi
    n=$((n + 1))
    if [ "$n" -ge "${PROTOCOL_UPGRADE_CI_WAIT:-30}" ]; then
        to_main
        die "el PR no tiene CI ($pr): sin ella no se fusiona; revísalo y fusiónalo a mano"
    fi
    sleep 10
done
[ "$rc" -eq 1 ] || { gh pr checks "$pr" --watch --interval 15 > "$TMPD/checks.log" 2>&1; rc=$?; }
if [ "$rc" -ne 0 ]; then
    tail -n 20 "$TMPD/checks.log" | sed 's/^/  │ /'
    to_main
    die "la CI de $pr falla: queda abierto. El kit nuevo no pasa con el código del proyecto"
fi
gh pr merge "$pr" --squash --delete-branch > "$TMPD/merge.log" 2>&1 \
    || { sed 's/^/  │ /' "$TMPD/merge.log"; to_main; die "la CI pasa, pero no pude fusionar $pr: fusiónalo a mano"; }
to_main || die "fusionado, pero main no quedó al día con origin: git switch main y git pull --ff-only"
git branch -D "$B" > /dev/null 2>&1
[ "$(locked core)" = "$now_core" ] && [ "$(locked "$STACK")" = "$now_stack" ] \
    || die "fusionado, pero $LOCK de main no dice core $now_core + $STACK $now_stack"
echo "✓ fusionado: main en $(git rev-parse --short HEAD), al día con origin, con core $now_core + $STACK $now_stack"
