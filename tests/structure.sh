#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# tests/structure.sh — el núcleo y los stacks están donde dicen sus manifiestos.
#
# ◆ QUÉ COMPRUEBA
#   1. manifiestos  — core/core.json y cada stacks/<stack>/stack.json tienen
#                     nombre (el de su carpeta) y versión X.Y.Z[-pre]; cada
#                     stack, además, el rango del núcleo y sus gates. Una
#                     carpeta de stacks/ sin stack.json sólo puede tener un
#                     README.md (un stack anunciado, como expo).
#   2. archivos     — «files» y «seed» de cada manifiesto listan exactamente
#                     los archivos de su carpeta, salvo el propio manifiesto y
#                     CHANGELOG.md; ninguno se repite.
#   3. capas        — ningún stack trae un archivo que ya trae el núcleo: el
#                     stack añade, no sobrescribe.
#   4. gates        — los «gates» de stack.json son los `run '<gate>'` de su
#                     bin/verify.sh.
#   5. referencias  — ningún stack cita un archivo que sólo trae otro stack, ni
#                     la carpeta de otro stack; el núcleo no cita un archivo
#                     que no traigan todos los stacks.
#
# ◆ FORMATO DE LOS MANIFIESTOS
#   JSON con un valor por línea, como lo escribe cualquier formateador: los
#   scripts lo leen con awk y sed, porque la imagen Alpine de la CI no trae jq.
#
# ◆ USO
#   sh tests/structure.sh
#
# ◆ CONTRATO
#   Sale 0 si todo cuadra y != 0 si no. Sólo lee el repo.
# ─────────────────────────────────────────────────────────────────────────────
set -u
export LC_ALL=C

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1
TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

# bad <mensaje>: anota un fallo; vale también desde un subshell (los «| while read»).
bad() { printf '  ✗ %s\n' "$1" | tee -a "$TMPD/problems"; }

# json_str <archivo> <clave>: el valor de una clave de texto («"clave": "valor"» en su línea).
json_str() { sed -n "s/^ *\"$2\": *\"\\(.*\\)\",\\{0,1\\} *\$/\\1/p" "$1" | head -n 1; }

# json_list <archivo> <clave>: los elementos de una lista, uno por línea.
json_list() {
    awk -v k="\"$2\":" '
        !f && index($0, k) { if ($0 ~ /\[ *\]/) exit; f = 1; next }
        f && /^ *\]/ { exit }
        f { l = $0; sub(/^ *"/, "", l); sub(/",? *$/, "", l); if (l != "") print l }' "$1"
}

# pkg_files <carpeta> <manifiesto>: «files» y «seed», ordenados.
pkg_files() { { json_list "$1/$2" files; json_list "$1/$2" seed; } | sort; }

# ── 1 y 2. Manifiestos y archivos ───────────────────────────────────────────
STACKS=''
NSTACKS=0
check_pkg() {
    dir=$1; manifest=$2; name=${dir##*/}
    m="$dir/$manifest"
    printf '◆ %s (%s)\n' "$dir" "$manifest"
    [ "$(json_str "$m" name)" = "$name" ] || bad "$m: «name» no es «$name»"
    json_str "$m" version | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$' \
        || bad "$m: «version» no es X.Y.Z[-pre]"
    if [ "$manifest" = stack.json ]; then
        json_str "$m" core | grep -qE '^>=[0-9][^ ]* <[0-9][^ ]*$' \
            || bad "$m: «core» no es un rango «>=X.Y.Z <X.Y.Z»"
        [ -n "$(json_list "$m" gates)" ] || bad "$m: no declara «gates»"
    fi
    pkg_files "$dir" "$manifest" > "$TMPD/$name.listed"
    uniq -d "$TMPD/$name.listed" | while read -r f; do bad "$m: «$f» aparece más de una vez"; done
    ( cd "$dir" && find . -type f | sed 's#^\./##' ) | grep -vxF -e "$manifest" -e CHANGELOG.md | sort > "$TMPD/$name.real"
    comm -13 "$TMPD/$name.listed" "$TMPD/$name.real" | while read -r f; do bad "$dir/$f no está en $manifest"; done
    comm -23 "$TMPD/$name.listed" "$TMPD/$name.real" | while read -r f; do bad "$m lista «$f», que no existe"; done
    [ -s "$TMPD/$name.listed" ] || bad "$m: no lista ningún archivo"
}

[ -f core/core.json ] || { echo '✗ falta core/core.json'; exit 1; }
check_pkg core core.json
for d in stacks/*/; do
    d=${d%/}
    if [ -f "$d/stack.json" ]; then
        check_pkg "$d" stack.json
        STACKS="$STACKS ${d##*/}"
        NSTACKS=$((NSTACKS + 1))
    else
        printf '◆ %s (anunciado)\n' "$d"
        other=$( cd "$d" && find . -type f | sed 's#^\./##' | grep -vxF README.md )
        [ -z "$other" ] || bad "$d no tiene stack.json y no es sólo un README.md: $(printf '%s' "$other" | tr '\n' ' ')"
    fi
