# Reglas de rendimiento, caché y colas — backend Laravel

> Lo que no rompe ningún test y sí rompe producción. Es un tema de `.ai/RULES.md §Reglas por tema`: tan innegociable como el
> núcleo, del kit `ai-protocol` y actualizado por `install.sh --upgrade`.

---

## 1. Rendimiento y resiliencia

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

## 2. Caché, serialización y colas

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
