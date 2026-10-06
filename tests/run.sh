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
#   2. Crea desde las plantillas las épicas de prueba: 01-demo, CERRADA, con dos
#      fases HECHA; y 02-paquete, creada desde el paquete de tareas
#      tests/fixtures/stages/E1.md como lo haría /plan-epic: una fase de código
#      HECHA y revisada, una de operación en ESPERA_EVIDENCIA y una ligera
#      LISTA_PARA_EJECUTAR, con el puntero de STATE.md en ella.
#   3. Comprueba que `sh bin/check-docs.sh --strict` pasa sobre esa instalación,
#      que bin/measure-context.sh la mide y que bin/handoff.sh imprime lo que
#      una fase cerrada dejó para la siguiente (y falla con una sin cerrar).
#   4. Provoca, cada uno en una copia limpia, los 15 fallos de «CÓMO PROVOCAR
#      CADA FALLO» de la cabecera de bin/check-docs.sh, más sus variantes (los
#      casos con letra): el puntero en una fase que espera evidencia (1e), una
#      fase con las secciones sin número (2n), una evidencia enlazada que no
#      existe (2e), los campos de la cabecera de una fase y la evidencia humana
#      (2t, 2h, 2w, 2x, 2l, 2c), su revisión (2r, 2s), un id D<n> que no existe
#      en ningún sitio (3n), §Esperando evidencia desfasada (7e), un paquete de
#      RULES.md sin versión en .ai/project/DECISIONS.md (9n), una cita de
#      sección por su número (12n), cada tope de la memoria (13a…13e) y un
#      criterio de una tarea externa que no está literal en su fase (14c). Cada
#      caso tiene que fallar con el mensaje de su chequeo, no con cualquier
#      otro. Y al revés, casos que tienen que pasar: una evidencia que sí existe
#      (2f), una fase sin «Tipo» (2a, como las de antes de los tipos), un
#      bloqueante resuelto (2v) y un epic-plan que cita una decisión archivada
#      en .ai/archive/DOMAIN.md (3a).
#   El fallo 5 (migraciones) sólo existe si la plantilla de fase declara
#   «Migraciones:»; en un kit que no lo hace, se comprueba en su lugar que el
#   guardián acepta fases sin ese campo.
#   5. Comprueba que lo que lee cada sesión al arrancar no se aleja más de un
#      3 % de tests/context-baseline.txt: falla si crece y avisa si baja, para
#      que se actualice la línea base.
#   6. Prueba el instalador: el lock tiene la suma de cada archivo instalado;
#      --dry-run no escribe nada; instalar otra vez falla; un --upgrade sin
#      cambios dice «sin cambios» y no toca ningún archivo; con un kit nuevo,
#      actualiza lo que el proyecto no tocó, deja como conflicto lo que sí
#      tocó, retira lo que ya no trae (con su carpeta si queda vacía) y no toca
#      la memoria; y no instala un stack incompatible con el núcleo.
#   7. Prueba la protección del protocolo (bin/check-protocol.sh) en una copia
#      de la instalación hecha repositorio git: una rama de fase que edita
#      CLAUDE.md, o el propio script, en un commit que no es de ámbito protocol
#      falla; el mismo cambio en un commit chore(protocol) pasa, y también los
#      cambios en archivos del proyecto (la memoria, .ai/project/verify.conf)
#      y cualquier cambio fuera de una rama de fase. Necesita git.
#
# ◆ ADEMÁS
#   Provoca en una copia del repo un fallo de cada chequeo de
#   tests/structure.sh y comprueba que lo detecta.
#
# ◆ CÓMO SE AÑADE UN CASO
#   Un chequeo nuevo del guardián trae su caso aquí: una rama en estropea()
#   que mete el defecto en la instalación (corre en su raíz) y una línea
#   `provoke` con el texto que el guardián tiene que imprimir (o `accept`, si
#   el caso tiene que pasar). Un caso con número es un fallo de la cabecera de
#   bin/check-docs.sh; uno con letra, una variante.
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