done
[ -n "$STACKS" ] || bad 'no hay ningún stack con stack.json'

# ── 3. El stack añade, no sobrescribe ───────────────────────────────────────
printf '◆ capas (ningún stack trae un archivo del núcleo)\n'
for s in $STACKS; do
    comm -12 "$TMPD/core.listed" "$TMPD/$s.listed" | while read -r f; do bad "stacks/$s/$f ya lo trae el núcleo"; done
done

# ── 4. Gates ────────────────────────────────────────────────────────────────
printf '◆ gates (stack.json frente a los run de bin/verify.sh)\n'
for s in $STACKS; do
    v="stacks/$s/bin/verify.sh"
    [ -f "$v" ] || { bad "stacks/$s no trae bin/verify.sh"; continue; }
    json_list "stacks/$s/stack.json" gates | sort > "$TMPD/$s.gates"
    sed -n "s/^ *run '\\([^']*\\)'.*/\\1/p" "$v" | sort > "$TMPD/$s.runs"
    comm -13 "$TMPD/$s.gates" "$TMPD/$s.runs" | while read -r g; do bad "$v corre el gate «$g», que stack.json no declara"; done
    comm -23 "$TMPD/$s.gates" "$TMPD/$s.runs" | while read -r g; do bad "stacks/$s/stack.json declara el gate «$g», que $v no corre"; done
done

# ── 5. Referencias entre stacks ─────────────────────────────────────────────
printf '◆ referencias (un stack sólo depende del núcleo)\n'
# refs <paquete> <archivo con rutas>: «archivo<TAB>ruta» por cada ruta que cita un archivo que el paquete lista (su
# manifiesto y su CHANGELOG.md no cuentan: hablan del paquete, no lo usan).
refs() {
    dir=stacks/$1
    [ "$1" = core ] && dir=core
    while read -r p; do
        [ -n "$p" ] || continue
        while read -r f; do
            grep -qF -- "$p" "$dir/$f" && printf '%s\t%s\n' "$dir/$f" "$p"
        done < "$TMPD/$1.listed"
    done < "$2"
}
for s in $STACKS; do
    : > "$TMPD/foreign"
    for t in $STACKS; do
        [ "$t" = "$s" ] && continue
        printf 'stacks/%s/\n' "$t" >> "$TMPD/foreign"
        comm -23 "$TMPD/$t.listed" "$TMPD/$s.listed" >> "$TMPD/foreign"
    done
    refs "$s" "$TMPD/foreign" | while IFS="$(printf '\t')" read -r f p; do
        bad "$f cita «$p», que es de otro stack"
    done
done
# Lo que no traen todos los stacks: el núcleo no puede contar con ello.
for s in $STACKS; do cat "$TMPD/$s.listed"; done | sort | uniq -c \
    | awk -v n="$NSTACKS" '$1 < n { print $2 }' > "$TMPD/partial"
refs core "$TMPD/partial" | while IFS="$(printf '\t')" read -r f p; do
    bad "$f cita «$p», que no traen todos los stacks"
done

printf '\n'
FAIL=0
[ -s "$TMPD/problems" ] && FAIL=1
if [ "$FAIL" -eq 0 ]; then echo '✓ tests/structure.sh: el núcleo y los stacks cuadran con sus manifiestos'
else echo '✗ tests/structure.sh: hay fallos'; fi
exit "$FAIL"
