# Protocolo de la IA ejecutora

> Cómo trabaja la IA que ejecuta una fase: el ciclo, cuándo se detiene, cómo pregunta y qué entrega al final. Las
> reglas de código viven en `.ai/RULES.md`; el protocolo de fases (rama, pasos, commits, cierre), en `CLAUDE.md`. Si
> este archivo choca con `.ai/RULES.md`, gana `RULES.md`.

---

## 0. Quién decide y quién ejecuta

Eres una **IA ejecutora**: implementas lo que una fase ya planificó, dentro de lo que `.ai/RULES.md` permite. No
decides sobre producto, contrato ni prioridad.

Hay un **Tech Lead humano** que sí decide. Tu trabajo no es evitar molestarlo: es darle decisiones bien planteadas y
ejecutar impecablemente las que ya tomó.

**El fallo más caro no es preguntar de más. Es inventar una respuesta a algo que no te correspondía responder, y
enterrarla en un commit o en un comentario.**

---

## 1. El ciclo obligatorio: LEER → CONTRASTAR → PLANTEAR → EJECUTAR → REPORTAR

1. **LEER**, antes de escribir una sola línea: la lectura en frío de `CLAUDE.md §Orden de lectura`, y **los tests
   que cubren lo que vas a tocar**, que son la especificación real, más fiable que cualquier documento.
2. **CONTRASTAR — la regla del `grep`.** La documentación describe intenciones; **el código es la única fuente de
   verdad sobre el estado.** Antes de citar un documento (`.ai/RULES.md`, `.ai/DOMAIN.md`, `.ai/BACKLOG.md`, un
   comentario) como justificación de algo, verifícalo contra el código: si dice «el valor X vive en tal archivo»,
   haz el `grep`. Si no coincide, **sigue el código**, no el documento, y repórtalo como divergencia
   documentación ↔ código.
3. **PLANTEAR.** Si algo dispara un criterio de §2, te detienes ahí: emites el bloque de §3 y terminas tu turno. No
   implementas una versión parcial «por avanzar».
4. **EJECUTAR.** Sólo lo que la fase pide (`CLAUDE.md §Alcance`). Nada adyacente, por tentador que sea.
5. **REPORTAR.** Con la plantilla de §9, que es el único formato de reporte final.

---

## 2. Criterios de parada — cuándo DEBES detenerte

Tienes **el mandato explícito** de parar. No es un permiso: es una obligación. Seguir cuando se cumple alguno de
estos criterios es un incumplimiento del protocolo, aunque el código funcione y los tests pasen.

### 2.1 Contrato

La tarea cambiaría el contrato con otro sistema (`.ai/RULES.md §Contrato HTTP`): una URL, un verbo, un nombre de
campo, un código de estado, una clave del envelope o el texto de un mensaje. **Detente incluso si crees que el
cambio es correcto**: especialmente entonces, porque es una decisión de coordinación, no una corrección técnica.

También te detienes si necesitas la forma exacta de una respuesta y nada del repositorio la fija (tests de
contrato, esquemas, snapshots): **no la adivines**.

### 2.2 Sin sentido lógico

- La premisa de la fase es falsa (el archivo no existe, el método hace otra cosa, el bug ya está arreglado).
- Dos instrucciones se contradicen.
- El resultado pedido no resolvería el problema descrito.
- Los datos que verificas dicen lo contrario de lo que la fase afirma.
- Los documentos del protocolo se contradicen entre sí o con el estado (`bin/check-docs.sh` en rojo).

### 2.3 Arquitectura

La tarea te obligaría a saltarte `.ai/RULES.md`: duplicar lógica que ya existe, crear una segunda fuente de verdad,
añadir una exención a un gate o a un test de arquitectura, meter una dependencia prohibida en una capa.

### 2.4 Producto

Reconocerás una decisión de producto porque **hay más de una respuesta técnicamente correcta y elegir entre ellas
cambia lo que el usuario experimenta**: cuánto dura algo, cuándo se cierra algo, si un usuario debe enterarse de
algo. También es de producto cualquier regla de negocio que no esté escrita en `.ai/DOMAIN.md`.

Puedes enumerar las opciones con sus consecuencias. **No puedes elegir.**

### 2.5 Defecto mayor

Si mientras arreglas A encuentras B, y B es más grave: **no arregles B, y no sigas con A en silencio.** Repórtalo
de inmediato, con evidencia, y pregunta si el orden cambia.

### 2.6 No se puede probar

Si no se te ocurre cómo escribir un test que falle antes de tu cambio y pase después, todavía no has entendido el
cambio. Explica el obstáculo.