# make_epic <slug> <estado> <fases…>: el epic-plan desde su plantilla, con una fila por cada una de esas fases.
make_epic() {
    slug=$1; st=$2; shift 2
    mkdir -p ".ai/epics/$slug"
    plan=".ai/epics/$slug/epic-plan.md"
    sed -e "s/^# Épica NN — .*/# Épica ${slug%%-*} — Demo/" \
        -e "s/^> \*\*Slug:\*\* .*/> **Slug:** \`$slug\`/" \
        -e "s/^> \*\*Estado:\*\* .*/> **Estado:** $st/" \
        .ai/templates/epic-plan.template.md > "$plan"
    awk_edit "$plan" "/^## Fases/ { s = 1 } s && /^## / && !/Fases/ { s = 0 }
        s && /^\| [0-9][0-9] \|/ { next }
        { print }
        s && /^\|---/ { n = split(\"$*\", k, \" \"); for (i = 1; i <= n; i++) print \"| \" k[i] \" | Demo | — |\" }"
    [ "$st" = CERRADA ] && edit "$plan" 's/^- \[ \]/- [x]/'
    return 0
}

# make_phase <slug> <FF> <estado> <depende de>: la fase desde su plantilla; HECHA o ESPERA_EVIDENCIA, con su
# RESULTADO, sus casillas marcadas y su revisión.
make_phase() {
    f=".ai/epics/$1/phase-$2.md"
    sed -e "s/^# Fase FF — .*/# Fase $2 — Demo/" \
        -e "s/^> \*\*Épica:\*\* .*/> **Épica:** \`$1\` · **Depende de:** $4/" \
        -e "s/^> \*\*Estado:\*\* .*/> **Estado:** $3/" \
        .ai/templates/phase.template.md > "$f"
    case "$3" in HECHA|ESPERA_EVIDENCIA) ;; *) return 0 ;; esac
    edit "$f" "s/^- \[ \]/- [x]/; s/^\*\*Fecha:\*\*\$/**Fecha:** $DATE/
        s/^Sin revisar\.\$/**Revisión 1 · $DATE · \`aaaaaaa..bbbbbbb\`:** 0 bloqueantes, 0 no bloqueantes./"
    awk_edit "$f" '{ print } /^### (Qué se hizo|Lo que la siguiente fase necesita saber)$/ { print ""; print "Fase de prueba." }'
}

# header <fase> <línea>: una línea más en la cabecera de la fase, tras «Tipo:».
header() { awk_edit "$1" "{ print } /^> \\*\\*Tipo:\\*\\*/ { print \"$2\" }"; }

# criterion <fase> <línea>: una casilla más al final de «Criterios de éxito».
criterion() { awk_edit "$1" "/^## [0-9]+\\. Restricciones/ { print \"$2\"; print \"\" } { print }"; }

# task <fase> <ID> <casilla> <comando>: la fase sale de esa tarea del paquete E1, con su criterio literal en §5
# seguido del comando que lo prueba.
task() {
    header "$1" "> **Tarea externa:** $2"
    c=$(awk -F'|' -v t="$2" '{ i = $2; gsub(/ /, "", i) } i == t { c = $5; sub(/^ +/, "", c); sub(/ +$/, "", c); print c }' .ai/stages/E1.md)
    criterion "$1" "$3 $c — \`$4\`"
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
        # La épica desde el paquete E1: lo que dejaría /plan-epic (.claude/skills/plan-epic/SKILL.md §Desde un
        # paquete de tareas). E1-04 es de otro repo y no entra.
        mkdir -p .ai/stages && cp "$FIXTURES/stages/E1.md" .ai/stages/E1.md
        make_epic 02-paquete EN_CURSO 01 02 03
        # shellcheck disable=SC2016  # las comillas invertidas son literales
        printf '\n- `.ai/stages/E1.md §Decisiones vigentes`.\n' >> .ai/epics/02-paquete/epic-plan.md
        p=.ai/epics/02-paquete
        make_phase 02-paquete 01 HECHA '—'
        task $p/phase-01.md E1-01 '- [x]' 'curl -s http://localhost/api/demos'
        make_phase 02-paquete 02 ESPERA_EVIDENCIA 'fase 01'
        edit $p/phase-02.md 's/^> \*\*Tipo:\*\* .*/> **Tipo:** operación/'
        task $p/phase-02.md E1-02 '- [ ] [humano]' 'dig +short demo.example'
        make_phase 02-paquete 03 LISTA_PARA_EJECUTAR 'fase 01'
        task $p/phase-03.md E1-03 '- [ ]' 'curl -s http://localhost/'
        header $p/phase-03.md '> **Modo:** ligero'
        awk_edit $p/phase-03.md '/^## [0-9]+\. Entregables/ { s = 1 } s && /^## [0-9]+\. Archivos/ { s = 0 } s && /^3\.$/ { next } { print }'

        awk_edit .ai/STATE.md "
            /^## Mapa de fases/ { m = 1 }
            { print }
            m && /^\|---/ { m = 0
                print \"| 01-demo | 01 | HECHA | $DATE |\"
                print \"| 01-demo | 02 | HECHA | $DATE |\"
                print \"| 02-paquete | 01 | HECHA | $DATE |\"
                print \"| 02-paquete | 02 | ESPERA_EVIDENCIA | $DATE |\"
                print \"| 02-paquete | 03 | LISTA_PARA_EJECUTAR | — |\" }"
        awk_edit .ai/STATE.md '/^## Esperando evidencia/ { w = 1 } /^## Bloqueo activo/ { w = 0 }
            w && /^\*\*Ninguna\.\*\*$/ { print "- 02-paquete/02 — la evidencia [humano] de E1-02."; next } { print }'
        edit .ai/STATE.md "s/^- \*\*Épica activa:\*\* .*/- **Épica activa:** 02-paquete/
            s/^- \*\*Fase activa:\*\* .*/- **Fase activa:** 03/
            s#^- \*\*Archivo de la fase:\*\* .*#- **Archivo de la fase:** \`.ai/epics/02-paquete/phase-03.md\`#
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
        # El puntero no se queda en una fase que espera la evidencia de la persona.
        1e) edit .ai/STATE.md 's/^- \*\*Fase activa:\*\* .*/- **Fase activa:** 02/
                s#^- \*\*Archivo de la fase:\*\* .*#- **Archivo de la fase:** `.ai/epics/02-paquete/phase-02.md`#' ;;
        2)  edit .ai/epics/01-demo/phase-02.md 's/^> \*\*Estado:\*\* HECHA$/> **Estado:** EN_CURSO/' ;;
        # La cabecera y la evidencia humana (.claude/skills/plan-phase/SKILL.md §Tipos de tarea).
        2t) edit .ai/epics/01-demo/phase-02.md 's/^> \*\*Tipo:\*\* .*/> **Tipo:** otro/' ;;
        2a) edit .ai/epics/01-demo/phase-02.md '/^> \*\*Tipo:\*\*/d' ;;
        2h) criterion .ai/epics/01-demo/phase-02.md '- [x] [humano] Prueba.' ;;
        2w) edit .ai/epics/02-paquete/phase-02.md 's/^- \[ \] \[humano\]/- [x] [humano]/' ;;
        2x) awk_edit .ai/epics/02-paquete/phase-02.md '!d && /^- \[x\]/ { sub(/\[x\]/, "[ ]"); d = 1 } { print }' ;;
        2l) awk_edit .ai/epics/02-paquete/phase-03.md '{ print } /^2\.$/ { print "3. Otro." }' ;;
        2c) edit .ai/epics/02-paquete/phase-03.md 's/^> \*\*Contrato HTTP:\*\* SIN CAMBIOS$/> **Contrato HTTP:** CAMBIO AUTORIZADO (prueba)/' ;;
        # La revisión: un bloqueante abierto (2r) o resuelto (2v), y una fase cerrada sin revisar (2s).
        2r|2v) b='- [ ] **B1** · `composer.json` — Prueba.'; [ "$1" = 2v ] && b='- [x] **B1** · `composer.json` — Prueba. Resuelto en `ccccccc`.'
            awk_edit .ai/epics/01-demo/phase-02.md "{ print } /^\\*\\*Revisión 1/ { print \"\"; print \"$b\" }" ;;
        2s) edit .ai/epics/01-demo/phase-02.md 's/^\*\*Revisión 1 .*/Sin revisar./' ;;
        # Las secciones se buscan por su nombre: sin el número delante, la casilla sin marcar se sigue viendo.
        2n) edit .ai/epics/01-demo/phase-02.md 's/^## [0-9][0-9]*\. /## /'
            awk_edit .ai/epics/01-demo/phase-02.md '!d && /^- \[x\]/ { sub(/\[x\]/, "[ ]"); d = 1 } { print }' ;;
        3)  awk_edit .ai/epics/01-demo/epic-plan.md '!d && /^- \[x\]/ { sub(/\[x\]/, "[ ]"); d = 1 } { print }' ;;
        4)  printf '\nVer fase 01/99.\n' >> .ai/BACKLOG.md ;;
        5)  edit .ai/epics/01-demo/phase-02.md 's/^> \*\*Migraciones:\*\* ninguna$/> **Migraciones:** autorizadas (users)/' ;;
        6)  edit .ai/epics/01-demo/phase-02.md \
                's/^> \*\*Contrato HTTP:\*\* SIN CAMBIOS$/> **Contrato HTTP:** CAMBIO AUTORIZADO (prueba)/' ;;
        7)  edit .ai/STATE.md 's/^- \*\*Decisiones abiertas:\*\* 0 (0/- **Decisiones abiertas:** 1 (0/' ;;
        7e) edit .ai/STATE.md 's/^- 02-paquete\/02 — .*/**Ninguna.**/' ;;
        8)  printf '| 1 | %s | api | interno | 99 | Prueba. | — | abierto |\n' "$DATE" >> .ai/BACKLOG.md ;;
        9)  awk_edit .ai/project/DECISIONS.md 'BEGIN { FS = OFS = "|" } /^## Stack/ { s = 1 }
                s && !d && /^\| `/ { $3 = " 0.0.0 "; d = 1 } { print }' ;;
        # Un paquete que el stack da por hecho y el proyecto no versiona.
        9n) awk_edit .ai/project/DECISIONS.md '/^## Stack/ { s = 1 } s && !d && /^\| `/ { d = 1; next } { print }' ;;
        10) printf '\nVer %s/docs/x.md.\n' "$SIBLING" >> .ai/DOMAIN.md ;;
        11) printf '\nVer `bin/no-existe.sh`.\n' >> CLAUDE.md ;;
        12) printf '\nVer `.ai/RULES.md §No existe`.\n' >> CLAUDE.md ;;
        12n) printf '\nVer `.ai/WORKFLOW.md §3`.\n' >> CLAUDE.md ;;
        # Una evidencia enlazada desde el RESULTADO: sin el archivo (2e) y con él (2f).
        2e|2f) awk_edit .ai/epics/01-demo/phase-02.md '{ print } /^### Verificación$/ { print ""; print "Salida en `.ai/epics/01-demo/evidence/02-verify.txt`." }'
            if [ "$1" = 2f ]; then mkdir -p .ai/epics/01-demo/evidence && echo ok > .ai/epics/01-demo/evidence/02-verify.txt; fi ;;
        # Un epic-plan que cita una decisión: que no existe (3n) o que está archivada (3a).
        3n) printf '\nVer D9.\n' >> .ai/epics/01-demo/epic-plan.md ;;
        3a) printf '| D1 | Prueba. | otro | — | fase 01/01 | respondida | A — %s |\n' "$DATE" >> .ai/archive/DOMAIN.md
            printf '\nVer D1.\n' >> .ai/epics/01-demo/epic-plan.md ;;
        # La memoria: lo cerrado va a .ai/archive/ y «Últimos movimientos» tiene un tope.
        13) printf '| 1 | %s | api | — | — | Prueba. | 01/01 | cerrado — 01/01 |\n' "$DATE" >> .ai/BACKLOG.md ;;
        13a) for i in 1 2 3 4 5 6 7 8 9 10; do printf -- '- Movimiento %s.\n' "$i" >> .ai/STATE.md; done ;;
        13b) printf '| 2 | %s | fase 01/01 | Prueba. | aplicada — %s |\n' "$DATE" "$DATE" >> .ai/PROTOCOL.md ;;
        13c) printf '\n### %s — Prueba (fase 01/01)\n\n**Reemplazada por:** %s — Otra.\n' "$DATE" "$DATE" >> .ai/DOMAIN.md ;;
        13d) printf '| D1 | Prueba. | otro | — | fase 01/01 | respondida | A — %s |\n' "$DATE" >> .ai/DOMAIN.md ;;
        13e) printf '| 1 | %s | api | — | — | Prueba. | 01/01 | cerrado — 01/01 |\n' "$DATE" >> .ai/archive/BACKLOG.md
             printf '| 1 | %s | api | interno | — | Prueba. | — | abierto |\n' "$DATE" >> .ai/BACKLOG.md ;;
        # Las tareas externas: un ID que no está en ningún paquete (14) y un criterio que no es el literal (14c).
        14) edit .ai/epics/02-paquete/phase-01.md 's/^> \*\*Tarea externa:\*\* .*/> **Tarea externa:** T9-99/' ;;
        14c) edit .ai/epics/02-paquete/phase-01.md 's/responde 200 con la lista de demos/responde 200/' ;;
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
        case "$1" in *[!0-9]*) ;; *) DETECTED=$((DETECTED + 1)) ;; esac
    else
        printf '  ✗ %-3s %s: el guardián salió %s sin decir «%s»\n' "$1" "$2" "$rc" "$3"
        printf '%s\n' "$out" | grep -E '✗|⚠' | sed 's/^/        /'
        FAIL=1
    fi
}

