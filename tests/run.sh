#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# tests/run.sh — el instalador y el guardián de cada stack, probados en las dos
# direcciones, y tests/structure.sh frente a sus propios fallos.
#
# ◆ QUÉ HACE, POR STACK
#   1. Lo instala con install.sh en un directorio temporal, como un proyecto
#      nuevo, y superpone tests/fixtures/<kit>/: el composer.json o package.json con una versión
#      por paquete de .ai/RULES.md §Stack y versiones exactas, y los archivos
#      del proyecto que RULES.md cita. Escribe esas versiones en
#      .ai/project/DECISIONS.md, rellena cada {{RELLENAR}} y declara un repo
#      hermano para que los chequeos «traspaso» y «cross-repo» apliquen.
#   2. Crea desde las plantillas una épica de prueba: 01-demo, CERRADA, con dos
#      fases HECHA; y 02-demo, con su fase 01 LISTA_PARA_EJECUTAR y el puntero
#      de STATE.md en ella.
#   3. Comprueba que `sh bin/check-docs.sh --strict` pasa sobre esa instalación.
#   4. Provoca, cada uno en una copia limpia, los 13 fallos de «CÓMO PROVOCAR
#      CADA FALLO» de la cabecera de bin/check-docs.sh, más tres variantes: una
#      fase con las secciones sin número (2n), un paquete de RULES.md sin
#      versión en .ai/project/DECISIONS.md (9n) y una cita de sección por su
#      número (12n). Cada caso tiene que fallar con el mensaje de su chequeo,
#      no con cualquier otro.
#   El fallo 5 (migraciones) sólo existe si la plantilla de fase declara
#   «Migraciones:»; en un kit que no lo hace, se comprueba en su lugar que el
#   guardián acepta fases sin ese campo.
#   5. Prueba el instalador: el lock tiene la suma de cada archivo instalado;
#      --dry-run no escribe nada; instalar otra vez falla; un --upgrade sin
#      cambios dice «sin cambios» y no toca ningún archivo; con un kit nuevo,
#      actualiza lo que el proyecto no tocó, deja como conflicto lo que sí
#      tocó y no toca la memoria; y no instala un stack incompatible con el
#      núcleo.
#
# ◆ ADEMÁS
#   Provoca en una copia del repo un fallo de cada chequeo de
#   tests/structure.sh y comprueba que lo detecta.
#
# ◆ CÓMO SE AÑADE UN CASO
#   Un chequeo nuevo del guardián trae su caso aquí: una rama en estropea()
#   que mete el defecto en la instalación (corre en su raíz) y una línea
#   `provoke` con el texto que el guardián tiene que imprimir.
#
# ◆ USO
#   sh tests/run.sh             # los dos stacks
#   sh tests/run.sh laravel     # sólo uno (structure.sh se prueba siempre)
#
# ◆ CONTRATO
#   Sale 0 si la instalación pasa el guardián, el instalador hace lo que dice y
#   todos los fallos provocados se detectan; != 0 si no. No toca el repo:
#   trabaja en un directorio temporal.
# ─────────────────────────────────────────────────────────────────────────────
set -u
export LC_ALL=C

ROOT=$(cd "$(dirname "$0")/.." && pwd)
FIXTURES="$ROOT/tests/fixtures"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

KITS=${1:-'laravel nextjs'}
DATE=2026-01-01
FAIL=0

# ── Helpers ─────────────────────────────────────────────────────────────────
ok()   { printf '  ✓ %s\n' "$1"; }
fail() { printf '  ✗ %s\n' "$1"; FAIL=1; }

# sha <archivo>: su suma SHA-256.
sha() {
    if command -v sha256sum > /dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d ' ' -f 1
}

# snapshot <dir>: «suma ruta» de cada archivo, ordenado: dos iguales = nada cambió.
snapshot() { ( cd "$1" && find . -type f | sort | while read -r f; do printf '%s %s\n' "$(sha "$f")" "$f"; done ); }

