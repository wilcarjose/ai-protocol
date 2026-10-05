#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# install.sh — instala o actualiza el protocolo (núcleo + un stack) en un proyecto.
#
# ◆ USO
#   sh install.sh --stack <stack> --target <dir> [--dry-run]
#   sh install.sh --upgrade --target <dir> [--stack <stack>] [--dry-run]
#
#   <stack> es una carpeta de stacks/ con stack.json (laravel, nextjs). Con
#   --dry-run dice lo que haría, diffs incluidos, sin escribir nada.
#
# ◆ INSTALAR
#   Comprueba que el stack es compatible con la versión del núcleo (el rango
#   «core» de su stack.json) y copia los archivos de core/core.json y de
#   stacks/<stack>/stack.json. Nunca pisa un archivo que ya exista en el
#   proyecto: lo avisa y sigue. Escribe .ai/protocol.lock con las versiones
#   instaladas y la suma SHA-256 de cada archivo, tal como lo trae el kit.
#   Si el proyecto ya tiene lock, para: eso es un --upgrade.
#
# ◆ ACTUALIZAR
#   Lee el stack y las sumas del lock. Por cada archivo del kit («files»):
#     igual       el proyecto ya tiene la versión nueva: nada.
#     nuevo       el proyecto no lo tiene: se copia.
#     actualizado el proyecto no lo tocó desde la última instalación (su suma
#                 es la del lock): se sustituye y se muestra el diff.
#     propio      el proyecto lo cambió y el kit no: se deja como está.
#     conflicto   el proyecto lo cambió y el kit también: se deja como está y
#                 se muestra el diff contra la versión nueva, para aplicarlo a
#                 mano. El lock conserva la suma anterior, así que el conflicto
#                 sigue saliendo en cada --upgrade hasta que el archivo es igual
#                 al del kit. Un archivo que el proyecto ya tenía al instalar
#                 (no se copió) cuenta igual. Sin lock (una instalación anterior
#                 al instalador), todo archivo que difiere es un conflicto: hace
#                 falta --stack.
#     retirado    el kit ya no lo trae: se borra si el proyecto no lo tocó, con
#                 las carpetas que deja vacías; si lo tocó, se deja y se avisa
#                 en cada --upgrade.
#   Las semillas («seed»: la memoria —STATE, DOMAIN, BACKLOG, PROTOCOL, las
#   épicas—, la capa del proyecto .ai/project/ y los registros que llenan las
#   fases) sólo se copian si faltan: el upgrade nunca las toca. Si nada cambia,
#   dice «sin cambios» y no escribe nada, tampoco el lock.
#
# ◆ FORMATO DE LOS MANIFIESTOS Y DEL LOCK
#   Los manifiestos son JSON con un valor por línea (tests/structure.sh lo
#   comprueba); se leen con awk y sed porque Alpine no trae jq. El lock:
#     package <nombre> <versión>
#     file <kit|seed> <sha256|-> <ruta>
#   La suma es la del archivo tal como lo trajo el kit la última vez que el
#   proyecto lo tuvo igual; «-» si nunca lo tuvo (no se copió al instalar).
#
# ◆ PORTABILIDAD
#   POSIX sh, como el resto de scripts del kit: corre en busybox (Alpine).
#
# ◆ CONTRATO
#   Sale 0 si instala o actualiza (también con conflictos, que se listan al
#   final) y != 0 si no puede: argumentos, stack incompatible, lock ausente o
#   presente cuando no toca.
# ─────────────────────────────────────────────────────────────────────────────
set -u
export LC_ALL=C

KIT=$(cd "$(dirname "$0")" && pwd)
LOCK_REL=.ai/protocol.lock

die() { printf '✗ install.sh: %s\n' "$1" >&2; exit 1; }

usage() {
    sed -n 's/^#   \(sh install\.sh .*\)/\1/p' "$KIT/install.sh" >&2
    exit 1
}

