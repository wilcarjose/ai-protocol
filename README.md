# ai-protocol — protocolo de trabajo con IA por épicas y fases

Kit para que un proyecto nuevo **Laravel** o **Next.js** trabaje con agentes de IA (Claude Code, Cursor, Codex…)
desde el primer día: el trabajo se planifica en **épicas** partidas en **fases**, cada fase se ejecuta en una sesión
que empieza **en frío**, y unos archivos `.md` hacen de memoria entre sesiones. Un guardián (`bin/check-docs.sh`)
comprueba que esa memoria no miente, y un único árbitro (`bin/verify.sh`) decide si el código está sano.

Sale del protocolo que se construyó en el backend y el frontend de Kiniela Pro, unificado en una sola versión con lo
mejor de cada repo y sin nada propio de ese proyecto.

El kit son tres capas: un **núcleo** común (`core/`), un **stack** por tecnología (`stacks/<stack>/`) y la **capa del
proyecto** (`.ai/project/`), que el instalador crea una vez y después nunca toca. Cada paquete lleva su versión
(§Versiones y etiquetas).

## Qué hay en el kit

```
core/                     El núcleo: protocolo, memoria y guardián. Igual para todos los stacks.
  core.json               Su versión y sus archivos.
stacks/<stack>/           Lo que añade cada stack: reglas, plantillas, verify.sh, permisos.
  stack.json              Su versión, sus archivos, el rango del núcleo con el que es compatible y sus gates.
stacks/expo/              Sólo un README que anuncia el stack.
install.sh                Instala o actualiza núcleo + stack en un proyecto.
tests/                    Las pruebas del kit: structure.sh, run.sh y sus fixtures.
docs/                     Planes y documentación del propio kit.
```

Lo que queda en el proyecto al instalar. **Kit** es lo que `install.sh --upgrade` actualiza; **semilla**, lo que sólo
se copia si falta y después es del proyecto.

```
CLAUDE.md                 Punto de entrada: lectura en frío, alcance, prohibiciones y punteros.    [núcleo · kit]
AGENTS.md                 Redirección a CLAUDE.md para Cursor, Codex, aider…                       [núcleo · kit]
.ai/
  RULES.md                El núcleo de las reglas de código: stack, alcance, contrato, lista negra. [stack · kit]
  rules/                  Las reglas por tema (arquitectura, tests…), que la fase cita si las toca.  [stack · kit]
  WORKFLOW.md             Protocolo del ejecutor: ciclo, criterios de parada, STOP & ASK.           [núcleo · kit]
  STATE.md                El puntero: fase activa, mapa de fases, bloqueos.                          [núcleo · semilla]
  DOMAIN.md               Glosario y decisiones vigentes. Lo decidido no se pregunta.                [núcleo · semilla]
  BACKLOG.md              Hallazgos abiertos fuera de alcance y pendientes en otros repos.           [núcleo · semilla]
  PROTOCOL.md             Mejoras del protocolo que propone cada fase, pendientes de aplicar.        [núcleo · semilla]
  archive/                Lo cerrado de la memoria: backlog, decisiones reemplazadas, mejoras.      [núcleo · semilla]
  project/                La capa del proyecto: contexto, versiones, alcance, contrato, zonas…      [núcleo · semilla]
  project/verify.conf     La baseline de bin/verify.sh y, en Laravel, el servicio de Docker Compose. [stack · semilla]
  templates/              Plantillas de épica y de fase.                                             [stack · kit]
  stages/                 Paquetes de tareas de un plan externo; su README dice el formato.         [núcleo · kit]
  epics/                  Las épicas y sus fases, con su evidence/ (vacía al instalar).             [núcleo · semilla]
  handoffs/               Entregas del repo hermano, copiadas.                                       [núcleo · kit]
  protocol.lock           Lo que instaló install.sh: versiones, suma y «kit» o «project» por archivo. [install.sh]
.claude/
  skills/phase/           /phase — ejecuta la fase activa: rama, pasos, commits; cierre.md, el cierre. [núcleo · kit]
  skills/close/           /close — documenta una fase que otra sesión dejó a medias.                 [núcleo · kit]
  skills/plan-epic/       /plan-epic — crea o cambia una épica, también desde un paquete de tareas.  [núcleo · kit]
  skills/plan-phase/      /plan-phase — crea o cambia una fase: corte, tipo de tarea, coherencia.    [núcleo · kit]
  skills/review/          /review — lanza el revisor y escribe sus hallazgos en la fase.             [núcleo · kit]
  agents/reviewer.md      El revisor IA: subagente de solo lectura que compara el diff con la fase.  [núcleo · kit]
  settings.json           Permisos del agente: qué ejecuta sin preguntar y qué nunca (push a main…). [stack · kit]
.github/
  pull_request_template.md  La plantilla del PR de cada fase.                                       [núcleo · kit]
  workflows/verify.yml    La CI: bin/verify.sh completo en cada PR.                                   [stack · kit]
bin/
  check-docs.sh           El guardián: 15 chequeos sobre la coherencia de la memoria.                [núcleo · kit]
  check-protocol.sh       En una rama de fase, el protocolo sólo cambia en commits (protocol).       [núcleo · kit]
  handoff.sh              Lo que una fase dejó dicho para la siguiente, y nada más.                  [núcleo · kit]
  measure-context.sh      Cuántos caracteres lee cada tipo de sesión al arrancar.                    [núcleo · kit]
  verify.sh               El único árbitro: gates, su orden y la baseline que nunca empeora.         [stack · kit]
docs/
  README.md               Qué va en cada carpeta de docs/.                                           [stack · semilla]
  runbooks/release.md     Manifiesto de despliegue: lo que cada fase deja por hacer en producción.   [núcleo · semilla]
```