# json_list <archivo> <clave>: los elementos de una lista de un manifiesto, uno por línea.
json_list() {
    awk -v k="\"$2\":" '
        !f && index($0, k) { if ($0 ~ /\[ *\]/) exit; f = 1; next }
        f && /^ *\]/ { exit }
        f { l = $0; sub(/^ *"/, "", l); sub(/",? *$/, "", l); if (l != "") print l }' "$1"
}

# kit_copy <dir>: una copia del repo del kit, para cambiarla sin tocar el de verdad.
kit_copy() { mkdir -p "$1" && cp -R "$ROOT/install.sh" "$ROOT/core" "$ROOT/stacks" "$ROOT/tests" "$1/"; }

# edit <archivo> <script de sed>: sed en el sitio sin «-i», que no es POSIX.
edit() { sed "$2" "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }

# awk_edit <archivo> <programa de awk>: lo mismo con awk.
awk_edit() { awk "$2" "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }

# fill_stack <RULES.md> <DECISIONS.md> <manifiesto>: la fila de marcador de DECISIONS.md §Stack pasa a una fila
# por paquete de RULES.md §Stack, con la versión que declara el manifiesto (una pareja «"paquete": "versión"» por
# línea).
fill_stack() {
    awk '
        FILENAME == ARGV[1] {
            if ($0 ~ /^ *"[^"]+": *"[^"]*",? *$/) {
                l = $0; sub(/^ *"/, "", l); sub(/",? *$/, "", l); split(l, kv, /": *"/); v[kv[1]] = kv[2]
            }
            next
        }
        FILENAME == ARGV[2] {
            if ($0 ~ /^## [0-9]+\. Stack/) { s = 1; next }
            if (s && /^## /) s = 0
            if (s && /^\| `/) {
                n = $0; sub(/^\| /, "", n); sub(/ \|.*/, "", n); gsub(/`/, "", n)
                k = split(n, N, / \/ /); for (i = 1; i <= k; i++) rows = rows "| `" N[i] "` | " v[N[i]] " |\n"
            }
            next
        }
        /^\| \{\{RELLENAR/ { printf "%s", rows; next }
        { print }' "$3" "$1" "$2" > "$2.tmp" && mv "$2.tmp" "$2"
}

# fill_markers <archivo> <repo hermano>: cada {{RELLENAR…}}, aunque ocupe varias líneas, pasa a «Demo»;
# el de los repos hermanos, al nombre del repo entre comillas invertidas.
fill_markers() {
    awk -v repo="$2" '
        { buf = buf $0 "\n" }
        END {
            while ((i = index(buf, "{{RELLENAR")) > 0) {
                rest = substr(buf, i); j = index(rest, "}}")
                val = index(substr(rest, 1, j), "repo hermano") ? "`" repo "`" : "Demo"
                out = out substr(buf, 1, i - 1) val
                buf = substr(rest, j + 2)
            }
            printf "%s", out buf
        }' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

# make_epic <slug> <estado> <fases…>: el epic-plan desde su plantilla, con sólo las filas de esas fases.
make_epic() {
    slug=$1; st=$2; shift 2
    mkdir -p ".ai/epics/$slug"
    plan=".ai/epics/$slug/epic-plan.md"
    sed -e "s/^# Épica NN — .*/# Épica ${slug%%-*} — Demo/" \
        -e "s/^> \*\*Slug:\*\* .*/> **Slug:** \`$slug\`/" \
        -e "s/^> \*\*Estado:\*\* .*/> **Estado:** $st/" \
        .ai/templates/epic-plan.template.md > "$plan"
    awk_edit "$plan" "/^## Fases/ { s = 1 } s && /^## / && !/Fases/ { s = 0 }
        s && /^\| [0-9][0-9] \|/ { split(\"$*\", k, \" \"); keep = 0; for (x in k) if (index(\$0, \"| \" k[x] \" |\") == 1) keep = 1; if (!keep) next }
        { print }"
    [ "$st" = CERRADA ] && edit "$plan" 's/^- \[ \]/- [x]/'
    return 0
}

# make_phase <slug> <FF> <estado> <depende de>: la fase desde su plantilla; HECHA, con su RESULTADO.
make_phase() {
    f=".ai/epics/$1/phase-$2.md"
    sed -e "s/^# Fase FF — .*/# Fase $2 — Demo/" \
        -e "s/^> \*\*Épica:\*\* .*/> **Épica:** \`$1\` · **Depende de:** $4/" \
        -e "s/^> \*\*Estado:\*\* .*/> **Estado:** $3/" \
        .ai/templates/phase.template.md > "$f"
    [ "$3" = HECHA ] || return 0
    edit "$f" "s/^- \[ \]/- [x]/; s/^\*\*Fecha:\*\*\$/**Fecha:** $DATE/"
    awk_edit "$f" '{ print } /^### (Qué se hizo|Lo que la siguiente fase necesita saber)$/ { print ""; print "Fase de prueba." }'
}

# install <kit> <dir>: el kit instalado con install.sh y con la épica de prueba.
install() {
    if ! sh "$ROOT/install.sh" --stack "$1" --target "$2" > "$WORK/$1.install.log" 2>&1; then
        sed 's/^/      /' "$WORK/$1.install.log"
        return 1
    fi
    cp -R "$FIXTURES/$1/." "$2/"
    (
        cd "$2" || exit 1
        manifest=composer.json
        [ -f package.json ] && manifest=package.json
        fill_stack .ai/RULES.md .ai/project/DECISIONS.md "$manifest"
        find . -type f -name '*.md' -exec grep -lF '{{RELLENAR' {} + | while read -r f; do fill_markers "$f" "$SIBLING"; done

        make_epic 01-demo CERRADA 01 02
        make_phase 01-demo 01 HECHA '—'
        make_phase 01-demo 02 HECHA 'fase 01'
        make_epic 02-demo SIN_EMPEZAR 01
        make_phase 02-demo 01 LISTA_PARA_EJECUTAR '—'

        awk_edit .ai/STATE.md "
            /^## Mapa de fases/ { m = 1 }
            { print }
            m && /^\|---/ { m = 0
                print \"| 01-demo | 01 | HECHA | $DATE |\"
                print \"| 01-demo | 02 | HECHA | $DATE |\"
                print \"| 02-demo | 01 | LISTA_PARA_EJECUTAR | — |\" }"
        edit .ai/STATE.md "s/^- \*\*Épica activa:\*\* .*/- **Épica activa:** 02-demo/
            s/^- \*\*Fase activa:\*\* .*/- **Fase activa:** 01/
            s#^- \*\*Archivo de la fase:\*\* .*#- **Archivo de la fase:** \`.ai/epics/02-demo/phase-01.md\`#
            s/^- \*\*Última actualización:\*\* .*/- **Última actualización:** $DATE/"
    )
}

# ── Los fallos de la cabecera de bin/check-docs.sh («CÓMO PROVOCAR CADA FALLO») ──
# estropea <caso>: mete el defecto del caso en la instalación del directorio actual.
# shellcheck disable=SC2016  # las comillas invertidas y los $ de awk son literales
estropea() {
    case "$1" in
        0)  printf '\n{{RELLENAR: x}}\n' >> .ai/DOMAIN.md ;;
        1)  edit .ai/STATE.md 's/^- \*\*Épica activa:\*\* .*/- **Épica activa:** 01-demo/
                s/^- \*\*Fase activa:\*\* .*/- **Fase activa:** 02/
                s#^- \*\*Archivo de la fase:\*\* .*#- **Archivo de la fase:** `.ai/epics/01-demo/phase-02.md`#' ;;
        2)  edit .ai/epics/01-demo/phase-02.md 's/^> \*\*Estado:\*\* HECHA$/> **Estado:** EN_CURSO/' ;;
        # Las secciones se buscan por su nombre: sin el número delante, la casilla sin marcar se sigue viendo.
        2n) edit .ai/epics/01-demo/phase-02.md 's/^## [0-9][0-9]*\. /## /'
            awk_edit .ai/epics/01-demo/phase-02.md '!d && /^- \[x\]/ { sub(/\[x\]/, "[ ]"); d = 1 } { print }' ;;
        3)  awk_edit .ai/epics/01-demo/epic-plan.md '!d && /^- \[x\]/ { sub(/\[x\]/, "[ ]"); d = 1 } { print }' ;;
        4)  printf '\nVer fase 01/99.\n' >> .ai/BACKLOG.md ;;
        5)  edit .ai/epics/01-demo/phase-02.md 's/^> \*\*Migraciones:\*\* ninguna$/> **Migraciones:** autorizadas (users)/' ;;
        6)  edit .ai/epics/01-demo/phase-02.md \
                's/^> \*\*Contrato HTTP:\*\* SIN CAMBIOS$/> **Contrato HTTP:** CAMBIO AUTORIZADO (prueba)/' ;;
        7)  edit .ai/STATE.md 's/^- \*\*Decisiones abiertas:\*\* 0 (0/- **Decisiones abiertas:** 1 (0/' ;;
        8)  printf '| 1 | %s | api | interno | 99 | Prueba. | — | abierto |\n' "$DATE" >> .ai/BACKLOG.md ;;
        9)  awk_edit .ai/project/DECISIONS.md 'BEGIN { FS = OFS = "|" } /^## Stack/ { s = 1 }
                s && !d && /^\| `/ { $3 = " 0.0.0 "; d = 1 } { print }' ;;
        # Un paquete que el stack da por hecho y el proyecto no versiona.
        9n) awk_edit .ai/project/DECISIONS.md '/^## Stack/ { s = 1 } s && !d && /^\| `/ { d = 1; next } { print }' ;;
        10) printf '\nVer %s/docs/x.md.\n' "$SIBLING" >> .ai/DOMAIN.md ;;
        11) printf '\nVer `bin/no-existe.sh`.\n' >> CLAUDE.md ;;
        12) printf '\nVer `.ai/RULES.md §No existe`.\n' >> CLAUDE.md ;;
        12n) printf '\nVer `.ai/WORKFLOW.md §3`.\n' >> CLAUDE.md ;;
        *)  return 1 ;;
    esac
}

