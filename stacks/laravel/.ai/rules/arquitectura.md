# Reglas de arquitectura — backend Laravel

> Cómo se organiza `app/` y cómo se escribe cada pieza. Es un tema de `.ai/RULES.md §Reglas por tema`: tan innegociable como el
> núcleo, del kit `ai-protocol` y actualizado por `install.sh --upgrade`.

---

## 1. Arquitectura objetivo

```
app/
├── Actions/          ← lógica de negocio: 1 clase = 1 caso de uso (§2)
├── Contracts/        ← interfaces de todo lo que cruza el proceso: red, disco, reloj, servicios externos (§4)
├── Data/             ← DTOs de configuración
├── Enums/            ← enums backed string: estados y constantes de negocio
├── Exceptions/       ← todas heredan de una ApiException base (§1.1)
├── Http/
│   ├── Controllers/Api/   ← delgados: validar → despachar una Action → responder
│   ├── Middleware/
│   ├── Requests/          ← FormRequest: autorización y validación, nada más
│   └── Resources/         ← transformación de salida
├── Models/
├── Services/         ← orquestación y consultas de lectura. Nada de negocio nuevo
└── ValueObjects/     ← objetos readonly que se validan al construirse (§3)
```

### Flujo obligatorio de una petición

```
Route → Middleware → FormRequest (authorize + rules) → Controller (sin lógica)
      → Action::handle(ValueObject|Model, …): Model|ValueObject|array
      → JsonResource | array
```

### 1.1 Excepciones

- Toda excepción de negocio hereda de una `ApiException` base que lleva su `error_code` (mayúsculas, estable: es el
  contrato), su status HTTP y un contexto. El render a JSON está en un solo sitio (`bootstrap/app.php`,
  `withExceptions`), con un único envelope de error.
- Toda subclase con status 4xx se registra en `dontReport`: sin eso, Laravel la reporta como `ERROR` y ensucia el
  log en cada rechazo legítimo. Ojo: `bootstrap/app.php` no declara namespace, así que dentro del closure
  `X::class` resuelve al namespace global si `X` no está importada con `use`.
- Un `500` nunca expone el mensaje de la excepción: texto fijo y el detalle al log.

### 1.2 Control de flujo — early returns

Las condiciones de error se validan al principio y se retorna o se lanza de inmediato; el camino feliz no lleva
indentación extra. Prohibido el código en flecha (`if (…) { if (…) { if (…) { /* lo útil */ } } }`). Aplica a
Actions, Services, Controllers, FormRequests, Commands y Jobs.

### 1.3 Estados — transiciones explícitas

Una entidad con ciclo de vida (pedido, pago, suscripción, invitación, membresía) no cambia de estado con un
`if/else` o un `match` anidado dentro de una Action:

- Estados como **enums backed string** en `app/Enums/`. Al serializar, siempre `->value`.
- **Una clase por transición** (`MarkPaymentAsCapturedTransition`), que encapsula precondiciones, efectos, eventos y
  limpieza de caché. El primer caller que necesita una transición la crea; el segundo la reutiliza.
- Un flujo nuevo es una transición nueva o registrada en la máquina existente, nunca una rama más.

### 1.4 Borrado lógico

Toda tabla principal del dominio (lo que el usuario referencia por identificador y cuyo borrado accidental sería un
incidente) usa `SoftDeletes`, y su migración incluye `softDeletes()`. El borrado real (`forceDelete()`) es una
operación administrativa explícita, en su propio comando o Action, nunca implícita en otra. Modelo de dominio
nuevo: **con** `SoftDeletes` por defecto.

### 1.5 Desactivación — `is_active`

Una entidad que se desactiva y se reactiva sin perder su identidad lleva `is_active` (booleano, `true` por defecto),
y las consultas públicas filtran por él. Desactivar no es borrar: la fila sigue editable por un administrador, y la
desactivación es una transición (§1.3), no un toggle directo. `is_active` y `deleted_at` resuelven problemas
distintos y no son intercambiables.

### 1.6 Autorización

Un solo mecanismo de autorización: dos conviviendo son una segunda fuente de verdad. Cuál es, lo dice
`.ai/project/ARCHITECTURE.md §Autorización`.

---

## 2. Patrón Action

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
   reloj o un servicio externo (§4).
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

## 3. Tipado estricto y Value Objects

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

### 3.1 El nombre es el contrato

El nombre de un constructor con nombre describe el **estado resultante**, no la intención de quien lo llama. Un
`Window::closed()` que devuelve una ventana *abierta* cuesta una auditoría entera. Prohibidos los nombres que se leen
en dos sentidos (`closed`, `disabled`, `locked`, `off`, `skip` sobre algo que *permite*). Si el nombre necesita un
docblock de tres líneas para explicar que significa lo contrario de lo que parece, el nombre está mal.

### 3.2 Un VO sin invariantes no es un VO

- Si su constructor no puede fallar, es una tupla con nombre: o tiene invariantes o es un `array` con forma
  documentada.
- **Excepción declarada:** un VO construido desde datos ya persistidos no puede validar con la dureza de uno
  construido desde la entrada del usuario, porque lanzaría en producción sobre filas históricas. Entonces valida
  sólo el formato, lanza `InvalidArgumentException` (nunca una `ApiException`, que cambiaría el envelope) y lo dice
  en el docblock de ese constructor.
- Un campo que ningún consumidor lee es un campo fantasma: se borra, o un test documenta que hoy no tiene efecto.

---

## 4. Contratos e inyección de dependencias

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

## 5. PHP 8.4+ — dónde sí y dónde no

Toda la capa de Actions y Value Objects es `final readonly class`. Los property hooks **con almacenamiento** no son
compatibles con propiedades `readonly`; los hooks **virtuales** (calculados, sin almacenamiento) sí.

| Característica | Actions | Value Objects | Models | Services, Resources |
|---|---|---|---|---|
| Property hooks con almacenamiento | ⛔ | ⛔ | ⚠️ probar primero | ✅ |
| Property hooks virtuales | ⚠️ rara vez útil | ✅ valores derivados | ⚠️ probar primero | ✅ |
| Visibilidad asimétrica `public private(set)` | ⛔ redundante | ⛔ redundante | ✅ | ✅ |
| `array_find` / `array_any` / `array_all` | ✅ | ✅ | ✅ | ✅ |
| `array_first` / `array_last` globales | ⛔ `.ai/RULES.md §Lista negra` | ⛔ | ⛔ | ⛔ |

**Modelos Eloquent:** Eloquent resuelve atributos con su propio sistema (`__get`). Un hook sobre un modelo puede no
integrarse con `toArray()`, el JSON ni `$appends`, y rompería el contrato sin avisar. Antes de migrar un accessor a
hook: uno solo como prueba, un test que compare acceso directo, `toArray()` y el JSON del endpoint, y sólo entonces
el resto. Una característica del lenguaje se aplica sólo si **elimina líneas** sin cambiar el comportamiento.

---

## 6. Forma de las respuestas

Parte del contrato (`.ai/RULES.md §Contrato HTTP`), porque PHP y las bases de datos la rompen sin avisar:

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
