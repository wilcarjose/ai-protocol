---
name: protocol-upgrade
description: Sube el protocolo del proyecto a la última versión del kit ai-protocol con bin/protocol-upgrade.sh, entre fases, y deja main al día con el upgrade fusionado o su PR abierto con el motivo. Para cuando el Tech Lead pide actualizar el protocolo, nunca dentro de una fase.
argument-hint: "[--no-merge | --ref <etiqueta>]"
disable-model-invocation: true
---

# /protocol-upgrade — subir el protocolo del proyecto

Argumentos: `$ARGUMENTS`, que pasan tal cual al script: nada (lo normal), `--no-merge` para dejar el PR a revisión,
`--ref <etiqueta>` para una versión concreta del kit.

Los archivos del kit los cambia sólo el kit: el proyecto los recibe con este upgrade, entre fases, y nunca los
parchea (`.ai/WORKFLOW.md §Archivos del protocolo`). `bin/protocol-upgrade.sh` hace todo lo mecánico, y su
cabecera dice qué y en qué orden. Esta skill lo lanza y se ocupa de lo que necesita criterio.

## 1. Lanzarlo

`sh bin/protocol-upgrade.sh $ARGUMENTS`, suelto y sin tubería, para leer su salida entera. Espera a la CI del PR, así
que puede tardar más de diez minutos: dale el tope de tiempo más alto de la herramienta o lánzalo en segundo plano
y espera a que termine (en Claude Code, `run_in_background`). No lo lances dos veces a la vez.

## 2. Leer cómo terminó

| Última línea | Qué haces |
|---|---|
| `✓ al día` | Nada más: dilo. |
| `✓ fusionado` | Ya está: main tiene el upgrade. Pasa al reporte. |
| `✓ PR abierto para revisar` | Una versión mayor, `PROTOCOL_AUTO_MERGE` o `--no-merge`: el PR es para la persona. Con una versión mayor, resume lo que su `CHANGELOG.md` pide en «Al actualizar un proyecto» (el cuerpo del PR lo trae). |
| `✗ … no se puede empezar` (árbol sucio, fuera de main, fases a medias, sin `gh`) | Di qué falta y para. Una fase a medias se termina antes, nunca se salta. |
| `✗ … conflicto(s)` | No se tocó nada. Enseña qué archivo del kit cambió el proyecto y propón llevar lo propio a `.ai/project/`. Lo decide la persona: STOP & ASK (`.ai/WORKFLOW.md §STOP & ASK`). |
| `✗ el guardián falla tras el upgrade` | La rama del upgrade queda sin commitear. Lo que pida el guardián en la memoria o en `.ai/project/` (que son del proyecto) se arregla ahí si el `CHANGELOG.md` del kit lo dice; si no, o si el arreglo tocaría un archivo del kit, STOP & ASK. |
| `✗ la CI de … falla` | El PR queda abierto. Di qué gate falla. Si es el código del proyecto contra una regla nueva, es trabajo de una fase: va a `.ai/BACKLOG.md` y se dice. Si es un fallo del kit, es un issue en el kit (`bin/protocol-feedback.sh` o a mano). Nunca se arregla parcheando un archivo del kit. |
| `✗ … no tiene CI` | Sin CI no se fusiona: el PR es para la persona. |

## 3. Reporte

- Las versiones de antes y de ahora, y de dónde salió el kit.
- Si quedó fusionado (con el commit de main) o el enlace del PR y por qué sigue abierto.
- Las filas de `.ai/PROTOCOL.md` archivadas.
- En qué rama quedó el repo: main al día con origin, salvo si el guardián falló.