Además, propios de cada stack:

- **Laravel:** `tests/Architecture/ArchitectureTest.php` (las reglas de Actions y Value Objects, con el plugin de
  arquitectura de Pest), `scripts/normalize-routes.php` (baseline de rutas del contrato HTTP) y `phpstan.neon`
  (semilla: el proyecto lo ajusta).
- **Next.js:** `docs/vendor/INDEX.md` (índice de notas de las librerías en la versión instalada; semilla).

## Instalación en un proyecto nuevo

### 1. El proyecto y sus herramientas

El kit da por hecho el stack de su `RULES.md` (`.ai/RULES.md §Stack y versiones exactas`). Instálalo. Si el proyecto
no usa alguno de esos paquetes, quitar su fila de `RULES.md` es un cambio local que `install.sh --upgrade` enseñará
como conflicto.

Además, en cualquier stack: `git` y [gitleaks](https://github.com/gitleaks/gitleaks#installing), que usan los
gates «protocolo» y «secretos» de `bin/verify.sh`, y `gh` para que la fase abra su PR. En la nube los instala el
script de preparación (`docs/modos.md`).

**Laravel**

```bash
laravel new mi-proyecto --pest        # o composer create-project; con Pest, no PHPUnit
cd mi-proyecto && git init
composer require --dev larastan/larastan
php artisan install:api               # si expone una API
echo 8.4 > .php-version               # la versión de PHP de la CI (.github/workflows/verify.yml)
```

En `tests/TestCase.php`, que ningún test llame a la red real (`.ai/RULES.md §Tests`):

```php
protected function setUp(): void
{
    parent::setUp();

    \Illuminate\Support\Facades\Http::preventStrayRequests();
}
```

**Next.js**

```bash
npx create-next-app@latest mi-front --typescript --eslint --app --src-dir
cd mi-front && git init
npm i zod @tanstack/react-query zustand
npm i -D vitest eslint-plugin-boundaries
```

La regla de capas de `.ai/RULES.md §Estructura y regla de dependencias` (`app → features → entities → shared`) se
configura en `eslint.config.mjs` con `eslint-plugin-boundaries`, y `tsconfig.json` lleva `"strict": true`. La CI toma
la versión de Node de `"engines": { "node": "…" }` en `package.json`.

### 2. Instalar el kit

```bash
sh ai-protocol/install.sh --stack laravel --target mi-proyecto --dry-run   # qué haría
sh ai-protocol/install.sh --stack laravel --target mi-proyecto             # o --stack nextjs
```

Copia el núcleo y el stack sin pisar nada que ya exista en el proyecto (lo avisa con `!`), crea `.ai/project/` desde
su plantilla y escribe `.ai/protocol.lock` con las versiones y la suma de cada archivo. Los proyectos no dependen de
este repo para funcionar: todo lo que necesitan queda copiado.

### 3. Rellenar los datos del proyecto

Todo lo que depende del proyecto está en `.ai/project/` y en la memoria, marcado con `{{RELLENAR: …}}`, y cada
marcador dice qué va:

```bash
grep -rn '{{RELLENAR' CLAUDE.md .ai docs
```

| Archivo | Qué se rellena |
|---|---|
| `.ai/project/README.md` | Nombre del proyecto, contexto operativo y **repos hermanos** (`` `frontend` ``, `` `backend` ``… o `—`) |
| `.ai/project/DECISIONS.md` | Una fila por paquete de `.ai/RULES.md §Stack y versiones exactas`, con la versión exacta de `composer.json` / `package.json` |
| `.ai/project/ARCHITECTURE.md` | Lo que el proyecto deja fuera de alcance y su único mecanismo de autorización |
| `.ai/project/CONTRACT.md` | Cómo se autentica quien llama y qué cabeceras lleva toda petición |
| `.ai/project/SENSITIVE-ZONES.md`, `CROSS-CUTTING.md`, `COMMIT-SCOPES.md` | Zonas sensibles del negocio, idiomas y tenant, ámbitos de commit del dominio |
| `.ai/STATE.md`, `.ai/DOMAIN.md` | Nombre del proyecto y qué es, en dos o tres frases |

El guardián no deja pasar `bin/verify.sh` mientras quede un marcador o una versión que no coincida.

### 4. Lo que generan los scripts (Laravel)

```bash
php scripts/normalize-routes.php > docs/contract/routes-baseline.txt
```

Si el proyecto corre en Docker Compose, pon el nombre del servicio de PHP en `VERIFY_SERVICE`, en
`.ai/project/verify.conf`: desde el host, `bin/verify.sh` se relanza dentro del contenedor, que necesita `git` y
gitleaks. Ese archivo es del proyecto, como la baseline que mueven las fases (`MIN_TESTS` y la deuda congelada), así
que `bin/verify.sh` queda entero del kit.

### 5. Primer verde y primer commit

```bash
bash bin/verify.sh
git add -A && git commit -m "chore(protocol): install ai-protocol"
```

En GitHub, un *ruleset* sobre `main` que exija PR y el check `verify`, y bloquee el push forzado y el borrado
(`docs/modos.md §Proteger main en GitHub`).

### 6. La primera épica

Con el agente: *«/plan-epic: la épica 01 —<objetivo>—»*, o *«/plan-epic .ai/stages/<id>.md»* si las tareas llegan
de un plan externo (§Cómo se trabaja). Quien planifica escribe el epic-plan y, con `/plan-phase`, las fases, las
filas del mapa en `.ai/STATE.md` y las decisiones pendientes en `.ai/DOMAIN.md`, y deja el puntero en la primera fase
lista. Después, `/phase`.

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
épicas), `.ai/project/` (con `verify.conf`), los registros que llenan las fases y la configuración que el proyecto
ajusta (`phpstan.neon`, `docs/README.md`). Si no hay nada que hacer, dice «sin cambios» y no escribe nada.

