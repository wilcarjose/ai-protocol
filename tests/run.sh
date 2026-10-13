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
#      una fase cerrada dejó para la siguiente (y falla con una sin cerrar). Y
#      bin/protocol-feedback.sh con un gh de mentira en el PATH: un issue por
#      fila de núcleo o stack en «propuesta», que pasa a «enviada —
#      ai-protocol#N», sin tocar las de proyecto ni las ya enviadas; sin gh,
#      imprime el texto y .ai/PROTOCOL.md no cambia.
#   4. Provoca (guardian_cases, en tests/lib.sh, que usan también los e2e),
#      cada uno en una copia limpia, los 16 fallos de «CÓMO PROVOCAR
#      CADA FALLO» de la cabecera de bin/check-docs.sh, más sus variantes (los
#      casos con letra): el puntero en una fase que espera evidencia (1e), una
#      fase con las secciones sin número (2n), una evidencia enlazada que no
#      existe (2e), los campos de la cabecera de una fase y la evidencia humana
#      (2t, 2h, 2w, 2x, 2l, 2c), su revisión (2r, 2s), un id D<n> que no existe
#      en ningún sitio (3n), §Esperando evidencia desfasada (7e), un paquete de
#      RULES.md sin versión en .ai/project/DECISIONS.md (9n), una cita de
#      sección por su número (12n), cada tope de la memoria (13a…13e), un
#      alcance de .ai/PROTOCOL.md que no existe (13k) y un
#      criterio de una tarea externa que no está literal en su fase (14c). Cada
#      caso tiene que fallar con el mensaje de su chequeo, no con cualquier
#      otro. Y al revés, casos que tienen que pasar: una evidencia que sí existe
#      (2f), una fase sin «Tipo» (2a, como las de antes de los tipos), un
#      bloqueante resuelto (2v), un epic-plan que cita una decisión archivada
#      en .ai/archive/DOMAIN.md (3a), filas «propuesta» y «enviada» de
#      .ai/PROTOCOL.md (13p, 13s) y su tabla de antes, sin «Alcance» (13v); y
#      una fase que cambió .env.example con su nota del .env local (15n, 15v)
#      o escrita antes de «Entorno local» (15a).
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
#      tocó, retira lo que ya no trae (con su carpeta si queda vacía), no toca
#      la memoria y avisa de la fila «enviada» de .ai/PROTOCOL.md cuyo issue
#      cita el CHANGELOG.md de la versión nueva, y no de la que no cita; y no
#      instala un stack incompatible con el núcleo.
#   7. Prueba el modo de proyecto nuevo (install.sh --new-project) en una copia
#      de la instalación como una plantilla ya usada: con la épica de prueba,
#      el paquete E1, una entrega, una evidencia y una línea de más en cada
#      semilla del núcleo. --dry-run no escribe nada. Después, la memoria,
#      README.md y SENSITIVE-ZONES.md de .ai/project/ son la semilla y las
#      carpetas de la memoria sólo tienen lo del kit; el lock, los archivos del
#      kit, lo que hereda el proyecto y el código no cambian; lista los
#      {{RELLENAR}} que quedan y el guardián falla sólo en «instalación» hasta
#      rellenarlos. Un --upgrade justo después dice «sin cambios». Sin lock, o
#      con el kit en otra versión que el lock, falla.
#   8. Prueba la protección del protocolo (bin/check-protocol.sh) en una copia
#      de la instalación hecha repositorio git: una rama de fase que edita
#      CLAUDE.md, o el propio script, en un commit que no es de ámbito protocol
#      falla; el mismo cambio en un commit chore(protocol) pasa, y también los
#      cambios en archivos del proyecto (la memoria, .ai/project/verify.conf)
#      y cualquier cambio fuera de una rama de fase. Y lo mismo dentro de un
#      git worktree, como los del VPS (docs/modos.md): el guardián pasa y la
#      protección compara con origin/main aunque el main local vaya por
#      detrás. Necesita git.
#
# ◆ ADEMÁS
#   Provoca en una copia del repo un fallo de cada chequeo de
#   tests/structure.sh y comprueba que lo detecta. Y corre docs/vps/doctor.sh
#   con un PATH de stubs: con todo, pasa; sin gitleaks, con Node 20 o con un
#   .env de staging legible, lo reporta. Y comprueba que cada ruta y cada
#   script que cita docs/guia.md existen en el kit o en una instalación de
#   prueba (con la épica del ejemplo), y que una ruta que no existe se reporta.
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
    # /close; el proyecto cambió además su STATE.md, que es memoria. El núcleo sube de versión y su CHANGELOG.md
    # cita el #901, que resuelve una fila «enviada» del proyecto; la del #90 sigue abierta.
    up="$WORK/$KIT-up"
    cp -R "$BASE" "$up"
    printf '| 2 | %s | fase 01/01 | Prueba. | núcleo | enviada — ai-protocol#901 |\n' "$DATE" >> "$up/.ai/PROTOCOL.md"
    printf '| 3 | %s | fase 01/01 | Prueba. | stack | enviada — ai-protocol#90 |\n' "$DATE" >> "$up/.ai/PROTOCOL.md"
    kit_copy "$WORK/$KIT-kit2"
    edit "$WORK/$KIT-kit2/core/core.json" 's/"version": ".*"/"version": "2.99.0"/'
    awk_edit "$WORK/$KIT-kit2/core/CHANGELOG.md" "!d && /^## \\[/ { print \"## [2.99.0] — $DATE\\n\\n- Arreglo (#901).\\n\"; d = 1 } 1"
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
    if printf '%s\n' "$out" | grep -qF '#2  enviada — ai-protocol#901' && ! printf '%s\n' "$out" | grep -qF '#3  enviada' \
       && printf '%s\n' "$out" | grep -qF "aplicada — kit core 2.99.0 + $KIT"; then
        ok '--upgrade avisa de la fila «enviada» cuyo issue cita el CHANGELOG.md nuevo, y no de la otra'
    else
        fail '--upgrade no avisó de la fila #2 (ai-protocol#901) o avisó de la #3 (ai-protocol#90):'
        printf '%s\n' "$out" | sed 's/^/      /'
    fi

    # El «gitignore» del stack: la instalación lo deja en .gitignore, y un --upgrade añade la línea que falte (aquí,
    # una que el proyecto escribió sin barras cuenta como presente) sin tocar las demás.
    json_list "$ROOT/stacks/$KIT/stack.json" gitignore > "$WORK/$KIT.gitignore"
    if [ -s "$WORK/$KIT.gitignore" ]; then
        missing=$(while read -r e; do grep -qxF -- "$e" "$BASE/.gitignore" 2>/dev/null || printf '%s ' "$e"; done < "$WORK/$KIT.gitignore")
        gi=$(fresh gitignore)
        first=$(head -n 1 "$WORK/$KIT.gitignore"); last=$(tail -n 1 "$WORK/$KIT.gitignore")
        bare=${first#/}; bare=${bare%/}
        printf '/node_modules\n%s\n' "$bare" > "$gi/.gitignore"
        out=$(sh "$ROOT/install.sh" --upgrade --target "$gi" 2>&1)
        if [ -z "$missing" ] && printf '%s\n' "$out" | grep -qE "\\+ \\.gitignore +ignora $last" \
           && ! printf '%s\n' "$out" | grep -qE "ignora $first\$" \
           && [ "$(head -n 2 "$gi/.gitignore")" = "$(printf '/node_modules\n%s' "$bare")" ] && grep -qxF -- "$last" "$gi/.gitignore"; then
            ok 'el «gitignore» del stack: lo deja al instalar, y --upgrade añade sólo la línea que falta'
        else
            fail "el «gitignore» del stack no cuadra (faltan al instalar: ${missing:-ninguna}):"; printf '%s\n' "$out" | sed 's/^/      /'
        fi
    fi

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

# ── El modo de proyecto nuevo (install.sh --new-project) ────────────────────
# reset_seeds: lo que vuelve a la semilla, las semillas del núcleo salvo lo que el proyecto hereda en .ai/project/.
reset_seeds() {
    json_list "$ROOT/core/core.json" seed \
        | grep -vxE '\.ai/project/(ARCHITECTURE|COMMIT-SCOPES|CONTRACT|CROSS-CUTTING|DECISIONS|FEATURES|GLOSSARY)\.md'
}

# kept <dir>: el snapshot de lo que el modo no toca: todo menos esas semillas y las carpetas de la memoria.
kept() {
    snapshot "$1" | awk -v r="$(reset_seeds | tr '\n' ' ')" '
        BEGIN { n = split(r, s, " "); for (i = 1; i <= n; i++) skip["./" s[i]] = 1 }
        !($2 in skip) && $2 !~ /^\.\/\.ai\/(archive|epics|handoffs|stages)\//'
}

# Sobre una copia de la instalación de prueba, como una plantilla ya usada: la capa del proyecto rellena, las dos
# épicas de prueba y el paquete E1, y además una entrega, una evidencia y una línea de más en cada semilla del núcleo.
test_new_project() {
    printf '  ◆ proyecto nuevo\n'
    np="$WORK/$KIT-new"
    cp -R "$BASE" "$np"
    mkdir -p "$np/.ai/handoffs/$DATE-demo" "$np/.ai/epics/01-demo/evidence"
    echo 'Rutas.' > "$np/.ai/handoffs/$DATE-demo/routes.md"
    echo ok > "$np/.ai/epics/01-demo/evidence/02-verify.txt"
    for f in $(json_list "$ROOT/core/core.json" seed); do printf '\nDe la plantilla.\n' >> "$np/$f"; done

    before=$(snapshot "$np")
    out=$(sh "$ROOT/install.sh" --new-project --target "$np" --dry-run 2>&1)
    rc=$?
    if [ "$rc" -eq 0 ] && [ "$(snapshot "$np")" = "$before" ] && printf '%s\n' "$out" | grep -qE '↺ \.ai/STATE\.md +vuelve a la semilla' \
       && printf '%s\n' "$out" | grep -qE -- '- \.ai/stages/E1\.md +de la plantilla'; then
        ok '--dry-run dice qué haría y no escribe nada'
    else
        fail "--dry-run salió $rc o escribió algo:"; printf '%s\n' "$out" | sed 's/^/      /'
    fi

    was_kept=$(kept "$np")
    out=$(sh "$ROOT/install.sh" --new-project --target "$np" 2>&1)
    rc=$?
    if [ "$rc" -ne 0 ]; then fail "--new-project salió $rc:"; printf '%s\n' "$out" | sed 's/^/      /'; return; fi

    differ=$(for f in $(reset_seeds); do cmp -s "$np/$f" "$ROOT/core/$f" || printf '%s ' "$f"; done)
    left=$(cd "$np" && find .ai/archive .ai/epics .ai/handoffs .ai/stages | sort | tr '\n' ' ')
    want='.ai/archive .ai/archive/BACKLOG.md .ai/archive/DOMAIN.md .ai/archive/PROTOCOL.md .ai/epics .ai/epics/.gitkeep '
    want="$want.ai/handoffs .ai/handoffs/README.md .ai/stages .ai/stages/README.md "
    if [ -z "$differ" ] && [ "$left" = "$want" ]; then
        ok 'la memoria, README.md y SENSITIVE-ZONES.md son la semilla, sin épicas, paquetes ni entregas'
    else
        fail "no es la semilla: ${differ:-}· queda: $left"
    fi
    bad_kit=$(awk '$1 == "file" && $2 == "kit" { print $3, $4 }' "$np/.ai/protocol.lock" | while read -r s p; do
                  [ "$(sha "$np/$p")" = "$s" ] || printf '%s ' "$p"; done)
    if [ "$(kept "$np")" = "$was_kept" ] && [ -z "$bad_kit" ]; then
        ok 'no cambian el lock, los archivos del kit, lo que hereda el proyecto ni el código'
    else
        fail "cambió algo que se conserva: ${bad_kit:-}"
        printf '%s\n' "$was_kept" > "$WORK/$KIT-kept"; kept "$np" | diff "$WORK/$KIT-kept" - | sed 's/^/      /'
    fi
    n=$(cd "$np" && grep -rn '{{RELLENAR' CLAUDE.md .ai docs 2>/dev/null | grep -c .)
    listed=$(printf '%s\n' "$out" | grep -E '^    [^ :]+:[0-9]+:' | grep -cF '{{RELLENAR')
    if [ "$n" -gt 0 ] && [ "$listed" -eq "$n" ]; then ok "al terminar, lista los $n {{RELLENAR}} que quedan"
    else fail "lista $listed {{RELLENAR}} y quedan $n:"; printf '%s\n' "$out" | sed 's/^/      /'; fi

    out=$(sh "$np/bin/check-docs.sh" --strict 2>&1)
    rc=$?
    if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -qF 'la instalación del protocolo no está terminada' \
       && printf '%s\n' "$out" | grep -qF '1 chequeo(s) en rojo, 0 aviso(s)'; then
        ok 'el guardián falla sólo en «instalación» mientras quedan marcadores'
    else
        fail "el guardián salió $rc y no falla sólo en «instalación»:"; printf '%s\n' "$out" | grep -E '✗|⚠' | sed 's/^/      /'
    fi

    before=$(snapshot "$np")
    out=$(sh "$ROOT/install.sh" --upgrade --target "$np" 2>&1)
    rc=$?
    if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qF 'sin cambios' && [ "$(snapshot "$np")" = "$before" ]; then
        ok 'un --upgrade justo después dice «sin cambios»'
    else
        fail "un --upgrade justo después salió $rc o cambió algo:"; printf '%s\n' "$out" | sed 's/^/      /'
    fi

    ( cd "$np" && find . -type f -name '*.md' -exec grep -lF '{{RELLENAR' {} + | while read -r f; do fill_markers "$f" "$SIBLING"; done )
    if out=$(sh "$np/bin/check-docs.sh" --strict 2>&1); then ok 'con los marcadores rellenos, el guardián pasa (--strict)'
    else fail 'con los marcadores rellenos, el guardián no pasa:'; printf '%s\n' "$out" | grep -E '✗|⚠' | sed 's/^/      /'; fi

    mkdir -p "$WORK/$KIT-nolock"
    if out=$(sh "$ROOT/install.sh" --new-project --target "$WORK/$KIT-nolock" 2>&1); then
        fail '--new-project sin lock no falla'
    elif printf '%s\n' "$out" | grep -qF 'no tiene .ai/protocol.lock'; then
        ok 'sin lock, falla: el modo es para un proyecto con el protocolo instalado'
    else
        fail "sin lock, falla, pero sin decir por qué: $out"
    fi
    kit_copy "$WORK/$KIT-kit4"
    edit "$WORK/$KIT-kit4/stacks/$KIT/stack.json" 's/"version": ".*"/"version": "9.9.9"/'
    before=$(snapshot "$np")
    if out=$(sh "$WORK/$KIT-kit4/install.sh" --new-project --target "$np" 2>&1); then
        fail '--new-project con el kit en otra versión que el lock no falla'
    elif printf '%s\n' "$out" | grep -qF 'actualízalo antes con --upgrade' && [ "$(snapshot "$np")" = "$before" ]; then
        ok 'con el kit en otra versión que el lock, falla sin tocar nada y pide --upgrade'
    else
        fail "con el kit en otra versión que el lock, falla, pero no por eso o tocando algo: $out"
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
    test_worktree
}

# w <args de git>: git en el worktree de prueba, como g.
w() { git -C "$WT" -c user.name=kit -c user.email=kit@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }

# in_worktree <pasa|falla> <qué se prueba> [texto que tiene que imprimir]: bin/check-protocol.sh en el worktree.
in_worktree() {
    out=$(GITHUB_HEAD_REF='' GITHUB_BASE_REF='' PROTOCOL_BASE='' sh "$WT/bin/check-protocol.sh" 2>&1)
    rc=$?
    if { [ "$1" = pasa ] && [ "$rc" -eq 0 ]; } || { [ "$1" = falla ] && [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -qF -- "$3"; }; then
        ok "worktree: $2"
    else
        fail "worktree: $2 (salió $rc)"; printf '%s\n' "$out" | sed 's/^/      /'
    fi
}

# Una fase en un git worktree, como los que crea Claude Code en el VPS (docs/modos.md §VPS): en .claude/worktrees/,
# desde origin/main. El main local del checkout principal se queda atrás: origin/main trae una fase ya fusionada con
# squash, en un commit que no es de ámbito protocol y tocó CLAUDE.md. La base tiene que ser origin/main.
test_worktree() {
    WT="$REPO/.claude/worktrees/demo"
    if ! { g switch -q -c merged main && printf '\nFase fusionada.\n' >> "$REPO/CLAUDE.md" \
           && g commit -q -am 'feat(demo): merged phase' && g update-ref refs/remotes/origin/main merged \
           && g switch -q main && g branch -q -D merged \
           && g worktree add -q -b phase/02-paquete/07 "$WT" origin/main; }; then
        fail 'worktree: no se pudo preparar'; return
    fi
    if out=$(sh "$WT/bin/check-docs.sh" --strict 2>&1); then ok 'worktree: el guardián pasa (--strict)'
    else fail 'worktree: el guardián no pasa'; printf '%s\n' "$out" | grep -E '✗|⚠' | sed 's/^/      /'; fi
    printf '\nCambio.\n' >> "$WT/.ai/project/verify.conf"
    w commit -q -am 'chore(phase-02-07): close'
    in_worktree pasa 'la protección compara con origin/main, no con el main local que va por detrás'
    printf '\nCambio.\n' >> "$WT/CLAUDE.md"
    w commit -q -am 'docs(demo): edit CLAUDE.md'
    in_worktree falla 'editar CLAUDE.md fuera de un commit (protocol) falla' 'toca CLAUDE.md'
    w commit -q --amend -m 'chore(protocol): edit CLAUDE.md'
    in_worktree pasa 'el mismo cambio en un commit chore(protocol) pasa'
}

# ── bin/protocol-feedback.sh, con un gh de mentira ──────────────────────────
# El gh del PATH apunta cada «issue create» en $GH_LOG y responde con la URL del issue siguiente, desde el 40. Las
# filas: dos por enviar (núcleo y stack), una de proyecto, una ya enviada y una de stack con un «\|» en el texto.
# shellcheck disable=SC2016  # el stub y las filas se escriben tal cual
test_feedback() {
    printf '◆ bin/protocol-feedback.sh\n'
    d=$(fresh feedback) || { fail 'protocol-feedback: no hay una instalación limpia'; return; }
    stubs="$WORK/$KIT-gh"
    mkdir -p "$stubs"
    printf '%s\n' '#!/bin/sh' 'case "$1 $2" in' \
        '    "repo view") exit 0 ;;' \
        '    "issue create") n=$(($(wc -l < "$GH_LOG") + 40)); printf "%s\n" "$*" >> "$GH_LOG"' \
        '        echo "https://github.com/x/ai-protocol/issues/$n" ;;' \
        '    *) exit 1 ;;' \
        'esac' > "$stubs/gh"
    chmod +x "$stubs/gh"
    {
        printf '| 1 | %s | fase 01/01 | Una fricción. **Propuesta:** `cierre.md §Entrega`: otra. | núcleo | propuesta |\n' "$DATE"
        printf '| 2 | %s | persona — fase 01/01 | Del proyecto. | proyecto | propuesta |\n' "$DATE"
        printf '| 3 | %s | fase 01/01 | Ya enviada. | núcleo | enviada — ai-protocol#7 |\n' "$DATE"
        printf '| 4 | %s | fase 01/02 | Con a \\| b en el texto. | stack | propuesta |\n' "$DATE"
    } >> "$d/.ai/PROTOCOL.md"
    before=$(sha "$d/.ai/PROTOCOL.md")

    # Sin gh: imprime el texto de cada issue y no cambia nada.
    nogh="$WORK/$KIT-nogh"
    mkdir -p "$nogh"
    for u in awk sed cat mktemp rm dirname tail wc; do ln -sf "$(command -v "$u")" "$nogh/$u"; done
    out=$(PATH="$nogh" "$(command -v sh)" "$d/bin/protocol-feedback.sh" 2>&1)
    if [ "$(sha "$d/.ai/PROTOCOL.md")" = "$before" ] && printf '%s\n' "$out" | grep -qF '[núcleo] Una fricción' \
       && printf '%s\n' "$out" | grep -qF "[$KIT] Con a | b en el texto" && printf '%s\n' "$out" | grep -qF 'nada enviado'; then
        ok 'sin gh, imprime el texto de cada issue y .ai/PROTOCOL.md no cambia'
    else fail 'sin gh, no imprime los issues o cambia .ai/PROTOCOL.md:'; printf '%s\n' "$out" | sed 's/^/      /'; fi

    : > "$WORK/$KIT-gh.log"
    if out=$(PATH="$stubs:$PATH" GH_LOG="$WORK/$KIT-gh.log" sh "$d/bin/protocol-feedback.sh" 2>&1) \
       && [ "$(wc -l < "$WORK/$KIT-gh.log" | tr -d ' ')" -eq 2 ] \
       && grep -q '^| 1 | .* | núcleo | enviada — ai-protocol#40 |$' "$d/.ai/PROTOCOL.md" \
       && grep -q '^| 4 | .* | stack | enviada — ai-protocol#41 |$' "$d/.ai/PROTOCOL.md" \
       && grep -q '^| 2 | .* | proyecto | propuesta |$' "$d/.ai/PROTOCOL.md" \
       && grep -q '^| 3 | .* | núcleo | enviada — ai-protocol#7 |$' "$d/.ai/PROTOCOL.md" \
       && grep -qF -- '--title [núcleo] Una fricción --body-file' "$WORK/$KIT-gh.log" \
       && grep -qF -- "--title [$KIT] Con a | b en el texto --body-file" "$WORK/$KIT-gh.log"; then
        ok 'un issue por fila de núcleo o stack sin enviar, que queda «enviada — ai-protocol#N»; las de proyecto y las enviadas, igual'
    else
        fail 'protocol-feedback no envía justo las filas de núcleo o stack en «propuesta»:'
        { printf '%s\n' "$out"; cat "$WORK/$KIT-gh.log"; grep '^| [0-9]' "$d/.ai/PROTOCOL.md"; } | sed 's/^/      /'
    fi
    if sh "$d/bin/check-docs.sh" --strict > /dev/null 2>&1; then ok 'después, el guardián pasa'
    else fail 'después de enviar, el guardián no pasa'; fi
    : > "$WORK/$KIT-gh.log"
    if PATH="$stubs:$PATH" GH_LOG="$WORK/$KIT-gh.log" sh "$d/bin/protocol-feedback.sh" 2>&1 | grep -qF 'nada que enviar' \
       && [ ! -s "$WORK/$KIT-gh.log" ]; then ok 'otra vez, no hay nada que enviar'
    else fail 'una segunda vuelta vuelve a enviar filas'; fi
}

# ── bin/protocol-upgrade.sh, con un origin local y un gh de mentira ─────────
# up_git <dir> <args de git>: git sin depender de la configuración de quien lo ejecuta.
up_git() { d=$1; shift; git -C "$d" -c user.name=kit -c user.email=kit@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }

# up_project <caso>: una copia de la instalación de prueba en un repo git, con un origin vacío que ya tiene su main.
# Lleva dos filas «enviada» en .ai/PROTOCOL.md: la #2 (ai-protocol#901), que resuelve el kit nuevo, y la #3, que no.
up_project() {
    p=$(fresh "up-$1") || return 1
    printf '| 2 | %s | fase 01/01 | Prueba. | núcleo | enviada — ai-protocol#901 |\n' "$DATE" >> "$p/.ai/PROTOCOL.md"
    printf '| 3 | %s | fase 01/01 | Otra. | stack | enviada — ai-protocol#90 |\n' "$DATE" >> "$p/.ai/PROTOCOL.md"
    git init -q --bare "$WORK/$KIT-up-$1.git" && git -C "$p" init -q && up_git "$p" checkout -q -b main \
        && up_git "$p" add -A && up_git "$p" commit -q -m init && up_git "$p" remote add origin "$WORK/$KIT-up-$1.git" \
        && up_git "$p" push -q -u origin main && printf '%s' "$p"
}

# upgrade <dir> <kit> [args]: bin/protocol-upgrade.sh en ese proyecto, con esa copia del kit y el gh de mentira.
# GH_CHECKS: 0 (CI en verde, por defecto), 1 (en rojo) o none (sin CI).
upgrade() {
    p=$1; k=$2; shift 2
    (cd "$p" && PATH="$WORK/$KIT-upgh:$PATH" GH_LOG="$WORK/$KIT-upgh.log" AI_PROTOCOL_DIR="$k" PROTOCOL_UPGRADE_CI_WAIT=1 \
        GIT_AUTHOR_NAME=kit GIT_AUTHOR_EMAIL=kit@example.invalid GIT_COMMITTER_NAME=kit GIT_COMMITTER_EMAIL=kit@example.invalid \
        GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false \
        GIT_CONFIG_KEY_1=core.hooksPath GIT_CONFIG_VALUE_1=/dev/null sh bin/protocol-upgrade.sh "$@" 2>&1)
}

# worktree <dir>: «suma ruta» de cada archivo del proyecto, sin .git, que un git fetch ya cambia.
worktree() { ( cd "$1" && find . -path ./.git -prune -o -type f -print | sort | while read -r f; do printf '%s %s\n' "$(sha "$f")" "$f"; done ); }

# on_main <dir>: en main, al día con su origin.
on_main() {
    [ "$(git -C "$1" rev-parse --abbrev-ref HEAD)" = main ] \
        && [ "$(git -C "$1" rev-parse HEAD)" = "$(git -C "$1" rev-parse origin/main)" ]
}

# shellcheck disable=SC2016  # los $ de los stubs y las comillas invertidas son literales
test_upgrade() {
    printf '  ◆ bin/protocol-upgrade.sh\n'
    stack_v=$(sed -n 's/^ *"version": *"\(.*\)",*$/\1/p' "$ROOT/stacks/$KIT/stack.json")
    stack_v=${stack_v%-dev}
    mkdir -p "$WORK/$KIT-upgh"
    printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$*" >> "$GH_LOG"' 'case "$1 $2" in' \
        '    "pr create") echo "https://github.com/x/demo/pull/7" ;;' \
        '    "pr checks") [ "${GH_CHECKS:-0}" = none ] && { echo "no checks reported on the branch"; exit 1; }; exit "${GH_CHECKS:-0}" ;;' \
        '    "pr merge") b=$(git rev-parse --abbrev-ref HEAD); git push -q origin "$b:main" && git push -q origin --delete "$b" ;;' \
        '    *) exit 1 ;;' 'esac' > "$WORK/$KIT-upgh/gh"
    chmod +x "$WORK/$KIT-upgh/gh"

    # El kit nuevo: una versión menor del núcleo cuyo CHANGELOG.md cita el #901, otro WORKFLOW.md y otro CLAUDE.md, y
    # su bin/protocol-upgrade.sh se distingue en lo que imprime. El mayor sube el stack a 9.0.0.
    k2="$WORK/$KIT-upkit2"
    kit_copy "$k2"
    edit "$k2/core/core.json" 's/"version": ".*"/"version": "2.99.0"/'
    awk_edit "$k2/core/CHANGELOG.md" "!d && /^## \\[/ { print \"## [2.99.0] — $DATE\\n\\n- Arreglo (#901).\\n\"; d = 1 } 1"
    printf '\nNovedad del kit.\n' >> "$k2/core/.ai/WORKFLOW.md"
    printf '\nNovedad del kit.\n' >> "$k2/core/CLAUDE.md"
    edit "$k2/core/bin/protocol-upgrade.sh" 's/^echo "◆ protocol-upgrade: /echo "◆ protocol-upgrade (kit nuevo): /'
    k3="$WORK/$KIT-upkit3"
    kit_copy "$k3"
    edit "$k3/stacks/$KIT/stack.json" 's/"version": ".*"/"version": "9.0.0"/'
    # Publicados, aunque el kit de verdad vaya con -dev mientras se trabaja en él.
    for f in "$k2/stacks/$KIT/stack.json" "$k3/core/core.json"; do edit "$f" 's/"version": "\(.*\)-dev"/"version": "\1"/'; done

    # Lo normal: versión menor, CI en verde.
    d=$(up_project merge) || { fail 'protocol-upgrade: no pude preparar el proyecto'; return; }
    : > "$WORK/$KIT-upgh.log"
    out=$(upgrade "$d" "$k2"); rc=$?
    first=$(awk '/^\|---/ { getline; print; exit }' "$d/.ai/archive/PROTOCOL.md")
    if [ "$rc" -eq 0 ] && on_main "$d" && grep -qx 'package core 2.99.0' "$d/.ai/protocol.lock" \
       && printf '%s\n' "$out" | grep -qF '◆ protocol-upgrade (kit nuevo): ' \
       && printf '%s\n' "$first" | grep -q "^| 2 | .* | núcleo | aplicada — kit core 2.99.0 + $KIT $stack_v |\$" \
       && ! grep -q '^| 2 |' "$d/.ai/PROTOCOL.md" && grep -q '^| 3 | .* | enviada — ai-protocol#90 |$' "$d/.ai/PROTOCOL.md" \
       && grep -q '^pr create ' "$WORK/$KIT-upgh.log" && grep -q '^pr merge ' "$WORK/$KIT-upgh.log" \
       && [ -z "$(git -C "$d" branch --list 'protocol/*')" ] && [ -z "$(git -C "$d" ls-remote --heads origin 'protocol/*')" ] \
       && sh "$d/bin/check-docs.sh" --strict > /dev/null 2>&1; then
        ok 'menor y con la CI en verde: lo hace la versión nueva del script, archiva la fila que resuelve, fusiona y deja main al día con origin'
    else
        fail "protocol-upgrade no fusionó el upgrade menor (salida $rc):"; { printf '%s\n' "$out"; cat "$WORK/$KIT-upgh.log"; } | sed 's/^/      /'
    fi
    out=$(upgrade "$d" "$k2"); rc=$?
    if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qF '✓ al día: core 2.99.0'; then ok 'otra vez: al día, sin hacer nada'
    else fail "una segunda vuelta no dice «al día» (salida $rc):"; printf '%s\n' "$out" | sed 's/^/      /'; fi

    # Una versión mayor: el PR queda para la persona.
    d=$(up_project major) || return
    : > "$WORK/$KIT-upgh.log"
    out=$(upgrade "$d" "$k3"); rc=$?
    if [ "$rc" -eq 0 ] && on_main "$d" && printf '%s\n' "$out" | grep -qF 'PR abierto para revisar (versión mayor' \
       && ! grep -q '^pr merge' "$WORK/$KIT-upgh.log" && ! grep -q "package $KIT 9.0.0" "$d/.ai/protocol.lock" \
       && [ -n "$(git -C "$d" ls-remote --heads origin "protocol/upgrade-core-*-$KIT-9.0.0")" ]; then
        ok 'una versión mayor: abre el PR, no lo fusiona y vuelve a main'
    else fail "protocol-upgrade fusionó o no abrió el PR de una versión mayor (salida $rc):"; printf '%s\n' "$out" | sed 's/^/      /'; fi

    # La CI en rojo, y un PR sin CI: no se fusiona y sale != 0.
    for c in 1 none; do
        d=$(up_project "ci-$c") || return
        : > "$WORK/$KIT-upgh.log"
        out=$(GH_CHECKS=$c upgrade "$d" "$k2"); rc=$?
        if [ "$rc" -ne 0 ] && on_main "$d" && ! grep -q '^pr merge' "$WORK/$KIT-upgh.log" \
           && printf '%s\n' "$out" | grep -qE 'la CI de .* falla|no tiene CI'; then
            if [ "$c" = 1 ]; then what='en rojo'; else what='que no existe'; fi
            ok "con la CI $what: no fusiona, lo dice, sale != 0 y vuelve a main"
        else fail "con GH_CHECKS=$c, protocol-upgrade fusionó o no lo dijo (salida $rc):"; printf '%s\n' "$out" | sed 's/^/      /'; fi
    done

    # Lo que para antes de tocar nada: --dry-run (sale 0), un conflicto, una fase a medias y el árbol sucio.
    for c in dry conflict busy dirty; do
        d=$(up_project "$c") || return
        case $c in
            conflict) printf '\nCambio del proyecto.\n' >> "$d/CLAUDE.md"; up_git "$d" commit -qam conflict; up_git "$d" push -q ;;
            busy)     edit "$d/.ai/STATE.md" 's/^| 02-paquete | 03 | LISTA_PARA_EJECUTAR | — |$/| 02-paquete | 03 | EN_CURSO | — |/'
                      up_git "$d" commit -qam busy; up_git "$d" push -q ;;
            dirty)    printf 'x\n' > "$d/suelto.txt" ;;
        esac
        before=$(worktree "$d"); head=$(git -C "$d" rev-parse HEAD)
        : > "$WORK/$KIT-upgh.log"
        if [ "$c" = dry ]; then out=$(upgrade "$d" "$k2" --dry-run); else out=$(upgrade "$d" "$k2"); fi
        rc=$?
        case $c in dry) want='y lo fusionaría con la CI en verde' ;; conflict) want='1 conflicto(s)' ;;
                   busy) want='hay fases a medias (02-paquete/03)' ;; dirty) want='el árbol no está limpio' ;; esac
        if [ "$c" = dry ]; then want_rc=0; else want_rc=1; fi
        if [ "$rc" -eq "$want_rc" ] && printf '%s\n' "$out" | grep -qF "$want" && [ "$(worktree "$d")" = "$before" ] \
           && [ "$(git -C "$d" rev-parse HEAD)" = "$head" ] && [ -z "$(git -C "$d" branch --list 'protocol/*')" ] \
           && [ ! -s "$WORK/$KIT-upgh.log" ]; then
            ok "$c: «$want», sin tocar nada"
        else fail "$c: protocol-upgrade no paró como se espera (salida $rc):"; printf '%s\n' "$out" | sed 's/^/      /'; fi
    done
}

