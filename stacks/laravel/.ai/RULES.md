# RULES — {{RELLENAR: nombre del proyecto}} · backend Laravel

> Las reglas de **cómo se escribe código** en este repositorio, para cualquier agente de IA y para cualquier humano.
> Léelo completo antes de escribir una sola línea. Si algo aquí contradice tu instinto, gana este archivo.
>
> Tres reglas que aplican a todo lo demás:
>
> 1. Si crees que una regla está mal o desactualizada: **STOP & ASK** (`.ai/WORKFLOW.md §STOP & ASK`). Nadie edita este
>    archivo sin el visto bueno del Tech Lead, y nunca desde una fase.
> 2. Las reglas de **cómo se trabaja** (qué reportar, cuándo parar, cómo verificar) viven en `.ai/WORKFLOW.md` y en
>    `CLAUDE.md`. Jerarquía si chocan: este archivo > `.ai/WORKFLOW.md` > `CLAUDE.md`.
> 3. Lo que cambia con el estado del proyecto (decisiones de negocio, fase activa) vive en `.ai/DOMAIN.md` y
>    `.ai/STATE.md`. Aquí sólo hay reglas **estables**.
>
> Son las convenciones por defecto del kit de protocolo. Al instalarlo se ajustan al proyecto; después, sólo las
> cambia el Tech Lead.

---

## 1. Stack y versiones exactas

Verificadas contra `composer.json`: el chequeo «stack» de `bin/check-docs.sh` compara esta tabla, versión a
versión, con lo que declaran los manifiestos. Una fila por paquete (varios en una fila, separados por « / »).

| Paquete | Versión | Nota |
|---|---|---|
| `php` | {{RELLENAR: p. ej. ^8.4}} | Property hooks y visibilidad asimétrica disponibles, con las restricciones de §10 |
| `laravel/framework` | {{RELLENAR: p. ej. ^13.0}} | Esqueleto slim: `bootstrap/app.php`, sin `Kernel.php` |
| `pestphp/pest` | {{RELLENAR: p. ej. ^4.0}} | Pest, no PHPUnit clásico. Incluye el plugin de arquitectura |
| `laravel/pint` | {{RELLENAR}} | Estilo |
| `larastan/larastan` | {{RELLENAR: p. ej. ^3.0}} | Análisis estático (`phpstan.neon`) |

**Regla dura:** la documentación de dos versiones seguidas de Laravel se parece mucho y los modelos de lenguaje
las mezclan. Si necesitas una API del framework y no estás 100 % seguro de que existe en **tu** versión, no la uses:
escribe la versión explícita y verbosa, o consulta la documentación de esa versión exacta
(`https://laravel.com/docs/<versión>.x/`), nunca la de otra ni `master`.

Que el framework traiga incluida una funcionalidad (un SDK, un tipo de recurso, un sistema de colas nuevo) no la
convierte en parte del alcance: añadirla es funcionalidad nueva y la autoriza una fase.

---

## 2. Alcance — qué puedes tocar

### ✅ Dentro de alcance (con autorización de la fase activa)

```
app/Actions/**
app/Contracts/**
app/Data/**
app/Enums/**
app/Exceptions/**
app/Http/Controllers/Api/**
app/Http/Middleware/**
app/Http/Requests/**
app/Http/Resources/**
app/Models/**                    (accessors, casts y relaciones: con cuidado, son contrato — §3)
app/Services/**
app/ValueObjects/**
app/Providers/AppServiceProvider.php   (bindings de contratos en register())
routes/api.php                   (URLs y verbos sólo con CAMBIO AUTORIZADO — §3)
tests/**
```

### ⛔ Fuera de alcance salvo autorización explícita de la fase

```
database/migrations/**     ← sólo si la fase lo autoriza en su cabecera «Migraciones:»
config/**                  ← sólo si la fase lo pide
composer.json              ← dependencias nuevas: .ai/WORKFLOW.md §Dependencia nueva
.env*                      ← nunca se leen ni se escriben secretos
```

{{RELLENAR: lo que este proyecto deja fuera además (un backoffice que se refactoriza aparte, un namespace que
pertenece a un paquete como `app/Actions/Fortify/**`…), o «Nada más.»}}

Si un cambio *parece* requerir tocar algo de fuera de alcance: **detente y repórtalo**. Es una señal de que el
alcance de la fase está mal, no un obstáculo que sortear.

---

## 3. Contrato HTTP

