#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# tag-versions.sh — la etiqueta de cada versión publicada que aún no la tiene.
#
# ◆ QUÉ HACE
#   Por cada manifiesto (core/core.json y stacks/*/stack.json), lee el nombre y
#   la versión. Si la versión está publicada (sin sufijo -dev) y no existe la
#   etiqueta <nombre>-vX.Y.Z (README.md §Versiones y etiquetas), la crea sobre
#   el último commit que cambió la línea «"version"» del manifiesto: el que
#   publica la versión, también cuando la etiqueta se crea más tarde. Las
#   etiquetas son ligeras, como las anteriores.
#
# ◆ USO
#   sh .github/tag-versions.sh          dice qué etiquetas crearía
#   sh .github/tag-versions.sh --push   las crea y las empuja a origin
#   Lo corre .github/workflows/tag.yml en cada push a main. Necesita la
#   historia y las etiquetas completas (actions/checkout con fetch-depth: 0).
#
# ◆ CONTRATO
#   Sale 0 si no falta ninguna etiqueta o si las crea todas, y != 0 si una no
#   se puede crear o empujar.
# ─────────────────────────────────────────────────────────────────────────────
set -u
export LC_ALL=C
cd "$(dirname "$0")/.." || exit 1

PUSH=0
[ "${1:-}" = "--push" ] && PUSH=1

# json_str <archivo> <clave>: el valor de una clave de texto («"clave": "valor"» en su línea).
json_str() { sed -n "s/^ *\"$2\": *\"\\(.*\\)\",\\{0,1\\} *\$/\\1/p" "$1" | head -n 1; }

FAIL=0
n=0
for m in core/core.json stacks/*/stack.json; do
    [ -f "$m" ] || continue
    name=$(json_str "$m" name)
    version=$(json_str "$m" version)
    case "$version" in *-*|'') continue ;; esac
    tag="$name-v$version"
    git rev-parse -q --verify "refs/tags/$tag" > /dev/null && continue
    commit=$(git log -1 --format=%H -G'"version":' -- "$m")
    [ -n "$commit" ] || { echo "✗ $tag: ningún commit cambia la versión de $m"; FAIL=1; continue; }
    n=$((n + 1))
    printf '+ %s → %s\n' "$tag" "$(git log -1 --format='%h %s' "$commit")"
    [ "$PUSH" -eq 1 ] || continue
    if ! git tag "$tag" "$commit" || ! git push -q origin "refs/tags/$tag"; then
        echo "✗ $tag: no se pudo crear o empujar"
        FAIL=1
    fi
done

if [ "$n" -eq 0 ] && [ "$FAIL" -eq 0 ]; then echo '✓ cada versión publicada tiene su etiqueta'
elif [ "$PUSH" -eq 0 ]; then echo "  (sin --push: no se ha creado nada)"; fi
exit "$FAIL"
