# Changelog — nextjs

El stack Next.js: lo que añade al núcleo. Versiones con [SemVer](https://semver.org/lang/es/) y etiqueta
`nextjs-vX.Y.Z` (README.md §Versiones y etiquetas). Lo más reciente, arriba.

## [Sin publicar] — 2.0.0-dev

Compatible con el núcleo `>=2.0.0-dev <3.0.0`.

### Añadido

- `stack.json`: nombre, versión, rango compatible del núcleo, archivos que aporta y gates de su `bin/verify.sh`.
- `.ai/rules/`: las reglas por tema que la fase cita cuando las toca: `contrato.md` (cómo se conoce el contrato,
  errores, claves de caché, formas variables), `arquitectura.md` (estado y componentes) y `tests.md`.

### Cambiado

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
  nota; la versión de cada uno es del proyecto y vive en `.ai/project/DECISIONS.md`, contra `package.json`.
- `.ai/RULES.md`: la autenticación y las cabeceras del cliente, los idiomas, el tenant, el alcance adicional, las
  zonas sensibles del negocio y los ámbitos del dominio pasan a `.ai/project/` y aquí se citan.

## 1.x

La carpeta `nextjs/` del kit, copiada entera con `cp -Rn`. Se actualiza con `install.sh --upgrade --stack nextjs`.
