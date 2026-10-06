#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# verify.sh — el único gate de «el código está sano».
#
# ◆ CÓMO SE EJECUTA
#   bash bin/verify.sh            todos los gates: el del cierre de una fase
#   bash bin/verify.sh --fast     sólo los baratos (sin la auditoría ni los
#                                 tests): el de cada commit de fila
#                                 (.claude/skills/phase/SKILL.md §Commits
#                                 durante la fase)
#   Sirve igual `sh bin/verify.sh` o un script `"verify": "sh bin/verify.sh"`
#   en package.json.
#
# ◆ CONTRATO
#   Sale 0 si todo está en verde y != 0 si algo falla. Este script es la ÚNICA
#   descripción de los gates y de su orden: la skill /phase y .ai/WORKFLOW.md
#   remiten aquí sin repetirlos, así que se cambian aquí sin tocar
#   documentación. Orden: barato primero (documentos, tipos, estilo), los tests
#   al final.
#
# ◆ EL PROYECTO
#   Este script es del kit: una fase no lo cambia (.ai/WORKFLOW.md §Archivos
#   del protocolo). La baseline, que sólo se mueve en la dirección buena, es
#   del proyecto y vive en .ai/project/verify.conf, que el script lee al
#   empezar.
#
# ◆ HERRAMIENTAS
#   Además de las del stack: git y gitleaks (gates «protocolo» y «secretos»).
#   Si falta una, su gate falla y dice cómo instalarla.
#
# ◆ LOGS
#   Cada ejecución usa su propio directorio temporal: dos sesiones en paralelo
#   no se pisan los logs.
# ─────────────────────────────────────────────────────────────────────────────
cd "$(dirname "$0")/.." || exit 1

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN DEL PROYECTO: MIN_TESTS y MAX_SUPPRESSIONS
# ─────────────────────────────────────────────────────────────────────────────
[ -f .ai/project/verify.conf ] || {
    echo '✗ falta .ai/project/verify.conf (la baseline del proyecto); install.sh --upgrade lo crea'
    exit 1
}
# shellcheck source=/dev/null  # es del proyecto
. ./.ai/project/verify.conf
: "${MIN_TESTS:?falta en .ai/project/verify.conf}"
: "${MAX_SUPPRESSIONS:?falta en .ai/project/verify.conf}"

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
# shellcheck disable=SC2329  # se invoca a través de run()
suppressions_gate() {
    n=0
    if [ -f eslint-suppressions.json ]; then
        # La suma de todos los «"count": N» del archivo que genera `eslint --suppress-all`.
        n=$(grep -oE '"count": *[0-9]+' eslint-suppressions.json | grep -oE '[0-9]+$' | awk '{ s += $1 } END { print s + 0 }')
    fi
    echo "supresiones: $n (máximo $MAX_SUPPRESSIONS)"
    [ "$n" -le "$MAX_SUPPRESSIONS" ] || { echo "las supresiones subieron: $n > $MAX_SUPPRESSIONS"; return 1; }
}

# Ningún secreto en el historial de git: lo que se empuja ya no se puede retirar. Va antes del push, también con
# --fast.
# shellcheck disable=SC2329  # se invoca a través de run()
secrets_gate() {
    command -v gitleaks > /dev/null 2>&1 || {
        echo 'falta gitleaks (https://github.com/gitleaks/gitleaks#installing; en la nube, docs/modos.md del kit)'
        return 1
    }
    gitleaks git --no-banner --no-color --redact --verbose --log-level=warn . && echo 'secretos: ninguno en el historial de git'
}

# Los tests y su baseline: el conteo sale de la línea «Tests  N passed» de Vitest (anclada, para no
# confundirla con «Test Files»). Sin archivos de test, cuenta 0.
# shellcheck disable=SC2329  # se invoca a través de run()
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
run 'protocolo'    sh bin/check-protocol.sh
run 'secretos'     secrets_gate
run 'tipos'        npx tsc --noEmit
run 'estilo'       npx eslint . --max-warnings=0
run 'supresiones'  suppressions_gate
# La auditoría consulta la red y los tests son lo más lento: los dos, sólo en el verify completo.
if [ "$FAST" -eq 0 ]; then
    run 'dependencias'  npm audit --audit-level=high
    run 'tests'    tests_gate
else
    printf '\n▸ dependencias y tests  (omitidos con --fast; el cierre de una fase exige el verify completo)\n'
fi

printf '\n'
if [ "$FAIL" -eq 0 ]; then echo '✅ VERDE'; else echo '❌ ROJO'; fi
exit "$FAIL"
