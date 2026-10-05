#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# check-docs.sh — el guardián de los documentos del protocolo.
#
# ◆ QUÉ COMPRUEBA
#   0. instalación — no queda ningún «{{RELLENAR» en los documentos normativos
#                    ni en la capa del proyecto (.ai/project/).
#   1. puntero     — la cabecera de .ai/STATE.md apunta a la primera fila sin
#                    HECHA del mapa (CLAUDE.md §Estado de una fase); sus seis
#                    claves aparecen una vez y sin notas detrás; sólo la fase
#                    activa está EN_CURSO; las filas de cada épica, en orden.
#   2. fases       — cada phase-*.md: estado válido e igual al del mapa;
#                    «Contrato HTTP» válido; los campos de cabecera propios del
#                    stack que pida la plantilla; «Plan de commits» con filas;
#                    «Depende de» sólo cita fases anteriores; RESULTADO vacío si
#                    no empezó, relleno si se cerró y con los encabezados de la
#                    plantilla; una HECHA, con todas las casillas de «Criterios
#                    de éxito» marcadas. Las secciones se buscan por su nombre,
#                    con o sin número delante («## 5. Criterios de éxito»).
#   3. épicas      — cada epic-plan: estado válido y coherente con el mapa
#                    (CERRADA = todas HECHA y criterio de cierre marcado); su
#                    tabla «Fases», en orden y con las mismas fases que el
#                    mapa; los ids D<n> que cita existen en DOMAIN.md; «Épica
#                    activa» no es una CERRADA si queda otra abierta.
#   4. referencias — «fase NN/FF», la columna «Bloquea» de DOMAIN.md, la
#                    columna «Fase» del manifiesto y «fase FF» dentro de una
#                    épica existen en la tabla de su epic-plan.
#   5. despliegue  — toda fase HECHA que declara migraciones tiene su fila en
#                    docs/runbooks/release.md (sólo si la plantilla las pide).
#   6. traspaso    — toda fase HECHA con «Contrato HTTP: CAMBIO AUTORIZADO»
#                    tiene una fila de BACKLOG.md para un repo hermano que la
#                    cita, o «> **Traspaso:** ninguno — <motivo>».
#   7. contadores  — la cabecera de STATE.md, §Bloqueo activo y §Pendientes en
#                    otros repos cuadran con DOMAIN.md y BACKLOG.md
#                    (CLAUDE.md §Sincronización post-lectura).
#   8. destinos    — todo «Destino» de BACKLOG.md nombra una épica que existe.
#   9. stack       — cada paquete de .ai/RULES.md §Stack tiene su versión en
#                    .ai/project/DECISIONS.md §Stack, y cada versión de esa
#                    tabla coincide con composer.json / package.json.
#  10. cross-repo  — ningún archivo cita documentos de un repo hermano.
#  11. rutas       — las rutas citadas en los documentos normativos existen.
#  12. secciones   — toda referencia «archivo.md §Sección» cita la sección por
#                    su nombre, no por su número, y el nombre es el de una
#                    sección que existe (un número no sobrevive a renumerar).
#
#   11 y 12 son heurísticos (sacan rutas y secciones de la prosa): avisan, y
#   sólo bloquean con --strict. El resto son comparaciones exactas y bloquean
#   siempre. bin/verify.sh lo ejecuta con --strict.
#
# ◆ CÓMO PROVOCAR CADA FALLO
#   Para probar un cambio en este script: tiene que fallar con el defecto y
#   pasar sin él. Restaura después con `git checkout -- <archivo>`.
#    0. escribe «{{RELLENAR: x}}» en .ai/DOMAIN.md.
#    1. en STATE.md, apunta «Fase activa» a una fase HECHA.
#    2. cambia la cabecera de una fase HECHA a EN_CURSO sin tocar el mapa.
#    3. en un epic-plan CERRADA, desmarca una casilla del criterio de cierre.
#    4. escribe «fase 01/99» en .ai/BACKLOG.md.
#    5. pon «Migraciones: autorizadas (users)» en una fase HECHA sin fila en
#       el manifiesto.
#    6. pon «Contrato HTTP: CAMBIO AUTORIZADO» en una fase HECHA, sin fila de
#       BACKLOG ni «Traspaso:».
#    7. sube en uno «Decisiones abiertas» sin tocar DOMAIN.md.
#    8. pon «99» en la columna Destino de una fila de BACKLOG.md.
#    9. cambia una versión de la tabla de .ai/project/DECISIONS.md §Stack.
#   10. escribe «<repo hermano>/docs/x.md» en cualquier .md.
#   11. cita `bin/no-existe.sh` en CLAUDE.md.
#   12. cita `.ai/RULES.md §No existe` en CLAUDE.md, o cita una que existe
#       por su número: `.ai/WORKFLOW.md §3`.
#
# ◆ PORTABILIDAD
#   POSIX sh y awk/sed/grep sin extensiones GNU: corre igual en el host que en
#   un contenedor Alpine (busybox). Sin «\b» en las regex, que musl no
#   garantiza. LC_ALL=C: los acentos se tratan como bytes y no dependen del
#   locale de quien lo ejecuta.
#
# ◆ CÓMO SE EXTIENDE
#   Un chequeo nuevo sólo entra si nace de un fallo que ya ocurrió (anotado en
#   .ai/PROTOCOL.md). Va como un bloque más con su propio «◆», y se documenta
#   arriba: qué comprueba y cómo provocarlo.
#
# ◆ USO
#   sh bin/check-docs.sh             # desde cualquier directorio del repo
#   sh bin/check-docs.sh --strict    # los avisos también fallan
#
# ◆ CONTRATO
#   Sale 0 si todo está en verde y != 0 si algo falla. Sólo lee el repo.
# ─────────────────────────────────────────────────────────────────────────────
set -u
export LC_ALL=C