El contrato HTTP es todo lo que un cliente ve: URLs, verbos, status, claves de entrada y salida, su forma y su
orden, cabeceras y el texto de los mensajes de error. **No cambia por defecto.** Cualquier cambio, aunque sea para
cerrar un agujero, requiere:

1. **STOP & ASK** (`.ai/WORKFLOW.md §Contrato`), salvo que la fase ya lo traiga autorizado.
2. La autorización del Tech Lead escrita en la fase: su cabecera dice `Contrato HTTP: CAMBIO AUTORIZADO`, con el
   cambio campo por campo y la decisión de `.ai/DOMAIN.md` que lo respalda.
3. El traspaso al repo hermano que lo consume (`CLAUDE.md §El otro repositorio`).
4. Los tests de contrato (`tests/Feature/Contract/`) y el baseline de rutas (`docs/contract/routes-baseline.txt`,
   generado con `php scripts/normalize-routes.php`) actualizados en la misma fase.

Si el contrato no cambia, los tests de contrato pasan **sin modificarlos** y el baseline de rutas no se toca: son
la red que salta cuando algo cambia sin querer.

Reglas de forma, porque PHP y las bases de datos las rompen sin avisar:

- **Una columna JSON-objeto sale siempre como objeto JSON**: `{}` si está vacía o es `NULL`, nunca `[]` ni `null`.
  PHP serializa un array vacío como `[]`, así que la salida pasa por un único helper en `app/Http/Resources/`, también
  en las respuestas que no usan un Resource. Ningún Resource escribe su propio `?: []` o `(object)`.
- **Un booleano sale siempre como `true`/`false`**: toda columna booleana tiene cast `boolean` en su modelo, y la de
  un pivote se convierte en su único punto de salida. MySQL la devuelve `0`/`1` si nadie la castea.
- **El orden de una lista es parte de la respuesta.** Toda consulta que pagina o cuyo orden ve el cliente termina en
  una columna única (la clave primaria): ordenar sólo por una fecha o un nombre deja los empates al motor, y no todos
  los devuelven siempre igual.
- **Un array de respuesta no cambia de tipo**: `[]` serializa como `[]` y una Collection vacía puede salir como `{}`.
  No conviertas uno en otro en un valor que termine en JSON.

---

## 4. Arquitectura objetivo

```
app/
├── Actions/          ← lógica de negocio: 1 clase = 1 caso de uso (§5)
├── Contracts/        ← interfaces de todo lo que cruza el proceso: red, disco, reloj, servicios externos (§8)
├── Data/             ← DTOs de configuración
├── Enums/            ← enums backed string: estados y constantes de negocio
├── Exceptions/       ← todas heredan de una ApiException base (§4.1)
├── Http/
│   ├── Controllers/Api/   ← delgados: validar → despachar una Action → responder
│   ├── Middleware/
│   ├── Requests/          ← FormRequest: autorización y validación, nada más
│   └── Resources/         ← transformación de salida
├── Models/
├── Services/         ← orquestación y consultas de lectura. Nada de negocio nuevo
└── ValueObjects/     ← objetos readonly que se validan al construirse (§6)
```

### Flujo obligatorio de una petición

```
Route → Middleware → FormRequest (authorize + rules) → Controller (sin lógica)
      → Action::handle(ValueObject|Model, …): Model|ValueObject|array
      → JsonResource | array
```

### 4.1 Excepciones

- Toda excepción de negocio hereda de una `ApiException` base que lleva su `error_code` (mayúsculas, estable: es el
  contrato), su status HTTP y un contexto. El render a JSON está en un solo sitio (`bootstrap/app.php`,
  `withExceptions`), con un único envelope de error.
- Toda subclase con status 4xx se registra en `dontReport`: sin eso, Laravel la reporta como `ERROR` y ensucia el
  log en cada rechazo legítimo. Ojo: `bootstrap/app.php` no declara namespace, así que dentro del closure
  `X::class` resuelve al namespace global si `X` no está importada con `use`.
- Un `500` nunca expone el mensaje de la excepción: texto fijo y el detalle al log.

### 4.2 Control de flujo — early returns

Las condiciones de error se validan al principio y se retorna o se lanza de inmediato; el camino feliz no lleva
indentación extra. Prohibido el código en flecha (`if (…) { if (…) { if (…) { /* lo útil */ } } }`). Aplica a
Actions, Services, Controllers, FormRequests, Commands y Jobs.

### 4.3 Estados — transiciones explícitas