# provoke <caso> <qué se estropea> <texto que el guardián tiene que imprimir>
provoke() {
    d="$WORK/$KIT-$1"
    cp -R "$BASE" "$d"
    if ! ( cd "$d" && estropea "$1" ); then
        printf '  ✗ %-3s %s: no se pudo provocar\n' "$1" "$2"; FAIL=1; return
    fi
    out=$(sh "$d/bin/check-docs.sh" --strict 2>&1)
    rc=$?
    if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -qF -- "$3"; then
        printf '  ✓ %-3s %s\n' "$1" "$2"
        DETECTED=$((DETECTED + 1))
    else
        printf '  ✗ %-3s %s: el guardián salió %s sin decir «%s»\n' "$1" "$2" "$rc" "$3"
        printf '%s\n' "$out" | grep -E '✗|⚠' | sed 's/^/        /'
        FAIL=1
    fi
}

# ── El instalador, sobre la instalación de prueba ($BASE) ───────────────────
# shellcheck disable=SC2016  # las comillas invertidas de los mensajes son literales
test_installer() {
    lock="$BASE/.ai/protocol.lock"
    printf '  ◆ instalador\n'

    # El lock: las dos versiones y una línea por archivo de los manifiestos, con la suma de lo instalado. Los
    # archivos que la instalación de prueba rellenó (semillas) ya no tienen esa suma: se miden en la de --dry-run.
    want=$(for m in "$ROOT/core/core.json" "$ROOT/stacks/$KIT/stack.json"; do
               json_list "$m" files; json_list "$m" seed
           done | grep -c .)
    have=$(grep -c '^file ' "$lock" 2>/dev/null)
    bad_sums=$(awk '$1 == "file" && $2 == "kit" { print $3, $4 }' "$lock" | while read -r s p; do
                   [ "$(sha "$BASE/$p")" = "$s" ] || printf '%s ' "$p"; done)
    if grep -q '^package core ' "$lock" && grep -q "^package $KIT " "$lock" && [ "$have" -eq "$want" ] && [ -z "$bad_sums" ]; then
        ok "deja .ai/protocol.lock con las versiones y la suma de los $have archivos"
    else
        fail "el lock no cuadra: $have líneas de $want; sumas que no coinciden: ${bad_sums:-ninguna}"
    fi

    dry="$WORK/$KIT-dry"
    if sh "$ROOT/install.sh" --stack "$KIT" --target "$dry" --dry-run > /dev/null 2>&1 && [ ! -e "$dry" ]; then
        ok '--dry-run termina en 0 y no escribe nada'
    else
        fail '--dry-run escribió algo o no terminó en 0'
    fi

    if out=$(sh "$ROOT/install.sh" --stack "$KIT" --target "$BASE" 2>&1); then
        fail 'instalar sobre una instalación con lock no falla'
    else
        if printf '%s\n' "$out" | grep -qF 'ya tiene .ai/protocol.lock'; then ok 'instalar otra vez falla: eso es un --upgrade'
        else fail "instalar otra vez falla, pero sin decir por qué: $out"; fi
    fi

    before=$(snapshot "$BASE")
    out=$(sh "$ROOT/install.sh" --upgrade --target "$BASE" 2>&1)
    rc=$?
    if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qF 'sin cambios' && [ "$(snapshot "$BASE")" = "$before" ]; then
        ok '--upgrade sin cambios dice «sin cambios» y no modifica ningún archivo'
    else
        fail "--upgrade sin cambios salió $rc o tocó algo:"; printf '%s\n' "$out" | sed 's/^/      /'
    fi

    # Un kit nuevo cambia WORKFLOW.md (el proyecto no lo tocó) y CLAUDE.md (el proyecto sí), y el proyecto
    # cambió además su STATE.md, que es memoria.
    up="$WORK/$KIT-up"
    cp -R "$BASE" "$up"
    kit_copy "$WORK/$KIT-kit2"
    printf '\nNovedad del kit.\n' >> "$WORK/$KIT-kit2/core/.ai/WORKFLOW.md"
    printf '\nNovedad del kit.\n' >> "$WORK/$KIT-kit2/core/CLAUDE.md"
    printf '\nCambio del proyecto.\n' >> "$up/CLAUDE.md"
    state=$(sha "$up/.ai/STATE.md")
    out=$(sh "$WORK/$KIT-kit2/install.sh" --upgrade --target "$up" 2>&1)
    again=$(sh "$WORK/$KIT-kit2/install.sh" --upgrade --target "$up" --dry-run 2>&1)
    if printf '%s\n' "$out" | grep -qE '~ \.ai/WORKFLOW\.md +actualizado' \
       && cmp -s "$up/.ai/WORKFLOW.md" "$WORK/$KIT-kit2/core/.ai/WORKFLOW.md"; then
        ok '--upgrade actualiza, con su diff, un archivo del kit que el proyecto no tocó'
    else
        fail '--upgrade no actualizó .ai/WORKFLOW.md:'; printf '%s\n' "$out" | sed 's/^/      /'
    fi
    if printf '%s\n' "$out" | grep -qE '! CLAUDE\.md +conflicto' && tail -n 1 "$up/CLAUDE.md" | grep -qF 'Cambio del proyecto.' \
       && printf '%s\n' "$again" | grep -qE '! CLAUDE\.md +conflicto'; then
        ok '--upgrade no pisa lo que el proyecto cambió: conflicto con su diff, hasta que se resuelve'
    else
        fail '--upgrade no trató CLAUDE.md como conflicto:'; printf '%s\n' "$out" | sed 's/^/      /'
    fi
    if [ "$(sha "$up/.ai/STATE.md")" = "$state" ]; then ok '--upgrade no toca la memoria (.ai/STATE.md)'
    else fail '--upgrade modificó .ai/STATE.md'; fi

    kit_copy "$WORK/$KIT-kit3"
    edit "$WORK/$KIT-kit3/stacks/$KIT/stack.json" 's/"core": ".*"/"core": ">=9.0.0 <10.0.0"/'
    if out=$(sh "$WORK/$KIT-kit3/install.sh" --stack "$KIT" --target "$WORK/$KIT-kit3-p" 2>&1); then
        fail 'install.sh instala un stack que pide otra versión del núcleo'
    else
        if printf '%s\n' "$out" | grep -qF 'pide el núcleo' && [ ! -e "$WORK/$KIT-kit3-p" ]; then
            ok 'no instala un stack incompatible con la versión del núcleo'
        else
            fail "un stack incompatible falla, pero no por el rango del núcleo: $out"
        fi
    fi
}