Un proyecto instalado con el kit 1.x (copiado con `cp`, sin lock) se actualiza con `--upgrade --stack <stack>`: sin
sumas anteriores, todo archivo que difiere del kit sale como conflicto.

**Al pasar a 2.0**, el upgrade trae `.ai/archive/` y el chequeo «memoria» del guardián, pero no toca la memoria: lo
cerrado que ya estaba en ella (las filas cerradas de `BACKLOG.md`, las respondidas y reemplazadas de `DOMAIN.md`, las
mejoras aplicadas de `PROTOCOL.md` —la n.º 1, «Protocolo instalado», también— y lo que pase de 10 líneas en
`STATE.md §Últimos movimientos`) se mueve a mano, en un commit `chore(protocol): …`, hasta que
`sh bin/check-docs.sh --strict` pase. `/phase` y `/close` pasan de `.claude/commands/` a `.claude/skills/`, y
`.ai/PLANNING.md` a las skills `/plan-epic` y `/plan-phase`: el upgrade retira los viejos si el proyecto no los
cambió. Las fases escritas con la plantilla anterior no llevan «Tipo» ni «Revisión»: cuentan como de código y el
guardián no les exige revisión. `.ai/STATE.md` no necesita `§Esperando evidencia` hasta que una fase quede en
`ESPERA_EVIDENCIA`. La baseline sale de `bin/verify.sh` a `.ai/project/verify.conf`: el upgrade crea éste con los
valores por defecto, y los del proyecto (y `VERIFY_SERVICE`) se copian a mano antes de aceptar el `bin/verify.sh`
nuevo.