ROOT=$(cd "$(dirname "$0")/.." && pwd)
AI="$ROOT/.ai"
CLAUDE_MD="$ROOT/CLAUDE.md"
RULES="$AI/RULES.md"
STATE="$AI/STATE.md"
DOMAIN="$AI/DOMAIN.md"
PROJECT="$AI/project"
DECISIONS="$PROJECT/DECISIONS.md"
BACKLOG="$AI/BACKLOG.md"
TPL_PHASE="$AI/templates/phase.template.md"
MANIFEST="$ROOT/docs/runbooks/release.md"
TAB=$(printf '\t')

STRICT=0
[ "${1:-}" = "--strict" ] && STRICT=1

for f in "$CLAUDE_MD" "$RULES" "$AI/WORKFLOW.md" "$AI/PLANNING.md" "$STATE" "$DOMAIN" "$BACKLOG" "$TPL_PHASE" \
         "$PROJECT/README.md" "$DECISIONS"; do
    [ -f "$f" ] || { printf '✗ check-docs: falta %s\n' "${f#"$ROOT"/}"; exit 1; }
done

TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT
PROBLEMS="$TMPD/problems"
: > "$PROBLEMS"

FAIL=0
WARN=0

# ── Helpers ─────────────────────────────────────────────────────────────────
ok()   { printf '  ✓ %s\n' "$1"; }
# Anota un problema del chequeo en curso (vale también desde un subshell).
bad()  { printf '%s\n' "$1" >> "$PROBLEMS"; }
# report <fail|warn> <mensaje si todo bien> <mensaje si hay problemas>
report() {
    if [ -s "$PROBLEMS" ]; then
        if [ "$1" = fail ]; then printf '  ✗ %s\n' "$3"; FAIL=$((FAIL + 1))
        else printf '  ⚠ %s\n' "$3"; WARN=$((WARN + 1)); fi
        sort -u "$PROBLEMS" | sed 's/^/      /'
    else
        ok "$2"
    fi
    : > "$PROBLEMS"
}
rel() { printf '%s' "${1#"$ROOT"/}"; }
# Las líneas no vacías de $1 en una sola, separadas por espacios y cada una con el prefijo $2.
inline() { printf '%s\n' "$1" | awk -v p="${2:-}" 'NF { printf "%s%s ", p, $0 }'; }

# Líneas de la sección «## <título>» de un archivo, hasta la siguiente «## ».
section() { awk -v t="## $2" 'index($0, t) == 1 { f = 1; next } f && /^## / { exit } f' "$1"; }

# Líneas de la sección de una fase que se llama <nombre>, con o sin número delante («## 5. <nombre>»), hasta la
# siguiente «## » o «---». Sale != 0 si la fase no la tiene. Por nombre: renumerar la plantilla no la pierde.
phase_section() {
    awk -v t="$2" '
        /^## / { if (f) exit; h = substr($0, 4); sub(/^[0-9]+[a-z]?\. */, "", h); sub(/ +$/, "", h)
                 if (h == t) { f = 1; next } }
        f && /^---/ { exit }
        f
        END { exit f ? 0 : 1 }' "$1"
}

# Valor de una clave de la cabecera de STATE.md («- **Clave:** valor»).
state_field() { sed -n "s/^- \*\*$1:\*\* *//p" "$STATE" | head -n 1; }

# Estado de la cabecera de un archivo de fase.
phase_state() { sed -n 's/^> \*\*Estado:\*\* *\([A-Z_]*\).*/\1/p' "$1" | head -n 1; }

# Quita los comentarios HTML (de una línea o de varias): son guía, no contenido.
strip_comments() {
    awk '
        { line = $0 }
        c { e = index(line, "-->"); if (e == 0) next; line = substr(line, e + 3); c = 0 }
        {
            while ((s = index(line, "<!--")) > 0) {
                rest = substr(line, s + 4); e = index(rest, "-->")
                if (e > 0) { line = substr(line, 1, s - 1) substr(rest, e + 3) }
                else       { line = substr(line, 1, s - 1); c = 1; break }
            }
            print line
        }
    ' "$1"
}

# Fases de la tabla «## Fases» de un epic-plan, en su orden.
epic_table() {
    section "$1" 'Fases' | awk -F'|' '/^\|/ { p = $2; gsub(/[ \t`]/, "", p); if (p ~ /^[0-9][0-9][a-z]?$/) print p }'
}

# has_phase <NN> <FF>: 0 si la épica NN tiene la fase FF en su tabla «Fases».
has_phase() {
    for plan in "$AI"/epics/"$1"-*/epic-plan.md; do
        [ -f "$plan" ] || continue
        epic_table "$plan" | grep -qx "$2" && return 0
    done
    return 1
}

