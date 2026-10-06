#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# verify.sh — el único gate de «el código está sano».
#
# ◆ CÓMO SE EJECUTA
#   bash bin/verify.sh            todos los gates: el del cierre de una fase
#   bash bin/verify.sh --fast     sólo los baratos (sin la auditoría ni la
#                                 suite): el de cada commit de fila
#                                 (.claude/skills/phase/SKILL.md §Commits
#                                 durante la fase)
#   Sirve igual `sh bin/verify.sh`: está escrito en POSIX sh porque la imagen
#   habitual de PHP (php:*-alpine) no trae bash.
#
# ◆ CONTRATO
#   Sale 0 si todo está en verde y != 0 si algo falla. Este script es la ÚNICA
#   descripción de los gates y de su orden: la skill /phase y .ai/WORKFLOW.md
#   remiten aquí sin repetirlos, así que se cambian aquí sin tocar
#   documentación. Orden: barato y ruidoso primero, la suite al final.
#
# ◆ EL PROYECTO
#   Este script es del kit: una fase no lo cambia (.ai/WORKFLOW.md §Archivos
#   del protocolo). Lo que es del proyecto —la baseline, que sólo se mueve en
#   la dirección buena, y el servicio de Docker Compose— vive en
#   .ai/project/verify.conf, que el script lee al empezar.
#
# ◆ HERRAMIENTAS
#   Además de las del stack: git y gitleaks (gates «protocolo» y «secretos»).
#   Si falta una, su gate falla y dice cómo instalarla.
# ─────────────────────────────────────────────────────────────────────────────
cd "$(dirname "$0")/.." || exit 1

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN DEL PROYECTO: MIN_TESTS, MAX_PHPSTAN_IGNORES, VERIFY_SERVICE…
# ─────────────────────────────────────────────────────────────────────────────
[ -f .ai/project/verify.conf ] || {
    echo '✗ falta .ai/project/verify.conf (la baseline y la configuración del proyecto); install.sh --upgrade lo crea'
    exit 1
}
# shellcheck source=/dev/null  # es del proyecto
. ./.ai/project/verify.conf
: "${VERIFY_SERVICE:=}"
: "${COMPOSE_CMD:=docker compose}"
: "${MIN_TESTS:?falta en .ai/project/verify.conf}"
: "${MAX_PHPSTAN_IGNORES:?falta en .ai/project/verify.conf}"

# laravel/pao (en el esqueleto de Laravel) cambia la salida de Pest, PHPStan y Pint por JSON cuando detecta un agente;
# los gates leen la salida de siempre.
export PAO_DISABLE=1

# Memoria de PHPStan. Con el memory_limit por defecto, un worker paralelo puede
# reventar sin que haya ningún error de código y el gate parece intermitente.
: "${PHPSTAN_MEMORY_LIMIT:=1G}"

# ─────────────────────────────────────────────────────────────────────────────
# ¿En el host o en el contenedor?
# ─────────────────────────────────────────────────────────────────────────────
in_container() { [ -f /.dockerenv ] || [ "${VERIFY_IN_DOCKER:-0}" = "1" ]; }

if [ -n "$VERIFY_SERVICE" ] && ! in_container && [ "${CI:-false}" != "true" ]; then
    printf '▸ en el host: relanzando dentro del servicio «%s»…\n' "$VERIFY_SERVICE"
    T_TTY=''
    [ -t 1 ] || T_TTY='-T'
    # shellcheck disable=SC2086  # separar COMPOSE_CMD y T_TTY es lo que se quiere
    exec $COMPOSE_CMD exec -e VERIFY_IN_DOCKER=1 $T_TTY "$VERIFY_SERVICE" sh bin/verify.sh "$@"
fi

FAST=0
[ "${1:-}" = "--fast" ] && FAST=1
FAIL=0
TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

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