Una entidad con ciclo de vida (pedido, pago, suscripción, invitación, membresía) no cambia de estado con un
`if/else` o un `match` anidado dentro de una Action:

- Estados como **enums backed string** en `app/Enums/`. Al serializar, siempre `->value`.
- **Una clase por transición** (`MarkPaymentAsCapturedTransition`), que encapsula precondiciones, efectos, eventos y
  limpieza de caché. El primer caller que necesita una transición la crea; el segundo la reutiliza.
- Un flujo nuevo es una transición nueva o registrada en la máquina existente, nunca una rama más.

### 4.4 Borrado lógico

Toda tabla principal del dominio (lo que el usuario referencia por identificador y cuyo borrado accidental sería un
incidente) usa `SoftDeletes`, y su migración incluye `softDeletes()`. El borrado real (`forceDelete()`) es una
operación administrativa explícita, en su propio comando o Action, nunca implícita en otra. Modelo de dominio
nuevo: **con** `SoftDeletes` por defecto.

### 4.5 Desactivación — `is_active`

Una entidad que se desactiva y se reactiva sin perder su identidad lleva `is_active` (booleano, `true` por defecto),
y las consultas públicas filtran por él. Desactivar no es borrar: la fila sigue editable por un administrador, y la
desactivación es una transición (§4.3), no un toggle directo. `is_active` y `deleted_at` resuelven problemas
distintos y no son intercambiables.

### 4.6 Autorización

{{RELLENAR: el único mecanismo de autorización del proyecto. Por ejemplo: «Policies de Laravel, invocadas desde
`FormRequest::authorize()`» o «middleware con alias por recurso + comprobación explícita en la Action; este proyecto
no usa Policies». Elige uno: dos mecanismos conviviendo es una segunda fuente de verdad.}}

---

## 5. Patrón Action

```php
<?php

declare(strict_types=1);

namespace App\Actions\Orders;

use App\Contracts\Payments\PaymentGateway;
use App\Models\Order;
use App\ValueObjects\Money;

final readonly class CaptureOrderPaymentAction
{
    public function __construct(
        private PaymentGateway $gateway,
    ) {}

    public function handle(Order $order, Money $amount): Order
    {
        // …
    }
}
```

1. `final readonly class` y `declare(strict_types=1)`.
2. **Un solo método público: `handle()`.** Nada de `execute()` ni `run()` al lado, ni métodos públicos auxiliares.
3. Métodos privados, sí; si pasan de tres, la Action hace demasiado: divídela.
4. Dependencias por constructor, tipadas contra **interfaces** cuando el colaborador toca la red, el disco, el
   reloj o un servicio externo (§8).
5. **Sin facades de infraestructura** (`Http::`, `Mail::`, `Log::`, `Cache::`): se inyecta un contrato.
   `DB::transaction()` sí.
6. **Sin `request()`, `auth()`, `session()`, `env()` ni `now()`.** Todo llega por parámetro o por un contrato (el
   reloj, también). Una Action se ejecuta igual desde un controlador, un comando o una cola.
7. Tipo de retorno **siempre explícito**; nunca `mixed`.
8. Nunca devuelve una respuesta HTTP: devuelve dominio (Model, Value Object, array). La forma HTTP es del
   controlador y del Resource.
9. Si escribe en más de una tabla, `DB::transaction()`. Sin excepción.
10. Señala el error lanzando una `ApiException` con su `error_code` y su status, no devolviendo `null`.

Nombre: `{Verbo}{Sustantivo}Action` (`StoreOrderAction`, `ApproveJoinRequestAction`). Un archivo, una clase, mismo
nombre. Las reglas que se pueden comprobar sobre el código las comprueba `tests/Architecture/ArchitectureTest.php`.

---

## 6. Tipado estricto y Value Objects

- `declare(strict_types=1)` en todo archivo nuevo o tocado.
- Todo parámetro, propiedad y retorno tipado. Un `array` lleva su forma en PHPDoc (`@param array<string, int>`).
- `?Type` explícito; nada de `mixed` salvo en un límite del framework que lo imponga.
- Constantes de clase de estado (`const STATUS_ACCEPTED = 'accepted'`) → enum backed string, con el mismo valor.

### Value Objects

```php
final readonly class Quantity
{
    private function __construct(public int $value) {}

    public static function from(int $value): self
    {
        if ($value < 1 || $value > 99) {
            throw new OrderException('La cantidad debe estar entre 1 y 99.', OrderException::INVALID_QUANTITY, ['value' => $value], 422);
        }

        return new self($value);
    }
}
```