# ── bin/sync-main.sh, con un origin local y un gh de mentira ───────────────
# sync_project <caso>: up_project con la rama phase/x commiteada y empujada, que es la del PR.
sync_project() {
    p=$(up_project "sync-$1") || return 1
    up_git "$p" switch -q -c phase/x && printf 'x\n' > "$p/x.txt" && up_git "$p" add x.txt \
        && up_git "$p" commit -q -m x && up_git "$p" push -q -u origin phase/x && printf '%s' "$p"
}

# sync <dir> [args]: bin/sync-main.sh en ese proyecto, con el gh de mentira. La punta del PR es la de origin/phase/x.
# GH_PR: merged (por defecto), open, closed o none (la rama no tiene PR). GH_MERGE_AT: la consulta del PR en la que
# se fusiona (1 por defecto: ya lo estaba). GH_CHECKS: la salida de «gh pr checks» (0 verde, 1 rojo, 8 en marcha).
sync() {
    p=$1; shift
    rm -f "$WORK/$KIT-syncgh.n"
    (cd "$p" && PATH="$WORK/$KIT-syncgh:$PATH" GH_LOG="$WORK/$KIT-syncgh.log" GH_N="$WORK/$KIT-syncgh.n" \
        GH_SHA=$(git rev-parse origin/phase/x) \
        SYNC_MAIN_POLL=0 sh bin/sync-main.sh "$@" 2>&1)
}

