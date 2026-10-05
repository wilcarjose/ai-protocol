# Protocolo de trabajo con IA

> Punto de entrada de cualquier sesión de IA en este repositorio: qué leer, qué no se hace y dónde vive cada cosa.
> Es del kit `ai-protocol`, como `.ai/RULES.md`, `.ai/rules/`, `.ai/WORKFLOW.md` y `.claude/skills/`, y lo actualiza
> `install.sh --upgrade`. Lo que decide este proyecto vive en `.ai/project/`, que el instalador no toca nunca.
>
> Jerarquía si algo choca: `.ai/RULES.md` > `.ai/WORKFLOW.md` > las skills > este archivo. **Cada regla vive en un
> solo archivo** y los demás la citan por el nombre de su sección; si puede incumplirse en silencio, lleva su
> chequeo en `bin/check-docs.sh`. `AGENTS.md` sólo redirige aquí.

## Orden de lectura (sesión en frío)

1. `.ai/STATE.md`: qué fase está activa y qué la bloquea.
2. `.ai/project/README.md`: el contexto operativo y los repos hermanos. El resto de `.ai/project/` se lee cuando
   una regla lo cita.
3. `.ai/DOMAIN.md`: lo decidido. **No se vuelve a preguntar.** Lo cerrado o reemplazado está en `.ai/archive/`.
4. `.ai/RULES.md`: el núcleo de las reglas de código. Los temas de `.ai/rules/` se leen cuando la fase los cita.
5. `.ai/WORKFLOW.md`: cuándo parar, cómo preguntar y cómo verificar.
6. El archivo de la fase activa y lo que cite en «Contexto que debes leer antes».
7. **El código real**, antes de citar un documento como evidencia de algo: si discrepan, gana el código y lo
   reportas (`.ai/WORKFLOW.md §El ciclo obligatorio`).

## Qué hace cada sesión

| Para | Skill | Sin skills, lee |
|---|---|---|
| Ejecutar la fase activa, o la que se pida | `/phase [<epica> <FF>]` | `.claude/skills/phase/SKILL.md` |
| Rescatar una fase que otra sesión dejó a medias | `/close [<epica> <FF>]` | `.claude/skills/close/SKILL.md` |
| Crear o cambiar una épica o una fase | `/planning` | `.claude/skills/planning/SKILL.md` |

«Ejecuta la siguiente fase» equivale a `/phase` sin argumentos. Una sesión, una fase.

## Alcance

- Lo que encuentres de más y no haga falta tocar va a `.ai/BACKLOG.md`. **No lo arregles.**
- Si para dejar tu cambio coherente tienes que tocar algo contiguo (el resto del comentario que reescribes, un
  import que queda huérfano), hazlo y decláralo en el RESULTADO. Es alcance mínimo, no ampliación.
- Si el cambio obliga a tocar otro archivo que no está en los «Archivos» de la fase, o un comportamiento que la fase
  no nombra: **para y pregunta** antes de tocarlo.

## El otro repositorio

Los repos hermanos se declaran en `.ai/project/README.md §Repos hermanos`, cada uno en su carpeta (`../<repo>/`) y
con su propio protocolo.

- **Su código se lee y se cita** (`../<repo>/app/...`) cuando hay una duda real del contrato. Escribe también el
  hecho observable por HTTP, que es lo que no envejece.
- **En él no se escribe**: ni archivos, ni documentos, ni comandos que lo cambien.
- **Sus documentos no se citan** (su `CLAUDE.md`, su `.ai/`, su `docs/`), ni al revés. Lo que entrega llega copiado
  a `.ai/handoffs/`. Lo vigila el chequeo «cross-repo» de `bin/check-docs.sh`.
- La fase que cambia algo que el otro repo consume deja su traspaso
  (`.claude/skills/phase/cierre.md §Traspaso al otro repo`).

## Cosas que no se hacen

- Instalar una dependencia nueva sin preguntar (`.ai/WORKFLOW.md §Dependencia nueva`).
- Ampliar el alcance de la fase o arreglar lo que encuentres de paso (§Alcance).
- Modificar, saltar o debilitar un test para que pase un cambio, o bajar el nivel de un linter o de un analizador.
- Añadir exenciones a un gate (`.ai/WORKFLOW.md §Obediencia arquitectónica`).
- Dejar llamadas de depuración en el código (las de `.ai/RULES.md §Lista negra`).
- Tocar los archivos de «No tocar» de la fase o lo que `.ai/RULES.md §Alcance` deja fuera.
- Escribir en el otro repositorio o citar sus documentos (§El otro repositorio).
- Modificar este archivo, `.ai/RULES.md`, `.ai/rules/`, `.ai/WORKFLOW.md` o las skills desde una fase. Si crees que
  están mal: STOP & ASK, y la propuesta a `.ai/PROTOCOL.md`.
- `git push` (`.claude/skills/phase/SKILL.md §Commits durante la fase`).
