# Plan 1c — Plantillas base y reglas para cualquier proyecto

> **Origen:** decisiones de la persona del 10 de octubre de 2026. El kit sirve a cualquier proyecto con API y web (y
> después Expo), no sólo al portal; todos los proyectos usan PostgreSQL; los textos para el usuario siempre son
> traducibles; y un proyecto nuevo nace de dos repos plantilla, `base-api` y `base-web`, con el protocolo instalado
> desde este repo (la opción A: este repo sigue siendo la fuente y el lock viaja con la plantilla).
> **Base:** núcleo 2.1.0, Laravel 2.0.1 y Next.js 2.0.0. Lo que cambie sube versión por paquete, con su
> `CHANGELOG.md` (README.md §Versiones y etiquetas).

## Estado

| Fase | Objetivo | Depende de | Estado | PR |
|---|---|---|---|---|
| 1 | Idiomas y PostgreSQL en las reglas | — | pendiente | |
| 2 | Proyecto nuevo desde una plantilla | 1 | pendiente | |
| 3 | Plantilla de la API (`base-api`) | 1 | pendiente | |
| 4 | Plantilla web (`base-web`) | 3 | pendiente | |
| 5 | Validación de punta a punta | 2, 4 | pendiente | |

Las fases 1 y 2 cambian el kit. Las 3 y 4 crean cada plantilla y la construyen con el propio protocolo; la 4 empieza
cuando la API publica su contrato de autenticación (BA-02 del paquete).

## Cómo se ejecuta una fase

Igual que en `docs/plan-1a.md §Cómo se ejecuta una fase`, con la rama `plan-1c/fase-N`. Antes de agregar algo, busca
lo mínimo que cumple el objetivo; si no se puede comprobar con un comando o con una casilla `[humano]`, simplifícalo o
propón quitarlo.

Las fases 3 y 4 trabajan en su repo plantilla, que es un proyecto más: allí el paquete de §Paquete de las plantillas
se convierte en una épica con `/plan-epic` y cada tarea se ejecuta con `/phase`, con su rama, su PR y su CI. En este
repo, el PR de esas fases sólo actualiza la tabla de estado y el «Registro», con los enlaces a los PR de la plantilla.

## Decisiones que no se reabren

1. Siguen vigentes las decisiones de `docs/plan-1a.md` y `docs/plan-1b.md`. La decisión 3 de este plan reemplaza a
   la 11 del 1a en lo que dice del idioma de los textos para el usuario.
2. **Todos los proyectos usan PostgreSQL.** El stack de Laravel no tiene motor configurable. La CI sigue con la imagen
   de PostGIS, que es PostgreSQL con una extensión más; un proyecto la usa sólo si la necesita.
3. **Los textos para el usuario siempre pasan por las traducciones**, aunque el proyecto tenga un solo idioma. El
   idioma por defecto y los demás los fija cada proyecto en `.ai/project/CROSS-CUTTING.md §Idiomas`; el kit no da
   ninguno por hecho. La única excepción es un impacto de rendimiento medido, escrito en la fase con su medición.
   El código sigue en inglés, y la documentación del protocolo y la descripción de los PR, en español.
4. **Opción A.** El protocolo vive en cada plantilla como una instalación más, con su `.ai/protocol.lock`, y este repo
   es su única fuente. Un proyecto nacido de una plantilla recibe las mejoras del kit con `install.sh --upgrade`; las
   del código de la plantilla sólo llegan a los proyectos que nazcan después.
5. **Las plantillas:** `base-api` (Laravel) y `base-web` (Next.js), repos de GitHub marcados como *template
   repository*, cada uno hermano del otro.
6. **Autenticación de la base:** correo y contraseña, con recuperación por correo. La API sólo acepta tokens Bearer de
   Sanctum; la web guarda el token en una cookie HttpOnly detrás de su BFF. El código por SMS o WhatsApp y el inicio
   de sesión social quedan para cada proyecto.
7. **Idiomas de la base:** español por defecto e inglés como segundo idioma, para que el multi-idioma quede probado
   desde el primer día. En la web, con `next-intl`; en la API, con las traducciones de Laravel y la cabecera
   `Accept-Language`.
