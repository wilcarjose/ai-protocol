#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# tests/e2e-laravel.sh — el stack de Laravel sobre un proyecto de verdad.
#
# ◆ QUÉ HACE
#   1. Crea un proyecto nuevo con composer create-project y le añade los
#      paquetes de .ai/RULES.md §Stack y versiones exactas, en las versiones de
#      abajo (Pest en lugar de PHPUnit).
#   2. Instala el stack con install.sh, rellena la capa del proyecto como
#      tests/run.sh (tests/lib.sh), copia la funcionalidad de ejemplo
#      (tests/fixtures/laravel-e2e/: la Action App\Actions\Demo\ShowDemo, su
#      endpoint, sus tests y una migración que activa PostGIS), genera los
#      baselines del contrato y lo versiona todo en un repo git.
#   3. Comprueba que `sh bin/verify.sh` completo termina en verde, con la
#      suite contra PostgreSQL con PostGIS.
#   4. Provoca los dos fallos que el stack promete detectar: una Action que usa
#      Illuminate\Http\Request hace fallar las pruebas de arquitectura, y un
#      endpoint que cambia sin actualizar el baseline hace fallar el gate
#      «contrato».
#
# ◆ LO QUE CAMBIA DE LO QUE DEJA create-project
#   Borra su AGENTS.md y su CLAUDE.md antes de instalar, porque el instalador
#   nunca pisa un archivo del proyecto y esos dos son los del kit; sus tests de
#   ejemplo, que son clases de PHPUnit; y las líneas de phpunit.xml que fijan
#   SQLite en memoria. Sustituye bootstrap/app.php por el del fixture, que
#   registra las rutas de la API y App\Http\ProblemDetails. Un proyecto que ya
#   existe hace lo mismo a mano (stacks/laravel/CHANGELOG.md).
#
# ◆ HERRAMIENTAS
#   PHP 8.4 con pdo_pgsql, Composer, git y gitleaks; un PostgreSQL con PostGIS
#   con la base de datos «testing» (usuario y contraseña postgres) en
#   DB_HOST:DB_PORT (127.0.0.1:5432 si no se dicen); y red, para Composer y la
#   auditoría.
#
# ◆ USO
#   sh tests/e2e-laravel.sh       (E2E_KEEP=1 conserva el proyecto y dice dónde)
#
# ◆ CONTRATO
#   Sale 0 si verify.sh pasa y los dos fallos provocados se detectan; != 0 si
#   no. No toca el repo: trabaja en un directorio temporal.
# ─────────────────────────────────────────────────────────────────────────────
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=tests/lib.sh
. "$ROOT/tests/lib.sh"

SKELETON_VERSION=13.10.1
DEPS='laravel/framework:13.34.0 dedoc/scramble:0.13.47'
DEV_DEPS='pestphp/pest:5.3.0 pestphp/pest-plugin-laravel:5.0.1 larastan/larastan:3.12.3 laravel/pint:1.32.1'

WORK=$(mktemp -d)
if [ "${E2E_KEEP:-0}" = 1 ]; then trap 'echo "proyecto: $WORK/demo"' EXIT; else trap 'rm -rf "$WORK"' EXIT; fi
APP=$WORK/demo
FAIL=0
export COMPOSER_NO_INTERACTION=1
# laravel/pao cambia la salida de Pest por JSON cuando detecta un agente; aquí se lee la de siempre.
export PAO_DISABLE=1