# ── tests/structure.sh, frente a un fallo de cada chequeo ───────────────────
# breaks <caso> <texto que structure.sh tiene que imprimir>: en una copia limpia del repo, mete el defecto.
# shellcheck disable=SC2016  # las comillas invertidas son literales
breaks() {
    d="$WORK/structure-$1"
    kit_copy "$d"
    (
        cd "$d" || exit 1
        case "$1" in
            listado)   printf 'x\n' > stacks/laravel/extra.md ;;
            capas)     cp core/AGENTS.md stacks/nextjs/AGENTS.md
                       edit stacks/nextjs/stack.json 's#^    "docs/README.md"$#    "docs/README.md",\n    "AGENTS.md"#' ;;
            gates)     edit stacks/nextjs/bin/verify.sh "s/^run 'tipos'/run 'types'/" ;;
            stacks)    printf '\nVer `phpstan.neon`.\n' >> stacks/nextjs/.ai/RULES.md ;;
            nucleo)    printf '\nVer `docs/vendor/INDEX.md`.\n' >> core/CLAUDE.md ;;
        esac
    )
    if ! out=$(sh "$d/tests/structure.sh" 2>&1) && printf '%s\n' "$out" | grep -qF -- "$2"; then ok "$1: $2"
    else fail "$1: structure.sh no dijo «$2»"; printf '%s\n' "$out" | grep '✗' | sed 's/^/      /'; fi
}

