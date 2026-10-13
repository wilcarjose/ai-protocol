---
name: sync-main
description: Después de que el Tech Lead fusione un PR (de una fase, del protocolo o cualquiera), deja el repo en su rama base al día con origin y borra la rama del PR con bin/sync-main.sh, para empezar la siguiente sesión. Con --wait espera a que se fusione. Para cuando la persona pide volver a main, ponerlo al día o esperar a su merge.
argument-hint: "[<PR>] [--wait [<min>]]"
disable-model-invocation: true
---

# /sync-main — de vuelta a la rama base, al día

Argumentos: `$ARGUMENTS`, que pasan tal cual al script: nada (la rama actual, si su PR ya se fusionó), `--wait
[<min>]` para esperar a que se fusione (30 minutos por defecto) o el número de un PR para ir a por él desde
cualquier rama.

`bin/sync-main.sh` no fusiona ni empuja nada: el merge lo decide el Tech Lead
(`.claude/skills/phase/cierre.md §Entrega`). Su cabecera dice qué hace y en qué orden.

## 1. Lanzarlo

`sh bin/sync-main.sh $ARGUMENTS`, suelto y sin tubería. Con `--wait` puede tardar lo que tarde la persona en
fusionar: dale el tope de tiempo más alto de la herramienta o lánzalo en segundo plano y espera a que termine (en
Claude Code, `run_in_background`).

## 2. Leer cómo terminó

| Última línea | Qué haces |
|---|---|
| `✓ sync-main: <rama> en <commit>, al día con origin` | Ya está. Si imprime la fase activa, di que la siguiente sesión es `/phase`. |
| `… sigue sin fusionar` | No se tocó nada: dale el enlace del PR y que lo relance con `--wait`, o cuando lo fusione. |
| `✗ … la CI … falla` | Di qué check falla. Arreglarlo es trabajo de la rama del PR, no de esta skill. |
| `✗ … cambios sin commitear`, `se cerró sin fusionar`, `no tiene PR` o `no avanza en línea recta` | Di qué pasa y para: lo decide la persona. Nunca descartes cambios ni fuerces la rama. |

Si avisa de que una rama local «se queda» porque tiene commits que el PR no llevó, dilo: esos commits no están en
la rama base.