8. **Interfaz de la base:** shadcn/ui con primitivas de Radix, instalado con su CLI en `src/shared/ui`; el panel parte
   de los bloques `sidebar-07` y `dashboard-01`, y la página de inicio pública de bloques de Tailark. Nada de
   plantillas de pago. El código MIT que se copie conserva su aviso de licencia.
9. **El kit no depende de las plantillas:** sus e2e siguen creando proyectos con `laravel new` y `create-next-app`, y
   el camino manual del README sigue valiendo para los proyectos que ya existen.
10. **El arranque del ejecutor no crece más de lo que permite `tests/context-baseline.txt`:** la fase 1 reescribe
    frases en su sitio, no añade secciones.
11. Expo queda fuera de este plan.

---

## Fase 1 — Idiomas y PostgreSQL en las reglas

**Objetivo:** que las reglas del kit no den por hecho el idioma del usuario y que exijan traducciones siempre.

Entregables:

- Las reglas que dicen «en español» para los textos del usuario, los slugs públicos y los datos semilla pasan a
  decir «en el idioma de `.ai/project/CROSS-CUTTING.md §Idiomas`»: la lista negra de los dos `RULES.md`, el punto 11
  de `.claude/agents/reviewer.md`, `.ai/rules/arquitectura.md` de Laravel, `.claude/skills/plan-phase/SKILL.md` y
  la semilla `.ai/project/GLOSSARY.md`.
- `.ai/rules/arquitectura.md` de Next.js: cero texto visible escrito a mano en JSX, siempre, no sólo con más de un
  idioma; con la excepción de la decisión 3 y cómo se declara sin bajar la regla.
- Una comprobación ejecutable de esa regla en Next.js, si es viable sin dependencias nuevas (por ejemplo,
  `react/jsx-no-literals` en la configuración de ESLint del kit). Si no lo es, STOP & ASK con las opciones.
- La semilla `.ai/project/CROSS-CUTTING.md §Idiomas` pide el idioma por defecto, los demás idiomas, la librería y
  dónde viven las traducciones; desaparece la opción «Un solo idioma: los textos van en el código».
- Laravel: `.ai/rules/tests.md` y los comentarios de `.github/workflows/verify.yml` y `.env.testing` dicen
  «PostgreSQL», con PostGIS disponible y opcional.
- `CHANGELOG.md` de cada paquete tocado, con la versión que corresponda (README.md §Versiones y etiquetas: si añade
  un chequeo que antes no fallaba, sube la mayor) y su «Al actualizar un proyecto».

Criterios de aceptación:

- [ ] `grep -rni 'español' core stacks --exclude=CHANGELOG.md` sólo encuentra la prohibición de escribir el código
      en español y la descripción de los PR: ninguna línea dice que los textos del usuario, los slugs o las semillas
      van en español.
- [ ] Si hay comprobación ejecutable, `tests/e2e-nextjs.sh` provoca un texto escrito en el JSX y el gate falla.
- [ ] `sh tests/run.sh` pasa, con el arranque del ejecutor dentro de `tests/context-baseline.txt`.
- [ ] La CI del PR está en verde.

## Fase 2 — Proyecto nuevo desde una plantilla

**Objetivo:** que un repo creado desde una plantilla quede, con un comando, como un proyecto nuevo que el guardián
obliga a rellenar.

Entregables:

- Un modo del instalador (propuesta: `install.sh --new-project --target <dir>`, porque el instalador ya tiene las
  semillas; la fase lo confirma en su resumen) que, sobre un proyecto con lock:
  - deja la memoria como la semilla del kit: `STATE`, `DOMAIN`, `BACKLOG`, `PROTOCOL`, `.ai/archive/`, `.ai/epics/`
    vacía, `.ai/stages/` y `.ai/handoffs/` sólo con su README, y `docs/runbooks/release.md`;
  - vuelve a la semilla, con sus `{{RELLENAR}}`, lo que describe el negocio: `.ai/project/README.md` (nombre,
    contexto y repos hermanos), `GLOSSARY.md`, `FEATURES.md`, `SENSITIVE-ZONES.md` y `COMMIT-SCOPES.md`;
  - conserva lo técnico que la plantilla ya decidió (`DECISIONS.md`, `ARCHITECTURE.md`, `CONTRACT.md`,
    `CROSS-CUTTING.md`, `verify.conf`, `lighthouse.json`), los archivos del kit, el lock y el código;
  - con `--dry-run`, dice qué haría; al terminar, lista los `{{RELLENAR}}` que quedan.