# shellcheck disable=SC2016  # los $ del stub son literales
test_sync() {
    printf '  ◆ bin/sync-main.sh\n'
    mkdir -p "$WORK/$KIT-syncgh"
    printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$*" >> "$GH_LOG"' 'case "$1 $2" in' \
        '    "pr view") [ "${GH_PR:-merged}" = none ] && exit 1' \
        '        n=$(( $(cat "$GH_N" 2> /dev/null || echo 0) + 1 )); echo "$n" > "$GH_N"; s=OPEN' \
        '        case ${GH_PR:-merged} in closed) s=CLOSED ;;' \
        '            merged) [ "$n" -ge "${GH_MERGE_AT:-1}" ] && git push -q origin "$GH_SHA:refs/heads/main" && s=MERGED ;; esac' \
        '        printf "number=7\nstate=%s\nbase=main\nhead=phase/x\nsha=%s\nurl=https://github.com/x/demo/pull/7\n" "$s" "$GH_SHA" ;;' \
        '    "pr checks") exit "${GH_CHECKS:-0}" ;;' \
        '    *) exit 1 ;;' 'esac' > "$WORK/$KIT-syncgh/gh"
    chmod +x "$WORK/$KIT-syncgh/gh"

    # Ya fusionado: a main, al día, sin la rama del PR. Y otra vez, ya en main: sólo la pone al día.
    d=$(sync_project merged) || { fail 'sync-main: no pude preparar el proyecto'; return; }
    out=$(sync "$d"); rc=$?
    if [ "$rc" -eq 0 ] && on_main "$d" && [ -f "$d/x.txt" ] && [ -z "$(git -C "$d" branch --list phase/x)" ] \
       && printf '%s\n' "$out" | grep -qF '✓ sync-main: main en ' && printf '%s\n' "$out" | grep -qF 'Fase activa: '; then
        ok 'con el PR fusionado: main al día con origin, sin la rama del PR, y dice la fase activa'
    else fail "sync-main no dejó main al día tras el merge (salida $rc):"; printf '%s\n' "$out" | sed 's/^/      /'; fi
    out=$(sync "$d"); rc=$?
    if [ "$rc" -eq 0 ] && on_main "$d"; then ok 'otra vez, ya en main: al día'
    else fail "en main, sync-main no terminó al día (salida $rc):"; printf '%s\n' "$out" | sed 's/^/      /'; fi

    # --wait: espera a que la CI pase y la persona lo fusione.
    d=$(sync_project wait) || return
    out=$(GH_MERGE_AT=3 sync "$d" --wait 1); rc=$?
    if [ "$rc" -eq 0 ] && on_main "$d" && printf '%s\n' "$out" | grep -qF 'CI en verde: falta que lo fusiones'; then
        ok '--wait: espera a la CI y al merge, y deja main al día'
    else fail "con --wait, sync-main no esperó al merge (salida $rc):"; printf '%s\n' "$out" | sed 's/^/      /'; fi

    # La rama local con un commit que el PR no llevó: main al día, pero la rama se queda.
    d=$(sync_project extra) || return
    up_git "$d" commit -q --allow-empty -m extra
    out=$(sync "$d"); rc=$?
    if [ "$rc" -eq 0 ] && on_main "$d" && [ -n "$(git -C "$d" branch --list phase/x)" ] \
       && printf '%s\n' "$out" | grep -qF 'tiene commits que el PR no llevó'; then
        ok 'una rama con commits que el PR no llevó: main al día y la rama se queda'
    else fail "sync-main borró una rama con commits sin fusionar (salida $rc):"; printf '%s\n' "$out" | sed 's/^/      /'; fi

    # Lo que no toca nada: sin fusionar (3), la CI en rojo esperando, cerrado sin fusionar, sin PR, cambios sin
    # commitear y un main local que no avanza en línea recta (1).
    for c in open red closed none dirty diverged; do
        d=$(sync_project "$c") || return
        export GH_PR=merged GH_CHECKS=0 GH_MERGE_AT=1
        args=''
        case $c in
            open)     GH_PR=open ;;
            red)      GH_PR=open GH_CHECKS=1 args=--wait ;;
            closed)   GH_PR=closed ;;
            none)     GH_PR=none ;;
            dirty)    printf 'y\n' >> "$d/x.txt" ;;
            diverged) up_git "$d" switch -q main; up_git "$d" commit -q --allow-empty -m local; up_git "$d" switch -q phase/x ;;
        esac
        before=$(worktree "$d"); head=$(git -C "$d" rev-parse HEAD)
        # shellcheck disable=SC2086  # args vacío o una palabra
        out=$(sync "$d" $args); rc=$?
        case $c in open) want='sigue sin fusionar'; want_rc=3 ;; red) want='la CI del PR #7 falla'; want_rc=1 ;;
                   closed) want='se cerró sin fusionar'; want_rc=1 ;; none) want='no tiene PR'; want_rc=1 ;;
                   dirty) want='cambios sin commitear'; want_rc=1 ;; diverged) want='no avanza en línea recta'; want_rc=1 ;; esac
        if [ "$rc" -eq "$want_rc" ] && printf '%s\n' "$out" | grep -qF "$want" && [ "$(worktree "$d")" = "$before" ] \
           && [ "$(git -C "$d" rev-parse HEAD)" = "$head" ] && [ -n "$(git -C "$d" branch --list phase/x)" ]; then
            ok "$c: «$want», sale $want_rc y no toca la rama"
        else fail "$c: sync-main no paró como se espera (salida $rc):"; printf '%s\n' "$out" | sed 's/^/      /'; fi
        unset GH_PR GH_CHECKS GH_MERGE_AT
    done
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
            permisos)  edit stacks/nextjs/.claude/settings.json 's/"Bash(gh pr edit \*)", //' ;;
            pull)      edit stacks/laravel/.claude/settings.json 's/"Bash(git pull --ff-only\*)", //' ;;
            feedback)  edit stacks/laravel/.claude/settings.json 's/"Bash(sh bin\/protocol-feedback.sh\*)", //' ;;
            suelta)    edit core/.claude/skills/phase/cierre.md 's/^1\. `git push -u origin <rama de la fase>`/1. `git push -u origin <rama de la fase> \&\& gh pr view`/' ;;
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
    breaks permisos 'stacks/nextjs/.claude/settings.json no permite «gh pr edit --body-file'
    breaks pull     'stacks/laravel/.claude/settings.json no permite «git pull --ff-only», que pide core/.claude/skills/phase/SKILL.md'
    breaks feedback 'stacks/laravel/.claude/settings.json no permite «sh bin/protocol-feedback.sh», que pide core/.claude/skills/phase/cierre.md'
    breaks suelta   '«git push -u origin phase/01-demo/01 && gh pr view» no va suelta'
}