## Cómo se trabaja

1. **Planificar.** `/plan-epic`: épica con objetivo, fuera de alcance, contrato, fases y criterio de cierre.
   `/plan-phase`: cada fase con un objetivo, 3–7 entregables, archivos, criterios de éxito ejecutables y plan de
   commits.
   - **Desde un plan externo:** la persona copia la parte que toca a este repo en `.ai/stages/<id>.md` (una tabla
     con ID, tarea, repo, criterio de aceptación y dependencias, más las decisiones vigentes), y `/plan-epic` la
     convierte en una épica con una fase por tarea. Cada fase lleva `> **Tarea externa:** <ID>` y el criterio
     copiado literal; las tareas no se replanifican.
   - **Tipo de tarea** (`> **Tipo:**`): `código`; `operación` (scripts, configuración y runbook versionados; lo que
     sólo la persona puede comprobar va en casillas `[humano]`); o `validación externa`. Una fase de los dos últimos
     tipos cierra en `ESPERA_EVIDENCIA` hasta que la persona aporta su evidencia; el puntero la salta mientras
     tanto y `STATE.md §Esperando evidencia` la nombra.
   - **Fase ligera** (`> **Modo:** ligero`): uno o dos entregables, sin cambio de contrato ni migraciones; no se
     para en el Paso A si no hay preguntas, y el cierre es reducido.
2. **`/phase`** — una sesión por fase:
   - **Paso 0:** resuelve la fase activa de `.ai/STATE.md` y su rama `phase/<NN-slug>/<FF>`.
   - **Paso A:** lectura en frío, revalidación contra el código, y **se para** a esperar tu visto bueno.
   - **Paso B:** un commit por fila del plan, cada uno con `bash bin/verify.sh --fast` en verde.
   - **Paso C:** `bash bin/verify.sh` completo, RESULTADO de la fase (sobre todo «Lo que la siguiente fase necesita
     saber», que la siguiente lee con `bin/handoff.sh`; las salidas de más de 40 líneas, en `evidence/`),
     **`/review`**, estado y puntero, memoria al día y archivada, commit de cierre, y la **entrega**: push de la rama
     y PR con la plantilla. El chat sólo da cinco líneas que apuntan al RESULTADO y al PR.
   - **El revisor** (`.claude/agents/reviewer.md`) es un subagente de solo lectura que no ve la conversación:
     compara el diff de la rama con los entregables, los criterios y su evidencia, las reglas, `.ai/project/`, las
     zonas sensibles y el alcance, y `/review` escribe sus hallazgos en la sección «Revisión» de la fase. Con un
     bloqueante sin resolver, la fase no se cierra.
3. **Revisar el PR**, con la CI en verde, y decidir el merge. El agente sólo empuja la rama de la fase: nunca a
   `main`, nunca forzado, y nunca fusiona.
4. **`/close`** si una sesión se cortó: documenta lo que de verdad pasó, sin completar nada.

Cuando el agente no puede decidir algo (contrato, producto, arquitectura, un criterio que no se puede cumplir tal
como está escrito), para con un **STOP & ASK**: opciones, consecuencias y su recomendación. La respuesta queda
escrita en la fase y, si sobrevive a ella, en `.ai/DOMAIN.md`.

## Dónde corre una fase

