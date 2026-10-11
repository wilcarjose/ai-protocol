#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# protocol-feedback.sh — las mejoras del protocolo que sirven a todos, al kit.
#
# ◆ QUÉ HACE
#   Lee las filas de .ai/PROTOCOL.md con «Alcance» núcleo o stack que siguen en
#   «propuesta», abre un issue por cada una en el repo del kit con `gh` y deja
#   la fila en «enviada — ai-protocol#N». El issue lleva el origen (este
#   proyecto, la fase y la fila), la evidencia, la propuesta (lo que sigue a
#   «**Propuesta:**» en «Qué») y el alcance; su título, el alcance entre
#   corchetes (el nombre del stack, del lock) y la primera frase de la fila.
#   Las filas de proyecto, las ya enviadas y las de una tabla sin «Alcance»
#   (la de antes) no se tocan. Lo corre el cierre de una fase
#   (.claude/skills/phase/cierre.md §Retro del protocolo).
#
#   Sin `gh`, o sin acceso al repo del kit, imprime el texto de cada issue y no
#   cambia nada: se puede abrir a mano o volver a correr después.
#
# ◆ USO
#   sh bin/protocol-feedback.sh
#   AI_PROTOCOL_REPO=<dueño>/<repo> sh bin/protocol-feedback.sh   # otro kit
#
# ◆ CONTRATO
#   Sale 0 si envió cada fila o no había nada que enviar, y también sin `gh`
#   (lo dice); != 0 si un issue no se pudo abrir: esa fila sigue «propuesta».
#   Sólo escribe .ai/PROTOCOL.md.
# ─────────────────────────────────────────────────────────────────────────────
set -u
export LC_ALL=C

ROOT=$(cd "$(dirname "$0")/.." && pwd)
P="$ROOT/.ai/PROTOCOL.md"
REPO=${AI_PROTOCOL_REPO:-wilcarjose/ai-protocol}
KIT=${REPO##*/}
PROJECT=${ROOT##*/}
STACK=$(awk '$1 == "package" && $2 != "core" { print $2; exit }' "$ROOT/.ai/protocol.lock" 2>/dev/null)
TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

[ -f "$P" ] || { echo '✗ protocol-feedback: no existe .ai/PROTOCOL.md' >&2; exit 1; }

# Las filas por enviar, una por línea: «id<TAB>fecha<TAB>de<TAB>qué<TAB>alcance». Un «\|» del texto no separa
# columnas.
awk -F'|' '/^\| *# *\|/ { a = (index($0, "| Alcance |") > 0); next }
    a && /^\| *[0-9]+ *\|/ {
        gsub(/\\\|/, "\001")
        for (i = 2; i < NF; i++) { gsub(/^[ \t]+|[ \t]+$/, "", $i); gsub("\001", "|", $i) }
        if (($(NF - 2) == "núcleo" || $(NF - 2) == "stack") && $(NF - 1) == "propuesta")
            print $2 "\t" $3 "\t" $4 "\t" $5 "\t" $(NF - 2)
    }' "$P" > "$TMPD/rows"

if [ ! -s "$TMPD/rows" ]; then
    echo '✓ protocol-feedback: ninguna fila de núcleo o stack en «propuesta»; nada que enviar'
    exit 0
fi

SEND=1
if ! command -v gh > /dev/null 2>&1; then
    SEND=0; why='sin gh'
elif ! gh repo view "$REPO" > /dev/null 2>&1; then
    SEND=0; why="sin acceso a $REPO"
fi

FAIL=0
TAB=$(printf '\t')
while IFS="$TAB" read -r id fecha de que alcance; do
    # La evidencia y la propuesta, separadas por «**Propuesta:**»; sin la marca, todo es evidencia.
    case "$que" in
        *'**Propuesta:**'*) ev=${que%%\*\*Propuesta:\*\**}; pr=${que#*\*\*Propuesta:\*\*} ;;
        *) ev=$que; pr='—' ;;
    esac
    ev=$(printf '%s' "$ev" | sed 's/[[:space:]]*$//'); pr=$(printf '%s' "$pr" | sed 's/^[[:space:]]*//')
    tag=$alcance; a=$alcance
    if [ "$alcance" = stack ] && [ -n "$STACK" ]; then tag=$STACK; a="stack de $STACK"; fi
    # La primera frase, cortada por palabras hacia los 100 caracteres.
    title=$(printf '%s' "$ev" | sed 's/[.:;] .*//; s/[.:;]$//' | awk '{ t = ""; for (i = 1; i <= NF; i++) {
        if (length(t) + length($i) > 100) { t = t "…"; break } t = (t == "" ? "" : t " ") $i } print t }')
    title="[$tag] $title"
    # shellcheck disable=SC2016  # las comillas invertidas son literales
    printf '**Origen:** `%s`, %s (%s). Fila #%s de su `.ai/PROTOCOL.md`.\n\n**Evidencia:** %s\n\n**Propuesta:** %s\n\n**Alcance:** %s.\n' \
        "$PROJECT" "$de" "$fecha" "$id" "$ev" "$pr" "$a" > "$TMPD/body"

    if [ "$SEND" -eq 0 ]; then
        printf -- '── fila #%s ──\n%s\n\n' "$id" "$title"; cat "$TMPD/body"; printf '\n'
        continue
    fi
    url=$(gh issue create --repo "$REPO" --title "$title" --body-file "$TMPD/body" 2> "$TMPD/err" | tail -n 1)
    n=${url##*/}
    case "$n" in
        ''|*[!0-9]*)
            printf '✗ fila #%s: no se pudo abrir el issue; sigue «propuesta»\n' "$id" >&2
            sed 's/^/    /' "$TMPD/err" >&2; FAIL=1; continue ;;
    esac
    awk -v id="$id" -v st="enviada — $KIT#$n" '
        /^\| *[0-9]+ *\|/ { i = $0; sub(/^\| */, "", i); sub(/ *\|.*/, "", i)
            if (i == id) sub(/\| *propuesta *\| *$/, "| " st " |") }
        { print }' "$P" > "$TMPD/p" && cat "$TMPD/p" > "$P"
    printf '✓ fila #%s → %s\n' "$id" "$url"
done < "$TMPD/rows"

if [ "$SEND" -eq 0 ]; then
    printf '⚠ protocol-feedback: %s; nada enviado y .ai/PROTOCOL.md no cambia. Abre los issues a mano en %s o vuelve a correrlo.\n' "$why" "$REPO"
fi
exit "$FAIL"