# ── Argumentos ──────────────────────────────────────────────────────────────
MODE=install
STACK=''
TARGET=''
DRY=0
while [ $# -gt 0 ]; do
    case "$1" in
        --stack)   [ $# -ge 2 ] || usage; STACK=$2; shift 2 ;;
        --target)  [ $# -ge 2 ] || usage; TARGET=$2; shift 2 ;;
        --upgrade) MODE=upgrade; shift ;;
        --dry-run) DRY=1; shift ;;
        *) usage ;;
    esac
done
[ -n "$TARGET" ] || usage
[ "$MODE" = upgrade ] || [ -n "$STACK" ] || usage

# ── Helpers ─────────────────────────────────────────────────────────────────
# json_str <archivo> <clave>: el valor de una clave de texto («"clave": "valor"» en su línea).
json_str() { sed -n "s/^ *\"$2\": *\"\\(.*\\)\",\\{0,1\\} *\$/\\1/p" "$1" | head -n 1; }

# json_list <archivo> <clave>: los elementos de una lista, uno por línea.
json_list() {
    awk -v k="\"$2\":" '
        !f && index($0, k) { if ($0 ~ /\[ *\]/) exit; f = 1; next }
        f && /^ *\]/ { exit }
        f { l = $0; sub(/^ *"/, "", l); sub(/",? *$/, "", l); if (l != "") print l }' "$1"
}

# sha <archivo>: su suma SHA-256.
sha() {
    if command -v sha256sum > /dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d ' ' -f 1
}

# vcmp <a> <b>: -1, 0 o 1, comparando X.Y.Z y, a igualdad, la versión con sufijo (-dev) antes que sin él.
vcmp() {
    awk -v a="$1" -v b="$2" '
        function parse(v, P,   i) {
            P[4] = ""; i = index(v, "-")
            if (i) { P[4] = substr(v, i + 1); v = substr(v, 1, i - 1) }
            split(v, T, "."); P[1] = T[1] + 0; P[2] = T[2] + 0; P[3] = T[3] + 0
        }
        BEGIN {
            parse(a, A); parse(b, B)
            for (i = 1; i <= 3; i++) {
                if (A[i] < B[i]) { print -1; exit }
                if (A[i] > B[i]) { print 1; exit }
            }
            if (A[4] == B[4]) print 0
            else if (A[4] == "") print 1
            else if (B[4] == "") print -1
            else print (A[4] < B[4]) ? -1 : 1
        }'
}