ok()   { printf '  ✓ %s\n' "$1"; }
fail() { printf '  ✗ %s\n' "$1"; FAIL=1; }
step() { printf '\n◆ %s\n' "$1"; }
# quiet <log> <comando…>: el comando con su salida en un log, que se enseña si falla.
quiet() {
    log=$1
    shift
    "$@" > "$log" 2>&1 && return 0
    tail -n 40 "$log" | sed 's/^/      /'
    return 1
}
# g <args de git>: git en el proyecto, sin depender de la configuración de quien lo ejecuta.
g() { git -C "$APP" -c user.name=kit -c user.email=kit@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
# gate_fails <log> <gate>: el gate falló en esa salida de verify.sh.
gate_fails() { awk -v g="▸ $2" 'index($0, g) == 1 { c = 1; next } c && /^▸/ { exit } c && /✗$/ { f = 1 } END { exit !f }' "$1"; }

step "proyecto nuevo (laravel/laravel $SKELETON_VERSION)"
# shellcheck disable=SC2086  # las listas de paquetes se parten a propósito
if ! quiet "$WORK/create.log" composer create-project --prefer-dist --no-progress "laravel/laravel=$SKELETON_VERSION" "$APP" \
   || ! rm -f "$APP/AGENTS.md" "$APP/CLAUDE.md" "$APP/tests/Feature/ExampleTest.php" "$APP/tests/Unit/ExampleTest.php" \
   || ! (cd "$APP" && quiet "$WORK/remove.log" composer remove --dev --no-progress phpunit/phpunit \
        && quiet "$WORK/deps.log" composer require --no-progress -W $DEPS \
        && quiet "$WORK/dev-deps.log" composer require --dev --no-progress -W $DEV_DEPS \
        && quiet "$WORK/pest.log" ./vendor/bin/pest --init --no-interaction); then
    fail 'no pude crear el proyecto'
    exit 1
fi
edit "$APP/phpunit.xml" '/<env name="DB_CONNECTION"/d; /<env name="DB_DATABASE"/d'
ok "Laravel $SKELETON_VERSION con los paquetes del stack"

step 'install.sh --stack laravel'
quiet "$WORK/install.log" sh "$ROOT/install.sh" --stack laravel --target "$APP" || { fail 'install.sh no termina en 0'; exit 1; }
cp -R "$ROOT/tests/fixtures/laravel-e2e/." "$APP/"
(
    cd "$APP" || exit 1
    fill_stack .ai/RULES.md .ai/project/DECISIONS.md composer.json
    find . -path ./vendor -prune -o -path ./node_modules -prune -o -type f -name '*.md' -exec grep -lF '{{RELLENAR' {} + \
        | while read -r f; do fill_markers "$f" frontend; done
    quiet "$WORK/key.log" php artisan key:generate --env=testing \
        && quiet "$WORK/contract.log" sh bin/contract.sh \
        && php scripts/normalize-routes.php > docs/contract/routes-baseline.txt
) || { fail 'no pude preparar la instalación'; exit 1; }
if ! quiet "$WORK/git.log" git init -q -b main "$APP" || ! g add -A \
   || ! quiet "$WORK/commit.log" g commit -q -m 'chore: demo project'; then
    fail 'no pude versionar el proyecto'
    exit 1
fi
ok 'stack instalado, capa del proyecto rellena, funcionalidad de ejemplo y baselines del contrato'

step 'bin/verify.sh completo'
if (cd "$APP" && sh bin/verify.sh > "$WORK/verify.log" 2>&1); then
    grep -E '^▸|✓$|✗$' "$WORK/verify.log" | paste - - | sed 's/^/  /'
    ok 'verify.sh en verde, con la suite contra PostgreSQL con PostGIS'
else
    sed 's/^/      /' "$WORK/verify.log"
    fail 'verify.sh no está en verde sobre un proyecto nuevo'
fi

step 'fallos provocados'
# Una Action que recibe la petición: la capa HTTP no entra en la lógica de negocio.
action="$APP/app/Actions/Demo/ShowDemo.php"
# shellcheck disable=SC2016  # el $id es de PHP
edit "$action" 's#^use App\\Exceptions\\ApiException;#&\nuse Illuminate\\Http\\Request;#
    s#public function handle(int \$id): array#public function handle(int $id, ?Request $request = null): array#'
if (cd "$APP" && ./vendor/bin/pest --colors=never tests/Architecture > "$WORK/arch.log" 2>&1); then
    fail 'arquitectura: las pruebas aceptan una Action que usa Illuminate\Http\Request'
elif grep -q 'App\\Actions no conoce la capa HTTP' "$WORK/arch.log"; then
    ok 'arquitectura: una Action que usa Illuminate\Http\Request hace fallar las pruebas de arquitectura'
else
    sed 's/^/      /' "$WORK/arch.log"
    fail 'arquitectura: las pruebas fallan, pero no por la capa HTTP'
fi
g checkout -q -- app/Actions/Demo/ShowDemo.php

# Un campo más en la respuesta del endpoint, sin regenerar el baseline: las rutas no cambian, el contrato sí.
edit "$action" "s#array{id: int, name: string}#array{id: int, name: string, slug: string}#
    s#return \['id' => \$id, 'name' => 'Demo'\];#return ['id' => \$id, 'name' => 'Demo', 'slug' => 'demo'];#"
(cd "$APP" && sh bin/verify.sh --fast > "$WORK/contract-gate.log" 2>&1)
if gate_fails "$WORK/contract-gate.log" contrato && ! gate_fails "$WORK/contract-gate.log" rutas; then
    ok 'contrato: un endpoint que cambia sin actualizar el baseline hace fallar el gate «contrato»'
else
    sed 's/^/      /' "$WORK/contract-gate.log"
    fail 'contrato: el gate «contrato» no detecta el endpoint cambiado'
fi
g checkout -q -- app/Actions/Demo/ShowDemo.php

printf '\n'
if [ "$FAIL" -eq 0 ]; then echo '✓ tests/e2e-laravel.sh: todo en verde'; else echo '✗ tests/e2e-laravel.sh: hay fallos'; fi
exit "$FAIL"
