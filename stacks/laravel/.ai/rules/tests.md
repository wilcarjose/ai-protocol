# Reglas de tests — backend Laravel

> Dónde va cada test y contra qué corre. Es un tema de `.ai/RULES.md §Reglas por tema`: tan innegociable como el
> núcleo, del kit `ai-protocol` y actualizado por `install.sh --upgrade`.

---

## 1. Tests

- **Pest**, nunca clases de PHPUnit. **Test antes que implementación** para toda Action, excepción, Value Object o
  contrato nuevos: el test se ve fallar por la causa correcta, se implementa, se ve pasar. En el mismo commit.
- Dónde va cada uno:
  - `tests/Unit/` — Actions y Value Objects, sin base de datos cuando se pueda.
  - `tests/Feature/` — lo que necesita base de datos o el framework arrancado.
  - `tests/Feature/Contract/` — el contrato HTTP: status y forma exactos (`assertExactJsonStructure`).
  - `tests/Architecture/` — reglas sobre el código con el plugin de arquitectura de Pest; corre sin base de datos,
    en su gate de `bin/verify.sh` y no en las suites de `phpunit.xml`.
- **La suite corre contra el mismo motor de base de datos que producción**, PostgreSQL, no contra SQLite en memoria:
  SQLite convierte un identificador entrecomillado que no existe en un literal de cadena, y una consulta rota
  devuelve cero filas en vez de fallar. La conexión sale de `.env.testing` (que sustituye a `.env`, no se mezcla)
  contra una base de datos **distinta** de la de desarrollo:
  - `phpunit.xml` no fija `DB_CONNECTION` ni `DB_DATABASE` (el del esqueleto de Laravel lo hace, con SQLite): el gate
    «suite» de `bin/verify.sh` falla si los encuentra.
  - `APP_KEY` de `.env.testing` sólo sirve a los tests: se genera una vez con `php artisan key:generate --env=testing`.
  - En la CI, el servicio `postgis/postgis` de `.github/workflows/verify.yml`; en local, un PostgreSQL (en la nube lo
    instala el script de preparación del kit) o un servicio más de Docker Compose.
  - PostGIS es opcional. La imagen de la CI lo trae; el proyecto que lo necesita lo activa con una migración
    (`CREATE EXTENSION IF NOT EXISTS postgis`) y lo instala también en local.
- **Cuando un test falla por una diferencia de motor:** prohibido cambiar el código de producción para que pase y
  prohibido mockear la base de datos. Si el fallo es del test (tipos, orden de `NULL`, colación), se arregla el test
  sin relajar la aserción. Si destapa un bug de producción, va a `.ai/BACKLOG.md` (`CLAUDE.md §Alcance`).
- **Fakes:** cada contrato tiene su Fake, que permite aserciones (`assertSent()`, `assertNothingSent()`,
  `respondWith()`). Viven en `tests/Fakes/` y se enlazan en el entorno de test. Si un test necesita `Http::fake()`,
  falta un contrato.
- Ningún test llama a la red real: `Http::preventStrayRequests()` en el `setUp()` de `tests/TestCase.php`.
- **El cliente de test pone cabeceras por defecto.** `getJson()` y compañía crean la petición con
  `Request::create()`, que fija `Accept-Language: en-us,en;q=0.5`, `Accept`, `User-Agent` y `REMOTE_ADDR=127.0.0.1`
  en toda petición que no los da. Un test cuyo comportamiento depende de una cabecera o de la IP la fija él mismo, o
  `tests/TestCase.php` la vacía para todos; quien planifica una fase así cuenta ese archivo en sus «Archivos».
- **La evidencia de Pest**, legible: `PAO_DISABLE=1 ./vendor/bin/pest <filtro> --colors=never`. laravel/pao, que
  trae el esqueleto, cambia la salida por JSON cuando la ejecuta un agente, y un criterio que pide la salida entera
  no se cumple con ese JSON. `bin/verify.sh` ya lo desactiva.

---

## 2. Exploración local

1. **Nunca imprimas volcados masivos.** Consultas a la base de datos con `LIMIT 3` o `take(3)`.
2. **Tinker antes que SQL**: `php artisan tinker` con Eloquent respeta scopes y casts.
3. `curl` sólo contra `localhost`, con `-s` y filtrado con `jq`, para comparar la salida de un endpoint con su
   contrato.
4. **No destruyas el estado**: nada de `DELETE` ni `UPDATE` masivos a mano. Si hace falta estado limpio, pídeselo al
   Tech Lead.