- `final readonly`, constructor privado, constructores con nombre (`from`, `fromArray`, `fromRequest`).
- **Se valida al construirse**: si existe una instancia, es válida. Es lo que impide reinventar la validación en
  cada capa. Los rangos reflejan exactamente las reglas del `FormRequest`; si divergen, gana el `FormRequest`, que
  es el contrato.
- Sin setters ni estado mutable.

### 6.1 El nombre es el contrato

El nombre de un constructor con nombre describe el **estado resultante**, no la intención de quien lo llama. Un
`Window::closed()` que devuelve una ventana *abierta* cuesta una auditoría entera. Prohibidos los nombres que se leen
en dos sentidos (`closed`, `disabled`, `locked`, `off`, `skip` sobre algo que *permite*). Si el nombre necesita un
docblock de tres líneas para explicar que significa lo contrario de lo que parece, el nombre está mal.

### 6.2 Un VO sin invariantes no es un VO

- Si su constructor no puede fallar, es una tupla con nombre: o tiene invariantes o es un `array` con forma
  documentada.
- **Excepción declarada:** un VO construido desde datos ya persistidos no puede validar con la dureza de uno
  construido desde la entrada del usuario, porque lanzaría en producción sobre filas históricas. Entonces valida
  sólo el formato, lanza `InvalidArgumentException` (nunca una `ApiException`, que cambiaría el envelope) y lo dice
  en el docblock de ese constructor.
- Un campo que ningún consumidor lee es un campo fantasma: se borra, o un test documenta que hoy no tiene efecto.

---

## 7. Tests

- **Pest**, nunca clases de PHPUnit. **Test antes que implementación** para toda Action, excepción, Value Object o
  contrato nuevos: el test se ve fallar por la causa correcta, se implementa, se ve pasar. En el mismo commit.
- Dónde va cada uno:
  - `tests/Unit/` — Actions y Value Objects, sin base de datos cuando se pueda.
  - `tests/Feature/` — lo que necesita base de datos o el framework arrancado.
  - `tests/Feature/Contract/` — el contrato HTTP: status y forma exactos (`assertExactJsonStructure`).
  - `tests/Architecture/` — reglas sobre el código con el plugin de arquitectura de Pest; corre sin base de datos.
- **La suite corre contra el mismo motor de base de datos que producción**, no contra SQLite en memoria: SQLite
  convierte un identificador entrecomillado que no existe en un literal de cadena, y una consulta rota devuelve cero
  filas en vez de fallar. La conexión de tests sale de `.env.testing` (que sustituye a `.env`, no se mezcla) contra
  una base de datos **distinta** de la de desarrollo.
- **Cuando un test falla por una diferencia de motor:** prohibido cambiar el código de producción para que pase y
  prohibido mockear la base de datos. Si el fallo es del test (tipos, orden de `NULL`, colación), se arregla el test
  sin relajar la aserción. Si destapa un bug de producción, va a `.ai/BACKLOG.md` (`CLAUDE.md §Alcance`).
- **Fakes:** cada contrato tiene su Fake, que permite aserciones (`assertSent()`, `assertNothingSent()`,
  `respondWith()`). Viven en `tests/Fakes/` y se enlazan en el entorno de test. Si un test necesita `Http::fake()`,
  falta un contrato.
- Ningún test llama a la red real: `Http::preventStrayRequests()` en el `setUp()` de `tests/TestCase.php`.

---

## 8. Contratos e inyección de dependencias

Todo lo que cruza el proceso —red, disco, reloj, correo, colas de terceros, proveedores externos— tiene su interfaz
en `app/Contracts/<Dominio>/`, su implementación real y su Fake. Los bindings, en
`AppServiceProvider::register()`.

| Colaborador | Contrato | Implementaciones |
|---|---|---|
| Reloj | `App\Contracts\Time\Clock` (lo crea la primera Action que necesite la hora) | `SystemClock`, `FrozenClock` (tests) |

<!-- Una fila por contrato, en la fase que lo crea. -->

**Nunca instancies un colaborador externo con `new` dentro de una Action.** `new` sólo para Value Objects y
excepciones.

---

## 9. Rendimiento y resiliencia

- **Cero N+1.** Si iteras una colección y accedes a una relación: `with()` o `loadMissing()`.
- **Nunca metas datos que dependen del usuario dentro de un valor cacheado compartido.** Un `is_current_user`
  calculado dentro de un `Cache::rememberForever` filtra datos de un usuario a otro. Esos campos se calculan
  **fuera** del closure de caché.