- README: §Proyecto nuevo desde una plantilla, con los pasos que GitHub no copia (la protección de `main` y los
  secretos). `docs/guia.md` la enlaza como el camino recomendado para proyectos nuevos.

Criterios de aceptación:

- [ ] `tests/run.sh` instala cada stack, rellena la capa del proyecto, crea una épica y corre el modo nuevo: el
      guardián falla en «instalación» hasta rellenar los marcadores, la memoria es la semilla y los archivos del kit
      y el lock no cambian.
- [ ] Un `install.sh --upgrade` justo después dice «sin cambios».
- [ ] `shellcheck -s sh install.sh` no da avisos y la CI del PR está en verde.

## Fase 3 — Plantilla de la API (`base-api`)

**Objetivo:** un repo Laravel listo para usar como plantilla, con autenticación, idiomas y contrato.

Entregables:

- `[humano]` El repo `base-api` en GitHub, marcado como *template repository*, con la protección de `main`
  (`docs/modos.md §Proteger main en GitHub`).
- El proyecto creado e instalado según README.md §Instalación en un proyecto nuevo, con la capa del proyecto
  rellena y `base-web` como repo hermano.
- §Paquete de las plantillas copiado a `.ai/stages/plan-1c.md`, su épica planificada con `/plan-epic` y las tareas
  BA ejecutadas con `/phase`.

Criterios de aceptación:

- [ ] `bash bin/verify.sh` en verde en `base-api`, en local y en su CI.
- [ ] La épica de las tareas BA está cerrada en `base-api`; sus PR, enlazados en «Registro».

## Fase 4 — Plantilla web (`base-web`)

**Objetivo:** un repo Next.js listo para usar como plantilla, con páginas públicas, sesión, panel e idiomas.

Entregables:

- `[humano]` El repo `base-web` en GitHub, marcado como *template repository*, con la protección de `main`.
- El proyecto creado e instalado según README.md §Instalación en un proyecto nuevo, con la capa del proyecto
  rellena, `base-api` como repo hermano y la copia de su contrato.
- El mismo paquete en `.ai/stages/plan-1c.md`, su épica y las tareas BW ejecutadas.

Criterios de aceptación:

- [ ] `bash bin/verify.sh` en verde en `base-web`, en local y en su CI, con Lighthouse sobre la página de inicio.
- [ ] La épica de las tareas BW está cerrada en `base-web`; sus PR, enlazados en «Registro».

## Fase 5 — Validación de punta a punta

**Objetivo:** comprobar que un proyecto nuevo nace de las dos plantillas, se rellena y sigue recibiendo el kit.

Entregables:

- `[humano]` Dos repos de prueba creados con «Use this template» desde `base-api` y `base-web`.
- En cada uno, el modo de proyecto nuevo de la fase 2, la capa del proyecto rellena y `bash bin/verify.sh`.
- Las versiones del plan publicadas: sin sufijo `-dev`, con su fecha en cada `CHANGELOG.md`.

Criterios de aceptación:

- [ ] `bash bin/verify.sh` en verde en los dos repos de prueba.
- [ ] El E2E de BW-05 pasa en el repo web de prueba contra el de la API levantado en local.
- [ ] `install.sh --upgrade` lleva a los dos repos de prueba la versión publicada sin conflictos.
- [ ] `[humano]` La persona arranca el proyecto de prueba siguiendo sólo `docs/guia.md` y confirma que no le faltó
      nada. Después borra los repos de prueba o los conserva, a su elección, y lo anota en «Registro».

---

## Paquete de las plantillas

Se copia tal cual a `.ai/stages/plan-1c.md` en `base-api` y en `base-web` (`.ai/stages/README.md §Formato`). Cada
repo convierte sólo sus tareas.