# accept <caso> <qué se cambia>: en una copia limpia, un cambio que el guardián tiene que aceptar.
accept() {
    d="$WORK/$KIT-$1"
    cp -R "$BASE" "$d"
    ( cd "$d" && estropea "$1" ) || { printf '  ✗ %-3s %s: no se pudo preparar\n' "$1" "$2"; FAIL=1; return; }
    if out=$(sh "$d/bin/check-docs.sh" --strict 2>&1); then printf '  ✓ %-3s %s\n' "$1" "$2"
    else
        printf '  ✗ %-3s %s: el guardián lo rechaza\n' "$1" "$2"
        printf '%s\n' "$out" | grep -E '✗|⚠' | sed 's/^/        /'
        FAIL=1
    fi
}

# ── Lo que lee cada sesión, frente a tests/context-baseline.txt ─────────────
# Sobre una instalación limpia: la de prueba tiene la épica y los marcadores rellenos, y mide otra cosa.
test_context() {
    clean="$WORK/$KIT-clean"
    sh "$ROOT/install.sh" --stack "$KIT" --target "$clean" > /dev/null 2>&1 || { fail 'no se pudo instalar limpio'; return; }
    sh "$clean/bin/measure-context.sh" > "$WORK/$KIT.context" || { fail 'bin/measure-context.sh falla'; return; }
    awk -v k="$KIT" '$1 == k { print $2, $3 }' "$ROOT/tests/context-baseline.txt" | while read -r sess base; do
        now=$(awk -v s="$sess" '$1 == s { print $2 }' "$WORK/$KIT.context")
        if [ -z "$now" ]; then
            printf '  ✗ contexto: bin/measure-context.sh no mide la sesión «%s»\n' "$sess"; echo x >> "$WORK/context-fail"
        elif [ $((now * 100)) -gt $((base * 103)) ]; then
            printf '  ✗ contexto: %s lee %s caracteres, más de un 3 %% sobre los %s de tests/context-baseline.txt\n' "$sess" "$now" "$base"
            echo x >> "$WORK/context-fail"
        elif [ $((now * 100)) -lt $((base * 97)) ]; then
            printf '  ⚠ contexto: %s lee %s caracteres, más de un 3 %% bajo los %s de tests/context-baseline.txt: actualízala\n' "$sess" "$now" "$base"
        else
            printf '  ✓ contexto: %s lee %s caracteres (línea base %s, ±3 %%)\n' "$sess" "$now" "$base"
        fi
    done
    [ ! -s "$WORK/context-fail" ] || FAIL=1
    rm -f "$WORK/context-fail"
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

    # Un kit nuevo cambia WORKFLOW.md (el proyecto no lo tocó) y CLAUDE.md (el proyecto sí), y retira la skill
    # /close; el proyecto cambió además su STATE.md, que es memoria.
    up="$WORK/$KIT-up"
    cp -R "$BASE" "$up"
    kit_copy "$WORK/$KIT-kit2"
    printf '\nNovedad del kit.\n' >> "$WORK/$KIT-kit2/core/.ai/WORKFLOW.md"
    printf '\nNovedad del kit.\n' >> "$WORK/$KIT-kit2/core/CLAUDE.md"
    rm -r "$WORK/$KIT-kit2/core/.claude/skills/close"
    edit "$WORK/$KIT-kit2/core/core.json" '\#"\.claude/skills/close/SKILL\.md",#d'
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
    if printf '%s\n' "$out" | grep -qE -- '- \.claude/skills/close/SKILL\.md +retirado' && [ ! -e "$up/.claude/skills/close" ] \
       && [ -d "$up/.claude/skills/phase" ]; then
        ok '--upgrade retira lo que el kit ya no trae, con la carpeta que deja vacía'
    else
        fail '--upgrade no retiró .claude/skills/close/:'; printf '%s\n' "$out" | sed 's/^/      /'
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

# ── La protección del protocolo (bin/check-protocol.sh), en un repositorio git ──
# g <args de git>: git en el repo de prueba, sin depender de la configuración de quien lo ejecuta.
g() { git -C "$REPO" -c user.name=kit -c user.email=kit@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }

# protect <rama> <archivo> <mensaje del commit> <pasa|falla> <qué se prueba> [texto que tiene que imprimir]: en una
# rama nueva desde main, un commit que cambia ese archivo; después, bin/check-protocol.sh como fuera de la CI.
protect() {
    if ! { g switch -q -c "$1" main && printf '\nCambio.\n' >> "$REPO/$2" && g add -A && g commit -q -m "$3"; }; then
        fail "protocolo: no se pudo preparar «$5»"; return
    fi
    out=$(GITHUB_HEAD_REF='' GITHUB_BASE_REF='' PROTOCOL_BASE='' sh "$REPO/bin/check-protocol.sh" 2>&1)
    rc=$?
    g switch -q main
    if { [ "$4" = pasa ] && [ "$rc" -eq 0 ]; } || { [ "$4" = falla ] && [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -qF -- "$6"; }; then
        ok "protocolo: $5"
    else
        fail "protocolo: $5 (salió $rc)"; printf '%s\n' "$out" | sed 's/^/      /'
    fi
}

test_protocol() {
    printf '  ◆ protección del protocolo\n'
    command -v git > /dev/null 2>&1 || { fail 'protocolo: hace falta git para probar bin/check-protocol.sh'; return; }
    REPO="$WORK/$KIT-git"
    cp -R "$BASE" "$REPO"
    if ! { g init -q -b main && g add -A && g commit -q -m 'chore(protocol): install ai-protocol'; }; then
        fail 'protocolo: no se pudo crear el repositorio de prueba'; return
    fi
    protect phase/02-paquete/03 CLAUDE.md 'docs(demo): edit CLAUDE.md' falla \
        'una rama de fase que edita CLAUDE.md fuera de un commit (protocol) falla' 'toca CLAUDE.md'
    protect phase/02-paquete/04 CLAUDE.md 'chore(protocol): edit CLAUDE.md' pasa \
        'el mismo cambio en un commit chore(protocol) pasa'
    protect phase/02-paquete/05 bin/check-protocol.sh 'fix(demo): relax the guard' falla \
        'el propio bin/check-protocol.sh también está protegido' 'toca bin/check-protocol.sh'
    protect phase/02-paquete/06 .ai/project/verify.conf 'chore(phase-02-06): close' pasa \
        'un archivo «project» del lock (.ai/project/verify.conf) es del proyecto'
    protect feature/demo CLAUDE.md 'docs(demo): edit CLAUDE.md' pasa \
        'fuera de una rama de fase no aplica'
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
                       edit stacks/nextjs/stack.json 's#^    "bin/verify.sh"$#    "bin/verify.sh",\n    "AGENTS.md"#' ;;
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

    if [ "$(sh "$BASE/bin/handoff.sh" 01-demo 01 2>&1)" = 'Fase de prueba.' ] \
       && ! sh "$BASE/bin/handoff.sh" 02-paquete 03 > /dev/null 2>&1; then
        ok 'bin/handoff.sh imprime lo que dejó una fase cerrada, y falla con una sin cerrar'
    else
        fail 'bin/handoff.sh no imprime sólo «Lo que la siguiente fase necesita saber»'
    fi
    e=$BASE/.ai/epics/02-paquete
    if grep -qx '> \*\*Tarea externa:\*\* E1-01' "$e/phase-01.md" && grep -qx '> \*\*Tipo:\*\* código' "$e/phase-01.md" \
       && grep -qx '> \*\*Tipo:\*\* operación' "$e/phase-02.md" && grep -qx '> \*\*Estado:\*\* ESPERA_EVIDENCIA' "$e/phase-02.md" \
       && grep -qx '> \*\*Modo:\*\* ligero' "$e/phase-03.md" && ! grep -q 'E1-04' "$e"/phase-*.md; then
        ok 'la épica 02-paquete, desde el paquete E1: una fase de código, una de operación y una ligera, y pasan el guardián'
    else
        fail 'la épica 02-paquete no tiene las fases de código, operación y ligera que se esperan del paquete E1'
    fi
    test_context

    DETECTED=0
    TOTAL=15
    provoke 0  'instalación: un {{RELLENAR}} sin completar'          'marcador(es) {{RELLENAR}}'
    provoke 1  'puntero: «Fase activa» en una fase HECHA'            'la cabecera apunta a'
    provoke 1e 'puntero: «Fase activa» en una ESPERA_EVIDENCIA'      'la cabecera apunta a'
    provoke 2  'fases: una HECHA pasa a EN_CURSO sin tocar el mapa'  'dice EN_CURSO y el mapa dice HECHA'
    provoke 2t 'fases: un «Tipo:» que no existe'                     '«Tipo:» es «otro»'
    accept  2a 'fases: una fase sin «Tipo:» (código, como las de antes)'
    provoke 2h 'fases: una casilla [humano] en una fase de código'  'tiene casillas [humano] y es de tipo código'
    provoke 2w 'fases: ESPERA_EVIDENCIA sin casilla [humano] abierta' 'no tiene ninguna casilla [humano] abierta'
    provoke 2x 'fases: ESPERA_EVIDENCIA con una casilla sin [humano] abierta' 'casilla(s) sin [humano] sin marcar'
    provoke 2l 'fases: una ligera con tres entregables'              'es ligera y tiene 3 entregable(s)'
    provoke 2c 'fases: una ligera que cambia el contrato'            'es ligera y cambia el contrato'
    provoke 2r 'fases: una HECHA con un bloqueante abierto'          '1 hallazgo(s) bloqueante(s) de «Revisión» sin resolver'
    accept  2v 'fases: una HECHA con su bloqueante resuelto'
    provoke 2s 'fases: una HECHA sin revisar'                        'la fase no pasó por /review'
    provoke 2n 'fases: una casilla sin marcar, con secciones sin número' 'casilla(s) de «Criterios de éxito» sin marcar'
    provoke 2e 'fases: enlaza una evidencia que no existe'            'enlaza la evidencia .ai/epics/01-demo/evidence/02-verify.txt'
    accept  2f 'fases: enlaza una evidencia que existe'
    provoke 3  'épicas: una CERRADA con su cierre sin marcar'        'casilla(s) del «Criterio de cierre» sin marcar'
    provoke 3n 'épicas: cita una decisión que no existe'             'cita D9, que no existe'
    accept  3a 'épicas: cita una decisión archivada en .ai/archive/DOMAIN.md'
    provoke 4  'referencias: «fase 01/99» en BACKLOG.md'             'cita la fase 01/99'
    if grep -q '^> \*\*Migraciones:\*\*' "$BASE/.ai/templates/phase.template.md"; then
        provoke 5 'despliegue: migraciones sin fila en el manifiesto' 'declara migraciones y no tiene fila'
    else
        TOTAL=14
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
    provoke 7e 'contadores: §Esperando evidencia no nombra la que espera' 'STATE.md §Esperando evidencia nombra'
    provoke 8  'destinos: «99» en la columna Destino'                '«Destino» es 99'
    provoke 9  'stack: otra versión en DECISIONS.md §Stack'          'dice 0.0.0 y el manifiesto dice'
    provoke 9n 'stack: un paquete de RULES.md sin versión'         '(de RULES.md §Stack) no tiene versión'
    provoke 10 'cross-repo: cita un documento del repo hermano'      "cita documentos de «$SIBLING»"
    # shellcheck disable=SC2016  # las comillas invertidas son literales
    provoke 11 'rutas: cita bin/no-existe.sh'                        'cita `bin/no-existe.sh`, que no existe'
    provoke 12 'secciones: cita una sección que no existe'           'cita «.ai/RULES.md §No existe»'
    provoke 12n 'secciones: cita una sección por su número'          'cita «.ai/WORKFLOW.md §3» por su número'
    provoke 13 'memoria: una fila cerrada sigue en BACKLOG.md'        'BACKLOG.md #1 está cerrada o descartada'
    provoke 13a 'memoria: 11 líneas en «Últimos movimientos»'       'tiene 11 líneas; el tope es 10'
    provoke 13b 'memoria: una mejora aplicada sigue en PROTOCOL.md'  'PROTOCOL.md #2 está aplicada o descartada'
    provoke 13c 'memoria: una decisión reemplazada sigue en DOMAIN.md' 'una decisión «**Reemplazada por:**» sigue aquí'
    provoke 13d 'memoria: una decisión respondida sigue en DOMAIN.md' 'D1 está respondida'
    provoke 13e 'memoria: un # de BACKLOG.md que ya está archivado'  'el id 1 ya está en .ai/archive/BACKLOG.md'
    provoke 14 'tareas: una «Tarea externa» que no está en ningún paquete' 'es T9-99, que no es una fila'
    provoke 14c 'tareas: el criterio de la tarea no está literal'    'el criterio de E1-01 no está, literal'
    # Los casos con letra son variantes: no cuentan entre los de la cabecera.
    n=$DETECTED
    note=''
    [ "$TOTAL" -eq 15 ] || note=' (el 5 no aplica)'
    printf '  → %s/%s fallos de la cabecera provocados y detectados%s\n' "$n" "$TOTAL" "$note"
    [ "$n" -eq "$TOTAL" ] || FAIL=1

    test_installer
    test_protocol
done

test_structure

printf '\n'
if [ "$FAIL" -eq 0 ]; then echo '✓ tests/run.sh: todo en verde'; else echo '✗ tests/run.sh: hay fallos'; fi
exit "$FAIL"