**Nunca inventes una causa raíz para justificar un atajo de test.** Si vas a declarar que algo es un bug del
framework o de una librería, demuéstralo antes con un caso mínimo reproducible. Un diagnóstico inventado acaba en
concesiones de diseño construidas sobre nada.

### 2.7 Un test existente tendría que cambiar

Para que tu cambio pase habría que modificar, saltar o relajar un test o una aserción existentes. Los tests sólo se
añaden; si uno te parece equivocado, lo decide el Tech Lead.

### 2.8 Dependencia nueva

La tarea requiere instalar un paquete que el proyecto no tiene, aunque la fase lo dé por hecho.

### 2.9 Zona sensible

La tarea toca una de las zonas que `.ai/RULES.md §Zonas sensibles` declara (autenticación, pagos, cálculos de los
que depende el negocio…) de una forma que la fase no describe con precisión.

### 2.10 Un criterio de éxito no se puede cumplir tal como está escrito

Cada casilla del §5 de la fase se ejecuta **tal como está escrita**: el comando que dice, contra lo que dice y con
el motor o el servicio que dice. Su salida —o su evidencia, si no es un comando— se pega **entera** en
«Verificación» del RESULTADO, y entonces se marca la casilla. Si no se puede ejecutar así (falta un servicio o un
dato, el comando está mal escrito, depende de algo que la fase no controla) o no se cumple, **te detienes**:
corregir el criterio o moverlo a otra fase lo decide el Tech Lead.

**Nunca** marques una casilla con otra prueba que te parezca equivalente, ni resumas su salida «por brevedad». Una
fase `HECHA` tiene todas las casillas de su §5 marcadas: `bin/check-docs.sh` rechaza la que no. El criterio de
cierre de una épica se comprueba igual.

---

## 3. El bloque STOP & ASK

Cuando pares, escribes exactamente esto y **terminas tu turno**. No implementas nada mientras esperas.

```markdown
## 🛑 STOP & ASK

**Tarea:** [una frase]
**Criterio disparado:** [§2.1 contrato | §2.2 sin sentido | §2.3 arquitectura | §2.4 producto | §2.5 defecto mayor |
                        §2.6 no testeable | §2.7 test existente | §2.8 dependencia | §2.9 zona sensible |
                        §2.10 criterio de éxito]

### Qué encontré
[Hechos verificados, con archivo y clase, método o sección. Sin interpretación.]

### Por qué me detengo
[Qué se rompería, o qué no se puede decidir sin el Tech Lead.]

### Opciones
**A) [nombre]** — qué implica · qué rompe · coste · reversibilidad
**B) [nombre]** — ídem
**C) No hacer nada** — qué pasa si se deja como está

### Mi recomendación (no vinculante)
[Cuál elegirías y por qué. Una recomendación clara ayuda; una decisión unilateral, no.]

### Qué necesito
[La pregunta concreta, respondible con una frase.]

### Estado del repositorio
[SIN CAMBIOS] o [cambios parciales en: rutas — y si son reversibles]
```

**Un STOP & ASK bien formulado es un entregable valioso, no un fracaso.** Cinco de éstos valen más que un commit que
decidió por el Tech Lead.

**Entrega.** El registro es siempre el archivo: el bloque se escribe en el §8 de la fase, con fecha, con cualquier
herramienta. En la conversación:

- Si tu herramienta tiene **preguntas nativas de opción múltiple** (p. ej. `AskUserQuestion` en Claude Code), haz la
  pregunta con ellas en vez de pegar el bloque: una pregunta por decisión, las opciones con su consecuencia, la
  recomendada primero. Si hay más preguntas de las que caben en una ronda, primero las que bloquean.
- Si no las tiene, emite el bloque tal cual.

Antes de seguir, copia la respuesta al archivo (§8 y, si aplica, la columna `Respuesta` de `.ai/DOMAIN.md`) con su
fecha. Si la respuesta llega como texto libre en vez de una opción, léela entera: puede pedir otra cosa.

**Regla de traza.** Si la pregunta debe sobrevivir a la fase —cruza su alcance, es de producto o de arquitectura,
afecta a otra épica o queda sin resolver al cerrar—, créala también como fila de
`.ai/DOMAIN.md §Decisiones pendientes`, con su `Categoría` y con `Propuesto por` apuntando a la fase. Si es
estrictamente local y se resuelve antes del cierre, se queda sólo en el §8 de la fase. El Tech Lead tiene que ver
todas las decisiones abiertas en una sola tabla.

---

## 4. Cuando un gate se pone rojo por algo ajeno a la fase

`bash bin/verify.sh` es el único árbitro (`CLAUDE.md §Verificación`). Si se pone rojo por algo que reproduces en la
rama base sin tus cambios, no lo arrastres:

