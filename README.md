# ai-protocol — protocolo de trabajo con IA por épicas y fases

Kit para que un proyecto **Laravel** o **Next.js** trabaje con agentes de IA (Claude Code, Cursor, Codex…) desde el
primer día. El trabajo se planifica en **épicas** partidas en **fases**. Cada fase se ejecuta en una sesión que empieza
**en frío** y termina en un PR, y unos archivos `.md` hacen de memoria entre sesiones. Un guardián
(`bin/check-docs.sh`) comprueba que esa memoria no miente, y un único árbitro (`bin/verify.sh`) decide si el código
está sano, en la sesión y en la CI.

**¿Empiezas?** Lee la [guía práctica](docs/guia.md): qué es el protocolo, cómo se arranca un proyecto, el ciclo de
una fase al cierre de la épica, para qué sirve cada pieza y un ejemplo de inicio a fin. Este README es la referencia.

## Principios

- **Simple:** sólo lo necesario. Antes de añadir una pieza se busca lo mínimo que cumple el objetivo.
- **Comprobable:** cada regla se comprueba con un comando o con una casilla `[humano]`. Si no se puede comprobar, se
  simplifica o se quita.
- **Mejorado con retroalimentación:** cada cierre de fase pregunta a la persona qué le estorbó, le faltó o le sobró, y
  su respuesta queda en `.ai/PROTOCOL.md` junto a las propuestas del agente. Una mejora que sirve a todos los
  proyectos llega al kit como un issue en ai-protocol con la fila de `PROTOCOL.md`.
- **Neutral respecto al proveedor:** Claude Code es la herramienta por defecto, pero el protocolo se puede usar con
  agentes de otros proveedores. Los textos usan un lenguaje neutro y lo propio de Claude Code va como nota entre
  paréntesis, sin adaptadores nuevos.

## Las tres capas

| Capa | Dónde vive en el kit | Qué es | Quién la cambia |
|---|---|---|---|
| **Núcleo** | `core/` (`core.json`) | El protocolo, la memoria, el guardián, las skills y el revisor. Igual en todos los stacks | El kit |
| **Stack** | `stacks/<stack>/` (`stack.json`) | Reglas de código, plantillas, `bin/verify.sh`, permisos y CI de una tecnología | El kit |
| **Proyecto** | `.ai/project/` (del núcleo y del stack) | Lo que decide cada proyecto: versiones, alcance, contrato, zonas sensibles, baseline… | El proyecto |

Un stack depende sólo del núcleo, nunca de otro stack, y declara en su `stack.json` el rango del núcleo con el que
funciona. El instalador copia núcleo + stack en el proyecto, que no depende de este repo para funcionar. La capa del
proyecto se crea una vez y el instalador ya no la toca. Hay stacks de **Laravel** y **Next.js**; `stacks/expo/` sólo
anuncia el de Expo.

```
core/                     El núcleo.                  core.json: versión, archivos del kit («files») y semillas («seed»).
stacks/laravel/           El stack de Laravel.        stack.json: versión, rango del núcleo, archivos y gates.
stacks/nextjs/            El stack de Next.js.
stacks/expo/              Sólo un README que anuncia el stack.
install.sh                Instala o actualiza núcleo + stack en un proyecto.
tests/                    Las pruebas del kit: structure.sh, run.sh, los e2e de cada stack y sus fixtures.
docs/                     Documentación del propio kit: la guía práctica, los modos de ejecución, los planes y, en
                          vps/, el doctor y la unidad de systemd del modo VPS.
```

### Lo que queda en el proyecto

**Kit** es lo que `install.sh --upgrade` actualiza y el gate «protocolo» protege; **semilla**, lo que sólo se copia
si falta y después es del proyecto.