# El contrato HTTP no cambia sin autorización (.ai/RULES.md §Contrato HTTP): si las rutas difieren del
# baseline, el cambio es involuntario hasta que se demuestre lo contrario.
# shellcheck disable=SC2329  # se invoca a través de run()
routes_gate() {
    if [ ! -f docs/contract/routes-baseline.txt ]; then
        echo 'falta docs/contract/routes-baseline.txt; genéralo con:'
        echo '  php scripts/normalize-routes.php > docs/contract/routes-baseline.txt'
        return 1
    fi
    php scripts/normalize-routes.php > "$TMPD/routes.txt" || return 1
    if ! diff -u docs/contract/routes-baseline.txt "$TMPD/routes.txt"; then
        echo 'las rutas cambiaron. Si es un cambio de contrato autorizado, regenera el baseline en la misma fase.'
        return 1
    fi
    echo "rutas: $(grep -cE '^[A-Z]+\|' docs/contract/routes-baseline.txt) sin cambios"
}

# La deuda de análisis estático sólo mengua (.ai/RULES.md §Verificación del stack).
# shellcheck disable=SC2329  # se invoca a través de run()
phpstan_debt_gate() {
    n=0
    [ -f phpstan-baseline.neon ] && n=$(grep -c 'message:' phpstan-baseline.neon)
    echo "phpstan-baseline.neon: $n entrada(s) (máximo $MAX_PHPSTAN_IGNORES)"
    [ "$n" -le "$MAX_PHPSTAN_IGNORES" ] || {
        echo "el baseline de PHPStan creció: $n > $MAX_PHPSTAN_IGNORES; los errores nuevos se arreglan, no se ignoran"
        return 1
    }
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

# La suite completa y su baseline: el conteo sale de la línea «Tests: … N passed» de Pest. Corre contra el motor de
# producción con la conexión de .env.testing (.ai/rules/tests.md §Tests): el phpunit.xml del esqueleto la pisa con
# SQLite en memoria.
# shellcheck disable=SC2329  # se invoca a través de run()
tests_gate() {
    if grep -qE '<env name="DB_(CONNECTION|DATABASE)"' phpunit.xml 2> /dev/null; then
        echo 'phpunit.xml fija DB_CONNECTION o DB_DATABASE: quítalos, la conexión de los tests sale de .env.testing'
        return 1
    fi
    ./vendor/bin/pest --colors=never > "$TMPD/pest.log" 2>&1
    rc=$?
    tail -n 30 "$TMPD/pest.log"
    [ "$rc" -eq 0 ] || return 1
    count=$(sed -n 's/.*Tests:.* \([0-9][0-9]*\) passed.*/\1/p' "$TMPD/pest.log" | tail -n 1)
    [ -n "$count" ] || { echo 'no pude leer el conteo de tests de la salida de Pest'; return 1; }
    echo "tests: $count (mínimo $MIN_TESTS)"
    [ "$count" -ge "$MIN_TESTS" ] || { echo "el conteo de tests bajó: $count < $MIN_TESTS"; return 1; }
}

# ─────────────────────────────────────────────────────────────────────────────
# Gates — barato primero
# ─────────────────────────────────────────────────────────────────────────────
run 'docs'          sh bin/check-docs.sh --strict
run 'protocolo'     sh bin/check-protocol.sh
run 'secretos'      secrets_gate
run 'estilo'        ./vendor/bin/pint --test
run 'análisis'      ./vendor/bin/phpstan analyse --no-progress --memory-limit="$PHPSTAN_MEMORY_LIMIT"
run 'deuda'         phpstan_debt_gate
run 'rutas'         routes_gate
# El contrato es el OpenAPI que genera el código: si ya no genera el baseline, cambió (.ai/RULES.md §Contrato HTTP).
run 'contrato'      sh bin/contract.sh --check
# tests/Architecture tiene su propio gate, en los dos modos: las suites del phpunit.xml de Laravel son Unit y Feature.
run 'arquitectura'  ./vendor/bin/pest --colors=never tests/Architecture
# La auditoría consulta la red y la suite es lo más lento: los dos, sólo en el verify completo.
if [ "$FAST" -eq 0 ]; then
    run 'dependencias'  composer audit --no-interaction --no-dev
    run 'suite'         tests_gate
else
    printf '\n▸ dependencias y suite  (omitidas con --fast; el cierre de una fase exige el verify completo)\n'
fi

printf '\n'
if [ "$FAIL" -eq 0 ]; then echo '✅ VERDE'; else echo '❌ ROJO'; fi
exit "$FAIL"
