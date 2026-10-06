#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# tests/lib.sh — lo que comparten tests/run.sh y los e2e de cada stack: dejar
# una instalación lista para el guardián (la capa del proyecto rellena y la
# épica de prueba, desde el paquete tests/fixtures/stages/E1.md) y provocar
# sobre ella cada fallo de la cabecera de bin/check-docs.sh. Se carga con «.»;
# no hace nada por sí solo. Quien lo carga define ROOT, SIBLING, FAIL y, para
# los fallos, fresh <caso> (ver provoke).
# ─────────────────────────────────────────────────────────────────────────────
# shellcheck disable=SC2034  # FAIL, DETECTED y TOTAL los lee quien carga este archivo

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

# gate_fails <log> <gate>: el gate falló en esa salida de bin/verify.sh.
gate_fails() { awk -v g="▸ $2" 'index($0, g) == 1 { c = 1; next } c && /^▸/ { exit } c && /✗$/ { f = 1 } END { exit !f }' "$1"; }

# ── La épica de prueba ──────────────────────────────────────────────────────
# Lo que sigue corre en la raíz de una instalación con la capa del proyecto rellena. Quien carga este archivo
# define ROOT (la raíz del kit) y SIBLING (el repo hermano que declaró al rellenar).
DATE=2026-01-01

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

# make_test_epics: las dos épicas de prueba, con el mapa y el puntero de STATE.md. 01-demo, CERRADA, con dos fases
# HECHA; y 02-paquete, desde el paquete de tareas tests/fixtures/stages/E1.md como lo haría /plan-epic: una fase de
# código HECHA y revisada, una de operación en ESPERA_EVIDENCIA y una ligera LISTA_PARA_EJECUTAR, con el puntero en
# ella.
make_test_epics() {
    make_epic 01-demo CERRADA 01 02
    make_phase 01-demo 01 HECHA '—'
    make_phase 01-demo 02 HECHA 'fase 01'
    # La épica desde el paquete E1: lo que dejaría /plan-epic (.claude/skills/plan-epic/SKILL.md §Desde un
    # paquete de tareas). E1-04 es de otro repo y no entra.
    mkdir -p .ai/stages && cp "$ROOT/tests/fixtures/stages/E1.md" .ai/stages/E1.md
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
        # La retroalimentación de la persona en el cierre (.claude/skills/phase/cierre.md §Cierre de fase).
        13p) printf '| 2 | %s | persona — fase 01/01 | Prueba. | propuesta |\n' "$DATE" >> .ai/PROTOCOL.md ;;
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

# provoke <caso> <qué se estropea> <texto que el guardián tiene que imprimir>: el defecto, sobre una instalación
# limpia que da «fresh <caso>» (la define quien carga este archivo: una copia, o el proyecto restaurado con git).
provoke() {
    d=$(fresh "$1") || { printf '  ✗ %-3s %s: no hay una instalación limpia\n' "$1" "$2"; FAIL=1; return; }
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

# accept <caso> <qué se cambia>: sobre una instalación limpia, un cambio que el guardián tiene que aceptar.
accept() {
    d=$(fresh "$1") || { printf '  ✗ %-3s %s: no hay una instalación limpia\n' "$1" "$2"; FAIL=1; return; }
    ( cd "$d" && estropea "$1" ) || { printf '  ✗ %-3s %s: no se pudo preparar\n' "$1" "$2"; FAIL=1; return; }
    if out=$(sh "$d/bin/check-docs.sh" --strict 2>&1); then printf '  ✓ %-3s %s\n' "$1" "$2"
    else
        printf '  ✗ %-3s %s: el guardián lo rechaza\n' "$1" "$2"
        printf '%s\n' "$out" | grep -E '✗|⚠' | sed 's/^/        /'
        FAIL=1
    fi
}

# guardian_cases <instalación>: los fallos de la cabecera de bin/check-docs.sh y sus variantes, cada uno sobre una
# instalación limpia con la épica de prueba, que pasa el guardián. Sin «Migraciones:» en la plantilla de fase, el
# fallo 5 no aplica, y se comprueba en su lugar que el guardián acepta fases sin ese campo.
guardian_cases() {
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
    if grep -q '^> \*\*Migraciones:\*\*' "$1/.ai/templates/phase.template.md"; then
        provoke 5 'despliegue: migraciones sin fila en el manifiesto' 'declara migraciones y no tiene fila'
    else
        TOTAL=14
        if sh "$1/bin/check-docs.sh" --strict 2>&1 | grep -qF 'no declara migraciones: no aplica' \
           && ! grep -q '^> \*\*Migraciones:\*\*' "$1"/.ai/epics/*/phase-*.md; then
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
    accept  13p 'memoria: una propuesta de la persona en PROTOCOL.md'
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
}
