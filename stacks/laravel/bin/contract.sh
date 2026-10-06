#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# contract.sh — el OpenAPI de la API, generado desde el código.
#
# ◆ CÓMO SE EJECUTA
#   sh bin/contract.sh            regenera el baseline desde el código
#   sh bin/contract.sh --check    falla si el código ya no genera el baseline
#                                 (el gate «contrato» de bin/verify.sh)
#
# ◆ QUÉ HACE
#   dedoc/scramble lee las rutas, los FormRequest y lo que devuelven los
#   controladores, y escribe el OpenAPI (`php artisan scramble:export`). El
#   baseline (CONTRACT_SPEC) se versiona, nunca se edita a mano y sólo se
#   regenera con un cambio de contrato autorizado (.ai/RULES.md §Contrato HTTP).
#   Es el archivo que el frontend copia.
#
# ◆ EL PROYECTO
#   La ruta sale de .ai/project/verify.conf; sin ella, la de abajo. El título
#   y el servidor del documento salen de APP_NAME y APP_URL, así que se genera
#   siempre con CONTRACT_APP_NAME y CONTRACT_APP_URL, para que no cambie con el
#   .env de cada máquina.
#   Este script es del kit: una fase no lo cambia.
#
# ◆ CONTRATO
#   Sale 0 si genera, o si con --check el baseline está al día; != 0 si falta
#   el baseline, está desactualizado o scramble falla.
# ─────────────────────────────────────────────────────────────────────────────
cd "$(dirname "$0")/.." || exit 1

if [ -f .ai/project/verify.conf ]; then
    # shellcheck source=/dev/null  # es del proyecto
    . ./.ai/project/verify.conf
fi
SPEC=${CONTRACT_SPEC:-docs/contract/openapi.json}
APP_NAME=${CONTRACT_APP_NAME:-API}
APP_URL=${CONTRACT_APP_URL:-http://localhost}
export APP_NAME APP_URL

if [ "${1:-}" != "--check" ]; then
    mkdir -p "$(dirname "$SPEC")"
    php artisan scramble:export --path="$SPEC" > /dev/null || exit 1
    echo "contrato: $SPEC regenerado desde el código"
    exit 0
fi

[ -f "$SPEC" ] || { echo "falta $SPEC; genéralo con «sh bin/contract.sh» y versiónalo"; exit 1; }
TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT
php artisan scramble:export --path="$TMPD/openapi.json" > "$TMPD/gen.log" 2>&1 || { cat "$TMPD/gen.log"; exit 1; }
if ! cmp -s "$TMPD/openapi.json" "$SPEC"; then
    diff -u "$SPEC" "$TMPD/openapi.json" | head -n 30
    echo "el contrato cambió: el código ya no genera $SPEC. Si es un cambio de contrato autorizado, regenéralo con «sh bin/contract.sh» en la misma fase; si no, deshaz el cambio"
    exit 1
fi
echo "contrato: $SPEC al día con el código"