- Si es configuración trivial (ignorar un directorio generado, por ejemplo), arréglalo en su propio commit y dilo en
  el reporte.
- Si no lo es, anótalo en `.ai/BACKLOG.md` y **para y pregunta**. Una fase no se cierra en rojo por ruido ajeno.

---

## 5. Obediencia arquitectónica

Todo `.ai/RULES.md` es innegociable salvo autorización explícita y por escrito del Tech Lead en la fase; si la fase
la contiene, cítala en el reporte. Además, estas prohibiciones de procedimiento valen para cualquier stack (las del
stack viven en `.ai/RULES.md §Lista negra`):

1. ⛔ **No añadas exenciones a un gate.** Ni a un test de arquitectura, ni al linter, ni al analizador estático, ni
   a la baseline de deuda. Si tu código no pasa la barandilla, el código está mal.
2. ⛔ **No escribas tests que escaneen el código fuente con expresiones regulares.** Una regex no distingue código
   de un comentario o de un literal de cadena. Las reglas sobre el código las aplica la herramienta que entiende el
   código (el plugin de arquitectura, el linter, el analizador).
3. ⛔ **No dupliques lógica «para preservar comportamiento».** Si dos caminos deben comportarse igual, extrae uno
   compartido y prueba ambos contra él. Documentar una duplicación no la hace segura: la hace permanente.
4. ⛔ **No conviertas deuda en invariante testeada.** Nada de un test que fija «hace X y además Y (duplicado)».
5. ⛔ **No introduzcas un segundo sitio donde vive un valor de negocio.** Una constante repetida en dos sitios con
   un comentario que dice «cambiar una sin la otra es un bug» es el bug.
6. ⛔ **No mantengas código viejo en paralelo con su reemplazo.** Si te tienta arreglar algo «por simetría» en la
   versión vieja: para y pregunta si la versión vieja debería seguir existiendo.

---

## 6. Verificación — la suite completa manda

**Ninguna fase se cierra sin `bash bin/verify.sh` en verde.** Qué comprueba, en qué orden y con qué baseline lo
define el propio script; no se repite aquí.

- La baseline (los números que nunca empeoran: conteo de tests, deuda congelada) vive en `bin/verify.sh`. Si un
  cierre los empeora, algo se borró o se saltó.
- ⛔ Prohibido `skip`, `todo`, tests marcados como incompletos o grupos excluidos para que la suite pase.
- Un test que falla **señala un problema real**. Los tests sólo se **añaden**; las aserciones existentes no se
  relajan (§2.7).
- **Cobertura obligatoria para todo cambio:** un test que falla antes del cambio y pasa después. Si el cambio es
  un fix, el test reproduce el bug.
- ⛔ Prohibido llamar a la red real en un test.
- Los procedimientos propios del stack (baselines de análisis estático, supresiones del linter) viven en
  `.ai/RULES.md §Verificación del stack`.

---

## 7. Documentación: dónde va cada cosa

| Archivo | Contiene | Quién escribe |
|---|---|---|
| `CLAUDE.md` | Protocolo de fases: lectura en frío, ramas, pasos, commits, cierre | Sólo el Tech Lead |
| `.ai/RULES.md` | Reglas de código: stack, alcance, contrato, arquitectura, lista negra | Sólo el Tech Lead |
| `.ai/WORKFLOW.md` | Este protocolo | Sólo el Tech Lead |
| `.ai/PLANNING.md` | Cómo se planifica una épica o una fase | Sólo el Tech Lead |
| `.ai/STATE.md` | El puntero: fase activa, mapa de fases, bloqueos, últimos movimientos | La IA, en cada cierre y en cada sincronización |
| `.ai/DOMAIN.md` | Glosario, reglas de negocio, decisiones tomadas y pendientes | La IA añade; nadie reescribe lo anterior |
| `.ai/BACKLOG.md` | Hallazgos fuera de alcance y pendientes en otros repos | La IA añade, sin arreglarlos |
| `.ai/PROTOCOL.md` | Mejoras del protocolo que propone cada fase | La IA añade al cerrar; el Tech Lead las aplica |
| `.ai/project/` | Lo que decide este proyecto y las reglas citan: contexto, versiones, alcance, contrato, zonas sensibles | El Tech Lead, o la fase que lo lista en su §4 |
| `.ai/epics/` | Épicas y fases: el encargo y el registro de lo que pasó | Quien planifica; el ejecutor rellena el RESULTADO |
| `.ai/handoffs/` | Entregas del otro repo, copiadas | La sesión de planificación |
| `docs/` | Lo que no es protocolo: arquitectura, runbooks, contrato… (`docs/README.md`) | Según `docs/README.md` |

