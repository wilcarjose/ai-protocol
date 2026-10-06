<!-- PR de una fase (.claude/skills/phase/cierre.md §Entrega). El RESULTADO de la fase es el reporte: aquí sólo el
     resumen y los enlaces. Sin tarea externa, «—». Lo que no aplica, «—», sin borrar la línea. -->

## Fase

- **Fase:** `<NN-slug>/<FF>` — `.ai/epics/<NN-slug>/phase-<FF>.md`
- **Tarea externa:** <ID del paquete de `.ai/stages/`, o —>
- **Estado al cerrar:** <HECHA · ESPERA_EVIDENCIA · BLOQUEADA · VERIFICACION_ROJA>
- **Base:** <`epic/<NN-slug>` o `main`>

<!-- Qué cambia, en dos o tres líneas, copiado de «Qué se hizo» del RESULTADO. -->

## Checklist

- [ ] `bash bin/verify.sh` en verde en local; la CI lo repite.
- [ ] `sh bin/check-docs.sh --strict` en verde.
- [ ] Criterios de éxito marcados, con su salida en «Verificación» o en `evidence/`.
- [ ] Sección «Revisión» de la fase sin bloqueantes abiertos.
- [ ] Ningún archivo del protocolo cambia fuera de un commit `(protocol)` (gate «protocolo»).
- [ ] Contrato HTTP: <SIN CAMBIOS, o el cambio autorizado y su traspaso en `.ai/BACKLOG.md`>.
- [ ] Pasos de despliegue en `docs/runbooks/release.md §Pasos por fase`: <los que añade, o ninguno>.

## Evidencia pendiente

<!-- Sólo en ESPERA_EVIDENCIA: las casillas [humano] abiertas y quién aporta cada evidencia. Llega después, con un
     commit «chore(phase-<NN>-<FF>): evidence» (.claude/skills/phase/cierre.md §Evidencia humana). -->

—

## Para el Tech Lead

<!-- Preguntas abiertas, decisiones tomadas, traspasos y hallazgos que hay que mirar, o «nada». -->

—
