#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# verify.sh — el único gate de «el código está sano».
#
# ◆ CÓMO SE EJECUTA
#   bash bin/verify.sh            todos los gates: el del cierre de una fase
#   bash bin/verify.sh --fast     sólo los baratos (sin tests): el de cada
#                                 commit de fila (CLAUDE.md §Commits durante la fase)
#   Sirve igual `sh bin/verify.sh` o un script `"verify": "sh bin/verify.sh"`
#   en package.json.
#
# ◆ CONTRATO
#   Sale 0 si todo está en verde y != 0 si algo falla. Este script es la ÚNICA
#   descripción de los gates, de su orden y de la baseline: CLAUDE.md y
#   .ai/WORKFLOW.md remiten aquí sin repetirlos, así que se cambian aquí sin
#   tocar documentación. Orden: barato primero (documentos, tipos, estilo), los
#   tests al final.
#
# ◆ BASELINE
#   Los números que nunca empeoran viven abajo, en «BASELINE». Los mueve quien
#   cierra una fase que los mejora, en su commit de cierre; el diff de este
#   archivo es el registro de esa mejora. Nunca se mueven en la dirección mala.
#
# ◆ LOGS
#   Cada ejecución usa su propio directorio temporal: dos sesiones en paralelo
#   no se pisan los logs.
# ─────────────────────────────────────────────────────────────────────────────
cd "$(dirname "$0")/.." || exit 1

# ─────────────────────────────────────────────────────────────────────────────
# BASELINE — sólo se mueven en la dirección buena.
# ─────────────────────────────────────────────────────────────────────────────
MIN_TESTS=0            # tests de Vitest que pasan (nunca baja)
MAX_SUPPRESSIONS=0     # supresiones de eslint-suppressions.json (nunca sube)

FAST=0
[ "${1:-}" = "--fast" ] && FAST=1
FAIL=0
TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT
export NO_COLOR=1

# run <nombre> <comando…>: ejecuta un gate; si falla, enseña el final de su salida.
run() {
    name=$1
    shift
    printf '\n▸ %s\n' "$name"
    if "$@" > "$TMPD/gate.log" 2>&1; then
        tail -n 1 "$TMPD/gate.log" | sed 's/^/  │ /'
        printf '  ✓\n'
    else
        tail -n 40 "$TMPD/gate.log" | sed 's/^/  │ /'
        printf '  ✗\n'
        FAIL=1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Gates propios del stack
# ─────────────────────────────────────────────────────────────────────────────

# La deuda de lint congelada sólo mengua (.ai/RULES.md §Verificación del stack).
suppressions_gate() {
    n=0
    if [ -f eslint-suppressions.json ]; then
        # La suma de todos los «"count": N» del archivo que genera `eslint --suppress-all`.
        n=$(grep -oE '"count": *[0-9]+' eslint-suppressions.json | grep -oE '[0-9]+$' | awk '{ s += $1 } END { print s + 0 }')
    fi
    echo "supresiones: $n (máximo $MAX_SUPPRESSIONS)"
    [ "$n" -le "$MAX_SUPPRESSIONS" ] || { echo "las supresiones subieron: $n > $MAX_SUPPRESSIONS"; return 1; }
}

# Los tests y su baseline: el conteo sale de la línea «Tests  N passed» de Vitest (anclada, para no
# confundirla con «Test Files»). Sin archivos de test, cuenta 0.
tests_gate() {
    npx vitest run --reporter=dot --passWithNoTests > "$TMPD/vitest.log" 2>&1
    rc=$?
    tail -n 30 "$TMPD/vitest.log"
    [ "$rc" -eq 0 ] || return 1
    count=$(grep -E '^[[:space:]]*Tests[[:space:]]+[0-9]+[[:space:]]+passed' "$TMPD/vitest.log" | grep -oE '[0-9]+' | head -n 1)
    if [ -z "$count" ]; then
        grep -q 'No test files found' "$TMPD/vitest.log" || { echo 'no pude leer el conteo de tests de la salida de Vitest'; return 1; }
        count=0
    fi
    echo "tests: $count (mínimo $MIN_TESTS)"
    [ "$count" -ge "$MIN_TESTS" ] || { echo "el conteo de tests bajó: $count < $MIN_TESTS"; return 1; }
}

# ─────────────────────────────────────────────────────────────────────────────
# Gates — barato primero
# ─────────────────────────────────────────────────────────────────────────────
run 'docs'         sh bin/check-docs.sh --strict
run 'tipos'        npx tsc --noEmit
run 'estilo'       npx eslint . --max-warnings=0
run 'supresiones'  suppressions_gate
if [ "$FAST" -eq 0 ]; then
    run 'tests'    tests_gate
else
    printf '\n▸ tests  (omitidos con --fast; el cierre de una fase exige el verify completo)\n'
fi

printf '\n'
if [ "$FAIL" -eq 0 ]; then echo '✅ VERDE'; else echo '❌ ROJO'; fi
exit "$FAIL"
