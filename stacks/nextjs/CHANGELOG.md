# Changelog — nextjs

El stack Next.js: lo que añade al núcleo. Versiones con [SemVer](https://semver.org/lang/es/) y etiqueta
`nextjs-vX.Y.Z` (README.md §Versiones y etiquetas). Lo más reciente, arriba.

## [Sin publicar] — 2.0.0-dev

Compatible con el núcleo `>=2.0.0-dev <3.0.0`.

### Añadido

- `stack.json`: nombre, versión, rango compatible del núcleo, archivos que aporta y gates de su `bin/verify.sh`.

### Cambiado

- `.ai/RULES.md` deja de tener `{{RELLENAR}}`. La tabla `§Stack y versiones exactas` queda con el paquete y su
  nota; la versión de cada uno es del proyecto y vive en `.ai/project/DECISIONS.md`, contra `package.json`.
- `.ai/RULES.md`: la autenticación y las cabeceras del cliente, los idiomas, el tenant, el alcance adicional, las
  zonas sensibles del negocio y los ámbitos del dominio pasan a `.ai/project/` y aquí se citan.

## 1.x

La carpeta `nextjs/` del kit, copiada entera con `cp -Rn`. Se actualiza con `install.sh --upgrade --stack nextjs`.
