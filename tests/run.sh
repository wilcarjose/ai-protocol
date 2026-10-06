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
#   2. Crea desde las plantillas (make_test_epics, en tests/lib.sh, que usan
#      también los e2e) las épicas de prueba: 01-demo, CERRADA, con dos
#      fases HECHA; y 02-paquete, creada desde el paquete de tareas
#      tests/fixtures/stages/E1.md como lo haría /plan-epic: una fase de código
#      HECHA y revisada, una de operación en ESPERA_EVIDENCIA y una ligera
#      LISTA_PARA_EJECUTAR, con el puntero de STATE.md en ella.
#   3. Comprueba que `sh bin/check-docs.sh --strict` pasa sobre esa instalación,
#      que bin/measure-context.sh la mide y que bin/handoff.sh imprime lo que
#      una fase cerrada dejó para la siguiente (y falla con una sin cerrar).
#   4. Provoca (guardian_cases, en tests/lib.sh, que usan también los e2e),
#      cada uno en una copia limpia, los 15 fallos de «CÓMO PROVOCAR
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
#   Un chequeo nuevo del guardián trae su caso en tests/lib.sh: una rama en
#   estropea() que mete el defecto en la instalación (corre en su raíz) y una
#   línea `provoke` en guardian_cases con el texto que el guardián tiene que
#   imprimir (o `accept`, si el caso tiene que pasar). Un caso con número es
#   un fallo de la cabecera de bin/check-docs.sh; uno con letra, una variante.
#   Así lo prueban también los e2e, sobre un proyecto de verdad.
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

# edit, awk_edit, fill_stack, fill_markers, la épica de prueba (make_test_epics) y los fallos del guardián
# (guardian_cases).
# shellcheck source=tests/lib.sh
. "$ROOT/tests/lib.sh"

# fresh <caso>: el directorio de una copia limpia de la instalación de prueba, para provocar ese caso en ella.
fresh() { d="$WORK/$KIT-$1"; cp -R "$BASE" "$d" && printf '%s' "$d"; }

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

        make_test_epics
    )
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

    [ -d "$FIXTURES/kit-1x/$KIT" ] && test_upgrade_1x

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

# memory <dir>: «suma ruta» de cada archivo de la memoria (STATE, DOMAIN, BACKLOG, PROTOCOL y las épicas).
memory() {
    ( cd "$1" && find .ai/STATE.md .ai/DOMAIN.md .ai/BACKLOG.md .ai/PROTOCOL.md .ai/epics -type f | sort \
        | while read -r f; do printf '%s %s\n' "$(sha "$f")" "$f"; done )
}

# Un proyecto con el kit 1.x: tests/fixtures/kit-1x/<kit>/ es la carpeta del stack tal como la copiaba `cp -Rn`
# antes del instalador (la «Versión del kit» 2026-10-04, la de c2151e4), sin lock. El proyecto ha usado su memoria.
# shellcheck disable=SC2016  # las comillas invertidas de los mensajes son literales
test_upgrade_1x() {
    old="$WORK/$KIT-1x"
    cp -R "$FIXTURES/kit-1x/$KIT" "$old"
    mkdir -p "$old/.ai/epics/01-demo"
    printf '# Épica 01 — Demo\n' > "$old/.ai/epics/01-demo/epic-plan.md"
    printf -- '- %s — Movimiento del proyecto.\n' "$DATE" >> "$old/.ai/STATE.md"
    before=$(memory "$old")

    if ! out=$(sh "$ROOT/install.sh" --upgrade --target "$old" 2>&1) && printf '%s\n' "$out" | grep -qF 'di qué stack tiene con --stack'; then
        ok '1.x: sin lock, --upgrade pide --stack'
    else
        fail '1.x: sin lock, --upgrade no pide --stack:'; printf '%s\n' "$out" | sed 's/^/      /'
    fi

    out=$(sh "$ROOT/install.sh" --upgrade --stack "$KIT" --target "$old" 2>&1)
    rc=$?
    printf '%s\n' "$out" > "$WORK/$KIT-1x.log"
    if [ "$rc" -eq 0 ] && grep -qE '^  ! CLAUDE\.md +conflicto' "$WORK/$KIT-1x.log" \
       && grep -qF -- '--- proyecto/CLAUDE.md' "$WORK/$KIT-1x.log" && grep -qF '+++ kit/CLAUDE.md' "$WORK/$KIT-1x.log" \
       && grep -qE '^  \+ \.claude/skills/phase/SKILL\.md +copiado' "$WORK/$KIT-1x.log" \
       && [ -f "$old/.ai/protocol.lock" ] && [ -f "$old/.ai/project/README.md" ]; then
        ok "1.x: --upgrade --stack $KIT termina en 0, enseña el diff de lo que difiere del kit ($(grep -c '^  ! ' "$WORK/$KIT-1x.log") conflictos) y copia lo nuevo"
    else
        fail "1.x: --upgrade --stack $KIT salió $rc o no enseñó los diffs:"; sed 's/^/      /' "$WORK/$KIT-1x.log" | head -n 40
    fi
    if [ "$(memory "$old")" = "$before" ]; then ok '1.x: --upgrade no toca la memoria (STATE, DOMAIN, BACKLOG, PROTOCOL y las épicas)'
    else fail '1.x: --upgrade modificó la memoria'; fi
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
                       edit stacks/nextjs/stack.json 's#^  "files": \[$#  "files": [\n    "AGENTS.md",#' ;;
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

    guardian_cases "$BASE"

    test_installer
    test_protocol
done

test_structure

printf '\n'
if [ "$FAIL" -eq 0 ]; then echo '✓ tests/run.sh: todo en verde'; else echo '✗ tests/run.sh: hay fallos'; fi
exit "$FAIL"