- Las claves de caché incluyen **todas** las dimensiones que afectan al resultado (tenant, usuario, idioma, filtros).
- Ninguna llamada HTTP saliente síncrona en el camino de la respuesta: a una cola o `dispatch()->afterResponse()`.
- Toda llamada externa: `timeout()` explícito, `try/catch` de `ConnectionException` y una degradación definida.
- `env()` **sólo** dentro de `config/**`: fuera devuelve `null` con `config:cache`.
- A un job encolado se le pasa lo mínimo (identificadores), no colecciones hidratadas.

---

## 10. PHP 8.4+ — dónde sí y dónde no

Toda la capa de Actions y Value Objects es `final readonly class`. Los property hooks **con almacenamiento** no son
compatibles con propiedades `readonly`; los hooks **virtuales** (calculados, sin almacenamiento) sí.

| Característica | Actions | Value Objects | Models | Services, Resources |
|---|---|---|---|---|
| Property hooks con almacenamiento | ⛔ | ⛔ | ⚠️ probar primero | ✅ |
| Property hooks virtuales | ⚠️ rara vez útil | ✅ valores derivados | ⚠️ probar primero | ✅ |
| Visibilidad asimétrica `public private(set)` | ⛔ redundante | ⛔ redundante | ✅ | ✅ |
| `array_find` / `array_any` / `array_all` | ✅ | ✅ | ✅ | ✅ |
| `array_first` / `array_last` globales | ⛔ §15 | ⛔ | ⛔ | ⛔ |

**Modelos Eloquent:** Eloquent resuelve atributos con su propio sistema (`__get`). Un hook sobre un modelo puede no
integrarse con `toArray()`, el JSON ni `$appends`, y rompería el contrato sin avisar. Antes de migrar un accessor a
hook: uno solo como prueba, un test que compare acceso directo, `toArray()` y el JSON del endpoint, y sólo entonces
el resto. Una característica del lenguaje se aplica sólo si **elimina líneas** sin cambiar el comportamiento.

---

## 11. Caché, serialización y colas

- **Cachea arrays y escalares, no objetos.** Si `config/cache.php` declara una lista blanca de clases
  deserializables (`serializable_classes`), un objeto de una clase que no está en ella falla al leerse en
  producción, no en los tests con el driver `array`. Añadir una clase a la lista se justifica en el commit: cada
  entrada es superficie de ataque.
- **Trampa de tests:** el driver de caché `array` no serializa nada. Un test que dice probar la serialización corre
  contra Redis, o declara que no la verifica.
- **Los prefijos de caché, de Redis y la cookie de sesión no se cambian** una vez en producción: huerfanizan Redis
  entero y cierran todas las sesiones a la vez, en el instante del despliegue. Lo mismo `session.serialization`.
- Las claves y tags de caché que usan varios sitios son **contrato interno**: cambiar una invalida la caché de
  producción sin que ningún test lo note.
- Antes de desplegar un cambio mayor de framework, se drenan las colas: los payloads serializados por la versión
  anterior se deserializan con la nueva.

---

## 12. Exploración local

1. **Nunca imprimas volcados masivos.** Consultas a la base de datos con `LIMIT 3` o `take(3)`.
2. **Tinker antes que SQL**: `php artisan tinker` con Eloquent respeta scopes y casts.
3. `curl` sólo contra `localhost`, con `-s` y filtrado con `jq`, para comparar la salida de un endpoint con su
   contrato.
4. **No destruyas el estado**: nada de `DELETE` ni `UPDATE` masivos a mano. Si hace falta estado limpio, pídeselo al
   Tech Lead.

---

## 13. Zonas sensibles

Tocar estas zonas de una forma que la fase no describe con precisión es motivo de parada
(`.ai/WORKFLOW.md §Zona sensible`):

- Autenticación, sesiones, tokens y permisos.
- Pagos, planes y facturación.
- {{RELLENAR: los cálculos de los que depende el negocio (puntuaciones, precios, plazos…), o bórralo}}

---

## 14. Verificación del stack

`bash bin/verify.sh` corre los gates en su orden (estilo, análisis estático, rutas, arquitectura, suite); aquí sólo
lo que no cabe en el script:

