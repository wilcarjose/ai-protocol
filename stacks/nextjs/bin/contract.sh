#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# contract.sh — los tipos del cliente HTTP, generados del contrato.
#
# ◆ CÓMO SE EJECUTA
#   sh bin/contract.sh            regenera los tipos desde la copia del OpenAPI
#   sh bin/contract.sh --check    falla si los tipos no son los que salen de
#                                 ella (el gate «contrato» de bin/verify.sh)
#
# ◆ QUÉ HACE
#   openapi-typescript lee la copia del OpenAPI del backend (CONTRACT_SPEC) y
#   escribe los tipos que usa el cliente de src/shared/api/ (CONTRACT_TYPES).
#   Los dos archivos se versionan, y los tipos nunca se editan a mano: cuando
#   cambia la copia, se regeneran en el mismo commit
#   (.ai/rules/contrato.md §Cómo se conoce el contrato).
#
# ◆ EL PROYECTO
#   Las rutas salen de .ai/project/verify.conf; sin ellas, las de abajo.
#   Este script es del kit: una fase no lo cambia.
#
# ◆ CONTRATO
#   Sale 0 si genera, o si con --check los tipos están al día; != 0 si falta
#   la copia, los tipos están desactualizados o openapi-typescript falla.
# ─────────────────────────────────────────────────────────────────────────────
cd "$(dirname "$0")/.." || exit 1

if [ -f .ai/project/verify.conf ]; then
    # shellcheck source=/dev/null  # es del proyecto
    . ./.ai/project/verify.conf
fi
SPEC=${CONTRACT_SPEC:-docs/contract/openapi.json}
TYPES=${CONTRACT_TYPES:-src/shared/api/schema.d.ts}

[ -f "$SPEC" ] || { echo "falta $SPEC: la copia del OpenAPI del backend (.ai/rules/contrato.md §Cómo se conoce el contrato)"; exit 1; }

if [ "${1:-}" != "--check" ]; then
    npx openapi-typescript "$SPEC" --output "$TYPES" || exit 1
    echo "contrato: $TYPES regenerado desde $SPEC"
    exit 0
fi

[ -f "$TYPES" ] || { echo "falta $TYPES: genéralo con «sh bin/contract.sh» y versiónalo"; exit 1; }
TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT
npx openapi-typescript "$SPEC" --output "$TMPD/schema.d.ts" > "$TMPD/gen.log" 2>&1 || { cat "$TMPD/gen.log"; exit 1; }
if ! cmp -s "$TMPD/schema.d.ts" "$TYPES"; then
    diff -u "$TYPES" "$TMPD/schema.d.ts" | head -n 30
    echo "$TYPES no es lo que sale de $SPEC: regenéralo con «sh bin/contract.sh» en el mismo commit que la copia"
    exit 1
fi
echo "contrato: $TYPES al día con $SPEC"
