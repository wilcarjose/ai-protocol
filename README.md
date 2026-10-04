# ai-protocol — protocolo de trabajo con IA por épicas y fases

Kit para que un proyecto nuevo **Laravel** o **Next.js** trabaje con agentes de IA (Claude Code, Cursor, Codex…)
desde el primer día: el trabajo se planifica en **épicas** partidas en **fases**, cada fase se ejecuta en una sesión
que empieza **en frío**, y unos archivos `.md` hacen de memoria entre sesiones. Un guardián (`bin/check-docs.sh`)
comprueba que esa memoria no miente, y un único árbitro (`bin/verify.sh`) decide si el código está sano.

Sale del protocolo que se construyó en el backend y el frontend de Kiniela Pro, unificado en una sola versión con lo
mejor de cada repo y sin nada propio de ese proyecto.

**Versión del kit:** 2026-10-01.

## Qué hay en cada kit

Cada carpeta (`laravel/`, `nextjs/`) es un kit completo: se copia entera a la raíz del proyecto.

```
CLAUDE.md                 Punto de entrada: lectura en frío, fases, ramas, commits, cierre.        [común]
AGENTS.md                 Redirección a CLAUDE.md para Cursor, Codex, aider…                       [común]
.ai/
  RULES.md                Reglas de código: stack, alcance, contrato, arquitectura, lista negra.    [stack]
  WORKFLOW.md             Protocolo del ejecutor: ciclo, criterios de parada, STOP & ASK, reporte.  [común]
  PLANNING.md             Cómo se planifica una épica o una fase.                                   [común]
  STATE.md                El puntero: fase activa, mapa de fases, bloqueos.                          [común]
  DOMAIN.md               Glosario y decisiones (tomadas y pendientes). Lo decidido no se pregunta.  [común]
  BACKLOG.md              Hallazgos fuera de alcance y pendientes en otros repos.                    [común]
  PROTOCOL.md             Mejoras del protocolo que propone cada fase.                               [común]
  templates/              Plantillas de épica y de fase.                                             [stack]
  epics/                  Las épicas y sus fases (vacía al instalar).                                [común]
  handoffs/               Entregas del repo hermano, copiadas.                                       [común]
.claude/
  commands/phase.md       /phase — ejecuta la fase activa de principio a fin.                        [común]
  commands/close.md       /close — documenta una fase que otra sesión dejó a medias.                 [común]
  settings.json           Permisos del agente (qué puede ejecutar sin preguntar y qué nunca).        [stack]
bin/
  check-docs.sh           El guardián: 13 chequeos sobre la coherencia de la memoria.                [común]
  verify.sh               El único árbitro: gates, su orden y la baseline que nunca empeora.         [stack]
docs/
  README.md               Qué va en cada carpeta de docs/.                                           [stack]
  runbooks/release.md     Manifiesto de despliegue: lo que cada fase deja por hacer en producción.   [común]
```

Además, propios de cada stack:

- **Laravel:** `tests/Architecture/ArchitectureTest.php` (las reglas de Actions y Value Objects, con el plugin de
  arquitectura de Pest), `scripts/normalize-routes.php` (baseline de rutas del contrato HTTP) y `phpstan.neon`.
- **Next.js:** `docs/vendor/INDEX.md` (índice de notas de las librerías en la versión instalada).

## Instalación en un proyecto nuevo

### 1. El proyecto y sus herramientas

El kit da por hecho el stack de su `RULES.md`. Instálalo o, si el proyecto no lo usa, quita la fila de
`.ai/RULES.md §Stack y versiones exactas` y lo que dependa de ella.

**Laravel**

