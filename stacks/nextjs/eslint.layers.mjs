// eslint.layers.mjs — la regla de capas de .ai/RULES.md §Estructura y regla de dependencias, aplicada por el linter.
//
// Es del kit ai-protocol: la actualiza install.sh --upgrade y una fase no la cambia (.ai/WORKFLOW.md §Archivos del
// protocolo). eslint.config.mjs, que es del proyecto, la importa; el gate «capas» de bin/verify.sh comprueba que
// sigue activa.
//
//   app  →  features  →  entities  →  shared
//
// - Cada capa importa sólo de las de su derecha, y dentro de sí misma.
// - Una feature no importa de otra feature, ni una entidad de otra entidad.
// - Entre carpetas se entra por su index.ts: nadie importa de las tripas de otra.
// - shared/ son segmentos (api/, ui/, lib/, config/…) que se importan entre sí, también por su index.ts.
//
// El alias «@/…» de tsconfig.json se resuelve con eslint-import-resolver-typescript; sin él, los imports con alias
// no se clasificarían y la regla no los vería.
import boundaries from "eslint-plugin-boundaries";

// La entrada de cada carpeta, relativa a ella.
const ENTRY = "index.{ts,tsx}";

const layers = [
  {
    files: ["src/**/*.{js,jsx,mjs,ts,tsx}"],
    plugins: { boundaries },
    settings: {
      "import/resolver": { typescript: { alwaysTryTypes: true }, node: true },
      "boundaries/elements": [
        { type: "app", pattern: "src/app" },
        { type: "feature", pattern: "src/features/*", capture: ["feature"] },
        { type: "entity", pattern: "src/entities/*", capture: ["entity"] },
        { type: "shared", pattern: "src/shared/*", capture: ["segment"] },
      ],
    },
    rules: {
      // Una sola regla: lo que no permite una política, se prohíbe. Hacia otra carpeta, sólo su index.
      "boundaries/dependencies": [
        2,
        {
          default: "disallow",
          message:
            "rompe la regla de capas (app → features → entities → shared; entre carpetas, por su index.ts): .ai/RULES.md §Estructura y regla de dependencias",
          policies: [
            { allow: { dependency: { relationship: { to: "internal" } } } },
            { from: { element: { type: "app" } }, allow: { to: { element: { types: "{feature,entity,shared}", fileInternalPath: ENTRY } } } },
            { from: { element: { type: "feature" } }, allow: { to: { element: { types: "{entity,shared}", fileInternalPath: ENTRY } } } },
            { from: { element: { type: "entity" } }, allow: { to: { element: { type: "shared", fileInternalPath: ENTRY } } } },
            { from: { element: { type: "shared" } }, allow: { to: { element: { type: "shared", fileInternalPath: ENTRY } } } },
          ],
        },
      ],
    },
  },
];

export default layers;
