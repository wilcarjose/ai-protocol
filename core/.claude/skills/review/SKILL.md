---
name: review
description: Revisa la rama de una fase con el subagente revisor, de solo lectura, y escribe sus hallazgos en la sección «Revisión» de la fase. /phase la ejecuta antes de cerrar; también se lanza a mano.
argument-hint: "[epica numero-de-fase]"
---

# /review — revisar una fase

Argumentos: `$ARGUMENTS`. Sin argumentos, la fase activa de `.ai/STATE.md`; con argumentos, `<epica>` y `<FF>`. Se
ejecuta en la rama de la fase, sin nada por commitear fuera de `.ai/`: lo que no está commiteado no se revisa, y
la memoria que el cierre ya escribió (o una revisión anterior) no es parte del diff.

1. **La base** es el padre del commit de arranque:
   `git log --format=%h --grep='^chore(phase-<NN>-<FF>): start' | tail -n 1`, y su `^`. Sin commit de arranque no
   hay nada que revisar: dilo y para.
2. **Primera revisión o seguimiento.** Si «Revisión» ya tiene alguna, esta es un **seguimiento** y el revisor sólo
   lee lo que entró después: `desde` es el HEAD de la cabecera de la última (`` `<base>..<head>` ``, el segundo
   hash). Si ese commit ya no está en la historia (un rebase, un amend), no hay desde donde seguir: revisión
   completa desde la base.
3. **El revisor.** Lanza el subagente `reviewer` (`.claude/agents/reviewer.md`) con la ruta de la fase, la base, el
   número de esta revisión (las que ya tiene «Revisión», más una) y, en un seguimiento, `desde`. Sólo eso: ni tu
   opinión ni la conversación, que son lo que la revisión tiene que poder contradecir. Sin subagentes, ábrelo en una sesión nueva con ese archivo
   como instrucciones; en la misma sesión, sólo si el Tech Lead lo acepta, y dilo en la revisión.
4. **Escríbela** en la sección «Revisión» de la fase tal como la devuelve: sustituye «Sin revisar.» o va debajo de
   la anterior, que no se borra. Si la fase no tiene la sección (se escribió con una plantilla anterior), créala
   justo antes de `---`.
5. **Cada bloqueante** se resuelve antes de cerrar:
   - Si se arregla dentro del alcance, su `fix(...)` va en su propio commit
     (`.claude/skills/phase/SKILL.md §Commits durante la fase`), la casilla se marca con
     `— resuelto en <hash>`, y vuelven `bash bin/verify.sh` y un seguimiento.
   - Si el arreglo sale del alcance, o el hallazgo te parece falso: STOP & ASK (`.ai/WORKFLOW.md §STOP & ASK`).
     Sólo el Tech Lead lo descarta, y la casilla se marca con `— descartado por el Tech Lead (<fecha>): <motivo>`.
   - Si el seguimiento sigue con bloqueantes: STOP & ASK.
6. **Los no bloqueantes** no se arreglan en la fase salvo que estén en su alcance; lo de otra parte va a
   `.ai/BACKLOG.md` (`CLAUDE.md §Alcance`).
7. **Lo que se cierra está revisado.** Si después de la última revisión entra un commit de código, `bash
   bin/verify.sh` vuelve a pasar, y además:
   - **Por regla general, un seguimiento:** un arreglo puede introducir lo que ninguna revisión vio. Cuesta poco,
     porque sólo lee ese cambio (paso 2).
   - **Sin revisión nueva,** sólo el arreglo de un **no bloqueante** que cumple las tres condiciones: está en el
     alcance de la fase; sólo toca archivos que el diff revisado ya tocaba, y ninguno es un test existente, el
     contrato, una dependencia, una migración ni una zona sensible; y cambia 30 líneas o menos en total
     (`git diff --shortstat <head de la última revisión>..HEAD`). El RESULTADO lo declara en «Qué se hizo», con su
     hash. Si no cumple una, seguimiento.

`bin/check-docs.sh` no deja una fase en `HECHA` ni en `ESPERA_EVIDENCIA` sin revisión o con un bloqueante sin
marcar. La revisión entra en el commit de cierre (`.claude/skills/phase/cierre.md §Cierre de fase`); lanzada a mano
fuera del cierre, no se commitea.
