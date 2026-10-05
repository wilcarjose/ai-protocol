# Manifiesto de despliegue — pasos por fase

> Lo que hay que hacer en producción al desplegar cada fase, además de desplegar el código. Lo escribe quien
> cierra la fase (`.claude/skills/phase/cierre.md §Cierre de fase`), con los nombres reales (la migración, el
> comando, la variable), y lo lee quien despliega, que puede llegar meses después.
>
> Al hacer un despliegue, las filas desplegadas se marcan con la fecha en «Hecho en producción». Cuando todas lo
> están, la tabla se archiva (p. ej. en `docs/archive/releases/<AAAA-MM-DD>.md`) y aquí se empieza una vacía.

## Pasos por fase

<!-- Una fila por paso. «Fase» en la forma NN/FF: bin/check-docs.sh comprueba que toda fase HECHA que declara
     migraciones tiene aquí su fila. «Cuándo»: antes, durante o después de desplegar el código, y respecto a qué. -->

| Fase | Paso | Cuándo | Hecho en producción |
|---|---|---|---|
