#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# doctor.sh — qué le falta a un VPS para ejecutar fases (docs/modos.md §VPS).
#
# ◆ QUÉ MIRA
#   Se ejecuta como el usuario de los agentes, en el VPS:
#   - los comandos: git, gh, claude, tmux, gitleaks, php (8.4 o más, con
#     pdo_pgsql), composer, node (22 o más), npm y psql;
#   - las sesiones: `gh auth status`, y `claude auth status` con la cuenta de
#     claude.ai (Remote Control no acepta API keys);
#   - la base de datos de los tests: que PostGIS esté disponible en ella y que
#     su rol no sea superusuario (si lo es, también llega a la de staging).
#     Se conecta con DB_HOST, DB_PORT, DB_DATABASE, DB_USERNAME y DB_PASSWORD
#     del entorno o, si no están, con los de .env.testing del stack Laravel;
#   - con --env <ruta>, que este usuario NO pueda leer ese .env (el de
#     staging).
#
# ◆ USO
#   sh doctor.sh
#   sh doctor.sh --env /srv/staging/mi-proyecto/.env
#
# ◆ CONTRATO
#   Sale 0 si no falta nada, 1 si falta algo y 2 si se usa mal. Sólo lee.
#   POSIX sh, como el resto de scripts del kit.
# ─────────────────────────────────────────────────────────────────────────────
set -u
export LC_ALL=C

ENV_FILE=''
case "${1:-}" in
    '') ;;
    --env) [ $# -eq 2 ] || { echo 'uso: sh doctor.sh [--env <ruta del .env de staging>]' >&2; exit 2; }; ENV_FILE=$2 ;;
    *) echo 'uso: sh doctor.sh [--env <ruta del .env de staging>]' >&2; exit 2 ;;
esac

FAIL=0
ok()   { printf '  ✓ %s\n' "$1"; }
bad()  { printf '  ✗ %s\n' "$1"; FAIL=1; }
warn() { printf '  ⚠ %s\n' "$1"; }
has()  { command -v "$1" > /dev/null 2>&1; }

# major_minor <versión>: «8.4.1» o «v22.3.0» → 804 o 2203, para comparar.
major_minor() { printf '%s\n' "$1" | sed -n 's/^v\{0,1\}\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2/p' | { read -r a b && echo $((a * 100 + b)); }; }

printf '◆ comandos (como %s)\n' "$(id -un)"
for c in git gh claude tmux gitleaks composer npm psql; do
    if has "$c"; then ok "$c"; else bad "$c: falta (docs/modos.md §Preparación)"; fi
done

if has php; then
    v=$(php -r 'echo PHP_VERSION;' 2>/dev/null)
    if [ "$(major_minor "$v")" -ge 804 ] 2>/dev/null; then ok "php $v"; else bad "php ${v:-?}: hace falta 8.4 o más"; fi
    if php -m 2>/dev/null | grep -qx pdo_pgsql; then ok 'php: pdo_pgsql'; else bad 'php: falta la extensión pdo_pgsql'; fi
else
    bad 'php: falta (docs/modos.md §Preparación)'
fi

if has node; then
    v=$(node --version 2>/dev/null)
    if [ "$(major_minor "$v")" -ge 2200 ] 2>/dev/null; then ok "node $v"; else bad "node ${v:-?}: hace falta 22 o más"; fi
else
    bad 'node: falta (docs/modos.md §Preparación)'
fi

printf '◆ sesiones\n'
if has gh; then
    if gh auth status > /dev/null 2>&1; then ok 'gh: con sesión'; else bad 'gh: sin sesión (gh auth login)'; fi
fi
if has claude; then
    if ! out=$(claude auth status 2>/dev/null); then
        bad 'claude: sin sesión (claude auth login, con la cuenta de claude.ai)'
    elif printf '%s\n' "$out" | grep -qE '"authMethod": *"claude\.ai"'; then
        ok 'claude: con la cuenta de claude.ai'
    else
        bad 'claude: no usa la cuenta de claude.ai, y Remote Control no acepta API keys (quita ANTHROPIC_API_KEY y claude auth login)'
    fi
fi

printf '◆ base de datos de los tests\n'
if has psql; then
    db="${DB_USERNAME:-postgres}@${DB_HOST:-127.0.0.1}:${DB_PORT:-5432}/${DB_DATABASE:-testing}"
    row=$(PGPASSWORD=${DB_PASSWORD:-postgres} PGCONNECT_TIMEOUT=5 psql -h "${DB_HOST:-127.0.0.1}" -p "${DB_PORT:-5432}" \
        -U "${DB_USERNAME:-postgres}" -d "${DB_DATABASE:-testing}" -tAc \
        "select (select count(*) from pg_available_extensions where name = 'postgis'), rolsuper from pg_roles where rolname = current_user" 2>/dev/null)
    case "$row" in
        1\|*) ok "$db: PostGIS disponible" ;;
        0\|*) bad "$db: PostgreSQL sin PostGIS" ;;
        *)    bad "$db: no me conecto" ;;
    esac
    case "$row" in *\|t) warn "$db: el rol es superusuario y también llega a la base de staging (docs/modos.md §Aislamiento con staging)" ;; esac
else
    bad 'sin psql no puedo comprobarla'
fi

if [ -n "$ENV_FILE" ]; then
    printf '◆ staging\n'
    if [ -r "$ENV_FILE" ]; then bad "$(id -un) puede leer $ENV_FILE: tiene que ser del usuario de staging, con permisos 600"
    elif [ -e "$ENV_FILE" ]; then ok "$(id -un) no puede leer $ENV_FILE"
    else warn "$(id -un) no ve $ENV_FILE: o no existe (comprueba la ruta) o no llega a su carpeta, que también vale"; fi
fi

printf '\n'
if [ "$FAIL" -eq 0 ]; then echo '✓ doctor: no falta nada'; else echo '✗ doctor: falta lo que lleva ✗'; fi
exit "$FAIL"
