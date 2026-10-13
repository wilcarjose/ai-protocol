---
name: kit-feedback
description: Revisa los issues de mejora del protocolo que abren los proyectos (bin/protocol-feedback.sh), propone qué hacer con cada uno y, con el visto bueno, los aplica en core o en su stack, sube las versiones, cierra los issues y abre el PR. Sólo en el repo del kit.
argument-hint: "[número de issue…]"
disable-model-invocation: true
---

# /kit-feedback — aplicar en el kit las mejoras que llegan de los proyectos

Argumentos: `$ARGUMENTS`. Sin argumentos, todos los issues de mejora abiertos; con números, sólo esos.

Es el paso del medio del ciclo de mejora (README.md §Principios): un proyecto anota la fricción en su
`.ai/PROTOCOL.md`, `bin/protocol-feedback.sh` la sube como issue, **esta skill la aplica en el kit** y el proyecto
la recibe con `install.sh --upgrade`. Corre en este repo, nunca en un proyecto.

## 1. Los issues

1. Árbol limpio y `main` al día: `git switch main`, `git pull --ff-only`. Si no avanza en línea recta, para y dilo.
2. Sin argumentos: `gh issue list --state open --limit 100 --json number,title,body`. Son de mejora los que traen
   `**Origen:**` y `**Propuesta:**` en el cuerpo (el formato de `bin/protocol-feedback.sh`). Uno que agrupa a otros
   (un plan, como el #34) no se aplica: se nombra aparte.
3. `gh issue view <n>` de cada uno, con sus comentarios.

## 2. Contrastar cada propuesta con el kit

Sin escribir nada todavía:

- **Dónde cae.** El alcance del título (`[núcleo]`, `[nextjs]`, `[laravel]`) dice el paquete: el núcleo en `core/`
  y cada stack en `stacks/<stack>/`. La ruta del proyecto que cita la propuesta (`.claude/skills/phase/SKILL.md`)
  está en el kit bajo ese paquete (`core/.claude/skills/phase/SKILL.md`). `install.sh`, `tests/` y `docs/` son del
  kit entero; un cambio en `install.sh` se anota en el `CHANGELOG.md` del núcleo.
- **Si sigue vigente.** Lee la sección que nombra en el código actual, y busca el `#N` en los `CHANGELOG.md`: puede
  estar ya resuelto, o resuelto por otro issue del lote.
- **Si choca con otra regla.** Cada regla vive en un solo archivo (`core/CLAUDE.md`): una propuesta que repite o
  contradice otra sección se aplica allí o se descarta. El núcleo no cita lo que no traen todos los stacks, y un
  stack no cita otro (`tests/structure.sh`).
- **Si funciona.** Lo que dice cómo se comporta una herramienta (un CLI, `next build`, un permiso) se reproduce,
  no se deduce. Para un stack, `E2E_KEEP=1 sh tests/e2e-<stack>.sh` deja un proyecto real donde probarlo.
- **Lo que arrastra.** Una orden nueva que pide el núcleo tiene que estar permitida en el `.claude/settings.json`
  de **todos** los stacks, y eso los sube de versión. Issues que tocan lo mismo se aplican juntos, cada uno con su
  commit.

## 3. La tabla y el visto bueno

Responde con una tabla: **issue · paquete · qué propone · decisión · archivos que cambiarías**. La decisión es
aplicarla tal cual, aplicarla con otra forma (di cuál y por qué) o descartarla (con el motivo). Debajo, las
versiones previstas (README.md §Versiones y etiquetas: mayor, menor o parche) y las preguntas: cada una con sus
opciones y la recomendada primero.

**Para y espera el visto bueno.** Si al aplicar algo sale distinto de lo aprobado (una prueba lo desmiente), para
otra vez y pregunta antes de escribirlo.

## 4. Aplicar

- **Rama propia** desde `main`: `feat/protocol-feedback-<AAAA-MM-DD>`. Nunca `plan-1x`, que impide después las
  ramas `plan-1x/fase-N`.
- **Un commit por issue**, en Conventional Commits en inglés, con el `(#N)` al final de la primera línea y el porqué
  en el cuerpo. Dos issues sobre lo mismo: dos commits, el segundo sobre el primero.
- **Versiones mientras trabajas:** el primer commit que toca un paquete le pone la versión siguiente con `-dev` en
  su manifiesto y abre «## Sin publicar» en su `CHANGELOG.md`. Cada commit añade ahí su línea, con el archivo, la
  sección y el `#N`. Si el cambio obliga a hacer algo al actualizar un proyecto, va en «### Al actualizar un
  proyecto».
- **Pruebas** del comportamiento nuevo: `tests/run.sh` para el instalador y el guardián, `tests/structure.sh` para
  los manifiestos y los permisos, `tests/e2e-<stack>.sh` para `bin/verify.sh`. Cada prueba falla sin el cambio.

## 5. Verificar

Todo en verde antes de publicar:

- `sh tests/structure.sh` y `sh tests/run.sh`. Si una sesión crece más de un 3 % en `tests/context-baseline.txt`,
  la línea se sube en un commit que explica por qué.
- `shellcheck -s sh install.sh core/bin/*.sh stacks/*/bin/*.sh tests/*.sh docs/vps/*.sh .github/*.sh`.
- `sh tests/e2e-<stack>.sh` de cada stack cuyo `bin/verify.sh`, plantillas o instalación cambien (necesita red).

## 6. Publicar y entregar

1. **Commit de versión**, `chore(kit): release core X.Y.Z, <stack> X.Y.Z…`: quita el `-dev` de cada manifiesto, y
   «Sin publicar» pasa a `## [X.Y.Z] — <fecha>`.
2. `git push -u origin <rama>` y `gh pr create --base main` con el cuerpo en un archivo temporal, fuera del repo: las
   versiones, una tabla issue · paquete · cambio, la verificación y lo que no se ha podido probar. Espera la CI con
   `gh pr checks <n> --watch`.
3. **Cada issue**, comentado y cerrado: `gh issue close <n> --comment "…"` con la versión en la que queda aplicado y
   cómo (o el motivo si se descarta), citando el PR.
4. Las etiquetas no se crean a mano: `.github/workflows/tag.yml` las crea al fusionar.

## 7. Reporte

- Las versiones nuevas: `core X.Y.Z` y cada stack que cambió.
- Los issues aplicados y los descartados, con el motivo; los que quedan abiertos fuera del lote.
- La orden para actualizar un proyecto, entre fases, desde la carpeta que contiene los dos repos:
  `sh ai-protocol/install.sh --upgrade --target <proyecto> --dry-run` y después sin `--dry-run`, en un PR
  `chore(protocol): upgrade ai-protocol to vX.Y`.