test_structure() {
    printf '◆ tests/structure.sh\n'
    if sh "$ROOT/tests/structure.sh" > /dev/null 2>&1; then ok 'pasa sobre el repo'; else fail 'no pasa sobre el repo'; fi
    breaks listado 'stacks/laravel/extra.md no está en stack.json'
    breaks capas   'stacks/nextjs/AGENTS.md ya lo trae el núcleo'
    breaks gates   'corre el gate «types», que stack.json no declara'
    breaks stacks  'cita «phpstan.neon», que es de otro stack'
    breaks nucleo  'cita «docs/vendor/INDEX.md», que no traen todos los stacks'
}

# ── Por kit ─────────────────────────────────────────────────────────────────
for KIT in $KITS; do
    case "$KIT" in
        laravel) SIBLING=frontend ;;
        nextjs)  SIBLING=backend ;;
        *) printf '✗ kit desconocido: %s\n' "$KIT"; exit 1 ;;
    esac
    printf '◆ %s\n' "$KIT"
    BASE="$WORK/$KIT"
    install "$KIT" "$BASE" || { fail "install.sh --stack $KIT no termina en 0"; continue; }
    ok "install.sh --stack $KIT termina en 0"

    if ! out=$(sh "$BASE/bin/check-docs.sh" --strict 2>&1); then
        printf '  ✗ la instalación con la épica de prueba no pasa el guardián:\n'
        printf '%s\n' "$out" | sed 's/^/      /'
        FAIL=1
        continue
    fi
    printf '  ✓ la instalación con la épica de prueba pasa el guardián (--strict)\n'
    if sh "$BASE/bin/measure-context.sh" > /dev/null; then
        printf '  ✓ bin/measure-context.sh mide la instalación\n'
    else
        printf '  ✗ bin/measure-context.sh falla sobre la instalación\n'; FAIL=1
    fi

    DETECTED=0
    TOTAL=13
    provoke 0  'instalación: un {{RELLENAR}} sin completar'          'marcador(es) {{RELLENAR}}'
    provoke 1  'puntero: «Fase activa» en una fase HECHA'            'la cabecera apunta a'
    provoke 2  'fases: una HECHA pasa a EN_CURSO sin tocar el mapa'  'dice EN_CURSO y el mapa dice HECHA'
    provoke 2n 'fases: una casilla sin marcar, con secciones sin número' 'casilla(s) de «Criterios de éxito» sin marcar'
    provoke 3  'épicas: una CERRADA con su cierre sin marcar'        'casilla(s) del «Criterio de cierre» sin marcar'
    provoke 4  'referencias: «fase 01/99» en BACKLOG.md'             'cita la fase 01/99'
    if grep -q '^> \*\*Migraciones:\*\*' "$BASE/.ai/templates/phase.template.md"; then
        provoke 5 'despliegue: migraciones sin fila en el manifiesto' 'declara migraciones y no tiene fila'
    else
        TOTAL=12
        if printf '%s\n' "$out" | grep -qF 'no declara migraciones: no aplica' \
           && ! grep -q '^> \*\*Migraciones:\*\*' "$BASE"/.ai/epics/*/phase-*.md; then
            printf '  ✓ 5   despliegue: no aplica; el guardián acepta fases sin «Migraciones:»\n'
        else
            printf '  ✗ 5   despliegue: la plantilla no declara migraciones y el guardián no lo trata como «no aplica»\n'
            FAIL=1
        fi
    fi
    provoke 6  'traspaso: CAMBIO AUTORIZADO sin traspaso'            'cambia el contrato y nada lo traspasa'
    provoke 7  'contadores: «Decisiones abiertas» sube sin DOMAIN'   'la cabecera dice «Decisiones abiertas: 1'
    provoke 8  'destinos: «99» en la columna Destino'                '«Destino» es 99'
    provoke 9  'stack: otra versión en DECISIONS.md §Stack'          'dice 0.0.0 y el manifiesto dice'
    provoke 9n 'stack: un paquete de RULES.md sin versión'         '(de RULES.md §Stack) no tiene versión'
    provoke 10 'cross-repo: cita un documento del repo hermano'      "cita documentos de «$SIBLING»"
    # shellcheck disable=SC2016  # las comillas invertidas son literales
    provoke 11 'rutas: cita bin/no-existe.sh'                        'cita `bin/no-existe.sh`, que no existe'
    provoke 12 'secciones: cita una sección que no existe'           'cita «.ai/RULES.md §No existe»'
    provoke 12n 'secciones: cita una sección por su número'          'cita «.ai/WORKFLOW.md §3» por su número'
    # 2n, 9n y 12n son variantes de los chequeos 2, 9 y 12: no cuentan entre los 13 de la cabecera.
    n=$((DETECTED - 3))
    note=''
    [ "$TOTAL" -eq 13 ] || note=' (el 5 no aplica)'
    printf '  → %s/%s fallos de la cabecera provocados y detectados%s\n' "$n" "$TOTAL" "$note"
    [ "$n" -eq "$TOTAL" ] || FAIL=1

    test_installer
done

test_structure

printf '\n'
if [ "$FAIL" -eq 0 ]; then echo '✓ tests/run.sh: todo en verde'; else echo '✗ tests/run.sh: hay fallos'; fi
exit "$FAIL"