# ── Datos compartidos ───────────────────────────────────────────────────────
# El mapa: «épica fase estado», una fila por fase, en el orden de STATE.md.
MAP="$TMPD/map"
section "$STATE" 'Mapa de fases' | awk -F'|' '/^\|/ {
    e = $2; p = $3; s = $4
    gsub(/[ \t`]/, "", e); gsub(/[ \t`]/, "", p); gsub(/[ \t`]/, "", s)
    if (p ~ /^[0-9][0-9][a-z]?$/) print e, p, s
}' > "$MAP"

ACT_EPIC=$(state_field 'Épica activa')
ACT_PH=$(state_field 'Fase activa')
ACT_FILE=$(state_field 'Archivo de la fase' | tr -d '`')
NN_ACT=''
[ "$ACT_EPIC" = '—' ] || NN_ACT=${ACT_EPIC%%-*}

# Repos hermanos: los nombres entre comillas invertidas de «> **Repos hermanos:**» de .ai/project/README.md.
REPOS=$(sed -n 's/^> \*\*Repos hermanos:\*\* *//p' "$PROJECT/README.md" | head -n 1)
case "$REPOS" in *'{{'*) REPOS='' ;; esac
# shellcheck disable=SC2016  # las comillas invertidas son literales
REPOS=$(printf '%s\n' "$REPOS" | grep -oE '`[^`]+`' | tr -d '`' | tr '\n' ' ')

TPL_HAS_MIG=0
grep -q '^> \*\*Migraciones:\*\*' "$TPL_PHASE" && TPL_HAS_MIG=1

# ── 0. Instalación ──────────────────────────────────────────────────────────
printf '◆ instalación (no queda ningún {{RELLENAR}} en los documentos normativos ni en .ai/project/)\n'

for f in "$CLAUDE_MD" "$ROOT/AGENTS.md" "$AI"/*.md "$PROJECT"/*.md "$ROOT"/.claude/commands/*.md "$ROOT/docs/README.md"; do
    [ -f "$f" ] || continue
    n=$(grep -c '{{RELLENAR' "$f")
    [ "$n" -eq 0 ] || bad "$(rel "$f"): $n marcador(es) {{RELLENAR}} sin completar; cada uno dice qué va"
done
report fail 'no queda nada por rellenar' 'la instalación del protocolo no está terminada:'

# ── 1. Puntero de STATE.md ──────────────────────────────────────────────────
printf '◆ puntero de STATE.md (la fase activa es la primera fila sin HECHA del mapa)\n'

for key in 'Épica activa' 'Fase activa' 'Archivo de la fase' 'Decisiones abiertas' 'Pendientes en otros repos' 'Última actualización'; do
    n=$(grep -c "^- \*\*$key:\*\*" "$STATE")
    [ "$n" -eq 1 ] || bad "STATE.md: la clave «$key» aparece $n veces en la cabecera; tiene que aparecer una"
done
grep -qE '^- \*\*(Épica activa|Fase activa):\*\* *[^ ]+ +[^ ]' "$STATE" \
    && bad 'STATE.md: «Épica activa» o «Fase activa» lleva texto detrás del valor; las notas van en §Bloqueo activo'
# shellcheck disable=SC2016  # las comillas invertidas son literales
grep -qE '^- \*\*Archivo de la fase:\*\* *(`[^`]+`|—) *$' "$STATE" \
    || bad 'STATE.md: «Archivo de la fase» lleva algo más que la ruta entre comillas invertidas (o «—»)'

awk '$3 !~ /^(SIN_PLANIFICAR|LISTA_PARA_EJECUTAR|EN_CURSO|BLOQUEADA|VERIFICACION_ROJA|HECHA)$/ { print $1 "/" $2 " " $3 }' "$MAP" \
    | while read -r r s; do bad "STATE.md §Mapa de fases: $r tiene un estado que no existe («$s»)"; done

while read -r e p s; do
    [ "$s" = SIN_PLANIFICAR ] || [ -f "$AI/epics/$e/phase-$p.md" ] \
        || bad "STATE.md §Mapa de fases: $e/$p está $s, pero no existe .ai/epics/$e/phase-$p.md"
done < "$MAP"

NEXT=$(awk '$3 != "HECHA" { print; exit }' "$MAP")
if [ -z "$NEXT" ]; then
    want_e='—'; want_p='—'; want_f='—'
else
    # shellcheck disable=SC2086  # separar «épica fase estado» es lo que se quiere
    set -- $NEXT
    want_e=$1
    if [ "$3" = SIN_PLANIFICAR ]; then want_p='—'; want_f='—'
    else want_p=$2; want_f=".ai/epics/$1/phase-$2.md"; fi
fi
{ [ "$ACT_EPIC" = "$want_e" ] && [ "$ACT_PH" = "$want_p" ] && [ "$ACT_FILE" = "$want_f" ]; } \
    || bad "STATE.md: la cabecera apunta a «$ACT_EPIC · $ACT_PH · $ACT_FILE»; según el mapa debe ser «$want_e · $want_p · $want_f» (CLAUDE.md §Estado de una fase)"

awk '$3 == "EN_CURSO" { print $1 "/" $2 }' "$MAP" | while read -r r; do
    [ "$r" = "$ACT_EPIC/$ACT_PH" ] || bad "STATE.md: $r está EN_CURSO, pero la fase activa es $ACT_EPIC/$ACT_PH; sólo una sesión ejecuta"
done

awk '!seen[$1]++ { print $1 }' "$MAP" | while read -r e; do
    seq=$(awk -v e="$e" '$1 == e { print $2 }' "$MAP")
    [ "$seq" = "$(printf '%s\n' "$seq" | sort)" ] \
        || bad "STATE.md §Mapa de fases: las filas de $e no están en orden de ejecución ($(inline "$seq"))"
done
report fail 'el puntero coincide con el mapa' 'el puntero de STATE.md no es fiable:'

# ── 2. Fases ────────────────────────────────────────────────────────────────
printf '◆ fases (estado igual al del mapa, cabecera, «Plan de commits», «Depende de», RESULTADO)\n'

TPL_HEADS="$TMPD/tpl-heads"
awk '/^## RESULTADO DE LA EJECUCI/ { f = 1; next } f && /^### / { print }' "$TPL_PHASE" > "$TPL_HEADS"

for f in "$AI"/epics/*/phase-*.md; do
    [ -f "$f" ] || continue
    r=$(rel "$f")
    e=$(basename "$(dirname "$f")")
    p=$(basename "$f" .md); p=${p#phase-}
    fs=$(phase_state "$f")
    case "$fs" in
        SIN_PLANIFICAR|LISTA_PARA_EJECUTAR|EN_CURSO|BLOQUEADA|VERIFICACION_ROJA|HECHA) ;;
        *) bad "$r: la cabecera no tiene un «> **Estado:**» válido"; continue ;;
    esac
    grep -qE '^> \*\*Estado:\*\* *[A-Z_]+ *$' "$f" || bad "$r: «Estado:» lleva algo más que el estado"

    ms=$(awk -v e="$e" -v p="$p" '$1 == e && $2 == p { print $3; exit }' "$MAP")
    if [ -z "$ms" ]; then
        bad "$r: no tiene fila «| $e | $p |» en STATE.md §Mapa de fases"
    elif [ "$fs" != "$ms" ]; then
        bad "$r: dice $fs y el mapa dice $ms; se escriben a la vez (CLAUDE.md §Estado de una fase)"
    fi

    grep -qE '^> \*\*Contrato HTTP:\*\* *(\*\*)?(SIN CAMBIOS|CAMBIO AUTORIZADO)' "$f" \
        || bad "$r: la cabecera no tiene «Contrato HTTP:» (SIN CAMBIOS | CAMBIO AUTORIZADO …)"
    if [ "$TPL_HAS_MIG" -eq 1 ]; then
        grep -q '^> \*\*Migraciones:\*\* ' "$f" || bad "$r: la cabecera no tiene «Migraciones:» (la plantilla lo pide)"
    fi

    for sec in 'Criterios de éxito' 'Plan de commits'; do
        phase_section "$f" "$sec" > /dev/null || bad "$r: no tiene la sección «$sec» (la de la plantilla)"
    done
    phase_section "$f" 'Plan de commits' | grep -qE '^\| *[0-9]+[a-z]? *\|' || bad "$r: «Plan de commits» sin filas"

    # «Depende de» sólo cita fases anteriores de su épica; las de otra épica («NN/FF») no se comparan.
    for dep in $(sed -n 's/.*\*\*Depende de:\*\* *//p' "$f" | head -n 1 \
                 | sed 's#[0-9][0-9]/[0-9][0-9][a-z]*##g' | grep -oE '[0-9][0-9][a-z]?'); do
        first=$(printf '%s\n%s\n' "$dep" "$p" | sort | head -n 1)
        { [ "$dep" != "$p" ] && [ "$first" = "$dep" ]; } \
            || bad "$r: «Depende de» cita la fase $dep, que no es anterior a la $p"
    done

    body=$(strip_comments "$f")
    fecha=$(printf '%s\n' "$body" | sed -n 's/^\*\*Fecha:\*\* *//p' | head -n 1)
    case "$fs" in
        SIN_PLANIFICAR|LISTA_PARA_EJECUTAR)
            [ -z "$fecha" ] || bad "$r ($fs): el RESULTADO tiene «Fecha:»; una fase que no ha empezado lo deja vacío"
            txt=$(printf '%s\n' "$body" | awk '/^## RESULTADO DE LA EJECUCI/ { s = 1; next }
                s && /^### / { h = 1; next } s && h && NF > 0 { print; exit }')
            [ -z "$txt" ] || bad "$r ($fs): el RESULTADO tiene contenido («$txt»); una fase que no ha empezado lo deja vacío"
            ;;
        HECHA|BLOQUEADA|VERIFICACION_ROJA)
            printf '%s' "$fecha" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' \
                || bad "$r ($fs): el RESULTADO no tiene «Fecha:» (AAAA-MM-DD); el cierre la rellena siempre"
            for h in 'Qué se hizo' 'Lo que la siguiente fase necesita saber'; do
                txt=$(printf '%s\n' "$body" | awk -v h="### $h" 'index($0, h) == 1 { s = 1; next }
                    s && /^#/ { exit } s && NF > 0 { print; exit }')
                [ -n "$txt" ] || bad "$r ($fs): «$h» está vacío"
            done
            ;;
    esac

    if [ "$fs" = HECHA ]; then
        n=$(phase_section "$f" 'Criterios de éxito' | grep -c '^- \[ \]')
        [ "$n" -eq 0 ] || bad "$r (HECHA): $n casilla(s) de «Criterios de éxito» sin marcar (.ai/WORKFLOW.md §Un criterio de éxito no se puede cumplir)"
    else
        # Una fase viva tiene los encabezados del RESULTADO de la plantilla vigente: si se escribió con una
        # plantilla vieja, salta en su Paso A y no al cerrarla. Las HECHA son historia.
        while IFS= read -r h; do
            [ -n "$h" ] || continue
            grep -qxF "$h" "$f" || bad "$r: el RESULTADO no tiene «$h» (encabezado de la plantilla)"
        done < "$TPL_HEADS"
    fi
done
report fail 'las fases están bien formadas y coinciden con el mapa' 'problemas en las fases:'

# ── 3. Épicas ───────────────────────────────────────────────────────────────
printf '◆ épicas (estado frente al mapa, tabla «Fases», ids de DOMAIN.md)\n'

DOM_IDS="$TMPD/dom-ids"
awk -F'|' '/^\| *D[0-9]+ *\|/ { i = $2; gsub(/[ \t]/, "", i); print i }' "$DOMAIN" | sort -u > "$DOM_IDS"

epic_state() { sed -n 's/.*\*\*Estado:\*\* *\([A-Z_]*\).*/\1/p' "$1" | head -n 1; }

OPEN=0
for d in "$AI"/epics/*/; do
    [ -d "$d" ] || continue
    e=$(basename "$d")
    plan="$AI/epics/$e/epic-plan.md"
    r=".ai/epics/$e/epic-plan.md"
    case "$e" in [0-9][0-9]-*) ;; *) bad ".ai/epics/$e: el nombre de la carpeta no es «NN-slug»"; continue ;; esac
    [ -f "$plan" ] || { bad "$r: no existe; cada épica tiene su epic-plan"; continue; }

    est=$(epic_state "$plan")
    grep -F '**Estado:**' "$plan" | head -n 1 | grep -qE '\*\*Estado:\*\* *(SIN_EMPEZAR|EN_CURSO|CERRADA) *$' \
        || bad "$r: «Estado:» tiene que ser SIN_EMPEZAR, EN_CURSO o CERRADA, sin nada detrás"
    rows=$(awk -v e="$e" '$1 == e { print $3 }' "$MAP")
    started=$(printf '%s\n' "$rows" | grep -cvE '^(SIN_PLANIFICAR|LISTA_PARA_EJECUTAR)?$')
    unfinished=$(printf '%s\n' "$rows" | grep -cvE '^(HECHA)?$')
    [ "$est" = CERRADA ] || OPEN=$((OPEN + 1))
    case "$est" in
        SIN_EMPEZAR)
            [ "$started" -eq 0 ] || bad "$r: SIN_EMPEZAR, pero el mapa tiene fases suyas empezadas" ;;
        EN_CURSO)
            [ "$started" -gt 0 ] || bad "$r: EN_CURSO, pero ninguna fase suya ha empezado en el mapa" ;;
        CERRADA)
            { [ -n "$rows" ] && [ "$unfinished" -eq 0 ]; } || bad "$r: CERRADA, pero el mapa tiene fases suyas sin HECHA"
            n=$(section "$plan" 'Criterio de cierre' | grep -c '^- \[ \]')
            [ "$n" -eq 0 ] || bad "$r: CERRADA con $n casilla(s) del «Criterio de cierre» sin marcar (CLAUDE.md §Cierre de épica)" ;;
    esac

    seq=$(epic_table "$plan")
    [ "$seq" = "$(printf '%s\n' "$seq" | sort)" ] \
        || bad "$r: la tabla «Fases» no está en orden de ejecución ($(inline "$seq"))"
    mseq=$(awk -v e="$e" '$1 == e { print $2 }' "$MAP" | sort)
    [ "$(printf '%s\n' "$seq" | sort)" = "$mseq" ] \
        || bad "$r: la tabla «Fases» ($(inline "$seq")) y STATE.md §Mapa de fases ($(inline "$mseq")) no tienen las mismas fases"

    grep -oE '(^|[^A-Za-z0-9])D[0-9]+' "$plan" | sed 's/^[^D]*//' | sort -u | while read -r id; do
        grep -qx "$id" "$DOM_IDS" || bad "$r: cita $id, que no existe en DOMAIN.md §Decisiones pendientes"
    done
done
awk '{ print $1 }' "$MAP" | sort -u | while read -r e; do
    [ -d "$AI/epics/$e" ] || bad "STATE.md §Mapa de fases: la épica $e no tiene carpeta en .ai/epics/"
done
if [ -n "$NN_ACT" ] && [ -f "$AI/epics/$ACT_EPIC/epic-plan.md" ] && [ "$OPEN" -gt 0 ] \
   && [ "$(epic_state "$AI/epics/$ACT_EPIC/epic-plan.md")" = CERRADA ]; then
    bad "STATE.md: «Épica activa» es $ACT_EPIC, que está CERRADA, y quedan épicas abiertas"
fi
report fail 'el estado de cada épica cuadra con el mapa' 'problemas en las épicas:'

# ── 4. Referencias a fases ──────────────────────────────────────────────────
printf '◆ referencias a fases (existen en la tabla de su épica; las fases no se renumeran)\n'

check_ref() { has_phase "${2%%/*}" "${2#*/}" || bad "$(rel "$1"): cita la fase $2, que no está en la tabla «Fases» de la épica ${2%%/*}"; }

for f in "$DOMAIN" "$STATE" "$BACKLOG" "$MANIFEST" "$AI"/epics/*/*.md; do
    [ -f "$f" ] || continue
    grep -oE '[Ff]ases? [0-9][0-9]/[0-9][0-9][a-z]?' "$f" | sed 's/^[Ff]ases* //' | sort -u | while read -r x; do
        check_ref "$f" "$x"
    done
done
awk -F'|' '/^\| *D[0-9]+ *\|/ { print $(NF-4) }' "$DOMAIN" | grep -oE '[0-9][0-9]/[0-9][0-9][a-z]?' | sort -u | while read -r x; do
    check_ref "$DOMAIN" "$x"
done
if [ -f "$MANIFEST" ]; then
    awk -F'|' '/^\| *[0-9][0-9]\/[0-9][0-9][a-z]? *\|/ { x = $2; gsub(/[ \t]/, "", x); print x }' "$MANIFEST" | sort -u | while read -r x; do
        check_ref "$MANIFEST" "$x"
    done
fi
# «fase FF» dentro de los archivos de una épica es una fase de esa épica; «fase NN/FF» ya se miró arriba.
for d in "$AI"/epics/*/; do
    [ -d "$d" ] || continue
    e=$(basename "$d")
    for f in "$d"*.md; do
        [ -f "$f" ] || continue
        grep -oE '[Ff]ases? [0-9][0-9][a-z]?/?' "$f" | grep -v '/$' | sed 's/^[Ff]ases* //' | sort -u | while read -r x; do
            has_phase "${e%%-*}" "$x" || bad "$(rel "$f"): cita la fase $x, que no está en la tabla «Fases» de su épica"
        done
    done
done
report fail 'todas las referencias a fases existen' 'referencias a fases que no existen:'

# ── 5. Manifiesto de despliegue ─────────────────────────────────────────────
printf '◆ despliegue (toda fase HECHA con migraciones está en el manifiesto)\n'

if [ "$TPL_HAS_MIG" -eq 0 ]; then
    ok 'la plantilla de fase no declara migraciones: no aplica'
else
    MANIFESTS=$(ls "$MANIFEST" "$ROOT"/docs/archive/releases/*.md 2>/dev/null)
    for f in "$AI"/epics/*/phase-*.md; do
        [ -f "$f" ] || continue
        [ "$(phase_state "$f")" = HECHA ] || continue
        sed -n 's/^> \*\*Migraciones:\*\* *//p' "$f" | head -n 1 | grep -qi '^ninguna' && continue
        e=$(basename "$(dirname "$f")"); p=$(basename "$f" .md); p=${p#phase-}; x="${e%%-*}/$p"
        # shellcheck disable=SC2086  # varios manifiestos, separados por espacios
        { [ -n "$MANIFESTS" ] && cat $MANIFESTS | grep -qF "| $x |"; } \
            || bad "$(rel "$f"): declara migraciones y no tiene fila «| $x |» en docs/runbooks/release.md §Pasos por fase"
    done
    report fail 'toda fase con migraciones está en el manifiesto' 'fases con migraciones fuera del manifiesto:'
fi

# ── 6. Traspaso al repo hermano ─────────────────────────────────────────────
printf '◆ traspaso (una fase HECHA que cambió el contrato deja su fila para el repo hermano)\n'

if [ -z "$REPOS" ]; then
    ok '.ai/project/README.md no declara repos hermanos: no aplica'
else
    for f in "$AI"/epics/*/phase-*.md; do
        [ -f "$f" ] || continue
        [ "$(phase_state "$f")" = HECHA ] || continue
        sed -n 's/^> \*\*Contrato HTTP:\*\* *//p' "$f" | head -n 1 | grep -qE '^(\*\*)?CAMBIO AUTORIZADO' || continue
        grep -q '^> \*\*Traspaso:\*\* *ninguno' "$f" && continue
        e=$(basename "$(dirname "$f")"); p=$(basename "$f" .md); p=${p#phase-}; x="${e%%-*}/$p"
        found=0
        for repo in $REPOS; do
            awk -F'|' -v a="$repo" -v re="fase $x([^0-9a-z]|$)" '/^\| *[0-9]+ *\|/ {
                    r = $4; gsub(/[ \t`]/, "", r); if (r == a && match($0, re)) hit = 1 }
                END { exit hit ? 0 : 1 }' "$BACKLOG" && found=1
        done
        [ "$found" -eq 1 ] || bad "$(rel "$f"): cambia el contrato y nada lo traspasa: ni una fila de BACKLOG.md con Área $REPOS que diga «fase $x», ni «> **Traspaso:** ninguno — <motivo>» (CLAUDE.md §El otro repositorio)"
    done
    report fail 'toda fase que cambió el contrato tiene su traspaso' 'cambios de contrato sin traspaso:'
fi

# ── 7. Contadores y secciones derivadas de STATE.md ─────────────────────────
printf '◆ contadores (cabecera, §Bloqueo activo y §Pendientes en otros repos de STATE.md)\n'

# Decisiones pendientes como «id bloquea(0|1)». Columnas contadas desde el final, porque el texto de la
# decisión puede llevar «|»: … | Bloquea | Propuesto por | Estado | Respuesta |
awk -F'|' -v nn="$NN_ACT" '/^\| *D[0-9]+ *\|/ {
    id = $2; gsub(/[ \t]/, "", id)
    st = $(NF - 2); gsub(/[ \t]/, "", st)
    if (st != "pendiente") next
    blk = 0
    if (nn != "") {
        n = split($(NF - 4), t, "[^0-9a-z/]+")
        for (i = 1; i <= n; i++) if (t[i] == nn || index(t[i], nn "/") == 1) blk = 1
    }
    print id, blk
}' "$DOMAIN" > "$TMPD/dpend"
d_n=$(grep -c . "$TMPD/dpend")
d_m=$(awk '$2 == 1' "$TMPD/dpend" | grep -c .)

hdr=$(state_field 'Decisiones abiertas')
h_n=$(printf '%s' "$hdr" | sed -n 's/^\([0-9][0-9]*\) *(\([0-9][0-9]*\) .*/\1/p')
h_m=$(printf '%s' "$hdr" | sed -n 's/^\([0-9][0-9]*\) *(\([0-9][0-9]*\) .*/\2/p')
if [ -z "$h_n" ]; then
    bad 'STATE.md: la cabecera no tiene «Decisiones abiertas: N (M bloquean la épica activa)»'
elif [ "$h_n" != "$d_n" ] || [ "$h_m" != "$d_m" ]; then
    bad "STATE.md: la cabecera dice «Decisiones abiertas: $h_n ($h_m bloquean…)», pero DOMAIN.md tiene $d_n pendientes y $d_m bloquean la épica activa"
fi

blq=$(strip_comments "$STATE" | awk 'index($0, "## Bloqueo activo") == 1 { f = 1; next } f && /^## / { exit } f')
blq_ids=$(printf '%s\n' "$blq" | grep -oE '(^|[^A-Za-z0-9])D[0-9]+' | sed 's/^[^D]*//' | sort -u)
want_ids=$(awk '$2 == 1 { print $1 }' "$TMPD/dpend" | sort -u)
[ "$blq_ids" = "$want_ids" ] \
    || bad "STATE.md §Bloqueo activo nombra «$(inline "$blq_ids")» y las decisiones pendientes que bloquean la épica activa son «$(inline "$want_ids")»"
[ "$d_m" -gt 0 ] || printf '%s\n' "$blq" | grep -q 'Ninguno' \
    || bad 'STATE.md §Bloqueo activo: no hay decisiones que bloqueen y la sección no dice «**Ninguno.**»'

# Pendientes en otros repos como «id despliegue(0|1)»: filas de BACKLOG con Área = un repo hermano y
# Estado (la última columna) que no empieza por cerrado ni descartado.
: > "$TMPD/xpend"
for repo in $REPOS; do
    awk -F'|' -v a="$repo" '/^\| *[0-9]+ *\|/ {
        r = $4; gsub(/[ \t`]/, "", r); if (r != a) next
        st = $(NF - 1); sub(/^[ \t]+/, "", st); if (st ~ /^(cerrado|descartado)/) next
        id = $2; gsub(/[ \t]/, "", id)
        print id, (index($0, "**Despliegue:**") ? 1 : 0)
    }' "$BACKLOG" >> "$TMPD/xpend"
done
x_n=$(grep -c . "$TMPD/xpend")
x_m=$(awk '$2 == 1' "$TMPD/xpend" | grep -c .)

hdr=$(state_field 'Pendientes en otros repos')
h_n=$(printf '%s' "$hdr" | sed -n 's/^\([0-9][0-9]*\) *(\([0-9][0-9]*\) .*/\1/p')
h_m=$(printf '%s' "$hdr" | sed -n 's/^\([0-9][0-9]*\) *(\([0-9][0-9]*\) .*/\2/p')
if [ -z "$h_n" ]; then
    bad 'STATE.md: la cabecera no tiene «Pendientes en otros repos: N (M condicionan el despliegue)»'
elif [ "$h_n" != "$x_n" ] || [ "$h_m" != "$x_m" ]; then
    bad "STATE.md: la cabecera dice «Pendientes en otros repos: $h_n ($h_m condicionan…)», pero BACKLOG.md tiene $x_n abiertas para un repo hermano y $x_m condicionan el despliegue"
fi
tbl_ids=$(section "$STATE" 'Pendientes en otros repos' | grep -oE '^\| *#[0-9]+' | tr -dc '0-9\n' | sort -u)
want_ids=$(awk '{ print $1 }' "$TMPD/xpend" | sort -u)
[ "$tbl_ids" = "$want_ids" ] \
    || bad "STATE.md §Pendientes en otros repos lista «$(inline "$tbl_ids" '#')» y BACKLOG.md tiene abiertas «$(inline "$want_ids" '#')»"
report fail "contadores al día (decisiones: $d_n/$d_m · otros repos: $x_n/$x_m)" 'STATE.md no está sincronizado (CLAUDE.md §Sincronización post-lectura):'

# ── 8. Destinos de BACKLOG.md ───────────────────────────────────────────────
printf '◆ destinos (todo «Destino» de BACKLOG.md es una épica que existe)\n'

awk -F'|' '/^\| *[0-9]+ *\|/ { id = $2; d = $6; gsub(/[ \t]/, "", id); gsub(/[ \t`]/, "", d)
    if (d != "" && d != "—") print id, d }' "$BACKLOG" | while read -r id d; do
    nn=$(printf '%s' "$d" | sed -nE 's/^([0-9][0-9])(-[a-z0-9-]+)?$/\1/p')
    if [ -z "$nn" ]; then
        bad "BACKLOG.md #$id: «Destino» es «$d», que no es una épica (NN o NN-slug)"
    elif ! ls -d "$AI"/epics/"$nn"-*/ >/dev/null 2>&1; then
        bad "BACKLOG.md #$id: «Destino» es $d, pero no existe ninguna .ai/epics/$nn-*"
    fi
done
report fail 'todos los destinos existen' 'destinos que no son una épica:'

# ── 9. Stack ────────────────────────────────────────────────────────────────
printf '◆ stack (.ai/RULES.md §Stack y .ai/project/DECISIONS.md §Stack frente a composer.json y package.json)\n'

MANIFS=''
for m in composer.json package.json; do [ -f "$ROOT/$m" ] && MANIFS="$MANIFS $ROOT/$m"; done
if ! grep -qE '^## [0-9]+\. Stack' "$RULES"; then
    bad 'RULES.md: no tiene la sección «## N. Stack y versiones exactas»'
fi
grep -q '^## Stack y versiones exactas' "$DECISIONS" \
    || bad '.ai/project/DECISIONS.md: no tiene la sección «## Stack y versiones exactas»'
# Los paquetes que el stack da por hechos: la primera columna de la tabla de RULES.md §Stack, uno por línea.
awk '/^## [0-9]+\. Stack/ { f = 1; next } f && /^## / { exit } f' "$RULES" | awk -F'|' '
    /^\|/ && !/^\| *-/ {
        n = $2; gsub(/`/, "", n); gsub(/^ +| +$/, "", n)
        if (n == "Paquete" || n == "") next
        nn = split(n, N, / \/ /); for (i = 1; i <= nn; i++) print N[i]
    }' > "$TMPD/stack-rules"
# Las versiones del proyecto: «paquete<TAB>versión», o «paquete<TAB><TAB>MAL» si una fila tiene un número de
# versiones que no cuadra con el de paquetes.
section "$DECISIONS" 'Stack y versiones exactas' | awk -F'|' '
    /^\|/ && !/^\| *-/ {
        n = $2; v = $3; gsub(/`/, "", n); gsub(/^ +| +$/, "", n); gsub(/^ +| +$/, "", v)
        if (n == "Paquete" || n == "") next
        nn = split(n, N, / \/ /); nv = split(v, V, / \/ /)
        for (i = 1; i <= nn; i++) {
            if (nv == 1) print N[i] "\t" V[1]
            else if (nv == nn) print N[i] "\t" V[i]
            else print N[i] "\t\tMAL"
        }
    }' > "$TMPD/stack"
while read -r name; do
    [ -n "$name" ] || continue
    cut -f1 "$TMPD/stack" | grep -qxF "$name" \
        || bad "DECISIONS.md §Stack: «$name» (de RULES.md §Stack) no tiene versión"
done < "$TMPD/stack-rules"
while IFS="$TAB" read -r name ver flag; do
    [ -n "$name" ] || continue
    if [ -n "${flag:-}" ]; then bad "DECISIONS.md §Stack: la fila de «$name» no tiene una versión por paquete"; continue; fi
    case "$ver" in ''|*'{{'*) bad "DECISIONS.md §Stack: «$name» no tiene versión"; continue ;; esac
    found=''
    for m in $MANIFS; do grep -qF "\"$name\": \"$ver\"" "$m" && found=1; done
    [ -n "$found" ] && continue
    qname=$(printf '%s' "$name" | sed 's/[].[^$*\\]/\\&/g')
    # shellcheck disable=SC2086  # los manifiestos van separados por espacios
    have=$( [ -n "$MANIFS" ] && grep -hoE "\"$qname\": *\"[^\"]*\"" $MANIFS | head -n 1 | sed 's/.*: *"//; s/"$//')
    if [ -z "$have" ]; then bad "DECISIONS.md §Stack: «$name» no está en composer.json ni en package.json"
    else bad "DECISIONS.md §Stack: «$name» dice $ver y el manifiesto dice $have"; fi
done < "$TMPD/stack"
report fail 'las versiones del stack coinciden con los manifiestos' 'las versiones del stack no coinciden con lo instalado:'

# ── 10. Cross-repo ──────────────────────────────────────────────────────────
printf '◆ cross-repo (los documentos de un repo hermano no se citan; su código, sí)\n'

if [ -z "$REPOS" ]; then
    ok '.ai/project/README.md no declara repos hermanos: no aplica'
else
    ( cd "$ROOT" && find . \( -name .git -o -name node_modules -o -path ./vendor -o -path ./storage \
            -o -path ./bootstrap/cache -o -path ./public/build -o -path ./.next -o -path ./coverage \
            -o -path ./playwright-report -o -path ./test-results -o -path ./.ai/handoffs \) -prune -o -type f \
            \( -name '*.md' -o -name '*.mdc' -o -name '*.php' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' \
            -o -name '*.mjs' -o -name '*.cjs' -o -name '*.json' -o -name '*.yml' -o -name '*.yaml' -o -name '*.txt' \
            -o -name '*.sh' -o -name '*.neon' \) -print ) \
        | sed 's#^\./##' | grep -vxE '\.ai/PROTOCOL\.md|bin/check-docs\.sh|package-lock\.json|composer\.lock' > "$TMPD/files"
    for repo in $REPOS; do
        qrepo=$(printf '%s' "$repo" | sed 's/[].[^$*\\]/\\&/g')
        pat="(^|[^A-Za-z0-9_-])$qrepo/(docs|\.ai)/|(^|[^A-Za-z0-9_-])$qrepo/(CLAUDE|AGENTS|README)\.md"
        ( cd "$ROOT" && tr '\n' '\0' < "$TMPD/files" | xargs -0 -r grep -lE "$pat" 2>/dev/null ) | while read -r f; do
            bad "$f: cita documentos de «$repo» (su código sí se puede citar: CLAUDE.md §El otro repositorio)"
        done
    done
    report fail 'ningún archivo cita documentos de un repo hermano' 'archivos que citan documentos de un repo hermano:'
fi

# ── 11 y 12. Rutas y secciones citadas en los documentos normativos ─────────
NORMATIVE="$CLAUDE_MD $ROOT/AGENTS.md $RULES $AI/WORKFLOW.md $AI/PLANNING.md $DOMAIN $PROJECT/*.md $AI/templates/*.md $ROOT/.claude/commands/*.md $ROOT/docs/README.md"

printf '◆ rutas citadas en los documentos normativos (aviso; falla con --strict)\n'
for src in $NORMATIVE; do
    [ -f "$src" ] || continue
    # shellcheck disable=SC2016  # las comillas invertidas son literales
    for c in $(grep -oE '`[A-Za-z0-9_.][A-Za-z0-9_./@-]*/[A-Za-z0-9_.@-]+\.(php|ts|tsx|js|mjs|cjs|md|mdc|sh|json|neon|txt|xml|yml|yaml)`' "$src" \
               | tr -d '`' | sort -u); do
        case "$c" in ../*) continue ;; esac
        skip=''
        for repo in $REPOS; do case "$c" in "$repo"/*) skip=1 ;; esac; done
        [ -z "$skip" ] || continue
        [ -e "$ROOT/$c" ] || [ -e "$ROOT/src/$c" ] || bad "$(rel "$src"): cita \`$c\`, que no existe"
    done
done
report warn 'todas las rutas citadas existen' 'rutas citadas que no existen:'

printf '◆ referencias «archivo.md §Sección» (por su nombre; aviso, falla con --strict)\n'
# «archivo<TAB>sección» por cada «X.md §Sección». La sección termina en una comilla invertida, una
# puntuación, un punto seguido de espacio, «», », «—», «-->» u otro «§»; y sin un «y»/«o» final. Escribir la
# referencia entre comillas invertidas (`CLAUDE.md §Cierre de fase`) la delimita sin ambigüedad.
for src in $NORMATIVE; do
    [ -f "$src" ] || continue
    awk -v src="$(rel "$src")" '{
        line = $0
        while ((i = index(line, ".md \302\247")) > 0) {
            s = i
            while (s > 1 && substr(line, s - 1, 1) ~ /[A-Za-z0-9_.\/-]/) s--
            file = substr(line, s, i + 3 - s)
            rest = substr(line, i + 6)
            sec = rest
            k = match(sec, /[`,;:()|]/); if (k > 0) sec = substr(sec, 1, k - 1)
            n = split("\302\253 \302\273 \342\200\224 \302\247 -->", M, " ")
            for (q = 1; q <= n; q++) { k = index(sec, M[q]); if (k > 0) sec = substr(sec, 1, k - 1) }
            k = index(sec, ". "); if (k > 0) sec = substr(sec, 1, k - 1)
            sub(/[ .]+$/, "", sec)
            sub(/ (y|o)$/, "", sec)
            if (sec != "") print src "\t" file "\t" sec
            line = rest
        }
    }' "$src"
done > "$TMPD/refs"
while IFS="$TAB" read -r src file sec; do
    case "${file#./}" in
        CLAUDE.md) t="$CLAUDE_MD" ;;
        RULES.md|.ai/RULES.md) t="$RULES" ;;
        WORKFLOW.md|.ai/WORKFLOW.md) t="$AI/WORKFLOW.md" ;;
        PLANNING.md|.ai/PLANNING.md) t="$AI/PLANNING.md" ;;
        DOMAIN.md|.ai/DOMAIN.md) t="$DOMAIN" ;;
        STATE.md|.ai/STATE.md) t="$STATE" ;;
        BACKLOG.md|.ai/BACKLOG.md) t="$BACKLOG" ;;
        docs/runbooks/release.md) t="$MANIFEST" ;;
        .ai/project/*.md) t="$ROOT/${file#./}"; [ -f "$t" ] || { bad "$src: cita «$file», que no existe"; continue; } ;;
        *) continue ;;
    esac
    case "$sec" in *'<'*|*'NN'*) continue ;; esac
    case "$sec" in
        [0-9]*) bad "$src: cita «$file §$sec» por su número; cítala por su nombre"; continue ;;
    esac
    grep -E '^#{2,4} ' "$t" | sed -E 's/^#+ +//' | grep -qF "$sec" && continue
    bad "$src: cita «$file §$sec», que no es ninguna sección de $file"
done < "$TMPD/refs"
report warn 'todas las referencias a secciones existen y van por su nombre' 'referencias a secciones que no existen o van por su número:'

# ── Veredicto ───────────────────────────────────────────────────────────────
printf '\n'
if [ "$FAIL" -gt 0 ]; then
    printf '✗ check-docs: %d chequeo(s) en rojo, %d aviso(s)\n' "$FAIL" "$WARN"
    exit 1
fi
if [ "$WARN" -gt 0 ] && [ "$STRICT" -eq 1 ]; then
    printf '✗ check-docs: %d aviso(s) con --strict\n' "$WARN"
    exit 1
fi
printf '✓ check-docs: %d aviso(s)\n' "$WARN"
exit 0
