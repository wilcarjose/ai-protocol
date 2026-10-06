#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# tests/lib.sh — lo que comparten tests/run.sh y los e2e de cada stack para
# dejar una instalación lista para el guardián. Se carga con «.»; no hace nada
# por sí solo.
# ─────────────────────────────────────────────────────────────────────────────

# edit <archivo> <script de sed>: sed en el sitio sin «-i», que no es POSIX.
edit() { sed "$2" "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }

# awk_edit <archivo> <programa de awk>: lo mismo con awk.
awk_edit() { awk "$2" "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }

# fill_stack <RULES.md> <DECISIONS.md> <manifiesto>: la fila de marcador de DECISIONS.md §Stack pasa a una fila
# por paquete de RULES.md §Stack, con la versión que declara el manifiesto (una pareja «"paquete": "versión"» por
# línea).
fill_stack() {
    awk '
        FILENAME == ARGV[1] {
            if ($0 ~ /^ *"[^"]+": *"[^"]*",? *$/) {
                l = $0; sub(/^ *"/, "", l); sub(/",? *$/, "", l); split(l, kv, /": *"/); v[kv[1]] = kv[2]
            }
            next
        }
        FILENAME == ARGV[2] {
            if ($0 ~ /^## [0-9]+\. Stack/) { s = 1; next }
            if (s && /^## /) s = 0
            if (s && /^\| `/) {
                n = $0; sub(/^\| /, "", n); sub(/ \|.*/, "", n); gsub(/`/, "", n)
                k = split(n, N, / \/ /); for (i = 1; i <= k; i++) rows = rows "| `" N[i] "` | " v[N[i]] " |\n"
            }
            next
        }
        /^\| \{\{RELLENAR/ { printf "%s", rows; next }
        { print }' "$3" "$1" "$2" > "$2.tmp" && mv "$2.tmp" "$2"
}

# fill_markers <archivo> <repo hermano>: cada {{RELLENAR…}}, aunque ocupe varias líneas, pasa a «Demo»;
# el de los repos hermanos, al nombre del repo entre comillas invertidas.
fill_markers() {
    awk -v repo="$2" '
        { buf = buf $0 "\n" }
        END {
            while ((i = index(buf, "{{RELLENAR")) > 0) {
                rest = substr(buf, i); j = index(rest, "}}")
                val = index(substr(rest, 1, j), "repo hermano") ? "`" repo "`" : "Demo"
                out = out substr(buf, 1, i - 1) val
                buf = substr(rest, j + 2)
            }
            printf "%s", out buf
        }' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