```
CLAUDE.md                 Punto de entrada: lectura en frío, alcance, prohibiciones y punteros.    [núcleo · kit]
AGENTS.md                 Redirección a CLAUDE.md para Cursor, Codex, aider…                       [núcleo · kit]
.ai/
  RULES.md                El núcleo de las reglas de código: stack, alcance, contrato, lista negra. [stack · kit]
  rules/                  Las reglas por tema (arquitectura, tests…), que la fase cita si las toca.  [stack · kit]
  WORKFLOW.md             Protocolo del ejecutor: ciclo, criterios de parada, STOP & ASK.           [núcleo · kit]
  templates/              Plantillas de épica y de fase.                                             [stack · kit]
  stages/                 Paquetes de tareas de un plan externo; su README dice el formato.         [núcleo · kit]
  handoffs/               Entregas del repo hermano, copiadas.                                       [núcleo · kit]
  STATE.md                El puntero: fase activa, mapa de fases, bloqueos.                          [núcleo · semilla]
  DOMAIN.md               Decisiones vigentes y pendientes. Lo decidido no se pregunta.              [núcleo · semilla]
  BACKLOG.md              Hallazgos abiertos fuera de alcance y pendientes en otros repos.           [núcleo · semilla]
  PROTOCOL.md             Mejoras del protocolo que propone cada fase, pendientes de aplicar.        [núcleo · semilla]
  archive/                Lo cerrado de la memoria: backlog, decisiones reemplazadas, mejoras.      [núcleo · semilla]
  epics/                  Las épicas y sus fases, con su evidence/.                                  [núcleo · semilla]
  project/                La capa del proyecto: contexto, versiones, alcance, contrato, glosario,   [núcleo · semilla]
                          mapa de funcionalidades, zonas sensibles…
  project/verify.conf     La baseline de bin/verify.sh y lo que el stack necesita saber del proyecto. [stack · semilla]
  protocol.lock           Lo que instaló install.sh: versiones, suma y «kit» o «project» por archivo. [install.sh]
.claude/
  skills/                 /phase, /close, /plan-epic, /plan-phase y /review (§Roles).               [núcleo · kit]
  agents/reviewer.md      El revisor IA: subagente de solo lectura que compara el diff con la fase.  [núcleo · kit]
  settings.json           Permisos del agente: qué ejecuta sin preguntar y qué nunca (push a main…). [stack · kit]
.github/
  pull_request_template.md  La plantilla del PR de cada fase.                                       [núcleo · kit]
  workflows/verify.yml    La CI del proyecto: bin/verify.sh completo en cada PR.                    [stack · kit]
bin/
  check-docs.sh           El guardián: 15 chequeos sobre la coherencia de la memoria.                [núcleo · kit]
  check-protocol.sh       En una rama de fase, el protocolo sólo cambia en commits (protocol).       [núcleo · kit]
  handoff.sh              Lo que una fase dejó dicho para la siguiente, y nada más.                  [núcleo · kit]
  measure-context.sh      Cuántos caracteres lee cada tipo de sesión al arrancar.                    [núcleo · kit]
  verify.sh               El único árbitro: gates, su orden y la baseline que nunca empeora.         [stack · kit]
  contract.sh             El contrato OpenAPI: lo genera y, con --check, es el gate «contrato».      [stack · kit]
docs/runbooks/release.md  Manifiesto de despliegue: lo que cada fase deja por hacer en producción.   [núcleo · semilla]
```

Además, cada stack trae lo suyo, en su `stack.json`:

- **Laravel:** las pruebas de arquitectura por capas (`tests/Architecture/ArchitectureTest.php`, del kit, y
  `ProjectArchitectureTest.php`, semilla), el baseline de rutas (`scripts/normalize-routes.php`), los errores RFC 9457
  (`App\Exceptions\ApiException` y `App\Http\ProblemDetails`, semillas, con su test de contrato), `.env.testing` para
  la suite contra PostgreSQL con PostGIS y `phpstan.neon` (semilla).
