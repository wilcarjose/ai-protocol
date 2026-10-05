# Estado del proyecto — {{RELLENAR: nombre del proyecto y del repo}}

<!-- El puntero. Se lee al empezar CADA sesión y se reescribe al cerrar CADA fase. Si está desactualizado, la
     siguiente sesión empieza con información falsa.

     El formato exacto de las seis líneas de la cabecera lo lee bin/check-docs.sh: no las renombres, no las
     repitas y no escribas notas detrás del valor de «Épica activa», «Fase activa» ni «Archivo de la fase» (las
     notas van en §Bloqueo activo). Cómo se mueve el puntero: .claude/skills/phase/SKILL.md §Estado de una fase.
     Cómo se regeneran los contadores y las secciones derivadas: .claude/skills/phase/SKILL.md §Sincronización
     post-lectura.

     Este archivo no repite la baseline de la suite: vive en bin/verify.sh. -->

- **Épica activa:** —
- **Fase activa:** —
- **Archivo de la fase:** —
- **Decisiones abiertas:** 0 (0 bloquean la épica activa)
- **Pendientes en otros repos:** 0 (0 condicionan el despliegue)
- **Última actualización:** — (protocolo instalado; sin épicas todavía)

## Pendientes en otros repos

<!-- Sección derivada de .ai/BACKLOG.md: las filas cuya Área es un repo hermano y cuyo Estado no es cerrado ni
     descartado. Una fila condiciona el despliegue si lleva **Despliegue:**. No se edita a mano: se regenera. -->

| BACKLOG | Repo | Qué hay que cambiar | Condiciona el despliegue | Estado |
|---|---|---|---|---|

## Mapa de fases

<!-- Una fila por fase. El orden de las filas es el orden de ejecución. Estados: SIN_PLANIFICAR ·
     LISTA_PARA_EJECUTAR · EN_CURSO · BLOQUEADA · VERIFICACION_ROJA · ESPERA_EVIDENCIA · HECHA. «Cerrada» lleva la fecha del cierre,
     sea cual sea el estado final, o «—». -->

| Épica | Fase | Estado | Cerrada |
|---|---|---|---|

## Esperando evidencia

<!-- Derivada del mapa: las fases en ESPERA_EVIDENCIA, que el puntero salta, con su NN-slug/FF y lo que falta. -->

**Ninguna.**

## Bloqueo activo

<!-- Sección derivada de .ai/DOMAIN.md §Decisiones pendientes: las pendientes que bloquean la épica activa, una
     línea cada una con su id. Si no hay fase activa, qué hay que planificar. -->

**Ninguno.** No hay épicas planificadas: el siguiente paso es planificar la primera (`/plan-epic`).

## Últimos movimientos

<!-- Lo más reciente arriba, una línea por cierre y 10 como mucho (bin/check-docs.sh lo exige): las más viejas se
     borran, porque el detalle vive en el RESULTADO de cada fase. -->

- Protocolo instalado desde el kit `ai-protocol`.
