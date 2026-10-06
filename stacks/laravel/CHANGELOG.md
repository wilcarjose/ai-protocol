# Changelog — laravel

El stack Laravel: lo que añade al núcleo. Versiones con [SemVer](https://semver.org/lang/es/) y etiqueta
`laravel-vX.Y.Z` (README.md §Versiones y etiquetas). Lo más reciente, arriba.

## [Sin publicar] — 2.0.0-dev

Compatible con el núcleo `>=2.0.0-dev <3.0.0`.

### Añadido

- `.github/workflows/verify.yml`: la CI del proyecto, que corre `bin/verify.sh` completo en cada PR con todo el
  historial (los gates «protocolo» y «secretos» lo necesitan) y gitleaks en versión fija.
  La versión de PHP sale de `.php-version`.
- `bin/verify.sh`, gates «protocolo», «secretos» y «dependencias» (`composer audit`). «secretos» corre `gitleaks git`
  sobre el historial, también con `--fast`, y falla si falta gitleaks; «dependencias» va sólo en el verify completo,
  porque consulta la red.
- `.ai/project/verify.conf` (semilla): la baseline, `VERIFY_SERVICE` y `COMPOSE_CMD`, que salen de `bin/verify.sh`.
- `stack.json`: nombre, versión, rango compatible del núcleo, archivos que aporta y gates de su `bin/verify.sh`.
- `.ai/rules/`: las reglas por tema que la fase cita cuando las toca: `arquitectura.md` (estructura de `app/`,
  Actions, Value Objects, contratos, PHP 8.4+ y forma de las respuestas), `tests.md` (con la exploración local) y
  `rendimiento.md` (rendimiento, caché y colas).

### Cambiado

- `bin/verify.sh` es entero del kit: lee la configuración del proyecto de `.ai/project/verify.conf` y falla si no
  existe.
- `phpstan.neon` y `docs/README.md` pasan de `files` a `seed`: son del proyecto, el upgrade no los toca y el gate
  «protocolo» no los protege.
- `.claude/settings.json`: permite `git push [-u] origin phase/*`, `git fetch`, `gh pr create|view|checks|list`,
  `composer audit`, `gitleaks git` y `sh bin/check-protocol.sh`; bloquea el push a `main`, con `:` en el refspec,
  forzado, con borrado, `--mirror`, `--all` y `--tags`, y `gh pr merge`.
- Plantilla de fase: `> **Tipo:**` en la cabecera (código por defecto), los campos opcionales `Modo` y
  `Tarea externa`, las casillas `[humano]` en «Criterios de éxito» y la sección `## 10. Revisión`, fuera del
  RESULTADO, que escribe `/review`. Las plantillas citan `/plan-epic` y `/plan-phase` en vez de `/planning`.
- `.ai/RULES.md` queda como núcleo de innegociables (stack, alcance, contrato, zonas sensibles, verificación, lista
  negra y ámbitos), con `§Reglas por tema` como índice de `.ai/rules/`.
- Plantillas: la fase cita en su §2 la anterior con `sh bin/handoff.sh` y los temas de `.ai/rules/`; el RESULTADO
  enlaza la evidencia de las salidas largas y es el único reporte. Las citas a `.ai/PLANNING.md` y a las secciones
  que salieron de `CLAUDE.md` apuntan a las skills.
- `.claude/settings.json` permite `sh bin/handoff.sh` y `sh bin/measure-context.sh`.
- `.ai/RULES.md` deja de tener `{{RELLENAR}}`. La tabla `§Stack y versiones exactas` queda con el paquete y su
  nota; la versión de cada uno es del proyecto y vive en `.ai/project/DECISIONS.md`, contra `composer.json`.
- `.ai/RULES.md`: la autorización (`§Autorización`), el alcance adicional, las zonas sensibles del negocio y los
  ámbitos del dominio pasan a `.ai/project/` y aquí se citan.

## 1.x

La carpeta `laravel/` del kit, copiada entera con `cp -Rn`. Se actualiza con `install.sh --upgrade --stack laravel`.