- **Next.js:** la regla de capas `app → features → entities → shared` (`eslint.layers.mjs`, del kit, que importa
  `eslint.config.mjs`, semilla), el cliente generado del OpenAPI en `src/shared/api/` (semilla), las configuraciones
  de Vitest y Playwright, los presupuestos de Lighthouse (`.ai/project/lighthouse.json`) y `docs/vendor/INDEX.md`.

## Instalación en un proyecto nuevo

### 1. El proyecto y sus herramientas

El kit da por hecho el stack de `.ai/RULES.md §Stack y versiones exactas`. Si el proyecto no usa alguno de esos
paquetes, quitar su fila de `RULES.md` es un cambio local que `install.sh --upgrade` enseñará como conflicto.

En cualquier stack hacen falta `git`, [gitleaks](https://github.com/gitleaks/gitleaks#installing) (gates «protocolo»
y «secretos») y `gh`, para que la fase abra su PR. En el VPS, `docs/vps/doctor.sh` dice qué falta; en la nube, los
instala el script de preparación ([`docs/modos.md`](docs/modos.md)).

**Laravel**

```bash
laravel new mi-proyecto --pest              # o composer create-project, y Pest en lugar de PHPUnit
cd mi-proyecto && git init
composer require dedoc/scramble
composer require --dev larastan/larastan
php artisan install:api                     # si expone una API
echo 8.4 > .php-version                     # la versión de PHP de la CI (.github/workflows/verify.yml)
```

- En `phpunit.xml`, borra las líneas que fijan `DB_CONNECTION` y `DB_DATABASE` (SQLite en memoria): la suite corre
  contra PostgreSQL con PostGIS, con la configuración de `.env.testing`, y el gate «suite» falla si siguen.
- En `tests/TestCase.php`, que ningún test llame a la red real (`.ai/rules/tests.md`):
  `Http::preventStrayRequests()` en el `setUp()`.

**Next.js**

```bash
npx create-next-app@latest mi-front --ts --eslint --app --src-dir
cd mi-front && git init
rm AGENTS.md CLAUDE.md eslint.config.mjs    # los de create-next-app: el kit trae los suyos
npm i zod openapi-fetch @tanstack/react-query zustand
npm i -D openapi-typescript vitest @playwright/test eslint-plugin-boundaries eslint-import-resolver-typescript
npm pkg set engines.node=22.x               # la versión de Node de la CI
```

En `next.config.*`, `agentRules: false`: desde Next 16.3, `next dev` lanzado por un agente escribe su bloque en
`AGENTS.md`, que es del kit, y el gate «protocolo» fallaría. `tsconfig.json` lleva `"strict": true`.

### 2. Instalar el kit

```bash
sh ai-protocol/install.sh --stack laravel --target mi-proyecto --dry-run   # qué haría
sh ai-protocol/install.sh --stack laravel --target mi-proyecto             # o --stack nextjs
```

Copia el núcleo y el stack sin pisar nada que ya exista en el proyecto (lo avisa con `!`), crea `.ai/project/` desde
su plantilla y escribe `.ai/protocol.lock` con las versiones y la suma de cada archivo.

### 3. Rellenar los datos del proyecto

Lo que depende del proyecto está en `.ai/project/` y en la memoria, marcado con `{{RELLENAR: …}}`, y cada marcador
dice qué va:

```bash
grep -rn '{{RELLENAR' CLAUDE.md .ai docs
```

