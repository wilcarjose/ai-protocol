---
name: sync-main
description: En el repo del kit, después de que la persona fusione un PR, deja el repo en su rama base al día con origin y borra la rama del PR con core/bin/sync-main.sh. Con --wait espera a que se fusione. Para cuando la persona pide volver a main, ponerlo al día o esperar a su merge.
argument-hint: "[<PR>] [--wait [<min>]]"
disable-model-invocation: true
---

# /sync-main — de vuelta a main en el repo del kit

Es la misma skill que instala el núcleo en cada proyecto (`core/.claude/skills/sync-main/SKILL.md`), con el script
en su sitio del kit: lanza `sh core/bin/sync-main.sh $ARGUMENTS`, suelto y sin tubería, y sigue sus §1 y §2 tal como
están. Con `--wait`, el tope de tiempo más alto de la herramienta o en segundo plano.