**Reglas de escritura:**

1. **Nunca modifiques `CLAUDE.md`, `.ai/RULES.md`, `.ai/WORKFLOW.md` ni `.ai/PLANNING.md` desde una fase.** Si crees
   que algo está mal: STOP & ASK, y la propuesta a `.ai/PROTOCOL.md`.
2. **Todo hallazgo lateral va a `.ai/BACKLOG.md`**, con archivo, clase o método y evidencia. No a un comentario.
3. **No clasifiques la severidad tú.** Describe el impacto observable (¿afecta a datos de usuario, a la seguridad, a
   dinero, a lo que el usuario ve?) y deja que el Tech Lead decida la prioridad. Un defecto de facturación mal
   descrito acaba archivado como deuda técnica.
4. **Un comentario en el código no es un canal de comunicación.** Si un humano tiene que saberlo, va en el reporte
   y en `.ai/BACKLOG.md`, no enterrado en un docblock de cuarenta líneas.
5. **Las referencias entre archivos se verifican con `grep` en una sesión en frío.** Cita el nombre de la clase, el
   método o la sección, nunca un número de línea: un número no sobrevive a un cambio. Si el `grep` no encuentra el
   destino, la referencia miente y se corrige.
6. **Las cifras del RESULTADO se copian de la salida de un comando**, no de memoria: el RESULTADO es la evidencia
   con la que se verifica la fase.
7. **Entre repos**, lo que dice `CLAUDE.md §El otro repositorio`: su código se lee y se cita; sus documentos no.

---

## 8. Cuando la fase cita una regla para NO hacer algo

Situación frecuente y delicada. Si la fase (o tu propio razonamiento) usa una cláusula de `.ai/RULES.md` para
justificar **no** arreglar algo, aplica este filtro antes de aceptarla:

1. **¿La cita es literalmente correcta?** Verifica el texto de la regla.
2. **¿Sigue vigente el contexto en que se escribió?** Una regla escrita para una refactorización que preserva el
   comportamiento puede ser justo lo contrario de lo que hace falta en una fase de corrección de bugs.
3. **¿La regla describe una decisión o un estado?** El glosario de `.ai/DOMAIN.md` **describe** el sistema; no lo
   bendice. «N = 3» documenta lo que hay, no que 3 sea correcto.

Si los tres filtros no se superan con claridad: **STOP & ASK**, con la cita, el contexto original y por qué crees que
ya no aplica. **No arreglar es una decisión, no un valor por defecto.** Y las decisiones las toma el Tech Lead.

---

## 9. Plantilla del reporte final

```markdown
## Qué se hizo
[tres o cuatro frases]

## Archivos
- creados: ruta (N líneas) — propósito en una frase
- modificados: ruta — qué cambió en una frase

## Tests
- añadidos: N (cuáles y qué fijan)
- modificados: N — justificación obligatoria por cada uno (§2.7)

## Verificación
- bash bin/verify.sh: [VERDE | ROJO — gate que falla y el fallo concreto]
- baseline de bin/verify.sh: [IGUAL | mejoró: qué número y a cuánto]

## Contrato HTTP
[SIN CAMBIOS] o [CAMBIO AUTORIZADO por: cita de la fase + descripción] · traspaso: [fila de BACKLOG | ninguno — motivo]

## Commits aplicados
`git log --oneline <hash_de_arranque>^..HEAD`, uno por línea, incluido el de cierre. `git status` limpio.

## Divergencias documentación ↔ código detectadas
- archivo — el documento dice X, el código hace Y

## Hallazgos fuera de alcance (copiados a .ai/BACKLOG.md)
- descripción + impacto observable, sin asignar severidad

## Decisiones que tomé y podrías querer revisar
- donde elegí entre alternativas razonables

## Qué mejoraría del protocolo (copiado a .ai/PROTOCOL.md)
- qué estorbó y qué propongo

## Lo que la siguiente fase necesita saber
[lo que la siguiente fase da por hecho y ya es cierto, o ya no lo es]
```

Cierra con dos líneas fuera de la plantilla: qué debe revisar el Tech Lead y con qué comando
(`git diff <base>...HEAD`).

---

## 10. Las cinco frases que resumen el protocolo

1. **El código manda sobre la documentación.** Haz el `grep` antes de citar.
2. **Detente y pregunta.** Un STOP & ASK es un entregable, no un fracaso.
3. **`bash bin/verify.sh` en verde, siempre.** Baseline vigente y mejorando, nunca empeorando.
4. **No decidas de producto.** Enumera opciones, recomienda, espera.
5. **No entierres nada en un commit o en un comentario.** Si un humano debe saberlo, va en el reporte.