| Archivo | Qué se rellena |
|---|---|
| `.ai/project/README.md` | Nombre del proyecto, contexto operativo y **repos hermanos** (`` `frontend` ``, `` `backend` ``… o `—`) |
| `.ai/project/DECISIONS.md` | Una fila por paquete de `.ai/RULES.md §Stack y versiones exactas`, con la versión exacta de `composer.json` / `package.json` |
| `.ai/project/ARCHITECTURE.md` | Lo que el proyecto deja fuera de alcance y su único mecanismo de autorización |
| `.ai/project/CONTRACT.md` | Cómo se autentica quien llama y qué cabeceras lleva toda petición |
| `.ai/project/GLOSSARY.md`, `FEATURES.md` | Términos del negocio y su nombre en el código (en inglés); mapa de funcionalidades |
| `.ai/project/SENSITIVE-ZONES.md`, `CROSS-CUTTING.md`, `COMMIT-SCOPES.md` | Zonas sensibles del negocio, idiomas y tenant, ámbitos de commit del dominio |
| `.ai/STATE.md`, `.ai/DOMAIN.md` | Nombre del proyecto y qué es, en dos o tres frases |

El guardián no deja pasar `bin/verify.sh` mientras quede un marcador o una versión que no coincida.

### 4. Lo que generan los scripts

**Laravel**

```bash
php artisan key:generate --env=testing                                 # la clave de .env.testing, que se versiona
sh bin/contract.sh                                                     # docs/contract/openapi.json
php scripts/normalize-routes.php > docs/contract/routes-baseline.txt  # el baseline de rutas
```

Registra los errores RFC 9457 en `bootstrap/app.php`, que es del proyecto: `ProblemDetails::register($exceptions);`
dentro de `->withExceptions(...)`. Si el proyecto corre en
Docker Compose, pon el servicio de PHP en `VERIFY_SERVICE`, en `.ai/project/verify.conf`: desde el host,
`bin/verify.sh` se relanza dentro del contenedor, que necesita `git` y gitleaks.

**Next.js**

```bash
sh bin/contract.sh    # src/shared/api/schema.d.ts desde la copia del OpenAPI del backend (docs/contract/openapi.json)
```

### 5. Primer verde y primer commit

```bash
bash bin/verify.sh
git add -A && git commit -m "chore(protocol): install ai-protocol"
```

En GitHub, un *ruleset* sobre `main` que exija PR y el check `verify`, y bloquee el push forzado y el borrado
(`docs/modos.md §Proteger main en GitHub`).

### 6. La primera épica

Con el agente: *«/plan-epic: la épica 01 —<objetivo>—»*, o *«/plan-epic .ai/stages/<id>.md»* si las tareas llegan de
un plan externo (§Tipos de tarea y planes externos). Después, `/phase`.

## Actualizar un proyecto

```bash
sh ai-protocol/install.sh --upgrade --target mi-proyecto --dry-run   # qué cambiaría, con los diffs
sh ai-protocol/install.sh --upgrade --target mi-proyecto
```

Toma el stack del lock y compara cada archivo del kit con la suma que guardó la última vez:

| Marca | Qué pasa | Qué hace |
|---|---|---|
| `~` actualizado | El proyecto no lo tocó y el kit trae otra versión | Lo sustituye y enseña el diff |
| `!` conflicto | El proyecto lo cambió y el kit también | Lo deja, enseña el diff y lo repite en cada upgrade hasta que el archivo coincide con el kit |
| `·` propio | El proyecto lo cambió y el kit no | Nada |
| `+` copiado | El kit trae un archivo nuevo | Lo copia |
| `-` retirado | El kit ya no lo trae | Lo borra si el proyecto no lo tocó; si lo tocó, avisa |

Nunca toca las semillas, que el lock marca `project`: la memoria (`STATE`, `DOMAIN`, `BACKLOG`, `PROTOCOL`, las
épicas), `.ai/project/` y la configuración que el proyecto ajusta. Si no hay nada que hacer, dice «sin cambios» y no
escribe nada. Un conflicto se resuelve llevando lo propio del proyecto a `.ai/project/` y quedándose con la versión
del kit: borra el archivo y repite el `--upgrade`, que lo copia de nuevo y guarda su suma. Lo que obliga a cambiar
algo a mano al subir de versión lo dice el `CHANGELOG.md` de cada paquete.

## Migrar desde 1.x

