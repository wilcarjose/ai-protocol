# Changelog — core

El núcleo del protocolo: lo que es igual en todos los stacks. Versiones con [SemVer](https://semver.org/lang/es/) y
etiqueta `core-vX.Y.Z` (README.md §Versiones y etiquetas). Lo más reciente, arriba.

## [Sin publicar] — 2.0.0-dev

### Añadido

- `.claude/skills/`: `/phase` (`phase/SKILL.md`: pasos, rama, estados, sincronización, commits y verificación;
  `phase/cierre.md`: cierre de fase y de épica, archivo de la memoria, traspaso y reporte final), `/close` y
  `/planning`. `/phase` y `/close` llevan `disable-model-invocation: true`.
- `bin/handoff.sh <NN-slug> <FF>`: imprime sólo «Lo que la siguiente fase necesita saber» de una fase.
- `.ai/archive/` (semilla): `BACKLOG.md`, `DOMAIN.md` y `PROTOCOL.md` con lo cerrado de la memoria. La fila «Protocolo
  instalado» de `PROTOCOL.md` nace ya archivada.
- `bin/check-docs.sh`, chequeo 13 «memoria»: ni filas cerradas o descartadas en `BACKLOG.md`, ni decisiones
  reemplazadas o respondidas en `DOMAIN.md`, ni mejoras aplicadas o descartadas en `PROTOCOL.md`, ni más de 10 líneas
  en `STATE.md §Últimos movimientos`, ni ids de `BACKLOG.md` o `DOMAIN.md` repetidos en el archivo.
- `bin/check-docs.sh`, chequeo «fases»: cada evidencia enlazada (`.ai/epics/<NN-slug>/evidence/…`) existe.
- `core.json`: nombre, versión y archivos del núcleo, en dos listas: `files` (los del kit, que `install.sh --upgrade`
  actualiza) y `seed` (los que sólo se copian si faltan: memoria, capa del proyecto, manifiesto de despliegue).
- `.ai/project/`: la capa del proyecto, que el instalador nunca toca. `README.md` (contexto operativo y repos
  hermanos), `DECISIONS.md` (versiones del stack e infraestructura), `ARCHITECTURE.md`, `CONTRACT.md`,
  `SENSITIVE-ZONES.md`, `CROSS-CUTTING.md` y `COMMIT-SCOPES.md`.

### Cambiado

- `CLAUDE.md` mínimo (de 21 017 a 4 028 caracteres): orden de lectura, qué hace cada skill, alcance, el otro
  repositorio, prohibiciones y punteros. El ciclo de fase, las ramas, los commits y el cierre pasan a las skills.
- `.ai/WORKFLOW.md` sin `§Plantilla del reporte final` ni el resumen de cinco frases: el RESULTADO de la fase es el
  único reporte, y el chat lo resume en cinco líneas (`phase/cierre.md §Reporte final`). Una salida de más de 40
  líneas va a un archivo de evidencia que el RESULTADO enlaza.
- `bin/check-docs.sh` busca los ids `D<n>` también en `.ai/archive/DOMAIN.md`, cuenta como normativos `.ai/rules/` y
  las skills, y valida las citas a sus secciones.
- `bin/measure-context.sh` mide la sesión «cierre» (lo que añade el Paso C) aparte del arranque del ejecutor.
- Las semillas `BACKLOG.md`, `DOMAIN.md`, `PROTOCOL.md` y `STATE.md` explican qué pasa a `.ai/archive/` y el tope de
  «Últimos movimientos».
- `CLAUDE.md` deja de tener `{{RELLENAR}}`: el título es genérico, y el contexto operativo y los repos hermanos pasan
  a `.ai/project/README.md`, que entra en `§Orden de lectura`.
- `bin/check-docs.sh` lee los repos hermanos de `.ai/project/README.md` y las versiones de
  `.ai/project/DECISIONS.md §Stack y versiones exactas`; exige una versión por cada paquete de
  `.ai/RULES.md §Stack y versiones exactas`, busca marcadores en `.ai/project/` y valida las citas a sus secciones.
- `bin/measure-context.sh` cuenta `.ai/project/README.md` en las sesiones de ejecutor y planificador.
- `.ai/WORKFLOW.md §Documentación` lista `.ai/project/` y quién la escribe.

### Retirado

- `.claude/commands/phase.md` y `.claude/commands/close.md`: ahora son skills. `install.sh --upgrade` los retira, con
  su carpeta si queda vacía.
- `.ai/PLANNING.md`: ahora es la skill `/planning`.

## 1.x

El kit antes de separarse en paquetes: una carpeta completa por stack que se copiaba con `cp -Rn`, con la «Versión del
kit» como fecha (la última, 2026-10-04). Los proyectos instalados así se actualizan con `install.sh --upgrade --stack
<stack>`.
