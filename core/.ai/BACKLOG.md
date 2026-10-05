# Hallazgos fuera de alcance

<!-- Lo que la IA encuentra mientras trabaja y NO debe arreglar en la fase activa. Sin esto, o lo arregla (y la
     fase se descontrola) o lo olvida (y se pierde). Se revisa al planificar (.claude/skills/planning/SKILL.md §Épica, triaje).

     NO es un registro de decisiones: si un hallazgo pide una decisión de producto o de arquitectura, su pregunta
     va a .ai/DOMAIN.md §Decisiones pendientes y esta fila la cita.

     bin/check-docs.sh lee esta tabla: no cambies sus columnas.

     · #: correlativo, nunca se reutiliza.
     · Área: el módulo o la capa de este repo (api, auth, tests, ci…), o el nombre de un repo hermano
       (CLAUDE.md §El otro repositorio) si lo que hay que hacer es allí.
     · Impacto: lo observable, sin severidad (.ai/WORKFLOW.md §Documentación). Uno de:
         datos      expone o modifica datos de usuarios
         seguridad  autenticación, sesiones, permisos
         dinero     pagos, planes, facturación
         visible    defecto que el usuario ve
         interno    deuda invisible (tests, CI, lint, infraestructura)
       Una fila cerrada lleva «—».
     · Destino: la épica que lo va a cerrar (NN o NN-slug), o «—».
     · Hallazgo: archivo y clase o método, evidencia e impacto. Una fila de un repo hermano lleva además
       **Cambio:** (qué hacer allí), **Origen:** (fase NN/FF y commit) y, si condiciona el despliegue,
       **Despliegue:** (CLAUDE.md §El otro repositorio).
     · Cerrado por: la fase o el commit que lo cerró, o «—».
     · Estado: abierto · planificado — NN/FF · cerrado — NN/FF · descartado — <motivo>.

     Aquí sólo viven las filas abiertas o planificadas. Al cerrar o descartar una, la fase que lo hace la pasa
     entera a .ai/archive/BACKLOG.md (.claude/skills/phase/cierre.md §Archivo de la memoria); bin/check-docs.sh lo
     exige. Su # no se reutiliza. -->

| # | Fecha | Área | Impacto | Destino | Hallazgo | Cerrado por | Estado |
|---|---|---|---|---|---|---|---|