Un proyecto con el kit 1.x (la carpeta `laravel/` o `nextjs/` copiada con `cp -Rn`, con la «Versión del kit» en
`CLAUDE.md`) no tiene lock. Se actualiza diciendo su stack:

```bash
sh ai-protocol/install.sh --upgrade --stack laravel --target mi-proyecto --dry-run
sh ai-protocol/install.sh --upgrade --stack laravel --target mi-proyecto
```

Sin sumas anteriores, todo archivo del kit que difiere sale como conflicto, con su diff; lo nuevo (las skills, el
revisor, `.ai/project/`, `.ai/archive/`, `verify.conf`…) se copia, y la memoria no se toca (`tests/run.sh` lo prueba
con una instalación 1.x real, `tests/fixtures/kit-1x/`). Después, en un commit `chore(protocol): …`:

1. **La capa del proyecto.** Lo propio del proyecto que estaba en `CLAUDE.md` y en `.ai/RULES.md` (nombre, repos
   hermanos, versiones del stack, zonas sensibles, ámbitos de commit) pasa a `.ai/project/`. Después, cada archivo en
   conflicto toma la versión del kit: bórralo y repite el `--upgrade` hasta que no quede ninguno.
2. **La baseline.** `MIN_TESTS`, la deuda congelada y `VERIFY_SERVICE` salen de `bin/verify.sh` a
   `.ai/project/verify.conf`: copia los valores del proyecto antes de aceptar el `bin/verify.sh` nuevo.
3. **Lo que se retira.** Sin lock, el upgrade no sabe qué trajo la 1.x: borra a mano `.claude/commands/` (ahora son
   las skills `/phase` y `/close`) y `.ai/PLANNING.md` (ahora `/plan-epic` y `/plan-phase`).
4. **La memoria.** Lo cerrado que ya estaba en ella va a `.ai/archive/`: las filas cerradas de `BACKLOG.md`, las
   decisiones respondidas y reemplazadas de `DOMAIN.md` y las mejoras aplicadas de `PROTOCOL.md` (también la n.º 1,
   «Protocolo instalado»). «Últimos movimientos» de `STATE.md` se queda en 10 líneas como mucho. Hasta entonces,
   `sh bin/check-docs.sh --strict` falla en su chequeo «memoria».
5. **El stack.** Laravel: borra de `phpunit.xml` las líneas `DB_CONNECTION` y `DB_DATABASE`, registra `ProblemDetails`
   en `bootstrap/app.php`, genera la clave de `.env.testing` y el OpenAPI con `sh bin/contract.sh`, y añade
   `dedoc/scramble` a `.ai/project/DECISIONS.md`. Next.js: si `AGENTS.md` o `CLAUDE.md` eran los de create-next-app,
   valen los del kit; `eslint.config.mjs` importa `eslint.layers.mjs`; `next.config.*` lleva `agentRules: false`;
   instala los paquetes nuevos de `.ai/RULES.md §Stack y versiones exactas` y corre `sh bin/contract.sh`. El detalle,
   en «Al actualizar un proyecto» del `CHANGELOG.md` de cada stack.

Las fases escritas con la plantilla 1.x siguen pasando el guardián: sin «Tipo» cuentan como de código, y sin
«Revisión» no se les exige. `.ai/STATE.md` no necesita `§Esperando evidencia` hasta que una fase quede en
`ESPERA_EVIDENCIA`.

## Roles

Cada rol es una sesión distinta, con su skill, y lee sólo lo que necesita (`bin/measure-context.sh` lo mide).

