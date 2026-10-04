#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# tests/run.sh — el guardián de cada kit, probado en las dos direcciones.
#
# ◆ QUÉ HACE, POR KIT
#   1. Lo instala en un directorio temporal, como un proyecto nuevo: copia el
#      kit, superpone tests/fixtures/<kit>/ (el composer.json o package.json con
#      las versiones de .ai/RULES.md §Stack y versiones exactas, y los archivos
#      del proyecto que RULES.md cita), rellena cada {{RELLENAR}} y declara un
#      repo hermano para que los chequeos «traspaso» y «cross-repo» apliquen.
#   2. Crea desde las plantillas una épica de prueba: 01-demo, CERRADA, con dos
#      fases HECHA; y 02-demo, con su fase 01 LISTA_PARA_EJECUTAR y el puntero
#      de STATE.md en ella.
#   3. Comprueba que `sh bin/check-docs.sh --strict` pasa sobre esa instalación.
#   4. Provoca, cada uno en una copia limpia, los 13 fallos de «CÓMO PROVOCAR
#      CADA FALLO» de la cabecera de bin/check-docs.sh, más dos variantes: una
#      fase con las secciones sin número (2n) y una cita de sección por su
#      número (12n). Cada caso tiene que fallar con el mensaje de su chequeo,
#      no con cualquier otro.
#   El fallo 5 (migraciones) sólo existe si la plantilla de fase declara
#   «Migraciones:»; en un kit que no lo hace, se comprueba en su lugar que el
#   guardián acepta fases sin ese campo.
#
# ◆ CÓMO SE AÑADE UN CASO
#   Un chequeo nuevo del guardián trae su caso aquí: una rama en estropea()
#   que mete el defecto en la instalación (corre en su raíz) y una línea
#   `provoke` con el texto que el guardián tiene que imprimir.
#
# ◆ USO
#   sh tests/run.sh             # los dos kits
#   sh tests/run.sh laravel     # sólo uno
#
# ◆ CONTRATO
#   Sale 0 si la instalación pasa el guardián y todos los fallos provocados se
#   detectan; != 0 si no. No toca el repo: trabaja en un directorio temporal.
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
# edit <archivo> <script de sed>: sed en el sitio sin «-i», que no es POSIX.
edit() { sed "$2" "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }

# awk_edit <archivo> <programa de awk>: lo mismo con awk.
awk_edit() { awk "$2" "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }

# fill_stack <RULES.md> <manifiesto>: la versión de cada fila de §Stack sale del manifiesto (una pareja
# «"paquete": "versión"» por línea). Una fila con varios paquetes toma la del primero.
fill_stack() {
    awk '
        NR == FNR {
            if ($0 ~ /^ *"[^"]+": *"[^"]*",? *$/) {
                l = $0; sub(/^ *"/, "", l); sub(/",? *$/, "", l); split(l, kv, /": *"/); v[kv[1]] = kv[2]
            }
            next
        }
        /^## [0-9]+\. Stack/ { s = 1 }
        s && /^## / && !/Stack/ { s = 0 }
        s && /^\| `/ && (i = index($0, "{{RELLENAR")) > 0 {
            n = $0; sub(/^\| `/, "", n); sub(/`.*/, "", n)
            if (n in v) { r = substr($0, i); $0 = substr($0, 1, i - 1) v[n] substr(r, index(r, "}}") + 2) }
        }
        { print }' "$2" "$1" > "$1.tmp" && mv "$1.tmp" "$1"
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

# install <kit> <dir>: el kit instalado y con la épica de prueba.
install() {
    mkdir -p "$2"
    cp -R "$ROOT/$1/." "$2/"
    cp -R "$FIXTURES/$1/." "$2/"
    (
        cd "$2" || exit 1
        manifest=composer.json
        [ -f package.json ] && manifest=package.json
        fill_stack .ai/RULES.md "$manifest"
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
        9)  awk_edit .ai/RULES.md 'BEGIN { FS = OFS = "|" } /^## [0-9]+\. Stack/ { s = 1 }
                s && !d && /^\| `/ { $3 = " 0.0.0 "; d = 1 } { print }' ;;
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

# ── Por kit ─────────────────────────────────────────────────────────────────
for KIT in $KITS; do
    case "$KIT" in
        laravel) SIBLING=frontend ;;
        nextjs)  SIBLING=backend ;;
        *) printf '✗ kit desconocido: %s\n' "$KIT"; exit 1 ;;
    esac
    printf '◆ %s\n' "$KIT"
    BASE="$WORK/$KIT"
    install "$KIT" "$BASE"

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
    provoke 9  'stack: otra versión en RULES.md §Stack'              'dice 0.0.0 y el manifiesto dice'
    provoke 10 'cross-repo: cita un documento del repo hermano'      "cita documentos de «$SIBLING»"
    # shellcheck disable=SC2016  # las comillas invertidas son literales
    provoke 11 'rutas: cita bin/no-existe.sh'                        'cita `bin/no-existe.sh`, que no existe'
    provoke 12 'secciones: cita una sección que no existe'           'cita «.ai/RULES.md §No existe»'
    provoke 12n 'secciones: cita una sección por su número'          'cita «.ai/WORKFLOW.md §3» por su número'
    # 2n y 12n son variantes de los chequeos 2 y 12: no cuentan entre los 13 de la cabecera.
    n=$((DETECTED - 2))
    note=''
    [ "$TOTAL" -eq 13 ] || note=' (el 5 no aplica)'
    printf '  → %s/%s fallos de la cabecera provocados y detectados%s\n' "$n" "$TOTAL" "$note"
    [ "$n" -eq "$TOTAL" ] || FAIL=1
done

printf '\n'
if [ "$FAIL" -eq 0 ]; then echo '✓ tests/run.sh: todo en verde'; else echo '✗ tests/run.sh: hay fallos'; fi
exit "$FAIL"
