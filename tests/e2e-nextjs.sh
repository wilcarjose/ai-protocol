#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# tests/e2e-nextjs.sh — el stack de Next.js sobre un proyecto de verdad.
#
# ◆ QUÉ HACE
#   1. Crea un proyecto nuevo con create-next-app y le añade los paquetes de
#      .ai/RULES.md §Stack y versiones exactas, en las versiones de abajo.
#   2. Instala el stack con install.sh, rellena la capa del proyecto como
#      tests/run.sh (tests/lib.sh), copia el OpenAPI de ejemplo y la feature que
#      lo usa (tests/fixtures/nextjs-e2e/), genera el cliente y lo versiona todo
#      en un repo git.
#   3. Comprueba que `sh bin/verify.sh` completo, con `next build`, termina en
#      verde.
#   4. Provoca los dos fallos que el stack promete detectar: un import que
#      rompe las capas hace fallar ESLint, y un cambio en el OpenAPI sin
#      regenerar el cliente hace fallar el gate «contrato».
#   Con E2E_LIGHTHOUSE=1 corre además Lighthouse CI con los presupuestos de
#   .ai/project/lighthouse.json, como el job «lighthouse» del workflow del
#   stack (necesita Chrome).
#
# ◆ LO QUE CAMBIA DE LO QUE DEJA create-next-app
#   Borra su AGENTS.md, su CLAUDE.md y su eslint.config.mjs antes de instalar,
#   porque el instalador nunca pisa un archivo del proyecto: los dos primeros
#   son los del kit, y el tercero, la semilla que importa eslint.layers.mjs.
#   Un proyecto que ya existe los integra a mano (stacks/nextjs/CHANGELOG.md).
#
# ◆ HERRAMIENTAS
#   Node 22 o superior con npm, git y gitleaks; y red, para npm y la auditoría.
#
# ◆ USO
#   sh tests/e2e-nextjs.sh       (E2E_KEEP=1 conserva el proyecto y dice dónde)
#
# ◆ CONTRATO
#   Sale 0 si verify.sh pasa y los dos fallos provocados se detectan; != 0 si
#   no. No toca el repo: trabaja en un directorio temporal.
# ─────────────────────────────────────────────────────────────────────────────
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=tests/lib.sh
. "$ROOT/tests/lib.sh"

NEXT_VERSION=16.3.8
DEPS='openapi-fetch@0.17.0 zod@4.6.5 @tanstack/react-query@5.104.1 zustand@5.0.15'
DEV_DEPS='@types/node@22 openapi-typescript@7.13.0 eslint-plugin-boundaries@7.2.0 eslint-import-resolver-typescript@4.4.5 vitest@5.0.3 @playwright/test@1.63.0'
LHCI_VERSION=0.15.1

WORK=$(mktemp -d)
if [ "${E2E_KEEP:-0}" = 1 ]; then trap 'echo "proyecto: $WORK/demo"' EXIT; else trap 'rm -rf "$WORK"' EXIT; fi
APP=$WORK/demo
FAIL=0
export NEXT_TELEMETRY_DISABLED=1

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

step "proyecto nuevo (create-next-app@$NEXT_VERSION)"
# shellcheck disable=SC2086  # las listas de paquetes se parten a propósito
if ! quiet "$WORK/create.log" npx --yes "create-next-app@$NEXT_VERSION" "$APP" --ts --eslint --app --src-dir \
        --no-tailwind --no-react-compiler --import-alias '@/*' --use-npm --yes --disable-git --skip-install \
   || ! rm -f "$APP/AGENTS.md" "$APP/CLAUDE.md" "$APP/eslint.config.mjs" \
   || ! (cd "$APP" && npm pkg set engines.node=22.x \
        && quiet "$WORK/deps.log" npm install --save-exact --no-audit --no-fund $DEPS \
        && quiet "$WORK/dev-deps.log" npm install --save-dev --save-exact --no-audit --no-fund $DEV_DEPS); then
    fail 'no pude crear el proyecto'
    exit 1
fi
ok "Next $NEXT_VERSION con los paquetes del stack"