| Rol | Skill | Qué hace |
|---|---|---|
| **Planificador** | `/plan-epic`, `/plan-phase` | Escribe la épica (objetivo, fuera de alcance, contrato, fases, criterio de cierre) y cada fase (3–7 entregables, archivos, criterios ejecutables, plan de commits), las filas del mapa en `STATE.md` y las decisiones pendientes en `DOMAIN.md` |
| **Ejecutor** | `/phase` | Una sesión por fase (abajo) |
| **Revisor** | `/review` | Un subagente de solo lectura que no ve la conversación: compara el diff de la rama con los entregables, los criterios y su evidencia, las reglas, `.ai/project/`, las zonas sensibles y el alcance, y escribe sus hallazgos en la sección «Revisión» de la fase. Con un bloqueante abierto, la fase no se cierra |
| **Rescate** | `/close` | Documenta lo que de verdad hizo una sesión que se cortó, sin completar nada |
| **Persona** | — | Aprueba el Paso A, responde los STOP & ASK, aporta la evidencia `[humano]`, dice al cierre qué mejoraría del protocolo y revisa y fusiona cada PR |

**`/phase`**, paso a paso:

- **Paso 0:** resuelve la fase activa de `.ai/STATE.md` y su rama `phase/<NN-slug>/<FF>`.
- **Paso A:** lectura en frío, revalidación contra el código, y **se para** a esperar tu visto bueno.
- **Paso B:** un commit por fila del plan, cada uno con `bash bin/verify.sh --fast` en verde.
- **Paso C:** `bash bin/verify.sh` completo, el RESULTADO de la fase (sobre todo «Lo que la siguiente fase necesita
  saber», que la siguiente lee con `bin/handoff.sh`; las salidas de más de 40 líneas, en `evidence/`), `/review`,
  estado y puntero, memoria al día y archivada, commit de cierre y la **entrega**: push de la rama y PR con la
  plantilla. El chat sólo da cinco líneas que apuntan al RESULTADO y al PR.

Cuando el agente no puede decidir algo (contrato, producto, arquitectura, un criterio que no se puede cumplir tal
como está escrito), para con un **STOP & ASK**: opciones, consecuencias y su recomendación. La respuesta queda
escrita en la fase y, si sobrevive a ella, en `.ai/DOMAIN.md`.

## Tipos de tarea y planes externos

- **Tipo de tarea** (`> **Tipo:**` en la cabecera de la fase): `código`, el de siempre; `operación` (scripts,
  configuración y runbook versionados, y lo que sólo la persona puede comprobar en casillas `[humano]`); o
  `validación externa`. Una fase de los dos últimos tipos cierra en `ESPERA_EVIDENCIA` hasta que la persona aporta su
  evidencia (`/phase <epica> <FF>`): el puntero la salta mientras tanto, `STATE.md §Esperando evidencia` la nombra y
  la épica no se cierra.
- **Fase ligera** (`> **Modo:** ligero`): uno o dos entregables, sin cambio de contrato ni migraciones; no se para en
  el Paso A si no hay preguntas, y el cierre es reducido.
- **Desde un plan externo:** la persona copia la parte que toca a este repo en `.ai/stages/<id>.md` (una tabla con ID,
  tarea, repo, criterio de aceptación y dependencias, más las decisiones vigentes), y `/plan-epic` la convierte en
  una épica con una fase por tarea. Cada fase lleva `> **Tarea externa:** <ID>` y el criterio copiado literal; las
  tareas no se replanifican, y el guardián comprueba que cada una existe en su paquete.

## Modos de ejecución

Una fase corre por defecto en un VPS propio, con Remote Control en modo servidor (`claude remote-control --spawn
worktree`): cada sesión, en su worktree, y se maneja desde la app de Claude. La nube (claude.ai/code, la app o
`claude --cloud`) queda de respaldo y el local, con Docker Compose o con Remote Control, como opción. Termina siempre
igual: rama `phase/<NN-slug>/<FF>` en GitHub, PR y la CI del proyecto repitiendo `bin/verify.sh` completo; la persona
revisa y fusiona. El agente sólo empuja la rama de la fase: nunca a `main`, nunca forzado, y nunca fusiona. Qué hace
falta en cada modo, cómo preparar el VPS (y aislarlo de staging), el script de la nube y cómo proteger `main`:
[`docs/modos.md`](docs/modos.md).