# in_range <versión> <«>=X <Y»>
in_range() {
    lo=${2#>=}; lo=${lo%% *}; hi=${2##*<}
    [ "$(vcmp "$1" "$lo")" -ge 0 ] && [ "$(vcmp "$1" "$hi")" -lt 0 ]
}

# show_diff <ruta> <del proyecto> <del kit>: el diff unificado, con la ruta en la cabecera.
show_diff() {
    diff -u "$2" "$3" | sed -e "1s#.*#--- proyecto/$1#" -e "2s#.*#+++ kit/$1#" | sed 's/^/      /'
}

# ── Qué se instala ──────────────────────────────────────────────────────────
[ -d "$TARGET" ] || [ "$MODE" = install ] || die "no existe $TARGET"
LOCK="$TARGET/$LOCK_REL"
OLD_LOCK=''
if [ "$MODE" = upgrade ]; then
    if [ -f "$LOCK" ]; then
        OLD_LOCK=$LOCK
        locked=$(awk '$1 == "package" && $2 != "core" { print $2; exit }' "$LOCK")
        [ -n "$locked" ] || die "$LOCK_REL no dice qué stack hay instalado"
        [ -z "$STACK" ] || [ "$STACK" = "$locked" ] \
            || die "el proyecto tiene instalado el stack «$locked», no «$STACK»; cambiar de stack no es un upgrade"
        STACK=$locked
    else
        [ -n "$STACK" ] || die "$TARGET no tiene $LOCK_REL: di qué stack tiene con --stack y todo archivo que difiera del kit saldrá como conflicto"
    fi
elif [ -f "$LOCK" ]; then
    die "$TARGET ya tiene $LOCK_REL: para actualizarlo, --upgrade"
fi

case "$STACK" in *[!a-z0-9-]*|'') die "stack inválido: «$STACK»" ;; esac
CORE_JSON="$KIT/core/core.json"
STACK_JSON="$KIT/stacks/$STACK/stack.json"
if [ ! -f "$STACK_JSON" ]; then
    avail=$(for j in "$KIT"/stacks/*/stack.json; do [ -f "$j" ] && basename "$(dirname "$j")"; done | tr '\n' ' ')
    die "no hay stack «$STACK»; los disponibles: $avail"
fi
CORE_V=$(json_str "$CORE_JSON" version)
STACK_V=$(json_str "$STACK_JSON" version)
RANGE=$(json_str "$STACK_JSON" core)
in_range "$CORE_V" "$RANGE" || die "el stack $STACK $STACK_V pide el núcleo «$RANGE» y el kit trae $CORE_V"

TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

# «tipo<TAB>origen<TAB>ruta» por cada archivo: primero el núcleo, después el stack.
TAB=$(printf '\t')
{
    json_list "$CORE_JSON" files | sed "s#^#kit${TAB}core${TAB}#"
    json_list "$CORE_JSON" seed  | sed "s#^#seed${TAB}core${TAB}#"
    json_list "$STACK_JSON" files | sed "s#^#kit${TAB}stacks/$STACK${TAB}#"
    json_list "$STACK_JSON" seed  | sed "s#^#seed${TAB}stacks/$STACK${TAB}#"
} > "$TMPD/plan"

# locked_sum <ruta>: la suma que el lock anterior tiene para esa ruta, o nada.
locked_sum() {
    [ -n "$OLD_LOCK" ] || return 0
    awk -v p="$1" '$1 == "file" && $4 == p { print $3; exit }' "$OLD_LOCK"
}

# ── Copia ───────────────────────────────────────────────────────────────────
# version_of <paquete>: «antes → ahora» si el lock anterior tenía otra versión; si no, la de ahora.
version_of() {
    now=$2; was=''
    [ -n "$OLD_LOCK" ] && was=$(awk -v p="$1" '$1 == "package" && $2 == p { print $3; exit }' "$OLD_LOCK")
    if [ -n "$was" ] && [ "$was" != "$now" ]; then printf '%s → %s' "$was" "$now"; else printf '%s' "$now"; fi
}
printf '◆ %s de núcleo %s + %s %s en %s' "$MODE" "$(version_of core "$CORE_V")" "$STACK" "$(version_of "$STACK" "$STACK_V")" "$TARGET"
if [ "$DRY" -eq 1 ]; then printf ' (--dry-run: no se escribe nada)\n'; else printf '\n'; mkdir -p "$TARGET"; fi

: > "$TMPD/counts"
note() { printf '  %s %-44s %s\n' "$1" "$2" "$3"; printf '%s\n' "$4" >> "$TMPD/counts"; }

put() {
    [ "$DRY" -eq 1 ] && return 0
    mkdir -p "$(dirname "$TARGET/$2")" && cp "$1" "$TARGET/$2"
}

{
    printf '# %s — lo que instaló ai-protocol (install.sh). No se edita a mano: lo reescribe --upgrade.\n' "$LOCK_REL"
    printf 'package core %s\n' "$CORE_V"
    printf 'package %s %s\n' "$STACK" "$STACK_V"
} > "$TMPD/lock"

while IFS="$TAB" read -r kind from path; do
    src="$KIT/$from/$path"
    dst="$TARGET/$path"
    new=$(sha "$src")
    base=$new    # la suma que queda en el lock

    if [ ! -e "$dst" ]; then
        put "$src" "$path"; note + "$path" 'copiado' change
    elif [ "$MODE" = install ]; then
        if [ "$(sha "$dst")" = "$new" ]; then note '=' "$path" 'ya estaba, igual' same
        else note '!' "$path" 'ya existe en el proyecto: no se copia' skip; base=-; fi
    elif [ "$kind" = kit ]; then
        # Upgrade de un archivo del kit que el proyecto tiene. Las semillas no se tocan.
        cur=$(sha "$dst")
        old=$(locked_sum "$path")
        if [ "$cur" = "$new" ]; then
            printf 'same\n' >> "$TMPD/counts"
        elif [ "$old" = "$new" ]; then
            note '·' "$path" 'propio: el proyecto lo cambió y el kit no' same
        elif [ -n "$old" ] && [ "$old" = "$cur" ]; then
            note '~' "$path" 'actualizado' change
            show_diff "$path" "$dst" "$src"
            put "$src" "$path"
        else
            note '!' "$path" 'conflicto: el proyecto lo cambió; aplica el diff a mano' conflict
            show_diff "$path" "$dst" "$src"
            base=${old:--}
        fi
    fi
    printf 'file %s %s %s\n' "$kind" "$base" "$path" >> "$TMPD/lock"
done < "$TMPD/plan"

# Lo que el lock anterior tenía y el kit ya no trae.
if [ -n "$OLD_LOCK" ]; then
    awk '$1 == "file" { print $2 "\t" $3 "\t" $4 }' "$OLD_LOCK" | while IFS="$TAB" read -r kind old path; do
        cut -f 3 "$TMPD/plan" | grep -qxF -- "$path" && continue
        dst="$TARGET/$path"
        # Una semilla es del proyecto aunque el kit ya no la traiga; lo que ya no existe, no hay que retirarlo.
        if [ "$kind" = seed ] || [ ! -e "$dst" ]; then
            continue
        elif [ "$(sha "$dst")" = "$old" ]; then
            note - "$path" 'retirado del kit: se borra' change
            # Y las carpetas que deja vacías, sin salir del proyecto (la ruta es relativa a él).
            [ "$DRY" -eq 1 ] || { rm -f "$dst"; ( cd "$TARGET" && rmdir -p "$(dirname "$path")" 2>/dev/null ); }
        else
            note '!' "$path" 'retirado del kit, pero el proyecto lo cambió: se deja; bórralo si ya no lo usas' conflict
            printf 'file %s %s %s\n' "$kind" "$old" "$path" >> "$TMPD/lock"
        fi
    done
fi

# ── Lock y resumen ──────────────────────────────────────────────────────────
count() { grep -cx "$1" "$TMPD/counts"; }
lock_changed=1
[ -n "$OLD_LOCK" ] && cmp -s "$TMPD/lock" "$OLD_LOCK" && lock_changed=0

if [ "$MODE" = upgrade ] && [ "$lock_changed" -eq 0 ] && [ "$(count change)" -eq 0 ] && [ "$(count conflict)" -eq 0 ]; then
    echo '✓ sin cambios'
    exit 0
fi

if [ "$DRY" -eq 0 ]; then
    mkdir -p "$(dirname "$LOCK")" && cp "$TMPD/lock" "$LOCK"
fi

printf '\n'
if [ "$MODE" = install ]; then
    printf '✓ instalado: %s copiado(s), %s ya estaba(n) igual, %s no copiado(s) porque existían\n' \
        "$(count change)" "$(count same)" "$(count skip)"
    [ "$DRY" -eq 1 ] || printf '  Siguiente paso: rellena los marcadores (grep -rn %s CLAUDE.md .ai docs).\n' "'{{RELLENAR'"
else
    printf '✓ actualizado: %s cambio(s), %s conflicto(s)\n' "$(count change)" "$(count conflict)"
    [ "$(count change)" -ne 0 ] || [ "$(count conflict)" -ne 0 ] || printf '  (sólo cambia %s)\n' "$LOCK_REL"
fi
[ "$DRY" -eq 0 ] || echo '  (--dry-run: no se ha escrito nada)'
exit 0