```markdown
# Paquete plan-1c — Plantillas base

> **Origen:** ai-protocol, docs/plan-1c.md (10 de octubre de 2026)

## Objetivo

Dos plantillas, API y web, de las que nace cualquier proyecto nuevo con registro, inicio de sesión, recuperación de
contraseña, panel, página de inicio pública y dos idiomas.

## Tareas

| ID | Tarea | Repo | Criterio de aceptación | Depende de |
|---|---|---|---|---|
| BA-01 | Convenciones de la API: prefijo /v1, errores problem+json traducidos e idioma por la cabecera Accept-Language, con español por defecto e inglés | base-api | Un error de ejemplo bajo /v1 sale como problem+json en español sin cabecera y en inglés con Accept-Language en | — |
| BA-02 | Registro, inicio y cierre de sesión con tokens Bearer de Sanctum, y consulta del usuario actual | base-api | Un usuario se registra, inicia sesión, consulta /v1/auth/me con su token y, después de cerrar sesión, ese token recibe 401 | BA-01 |
| BA-03 | Recuperación de contraseña por correo, con el enlace hacia la web | base-api | Con el enlace del correo el usuario fija una contraseña nueva y la anterior deja de servir | BA-02 |
| BA-04 | Límites de tasa en registro, inicio de sesión y recuperación | base-api | El sexto intento fallido de inicio de sesión en un minuto recibe 429 como problem+json | BA-02 |
| BW-01 | Idiomas con next-intl: español por defecto e inglés, y el cliente único enviando Accept-Language | base-web | La página de inicio se ve en español por defecto y en inglés al cambiar de idioma, sin texto escrito en el JSX | — |
| BW-02 | Sistema de diseño con shadcn/ui (Radix), instalado por su CLI en src/shared/ui, y una página de muestra | base-web | La página de muestra enseña botón, campo, selector, tarjeta, diálogo y aviso con textos traducidos, y lo que genera el CLI pasa la regla de capas | BW-01 |
| BW-03 | Grupos de rutas (public), (auth) y (panel) con layouts separados, y una página de inicio pública con bloques de Tailark | base-web | La página de inicio cumple el presupuesto de Lighthouse y no carga JavaScript del panel | BW-02 |
| BW-04 | Sesión por el BFF: Route Handlers con lista blanca, token en cookie HttpOnly y protección del panel | base-web | Después de iniciar sesión el token sólo existe en una cookie HttpOnly, y sin ella el panel redirige al inicio de sesión | BW-03, BA-02 |
| BW-05 | Pantallas de registro, inicio de sesión y recuperación de contraseña con Server Actions | base-web | Un E2E, con base-api levantada en local, registra un usuario, entra al panel, cierra sesión y recupera su contraseña | BW-04, BA-03 |
| BW-06 | Shell del panel a partir de los bloques sidebar-07 y dashboard-01, sin sus datos de ejemplo | base-web | En móvil y en escritorio el panel muestra el nombre que devuelve /v1/auth/me y su navegación funciona con teclado | BW-04 |

## Decisiones vigentes

- Todos los proyectos usan PostgreSQL.
- Los textos para el usuario siempre pasan por las traducciones; la única excepción es un impacto de rendimiento medido y escrito en la fase.
- Español por defecto e inglés como segundo idioma: next-intl en la web, traducciones de Laravel y Accept-Language en la API.
- La API sólo acepta tokens Bearer de Sanctum; la web guarda el token en una cookie HttpOnly detrás de su BFF.
- Autenticación de la base: correo y contraseña con recuperación; SMS, WhatsApp e inicio de sesión social quedan para cada proyecto.
- Interfaz: shadcn/ui con Radix en src/shared/ui; panel desde sidebar-07 y dashboard-01; página de inicio con bloques de Tailark; el código MIT copiado conserva su aviso.
- Pendiente para la épica de base-web: cómo va el idioma en la URL (prefijo en todos los idiomas o sólo en los que no son el de por defecto).
```

---

## Registro

- **Decisiones tomadas durante el plan:**
  - (vacío)
- **Lo que la siguiente fase necesita saber:**
  - (vacío)