**La protección del protocolo.** Una fase no cambia los archivos del kit (`.ai/WORKFLOW.md §Archivos del
protocolo`): en una rama de fase, el gate «protocolo» de `bin/verify.sh` (`bin/check-protocol.sh`) falla si un commit
sin ámbito `protocol` toca un archivo que `.ai/protocol.lock` marca `kit`. Lo que marca `project` es libre.

## Un backend Laravel y un frontend Next.js

Instala un stack en cada repo y declara al otro en `.ai/project/README.md §Repos hermanos`. Entonces:

- Cada repo **lee** el código del otro cuando duda del contrato, pero **no escribe** en él ni cita sus documentos.
- El contrato es el OpenAPI que Laravel genera en `docs/contract/openapi.json`; Next.js guarda una copia en la misma
  ruta y genera de ella su cliente. Los errores son `application/problem+json` (RFC 9457) con la extensión `code`.
- Una fase que cambia lo que el otro consume deja un **traspaso**: una fila de `.ai/BACKLOG.md` con Área = el otro
  repo, `**Cambio:**`, `**Origen:**` (`fase NN/FF`) y, si aplica, `**Despliegue:**`. Aparece en
  `.ai/STATE.md §Pendientes en otros repos` hasta que lo cierras. El guardián no deja cerrar una fase que cambió el
  contrato sin su traspaso (o sin decir por qué no hace falta).
- Lo que un repo entrega al otro llega copiado a `.ai/handoffs/<fecha>-<tema>/`.

## Qué comprueba el guardián

`sh bin/check-docs.sh --strict`, el primer gate de `bin/verify.sh`: instalación completa, sin marcadores; el puntero
de `STATE.md` en la primera fase sin terminar; el estado, la cabecera (tipo, modo, tarea externa), el plan de commits,
las dependencias, la revisión y el RESULTADO de cada fase; el estado de cada épica frente a sus fases; que las fases,
decisiones, rutas, secciones y evidencias citadas existen; el manifiesto de despliegue; los traspasos; los
contadores de `STATE.md`; las versiones de `.ai/project/DECISIONS.md` frente a los manifiestos; que no se citen
documentos del repo hermano; que la memoria activa sólo guarde lo vigente; y que cada tarea externa está en un
paquete con su criterio literal en la fase. Corre igual en el host que en Alpine (busybox).

Su cabecera explica cómo provocar cada fallo. `tests/run.sh` los provoca todos en los dos stacks sobre una
instalación de prueba, y los e2e, sobre un proyecto de verdad.

## Versiones y etiquetas