En la nube por defecto (Claude Code en claude.ai/code, la app o `claude --cloud`), o en local, con Docker Compose o
con Remote Control. Termina siempre igual: rama `phase/<NN-slug>/<FF>` en GitHub, PR y la CI repitiendo
`bin/verify.sh`. Qué hace falta en cada modo, el script de preparación de la nube y cómo proteger `main`:
[`docs/modos.md`](docs/modos.md).

**La protección del protocolo.** Una fase no cambia los archivos del kit (`.ai/WORKFLOW.md §Archivos del
protocolo`): en una rama de fase, el gate «protocolo» de `bin/verify.sh` (`bin/check-protocol.sh`) falla si un
commit sin ámbito `protocol` toca un archivo que `.ai/protocol.lock` marca `kit`. Lo que marca `project` es libre.

## Un backend Laravel y un frontend Next.js

Instala un stack en cada repo y declara al otro en `.ai/project/README.md §Repos hermanos`. Entonces:

- Cada repo **lee** el código del otro cuando duda del contrato, pero **no escribe** en él ni cita sus documentos.
- Una fase que cambia lo que el otro consume deja un **traspaso**: una fila de `.ai/BACKLOG.md` con Área = el otro
  repo, `**Cambio:**`, `**Origen:**` (`fase NN/FF`) y, si aplica, `**Despliegue:**`. Aparece en
  `.ai/STATE.md §Pendientes en otros repos` hasta que lo cierras. El guardián no deja cerrar una fase que cambió el
  contrato sin su traspaso (o sin decir por qué no hace falta).
- Lo que un repo entrega al otro llega copiado a `.ai/handoffs/<fecha>-<tema>/`.

## Qué comprueba el guardián

`sh bin/check-docs.sh --strict` (primer gate de `bin/verify.sh`): instalación completa, sin marcadores en la memoria
ni en `.ai/project/`; el puntero de `STATE.md` apunta a la primera fase sin terminar; el estado de cada fase coincide en su archivo y en el mapa; la cabecera, el
plan de commits, las dependencias y el RESULTADO de cada fase; el estado de cada épica frente a sus fases y su
criterio de cierre; que las fases citadas existen; el manifiesto de despliegue; los traspasos; los contadores de
`STATE.md` frente a `DOMAIN.md` y `BACKLOG.md`; los destinos del backlog; las versiones de `.ai/project/DECISIONS.md`
frente a los manifiestos; que no se citen documentos del repo hermano; que las rutas y secciones citadas existan; que
cada evidencia enlazada exista; y que la memoria activa sólo guarde lo vigente, con lo cerrado en `.ai/archive/` y
como mucho 10 líneas en «Últimos movimientos». También el tipo y el modo de cada fase, sus casillas `[humano]`, el
estado `ESPERA_EVIDENCIA` y `STATE.md §Esperando evidencia`, que una fase cerrada pasó por `/review` sin bloqueantes
abiertos, y que cada tarea externa está en un paquete de `.ai/stages/` con su criterio literal en la fase. Corre igual
en el host que en un contenedor Alpine (busybox).

Su cabecera explica cómo provocar cada fallo, y `sh tests/run.sh` lo hace en los dos stacks: instala cada uno con
`install.sh` y una épica de prueba, comprueba que el guardián pasa y que cada fallo provocado lo hace saltar con su
mensaje.

## Diferencias con el protocolo de Kiniela Pro

Para quien venga de esos repos:

- **Un solo protocolo** para los dos stacks; lo que cambia por stack está en `RULES.md`, las plantillas,
  `verify.sh`, `settings.json` y `docs/`.
- **La baseline vive en `.ai/project/verify.conf`** (`MIN_TESTS` y la deuda congelada), no en `STATE.md`. Laravel gana el modo
  `--fast` y un gate de deuda de PHPStan que sólo mengua.
- **Sin páginas de seguimiento** (Artifacts): el archivo de la fase es el único registro.
- **`STATE.md`** lleva siempre `Pendientes en otros repos: N (M condicionan el despliegue)`, y el guardián comprueba
  que los contadores, `§Bloqueo activo` y la tabla de pendientes cuadran con `DOMAIN.md` y `BACKLOG.md`.
