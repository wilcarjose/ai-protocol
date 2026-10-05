---
name: review
description: Revisa la rama de una fase con el subagente revisor, de solo lectura, y escribe sus hallazgos en la sección «Revisión» de la fase. /phase la ejecuta antes de cerrar; también se lanza a mano.
argument-hint: "[epica numero-de-fase]"
---

# /review — revisar una fase

Argumentos: `$ARGUMENTS`. Sin argumentos, la fase activa de `.ai/STATE.md`; con argumentos, `<epica>` y `<FF>`. Se
ejecuta en la rama de la fase y con el árbol limpio: lo que no está commiteado no se revisa.

1. **La base** es el padre del commit de arranque:
   `git log --format=%h --grep='^chore(phase-<NN>-<FF>): start' | tail -n 1`, y su `^`. Sin commit de arranque no
   hay nada que revisar: dilo y para.
2. **El revisor.** Lanza el subagente `reviewer` (`.claude/agents/reviewer.md`) con la ruta de la fase, la base y el
   número de esta revisión (las que ya tiene «Revisión», más una). Sólo eso: ni tu opinión ni la conversación, que
   son lo que la revisión tiene que poder contradecir. Sin subagentes, ábrelo en una sesión nueva con ese archivo
   como instrucciones; en la misma sesión, sólo si el Tech Lead lo acepta, y dilo en la revisión.
3. **Escríbela** en la sección «Revisión» de la fase tal como la devuelve: sustituye «Sin revisar.» o va debajo de
   la anterior, que no se borra. Si la fase no tiene la sección (se escribió con una plantilla anterior), créala
   justo antes de `---`.
4. **Cada bloqueante** se resuelve antes de cerrar:
   - Si se arregla dentro del alcance, su `fix(...)` va en su propio commit
     (`.claude/skills/phase/SKILL.md §Commits durante la fase`), la casilla se marca con
     `— resuelto en <hash>`, y vuelven `bash bin/verify.sh` y otra revisión.
   - Si el arreglo sale del alcance, o el hallazgo te parece falso: STOP & ASK (`.ai/WORKFLOW.md §STOP & ASK`).
     Sólo el Tech Lead lo descarta, y la casilla se marca con `— descartado por el Tech Lead (<fecha>): <motivo>`.
   - Si la segunda revisión sigue con bloqueantes: STOP & ASK.
5. **Los no bloqueantes** no se arreglan en la fase salvo que estén en su alcance; lo de otra parte va a
   `.ai/BACKLOG.md` (`CLAUDE.md §Alcance`).

`bin/check-docs.sh` no deja una fase en `HECHA` ni en `ESPERA_EVIDENCIA` sin revisión o con un bloqueante sin
marcar. La revisión entra en el commit de cierre (`.claude/skills/phase/cierre.md §Cierre de fase`); lanzada a mano
fuera del cierre, no se commitea.