Cada paquete se versiona por separado con [SemVer](https://semver.org/lang/es/): el núcleo en `core/core.json` y
cada stack en su `stack.json`. Ésa es la única fuente de la versión; este README no la repite. Lo que cambió en cada
una está en el `CHANGELOG.md` del paquete.

- **Etiquetas:** `core-vX.Y.Z`, `laravel-vX.Y.Z`, `nextjs-vX.Y.Z`. Las crea quien fusiona, sobre el commit de `main`
  que publica la versión.
- **Compatibilidad:** cada `stack.json` declara en `core` el rango del núcleo con el que funciona
  (`">=2.0.0 <3.0.0"`), e `install.sh` no instala una combinación fuera de rango.
- **Qué sube cada número.** Mayor: algo que obliga al proyecto a cambiar (una sección que se renombra y el guardián
  exige, un archivo que se mueve, un chequeo que antes no fallaba). Menor: una regla, un chequeo o un archivo nuevo
  que no rompe una instalación al día. Parche: correcciones de texto y de scripts sin cambio de comportamiento.
- **Mientras se prepara una versión**, los paquetes que cambian llevan el sufijo `-dev` y su `CHANGELOG.md` acumula
  los cambios en «Sin publicar». Al publicar se quita el sufijo y la sección toma la versión y la fecha.
- **En el proyecto**, `.ai/protocol.lock` dice qué versiones están instaladas y con qué suma se copió cada archivo.

## Separar un stack con su historial

Un stack no cita archivos de otro stack (`tests/structure.sh` lo comprueba), así que se puede llevar a su propio
repo con [git filter-repo](https://github.com/newren/git-filter-repo), sobre un clon nuevo:

```bash
git clone https://github.com/<org>/ai-protocol ai-protocol-laravel && cd ai-protocol-laravel
git filter-repo --subdirectory-filter stacks/laravel
```

El repo nuevo tiene en su raíz lo que había en `stacks/laravel/`, con la historia de esa carpeta (desde que existe,
la 2.0). Para conservar también la de la 1.x, cuando el stack vivía en `laravel/`:

```bash
git filter-repo --path laravel/ --path stacks/laravel/ --path-rename laravel/: --path-rename stacks/laravel/:
```

El stack separado sigue necesitando un núcleo en su rango y un instalador: `core/` e `install.sh` se quedan aquí (o se
separan igual, con `--path core/ --path install.sh`).

## Mantener el kit

- **Una regla vive en un solo archivo**; los demás la citan por el nombre de su sección, nunca por su número. Si una
  regla puede incumplirse en silencio, se le añade un chequeo a `bin/check-docs.sh` y su caso a `tests/lib.sh`, que lo
  prueba en las dos direcciones (falla con el defecto, pasa sin él).
- **Lo común va en `core/`, una sola vez;** lo de un stack, en su carpeta. Un archivo nuevo entra en el manifiesto de
  su paquete, en `files` o en `seed`. `sh tests/structure.sh` falla si un manifiesto no lista exactamente los archivos
  de su carpeta, si un stack sobrescribe el núcleo o cita archivos de otro stack, o si los gates de `stack.json` no
  son los de su `verify.sh`.
- **Lo propio de un proyecto no entra en el kit:** va a `core/.ai/project/` como plantilla con `{{RELLENAR}}`, y las
  reglas lo citan.
- **La CI del kit** (`.github/workflows/kit.yml`) corre en cada PR:
  - `shellcheck -s sh` sobre los scripts y `actionlint` sobre sus workflows y los de cada stack.
  - `sh tests/structure.sh`, y `sh tests/run.sh` en el host y en Alpine (busybox, con git): instala cada stack con
    la épica de prueba, provoca cada fallo del guardián, prueba el instalador (también el upgrade de una instalación
    1.x sin tocar su memoria), la protección del protocolo (también dentro de un git worktree), el contexto de
    arranque, `docs/vps/doctor.sh` con un `PATH` de stubs y que cada ruta que cita `docs/guia.md` existe.
  - `e2e-laravel` y `e2e-nextjs` (`sh tests/e2e-<stack>.sh`): crean un proyecto nuevo de verdad, instalan el stack,
    generan la épica de prueba desde el paquete `tests/fixtures/stages/E1.md`, pasan el guardián y `bin/verify.sh`
    completo (Laravel, con la suite contra PostgreSQL con PostGIS; Next.js, con `next build` y Lighthouse CI), y
    provocan los fallos propios del stack (capas o arquitectura y contrato) y todos los del guardián.
- **El contexto no crece sin decidirlo.** `tests/context-baseline.txt` guarda lo que leen al arrancar el ejecutor de
  cada stack y `CLAUDE.md`. `tests/run.sh` falla si una sesión crece más de un 3 % y avisa si baja más de un 3 %;
  subir la línea base es cambiar ese archivo en un PR que explique por qué.
- **Las mejoras vienen de los proyectos.** Cada proyecto acumula las suyas en `.ai/PROTOCOL.md`; las que no son
  propias de ese proyecto se suben aquí como issue (§Principios).
- **Cada cambio se anota** en el `CHANGELOG.md` del paquete que toca, en «Sin publicar».