- **`BACKLOG.md`** con `Impacto`, `Destino` y `Cerrado por`, y la regla de triaje en la skill `/plan-epic`.
- **`DOMAIN.md §Decisiones pendientes`** con ids `D<n>` y las columnas `Categoría`, `Bloquea`, `Propuesto por`.
- **Commits de fase** `chore(phase-<NN>-<FF>): start | resume | close`, con épica y fase en el ámbito.
- **Criterios de parada** unificados (`WORKFLOW.md §Contrato`–`§2.10`); los propios del dominio se declaran en
  `RULES.md §Zonas sensibles`.
- **Sin listas de deuda congelada** (`handoff-allowlist.txt`, `crossrepo-allowlist.txt`): un proyecto nuevo empieza
  limpio y los chequeos no toleran excepciones.

## Versiones y etiquetas

Cada paquete se versiona por separado con [SemVer](https://semver.org/lang/es/): el núcleo en `core/core.json` y
cada stack en su `stack.json`. Ésa es la única fuente de la versión; este README no la repite.

- **Etiquetas:** `core-vX.Y.Z`, `laravel-vX.Y.Z`, `nextjs-vX.Y.Z`. Las crea quien fusiona, sobre el commit de `main`
  que publica la versión.
- **Compatibilidad:** cada `stack.json` declara en `core` el rango del núcleo con el que funciona
  (`">=2.0.0 <3.0.0"`), e `install.sh` no instala una combinación fuera de rango. Un stack depende sólo del núcleo,
  nunca de otro stack.
- **Qué sube cada número.** Mayor: algo que obliga al proyecto a cambiar (una sección que se renombra y el guardián
  exige, un archivo que se mueve, un chequeo que antes no fallaba). Menor: una regla, un chequeo o un archivo nuevo
  que no rompe una instalación al día. Parche: correcciones de texto y de scripts sin cambio de comportamiento.
- **Mientras se prepara una versión**, los paquetes llevan el sufijo `-dev` (`2.0.0-dev`) y su `CHANGELOG.md` acumula
  los cambios en «Sin publicar». Al publicar se quita el sufijo y la sección toma la versión y la fecha.
- **En el proyecto**, `.ai/protocol.lock` dice qué versiones están instaladas y con qué suma se copió cada archivo.

## Mantener el kit

- **Una regla vive en un solo archivo**; los demás la citan por el nombre de su sección, nunca por su número. Si una
  regla puede incumplirse en silencio, se le añade un chequeo a `bin/check-docs.sh` y su caso a `tests/run.sh`, que
  lo prueba en las dos direcciones (falla con el defecto, pasa sin él).
- **Lo común va en `core/`, una sola vez;** lo de un stack, en su carpeta. Un archivo nuevo entra en el manifiesto de
  su paquete, en `files` o en `seed`. `sh tests/structure.sh` falla si un manifiesto no lista exactamente los archivos
  de su carpeta, si un stack sobrescribe el núcleo o cita archivos de otro stack, o si los gates de `stack.json` no
  son los de su `verify.sh`.
- **Lo propio de un proyecto no entra en el kit:** va a `core/.ai/project/` como plantilla con `{{RELLENAR}}`, y las
  reglas lo citan.
- **La CI del kit** (`.github/workflows/kit.yml`) corre en cada PR `shellcheck -s sh` sobre los scripts, `actionlint`
  sobre sus workflows y los de cada stack, `sh tests/structure.sh` y `sh tests/run.sh`, también dentro de Alpine
  (busybox, con git).
- **El contexto no crece sin decidirlo.** `tests/context-baseline.txt` guarda lo que leen al arrancar el ejecutor
  de cada stack y `CLAUDE.md`, medido con `bin/measure-context.sh` sobre una instalación limpia. `tests/run.sh` falla
  si una sesión crece más de un 3 % y avisa si baja más de un 3 %; subir la línea base es cambiar ese archivo en un
  PR que explique por qué.
- **Las mejoras vienen de los proyectos.** Cada proyecto acumula las suyas en `.ai/PROTOCOL.md`; las que no son
  propias de ese proyecto se suben aquí.
- **Cada cambio se anota** en el `CHANGELOG.md` del paquete que toca, en «Sin publicar».