step 'install.sh --stack nextjs'
quiet "$WORK/install.log" sh "$ROOT/install.sh" --stack nextjs --target "$APP" || { fail 'install.sh no termina en 0'; exit 1; }
cp -R "$ROOT/tests/fixtures/nextjs-e2e/." "$APP/"
(
    cd "$APP" || exit 1
    fill_stack .ai/RULES.md .ai/project/DECISIONS.md package.json
    find . -path ./node_modules -prune -o -type f -name '*.md' -exec grep -lF '{{RELLENAR' {} + \
        | while read -r f; do fill_markers "$f" backend; done
    quiet "$WORK/contract.log" sh bin/contract.sh
) || { fail 'no pude preparar la instalación'; exit 1; }
if ! quiet "$WORK/git.log" git init -q -b main "$APP" || ! g add -A \
   || ! quiet "$WORK/commit.log" g commit -q -m 'chore: demo project'; then
    fail 'no pude versionar el proyecto'
    exit 1
fi
ok 'stack instalado, capa del proyecto rellena y cliente generado del OpenAPI de ejemplo'

step 'bin/verify.sh completo'
if (cd "$APP" && sh bin/verify.sh > "$WORK/verify.log" 2>&1); then
    grep -E '^▸|✓$|✗$' "$WORK/verify.log" | paste - - | sed 's/^/  /'
    ok 'verify.sh en verde, con next build'
else
    sed 's/^/      /' "$WORK/verify.log"
    fail 'verify.sh no está en verde sobre un proyecto nuevo'
fi

if [ "${E2E_LIGHTHOUSE:-0}" = 1 ]; then
    step "Lighthouse CI (@lhci/cli@$LHCI_VERSION)"
    if (cd "$APP" && quiet "$WORK/lhci.log" npx --yes "@lhci/cli@$LHCI_VERSION" autorun --config=.ai/project/lighthouse.json); then
        ok 'los presupuestos de .ai/project/lighthouse.json se cumplen'
    else
        fail 'Lighthouse CI no pasa con los presupuestos de la semilla'
    fi
fi

step 'fallos provocados'
# Una feature que importa de otra: la regla de capas.
mkdir -p "$APP/src/features/other"
printf 'import { getDemo } from "@/features/demos";\n\nexport const other = getDemo;\n' > "$APP/src/features/other/index.ts"
if (cd "$APP" && npx eslint src/features > "$WORK/layers.log" 2>&1); then
    fail 'capas: ESLint acepta que una feature importe de otra'
elif grep -q 'boundaries/dependencies' "$WORK/layers.log"; then
    ok 'capas: una feature que importa de otra hace fallar ESLint (boundaries/dependencies)'
else
    sed 's/^/      /' "$WORK/layers.log"
    fail 'capas: ESLint falla, pero no por la regla de capas'
fi
rm -rf "$APP/src/features/other"

# Una ruta nueva en el OpenAPI, sin regenerar el cliente: el gate «contrato».
edit "$APP/docs/contract/openapi.json" 's#"/demos/{id}": {#"/demos": { "get": { "responses": { "204": { "description": "Empty" } } } },\n    "/demos/{id}": {#'
(cd "$APP" && sh bin/verify.sh --fast > "$WORK/contract-gate.log" 2>&1)
if awk '/^▸ contrato/ { c = 1; next } c && /^▸/ { exit } c && /✗$/ { f = 1 } END { exit !f }' "$WORK/contract-gate.log"; then
    ok 'contrato: un cambio en el OpenAPI sin regenerar el cliente hace fallar el gate «contrato»'
else
    sed 's/^/      /' "$WORK/contract-gate.log"
    fail 'contrato: el gate «contrato» no detecta el OpenAPI cambiado'
fi
g checkout -q -- docs/contract/openapi.json

printf '\n'
if [ "$FAIL" -eq 0 ]; then echo '✓ tests/e2e-nextjs.sh: todo en verde'; else echo '✗ tests/e2e-nextjs.sh: hay fallos'; fi
exit "$FAIL"
