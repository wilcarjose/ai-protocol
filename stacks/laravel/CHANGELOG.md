# Changelog — laravel

El stack Laravel: lo que añade al núcleo. Versiones con [SemVer](https://semver.org/lang/es/) y etiqueta
`laravel-vX.Y.Z` (README.md §Versiones y etiquetas). Lo más reciente, arriba.

## [2.0.0] — 2026-10-06

Compatible con el núcleo `>=2.0.0 <3.0.0`.

### Añadido

- Contrato OpenAPI: `bin/contract.sh` lo genera desde el código con dedoc/scramble (`php artisan scramble:export`)
  en `docs/contract/openapi.json`, la misma ruta de la copia que usa Next.js, y con `--check` es el gate «contrato» de
  `bin/verify.sh`. El título y el servidor del documento se fijan con `CONTRACT_APP_NAME` y `CONTRACT_APP_URL` de
  `.ai/project/verify.conf`, para que no cambien con el `.env`. `dedoc/scramble` entra en `RULES.md §Stack y
  versiones exactas`. El baseline de rutas se mantiene. La semilla de `docs/contract/openapi.json` es la de un
  proyecto sin rutas de API: en uno que ya las tiene, el gate falla hasta que se genera con `sh bin/contract.sh`.
- Errores RFC 9457, como semillas: `App\Exceptions\ApiException` (`errorCode`, contexto y status) y
  `App\Http\ProblemDetails`, que responde `application/problem+json` con `type`, `title`, `status`, `detail` y la
  extensión `code`, y no reporta las `ApiException` 4xx. Se registra en `bootstrap/app.php`
  (`ProblemDetails::register($exceptions)` dentro de `withExceptions`), que es del proyecto.
  `tests/Feature/Contract/ProblemDetailsTest.php` verifica la forma.
- `tests/Architecture/ProjectArchitectureTest.php` (semilla): las reglas de arquitectura propias del proyecto, aparte
  de las del kit, que siguen protegidas.
- `.env.testing` (semilla): la suite contra PostgreSQL con PostGIS (base de datos `testing` en `127.0.0.1:5432`), sin
  secretos; `APP_KEY` se genera con `php artisan key:generate --env=testing`. El workflow del stack añade el servicio
  `postgis/postgis:17-3.5` y `pdo_pgsql`, y genera esa clave si está vacía.
- `.github/workflows/verify.yml`: la CI del proyecto, que corre `bin/verify.sh` completo en cada PR con todo el
  historial (los gates «protocolo» y «secretos» lo necesitan) y gitleaks en versión fija.
  La versión de PHP sale de `.php-version`.
- `bin/verify.sh`, gates «protocolo», «secretos» y «dependencias» (`composer audit`). «secretos» corre `gitleaks git`
  sobre el historial, también con `--fast`, y falla si falta gitleaks; «dependencias» va sólo en el verify completo,
  porque consulta la red.
- `.ai/project/verify.conf` (semilla): la baseline, `VERIFY_SERVICE` y `COMPOSE_CMD`, que salen de `bin/verify.sh`.
- `stack.json`: nombre, versión, rango compatible del núcleo, archivos que aporta y gates de su `bin/verify.sh`.
- `.ai/rules/`: las reglas por tema que la fase cita cuando las toca: `arquitectura.md` (estructura de `app/`,
  Actions, Value Objects, contratos, PHP 8.4+ y forma de las respuestas), `tests.md` (con la exploración local) y
  `rendimiento.md` (rendimiento, caché y colas).

### Cambiado

- `.ai/RULES.md §Lista negra`: el código va en inglés (nombres, tablas, rutas, claves de traducción, códigos de error,
  logs, tests y comentarios) y con los términos de `.ai/project/GLOSSARY.md`. En español quedan los textos para el
  usuario, los slugs públicos y los datos semilla. Los ejemplos de las reglas pasan a inglés
  (`app/Actions/Listings/PublishListing`), y también las semillas de código y sus tests.
- El mensaje de una `ApiException` es una clave de traducción (`listings.not_found`): `ProblemDetails` la traduce al
  escribir `detail`, con el contexto escalar como parámetros, y pasa también por el traductor sus textos fijos.
- Estructura estándar de Laravel con la lógica de negocio por funcionalidad (`.ai/rules/arquitectura.md §Arquitectura
  objetivo`): lo del framework en su sitio, la lógica de negocio en su carpeta por tipo y, cuando una funcionalidad
  tiene varias clases, en una subcarpeta con su nombre, el mismo en todas las carpetas. Las clases se crean con los
  `make:` de artisan. Sin módulos.
- Las Actions se llaman `{Verbo}{Sustantivo}`, sin el sufijo `Action`. Ninguna prueba lo exige: las que ya lo
  llevan siguen pasando.
- `tests/Architecture/ArchitectureTest.php`, por capas: la lógica de negocio (Actions, Services, Value Objects,
  Contracts, Data, Enums) no usa la capa HTTP (`App\Http`, `Illuminate\Http` salvo `Illuminate\Http\Client`,
  `Illuminate\Routing`) y los modelos no usan Actions, Services ni HTTP. Una regla por namespace y una expectativa por
  `arch()`: con varios namespaces, Pest 5 da la regla por buena si uno no existe, y `->ignoring()` sólo vale para la
  última expectativa. Las Actions de Laravel Fortify (`App\Actions\Fortify`) quedan fuera.
- `bin/verify.sh`: el gate «arquitectura» corre también en el verify completo. Antes se daba por hecho que iba en la
  suite, pero las suites del `phpunit.xml` de Laravel son Unit y Feature, y no corría nunca. El gate «suite» falla si
  `phpunit.xml` fija `DB_CONNECTION` o `DB_DATABASE`, como hace el del esqueleto con SQLite en memoria. «dependencias»
  pasa a `composer audit --no-dev`, como Next.js. `PAO_DISABLE=1`: laravel/pao, que trae el esqueleto, cambia la
  salida de Pest, PHPStan y Pint por JSON cuando detecta un agente.
- `.ai/RULES.md §Alcance`: lo no listado queda fuera. La lista suma `bootstrap/app.php`, comandos, jobs, eventos y
  listeners, policies, Filament, factories, seeders y todas las rutas.
- `.ai/rules/tests.md`: la suite corre contra PostgreSQL con PostGIS. `.ai/rules/arquitectura.md` deja de citar MySQL.

- `bin/verify.sh` es entero del kit: lee la configuración del proyecto de `.ai/project/verify.conf` y falla si no
  existe.
- `phpstan.neon` y `docs/README.md` pasan de `files` a `seed`: son del proyecto, el upgrade no los toca y el gate
  «protocolo» no los protege.
- `.claude/settings.json`: permite `git push [-u] origin phase/*`, `git fetch`, `gh pr create|view|checks|list`,
  `composer audit`, `gitleaks git` y `sh bin/check-protocol.sh`; bloquea el push a `main`, con `:` en el refspec,
  forzado, con borrado, `--mirror`, `--all` y `--tags`, y `gh pr merge`.
- Plantilla de fase: `> **Tipo:**` en la cabecera (código por defecto), los campos opcionales `Modo` y
  `Tarea externa`, las casillas `[humano]` en «Criterios de éxito» y la sección `## 10. Revisión`, fuera del
  RESULTADO, que escribe `/review`. Las plantillas citan `/plan-epic` y `/plan-phase` en vez de `/planning`.
- `.ai/RULES.md` queda como núcleo de innegociables (stack, alcance, contrato, zonas sensibles, verificación, lista
  negra y ámbitos), con `§Reglas por tema` como índice de `.ai/rules/`.
- Plantillas: la fase cita en su §2 la anterior con `sh bin/handoff.sh` y los temas de `.ai/rules/`; el RESULTADO
  enlaza la evidencia de las salidas largas y es el único reporte. Las citas a `.ai/PLANNING.md` y a las secciones
  que salieron de `CLAUDE.md` apuntan a las skills.
- `.claude/settings.json` permite `sh bin/handoff.sh` y `sh bin/measure-context.sh`.
- `.ai/RULES.md` deja de tener `{{RELLENAR}}`. La tabla `§Stack y versiones exactas` queda con el paquete y su
  nota; la versión de cada uno es del proyecto y vive en `.ai/project/DECISIONS.md`, contra `composer.json`.
- `.ai/RULES.md`: la autorización (`§Autorización`), el alcance adicional, las zonas sensibles del negocio y los
  ámbitos del dominio pasan a `.ai/project/` y aquí se citan.

**Al actualizar un proyecto:** borra de `phpunit.xml` las líneas `DB_CONNECTION` y `DB_DATABASE`; registra
`ProblemDetails` en `bootstrap/app.php` o, si el proyecto ya tiene su `ApiException` y su envelope de error, adapta
las semillas o retíralas en una fase con `Contrato HTTP: CAMBIO AUTORIZADO`; y genera `docs/contract/openapi.json`
con `sh bin/contract.sh`. Un proyecto nuevo de Laravel trae su `AGENTS.md` y su `CLAUDE.md`: se borran antes de
instalar, porque son los del kit.

## 1.x

La carpeta `laravel/` del kit, copiada entera con `cp -Rn`. Se actualiza con `install.sh --upgrade --stack laravel`.