# ── docs/vps/doctor.sh, con un PATH de stubs ────────────────────────────────
# El PATH sólo tiene stubs de las herramientas del VPS, que responden como un VPS preparado (STUB_NODE cambia la
# versión de Node), y las utilidades que usa el script.
# shellcheck disable=SC2016  # el stub se escribe tal cual
test_doctor() {
    printf '◆ docs/vps/doctor.sh\n'
    stubs="$WORK/doctor-path"
    mkdir -p "$stubs"
    printf '%s\n' '#!/bin/sh' 'case "${0##*/} $*" in' \
        "    'php -r'*) printf 8.4.1 ;;" \
        "    'php -m') echo pdo_pgsql ;;" \
        '    "node --version") echo "${STUB_NODE:-v22.3.0}" ;;' \
        "    'claude auth status') echo '{\"loggedIn\": true, \"authMethod\": \"claude.ai\"}' ;;" \
        "    'psql '*) echo '1|f' ;;" \
        'esac' > "$stubs/stub"
    chmod +x "$stubs/stub"
    for c in git gh claude tmux gitleaks php composer node npm psql; do ln -s stub "$stubs/$c"; done
    for u in sed grep id; do ln -s "$(command -v "$u")" "$stubs/$u"; done
    shell=$(command -v sh)
    doctor() { PATH="$stubs" STUB_NODE=${STUB_NODE:-} "$shell" "$ROOT/docs/vps/doctor.sh" "$@" 2>&1; }

    if out=$(doctor) && printf '%s\n' "$out" | grep -qF 'no falta nada'; then ok 'con todo, no falta nada'
    else fail 'con todo, dice que falta algo:'; printf '%s\n' "$out" | grep '✗' | sed 's/^/      /'; fi
    rm "$stubs/gitleaks"
    if ! out=$(doctor) && printf '%s\n' "$out" | grep -qF 'gitleaks: falta'; then ok 'sin gitleaks en el PATH, lo reporta'
    else fail 'sin gitleaks en el PATH, no lo reporta'; printf '%s\n' "$out" | sed 's/^/      /'; fi
    ln -s stub "$stubs/gitleaks"
    if ! out=$(STUB_NODE=v20.1.0 doctor) && printf '%s\n' "$out" | grep -qF 'node v20.1.0: hace falta 22'; then
        ok 'con Node 20, pide 22'
    else fail 'con Node 20, no pide 22'; printf '%s\n' "$out" | sed 's/^/      /'; fi
    echo 'APP_KEY=x' > "$WORK/staging.env"
    if ! out=$(doctor --env "$WORK/staging.env") && printf '%s\n' "$out" | grep -qF "puede leer $WORK/staging.env"; then
        ok 'un .env de staging que el usuario de los agentes puede leer falla'
    else fail 'un .env de staging legible no falla'; printf '%s\n' "$out" | sed 's/^/      /'; fi
}

