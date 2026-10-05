# Changelog — core

El núcleo del protocolo: lo que es igual en todos los stacks. Versiones con [SemVer](https://semver.org/lang/es/) y
etiqueta `core-vX.Y.Z` (README.md §Versiones y etiquetas). Lo más reciente, arriba.

## [Sin publicar] — 2.0.0-dev

### Añadido

- `core.json`: nombre, versión y archivos del núcleo, en dos listas: `files` (los del kit, que `install.sh --upgrade`
  actualiza) y `seed` (los que sólo se copian si faltan: memoria, capa del proyecto, manifiesto de despliegue).
- `.ai/project/`: la capa del proyecto, que el instalador nunca toca. `README.md` (contexto operativo y repos
  hermanos), `DECISIONS.md` (versiones del stack e infraestructura), `ARCHITECTURE.md`, `CONTRACT.md`,
  `SENSITIVE-ZONES.md`, `CROSS-CUTTING.md` y `COMMIT-SCOPES.md`.

### Cambiado

- `CLAUDE.md` deja de tener `{{RELLENAR}}`: el título es genérico, y el contexto operativo y los repos hermanos pasan
  a `.ai/project/README.md`, que entra en `§Orden de lectura`.
- `bin/check-docs.sh` lee los repos hermanos de `.ai/project/README.md` y las versiones de
  `.ai/project/DECISIONS.md §Stack y versiones exactas`; exige una versión por cada paquete de
  `.ai/RULES.md §Stack y versiones exactas`, busca marcadores en `.ai/project/` y valida las citas a sus secciones.
- `bin/measure-context.sh` cuenta `.ai/project/README.md` en las sesiones de ejecutor y planificador.
- `.ai/WORKFLOW.md §Documentación` lista `.ai/project/` y quién la escribe.

## 1.x

El kit antes de separarse en paquetes: una carpeta completa por stack que se copiaba con `cp -Rn`, con la «Versión del
kit» como fecha (la última, 2026-10-04). Los proyectos instalados así se actualizan con `install.sh --upgrade --stack
<stack>`.