- **Pint** con la configuración del repo; no se desactivan reglas para que algo pase.
- **PHPStan / Larastan** al nivel de `phpstan.neon`, que nunca baja. Si existe `phpstan-baseline.neon`, **sólo
  mengua**: un error nuevo se arregla, no se añade al baseline. Si el análisis falla con `ignore.unmatched`, un
  patrón quedó huérfano: regenera el baseline (`vendor/bin/phpstan analyse --generate-baseline`), revisa el diff
  línea por línea (cada patrón que desaparece corresponde a un error que de verdad se arregló; si protegía un error
  que sigue ahí, se restaura y se arregla el código) y va en su propio commit.
- **Test de arquitectura** (`tests/Architecture/`): las reglas de §5 y §6 que se pueden comprobar sobre el código.
  Una regla nueva de este archivo que se pueda comprobar, entra ahí.
- **Rutas:** `docs/contract/routes-baseline.txt` se regenera sólo con un cambio de contrato autorizado (§3).

---

## 15. Lista negra

Las prohibiciones que valen para cualquier stack no se repiten aquí: no arreglar de paso (`CLAUDE.md §Alcance`),
dependencias nuevas (`.ai/WORKFLOW.md §Dependencia nueva`) y exenciones a un gate
(`.ai/WORKFLOW.md §Obediencia arquitectónica`). Éstas son las de Laravel:

1. ⛔ **No inventes funcionalidad**: ni un endpoint, ni un campo, ni un flag «de paso».
2. ⛔ **No crees ni edites migraciones** sin que la cabecera de la fase las autorice.
3. ⛔ **No renombres columnas, tablas ni claves de respuesta** sin `CAMBIO AUTORIZADO` (§3).
4. ⛔ **No cambies el texto de un mensaje de error** sin `CAMBIO AUTORIZADO`: el cliente puede mostrarlo tal cual.
5. ⛔ **No borres código comentado que parezca una regla de negocio desactivada.** Repórtalo.
6. ⛔ **No cambies TTLs de caché ni valores de configuración** sin autorización. Si están mal, repórtalo.
7. ⛔ **No uses paquetes de Actions ni de DTOs** (`lorisleiva/laravel-actions`, `spatie/laravel-data`): las Actions
   son clases PHP planas resueltas por el contenedor.
8. ⛔ **No añadas un `JsonResource` con envoltorio `data`** donde hoy hay un array plano, ni reordenes las claves de
   una respuesta.
9. ⛔ **No refactorices más de un endpoint por commit.**
10. ⛔ **No dejes la Action y el Service viejo activos a la vez**: si extraes a una Action, el Service deja de tener
    esa lógica.
11. ⛔ **No uses `auth()->user()` en Services ni Actions.** Sólo controladores y middleware conocen la petición.
12. ⛔ **No silencies excepciones** (`catch (\Exception $e) { continue; }`). Si el código existente lo hace, se
    conserva y se reporta; código nuevo así, nunca.
13. ⛔ **No uses `->ignoring()`, `->exclude()` ni saltes un `arch()`** en el test de arquitectura: son exenciones a
    un gate.
14. ⛔ **No cambies comportamiento dentro de una tarea declarada «sin cambio de comportamiento».**
15. ⛔ **No uses `array_first()` ni `array_last()` globales**: un polyfill las define con otra semántica. Usa
    `Illuminate\Support\Arr::first()` / `Arr::last()`.
16. ⛔ **No uses `ReflectionMethod::setAccessible()` para probar un método privado**, ni quites `final` a una clase
    para heredarla en un test: falta un contrato o un Fake, o el test prueba implementación en vez de comportamiento.
17. ⛔ **No cites catálogos mutables** (`P<n>-<m>`, `§X` de una lista que se renumera) desde código, tests ni
    documentos. El porqué que debe sobrevivir va a `.ai/DOMAIN.md` o a `docs/`.
18. ⛔ **No dejes llamadas de depuración**: `dd()`, `dump()`, `ray()`, `var_dump()`.

---

## 16. Ámbitos de commit

Conventional Commits en inglés (`CLAUDE.md §Commits durante la fase`). Ámbitos:

- Transversales: `api`, `auth`, `infra`, `deps`, `docs`, `tests`, `ci`, `planning`, `protocol`, y
  `phase-<NN>-<FF>` para los commits de arranque, reanudación y cierre de una fase.
- Del dominio: {{RELLENAR: un ámbito por área del negocio, p. ej. `orders`, `payments`, `catalog`}}.

Un ámbito nuevo se añade aquí antes de usarlo.