# ── docs/guia.md: cada ruta que cita existe ─────────────────────────────────
# guide_paths <guía>: lo que cita, una ruta por línea. «enlace <ruta>», el destino relativo de un enlace; «ruta
# <ruta>», una palabra del código (en línea o en un bloque) que acaba en / o en una extensión de archivo del kit. Lo
# que lleva <…>, * o {…} es un patrón, lo que empieza por / es una skill y `.md` sola es una extensión: no son rutas.
guide_paths() {
    awk '
        function words(s,   n, i, w, a) {
            n = split(s, a, /[ \t]+/)
            for (i = 1; i <= n; i++) {
                w = a[i]; sub(/^[("«]+/, "", w); sub(/[,;:.)»]+$/, "", w)
                if (w ~ /[<>*{}]|:\/\/|^\/|^\.[a-z]+$/) continue
                if (w ~ /\/$/ || w ~ /\.(md|sh|json|yml|conf|lock|mjs|ts|php|neon|service|txt)$/) print "ruta " w
            }
        }
        /^```/ { f = !f; next }
        f { words($0); next }
        {
            s = $0
            while (match(s, /`[^`]+`/)) { words(substr(s, RSTART + 1, RLENGTH - 2)); s = substr(s, RSTART + RLENGTH) }
            s = $0
            while (match(s, /\]\([^)]+\)/)) {
                l = substr(s, RSTART + 2, RLENGTH - 3); s = substr(s, RSTART + RLENGTH)
                sub(/#.*/, "", l)
                if (l != "" && l !~ /:\/\//) print "enlace " l
            }
        }' "$1"
}

# guide_missing <guía> <carpeta de sus enlaces> <raíz…>: lo que cita la guía y no existe. Un enlace, desde su
# carpeta; una ruta, en alguna de las raíces (el kit y las instalaciones), y ai-protocol/ es el kit.
guide_missing() {
    gm_guide=$1 gm_dir=$2
    shift 2
    guide_paths "$gm_guide" | while read -r kind p; do
        if [ "$kind" = enlace ]; then
            [ -e "$gm_dir/$p" ] && continue
        else
            q=${p#../}; q=${q#ai-protocol/}
            for r in "$@"; do [ -e "$r/$q" ] && continue 2; done
        fi
        printf '%s\n' "$p"
    done
}

# Las rutas de la guía, frente al kit y a las instalaciones de prueba de los dos stacks, que tienen la épica del
# ejemplo; si este run sólo instaló uno, instala el otro. Y al revés: una ruta que no existe se reporta.
# shellcheck disable=SC2016  # las comillas invertidas son literales
test_guide() {
    printf '◆ docs/guia.md\n'
    for k in laravel nextjs; do
        [ -d "$WORK/$k" ] && continue
        case "$k" in laravel) SIBLING=frontend ;; nextjs) SIBLING=backend ;; esac
        install "$k" "$WORK/$k" || { fail "no se pudo instalar $k para comprobar la guía"; return; }
    done
    n=$(guide_paths "$ROOT/docs/guia.md" | sort -u | grep -c .)
    missing=$(guide_missing "$ROOT/docs/guia.md" "$ROOT/docs" "$ROOT" "$WORK/laravel" "$WORK/nextjs" | sort -u)
    if [ -z "$missing" ]; then ok "las $n rutas y scripts que cita existen en el kit o en una instalación"
    else fail 'cita rutas que no existen:'; printf '%s\n' "$missing" | sed 's/^/      /'; fi
    cp "$ROOT/docs/guia.md" "$WORK/guia-rota.md"
    printf '\nVer `bin/no-existe.sh` y [esto](no-existe.md).\n' >> "$WORK/guia-rota.md"
    missing=$(guide_missing "$WORK/guia-rota.md" "$ROOT/docs" "$ROOT" "$WORK/laravel" "$WORK/nextjs" | tr '\n' ' ')
    if [ "$missing" = 'bin/no-existe.sh no-existe.md ' ]; then ok 'una ruta o un enlace que no existen se reportan'
    else fail "con una ruta y un enlace que no existen, reporta «$missing»"; fi
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

    test_feedback
    test_installer
    test_upgrade
    test_sync
    test_new_project
    test_protocol
done

test_structure
test_doctor
test_guide

printf '\n'
if [ "$FAIL" -eq 0 ]; then echo '✓ tests/run.sh: todo en verde'; else echo '✗ tests/run.sh: hay fallos'; fi
exit "$FAIL"
