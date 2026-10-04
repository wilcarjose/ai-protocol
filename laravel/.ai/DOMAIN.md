# Dominio y decisiones — {{RELLENAR: nombre del proyecto}}

<!-- La memoria larga. Todo lo que está escrito aquí NO se vuelve a preguntar. Cuando se resuelve un bloqueo en
     la conversación, la decisión termina aquí o se pierde.

     Este archivo describe DECISIONES, no el estado del código: antes de citar una línea de aquí como evidencia
     de que algo «vive en tal sitio», compruébalo en el código (.ai/WORKFLOW.md §El ciclo obligatorio).

     Lo anterior no se reescribe: una decisión que cambia se escribe como enmienda nueva que cita la anterior. -->

## Qué es el proyecto

{{RELLENAR: dos o tres frases de negocio. Qué hace el producto, para quién, y en qué momento está (desarrollo,
producción, temporada baja…).}}

## Glosario

<!-- Los términos del negocio, cómo se llaman en el código y en la interfaz, y la trampa de cada uno. Un término
     ambiguo sin escribir aquí es lo que hace alucinar a un agente. -->

| Término | Qué es | Ojo |
|---|---|---|

## Reglas de negocio vigentes

<!-- Reglas que el código tiene que respetar y que no son obvias leyéndolo. Cada una con la decisión que la
     fijó (id o fecha). -->

Ninguna todavía.

## Contrato con el otro repositorio

<!-- Sólo si hay repo hermano (CLAUDE.md §El otro repositorio). Lo que este repo da por cierto del otro, escrito
     como hecho observable por HTTP («GET /api/x devuelve 404 si…»), con la decisión o el traspaso que lo fijó.
     Si no hay repo hermano: «No aplica.» -->

Nada todavía.

## Decisiones tomadas

<!-- Formato de cada entrada:

     ### AAAA-MM-DD — <título corto> (fase NN/FF | sesión de planificación)

     Qué se decidió, por qué, y qué alternativas se descartaron. Si responde a una fila de §Decisiones pendientes,
     cita su id. -->

Ninguna todavía.

## Decisiones pendientes

<!-- Toda pregunta que sobrevive a una fase (.ai/WORKFLOW.md §STOP & ASK, regla de traza). bin/check-docs.sh lee esta
     tabla: no cambies sus columnas.

     · #: D1, D2… correlativo, nunca se reutiliza.
     · Categoría: producto · arquitectura · contrato · bug · otro.
     · Bloquea: NN/FF (épica/fase), NN (épica completa), varias separadas por comas, o «—».
     · Propuesto por: el archivo donde está el detalle (la fase, una página de docs/…).
     · Estado: pendiente · respondida.
     · Respuesta: «<opción> — AAAA-MM-DD» y, si hace falta, la entrada de §Decisiones tomadas que la desarrolla. -->

| # | Decisión | Categoría | Bloquea | Propuesto por | Estado | Respuesta |
|---|---|---|---|---|---|---|