```bash
laravel new mi-proyecto --pest        # o composer create-project; con Pest, no PHPUnit
cd mi-proyecto && git init
composer require --dev larastan/larastan
php artisan install:api               # si expone una API
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
configura en `eslint.config.mjs` con `eslint-plugin-boundaries`, y `tsconfig.json` lleva `"strict": true`.

### 2. Copiar el kit

```bash
cp -Rn ai-protocol/laravel/. mi-proyecto/     # o ai-protocol/nextjs/.
chmod +x mi-proyecto/bin/*.sh
```

`-n` no sobrescribe nada que ya exista en el proyecto. Revisa qué no se copió si el proyecto no era nuevo.

### 3. Rellenar los datos del proyecto

Todo lo que depende del proyecto está marcado con `{{RELLENAR: …}}`, y cada marcador dice qué va:

```bash
grep -rn '{{RELLENAR' CLAUDE.md .ai docs
```

| Archivo | Qué se rellena |
|---|---|
| `CLAUDE.md` | Nombre del repo, contexto operativo y **repos hermanos** (`` `frontend` ``, `` `backend` ``… o `—`) |
| `.ai/STATE.md`, `.ai/DOMAIN.md` | Nombre del proyecto y qué es, en dos o tres frases |
| `.ai/RULES.md` | Versiones exactas del stack (tienen que coincidir con `composer.json` / `package.json`), alcance, zonas sensibles y ámbitos de commit del dominio. Laravel: el mecanismo de autorización. Next.js: autenticación y cabeceras del cliente, e i18n |

El guardián no deja pasar `bin/verify.sh` mientras quede un marcador o una versión que no coincida.

### 4. Lo que generan los scripts (Laravel)

```bash
php scripts/normalize-routes.php > docs/contract/routes-baseline.txt
```

Si el proyecto corre en Docker Compose, pon el nombre del servicio de PHP en `VERIFY_SERVICE`, en la sección
«CONFIGURACIÓN DEL PROYECTO» de `bin/verify.sh`: desde el host, el script se relanza dentro del contenedor.

### 5. Primer verde y primer commit

```bash
bash bin/verify.sh
git add -A && git commit -m "chore(protocol): install ai-protocol"
```

### 6. La primera épica

Con el agente: *«Planifica la épica 01 —<objetivo>— siguiendo `.ai/PLANNING.md`»*. Quien planifica escribe el
epic-plan y las fases, las filas del mapa en `.ai/STATE.md` y las decisiones pendientes en `.ai/DOMAIN.md`, y deja el
puntero en la primera fase lista. Después, `/phase`.

## Cómo se trabaja

1. **Planificar** (`.ai/PLANNING.md`): épica con objetivo, fuera de alcance, contrato, fases y criterio de cierre;
   cada fase con un objetivo, 3–7 entregables, archivos, criterios de éxito ejecutables y plan de commits.
2. **`/phase`** — una sesión por fase:
   - **Paso 0:** resuelve la fase activa de `.ai/STATE.md` y su rama `phase/<NN-slug>/<FF>`.
   - **Paso A:** lectura en frío, revalidación contra el código, y **se para** a esperar tu visto bueno.
   - **Paso B:** un commit por fila del plan, cada uno con `bash bin/verify.sh --fast` en verde.
   - **Paso C:** `bash bin/verify.sh` completo, RESULTADO de la fase (sobre todo «Lo que la siguiente fase necesita
     saber»), estado y puntero, decisiones, hallazgos, mejoras del protocolo, commit de cierre.
3. **Revisar** la rama en local (`git log --oneline main..HEAD`, `git diff main...HEAD`) y decidir el merge. El agente
   nunca hace `git push`.
4. **`/close`** si una sesión se cortó: documenta lo que de verdad pasó, sin completar nada.

Cuando el agente no puede decidir algo (contrato, producto, arquitectura, un criterio que no se puede cumplir tal
como está escrito), para con un **STOP & ASK**: opciones, consecuencias y su recomendación. La respuesta queda
escrita en la fase y, si sobrevive a ella, en `.ai/DOMAIN.md`.

## Un backend Laravel y un frontend Next.js

Instala cada kit en su repo y declara al otro en `CLAUDE.md` (`> **Repos hermanos:**`). Entonces:

- Cada repo **lee** el código del otro cuando duda del contrato, pero **no escribe** en él ni cita sus documentos.
- Una fase que cambia lo que el otro consume deja un **traspaso**: una fila de `.ai/BACKLOG.md` con Área = el otro
  repo, `**Cambio:**`, `**Origen:**` (`fase NN/FF`) y, si aplica, `**Despliegue:**`. Aparece en
  `.ai/STATE.md §Pendientes en otros repos` hasta que lo cierras. El guardián no deja cerrar una fase que cambió el
  contrato sin su traspaso (o sin decir por qué no hace falta).
- Lo que un repo entrega al otro llega copiado a `.ai/handoffs/<fecha>-<tema>/`.

## Qué comprueba el guardián

`sh bin/check-docs.sh --strict` (primer gate de `bin/verify.sh`): instalación completa; el puntero de `STATE.md`
apunta a la primera fase sin terminar; el estado de cada fase coincide en su archivo y en el mapa; la cabecera, el
plan de commits, las dependencias y el RESULTADO de cada fase; el estado de cada épica frente a sus fases y su
criterio de cierre; que las fases citadas existen; el manifiesto de despliegue; los traspasos; los contadores de
`STATE.md` frente a `DOMAIN.md` y `BACKLOG.md`; los destinos del backlog; el stack frente a los manifiestos; que no se
citen documentos del repo hermano; y que las rutas y secciones citadas existan. Corre igual en el host que en un
contenedor Alpine (busybox).

Su cabecera explica cómo provocar cada fallo a mano: un chequeo nuevo se prueba en las dos direcciones (falla con el
defecto, pasa sin él).

## Diferencias con el protocolo de Kiniela Pro

Para quien venga de esos repos:

- **Un solo protocolo** para los dos stacks; lo que cambia por stack está en `RULES.md`, las plantillas,
  `verify.sh`, `settings.json` y `docs/`.
- **La baseline vive en `bin/verify.sh`** (`MIN_TESTS` y la deuda congelada), no en `STATE.md`. Laravel gana el modo
  `--fast` y un gate de deuda de PHPStan que sólo mengua.
- **Sin páginas de seguimiento** (Artifacts): el archivo de la fase es el único registro.
- **`STATE.md`** lleva siempre `Pendientes en otros repos: N (M condicionan el despliegue)`, y el guardián comprueba
  que los contadores, `§Bloqueo activo` y la tabla de pendientes cuadran con `DOMAIN.md` y `BACKLOG.md`.
- **`BACKLOG.md`** con `Impacto`, `Destino` y `Cerrado por`, y la regla de triaje en `PLANNING.md`.
- **`DOMAIN.md §Decisiones pendientes`** con ids `D<n>` y las columnas `Categoría`, `Bloquea`, `Propuesto por`.
- **Commits de fase** `chore(phase-<NN>-<FF>): start | resume | close`, con épica y fase en el ámbito.
- **Criterios de parada** unificados (`WORKFLOW.md §Contrato`–`§2.10`); los propios del dominio se declaran en
  `RULES.md §Zonas sensibles`.
- **Sin listas de deuda congelada** (`handoff-allowlist.txt`, `crossrepo-allowlist.txt`): un proyecto nuevo empieza
  limpio y los chequeos no toleran excepciones.

## Mantener el kit

- **Una regla vive en un solo archivo**; los demás la citan por el nombre de su sección. Si una regla puede
  incumplirse en silencio, se le añade un chequeo a `bin/check-docs.sh`, probado en las dos direcciones.
- **Los archivos comunes son idénticos en todos los kits.** Se cambian en uno y se copian a los demás en el mismo
  commit; `sh check-kits.sh` falla si difieren.
- **Las mejoras vienen de los proyectos.** Cada proyecto acumula las suyas en `.ai/PROTOCOL.md`; las que no son
  propias de ese proyecto se suben aquí.
- Al cambiar el kit, actualiza «Versión del kit» arriba.
