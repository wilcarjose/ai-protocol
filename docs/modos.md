# Modos de ejecución

> Para quien prepara un proyecto que usa el kit: dónde puede correr la sesión que ejecuta una fase y qué hace falta
> en cada sitio. Lo que no cambia nunca es cómo termina la fase.

## La regla: toda fase termina igual

Corra donde corra, una fase acaba en el mismo sitio (`.claude/skills/phase/cierre.md §Entrega`):

1. `bash bin/verify.sh` completo en verde y `/review` sin bloqueantes, en la propia sesión.
2. Commit de cierre y push de su rama, `phase/<NN-slug>/<FF>`. Nunca a `main` ni forzado.
3. Un PR con la plantilla `.github/pull_request_template.md`, contra `epic/<NN-slug>` si la épica declara rama base o
   contra `main` si no. En borrador si la fase cerró `BLOQUEADA` o `VERIFICACION_ROJA`.
4. La CI del proyecto (`.github/workflows/verify.yml`) repite `bin/verify.sh` completo sobre el PR: los gates
   «protocolo» y «secretos» comparan la rama con su base y leen el historial.
5. La persona revisa y fusiona. La fase nunca fusiona su PR.

Una fase que espera evidencia (`ESPERA_EVIDENCIA`) también termina en su PR. Si la evidencia llega cuando ese PR ya
se fusionó, va en una rama nueva, `phase/<NN-slug>/<FF>-evidence`, con su propio PR
(`.claude/skills/phase/cierre.md §Evidencia humana`).

### Proteger `main` en GitHub

`.claude/settings.json` sólo deja empujar ramas `phase/*` y bloquea el push a `main`, el forzado y el borrado de
ramas. Pero una regla de permisos de Claude Code cubre la orden tal como la escribe el agente, no cualquier forma
de lanzarla, y en la nube el proxy de GitHub no limita a qué rama se empuja. La barrera de verdad está en GitHub:
un *ruleset* sobre `main` (y sobre `epic/*`, si se usan) que exija PR, exija el check `verify` en verde y bloquee
el push forzado y el borrado.

## Nube (por defecto)

Claude Code en la nube: [claude.ai/code](https://claude.ai/code), la pestaña *Code* de la app de Claude o
`claude --cloud "…"` desde la terminal. Cada sesión es una VM nueva de Ubuntu 24.04 con el repo clonado, que sigue
trabajando aunque cierres el portátil; el visto bueno del Paso A se da desde cualquier dispositivo.

**Una vez por cuenta:**

1. Conecta GitHub con la GitHub App de Claude o con `/web-setup` desde la terminal.
2. Crea un entorno de nube con acceso de red **Trusted** (la lista por defecto ya incluye Packagist, npm, Docker Hub,
   los repositorios de Ubuntu y `proxy.golang.org`) y pega en «Setup script» el script de abajo.

**Lo que trae la imagen:** PHP 8.3 con Composer, Node 20–22, PostgreSQL 16, Docker con Compose, `git` y `gh`. `gh`
funciona sin token propio: el proxy de GitHub pone las credenciales.

**Lo que añade el script:** PostGIS con la base de datos de los tests, gitleaks y, si el proyecto lo pide, PHP 8.4. Corre como root antes de que
arranque Claude Code; si termina en unos cinco minutos, la VM se guarda en caché y las sesiones siguientes no lo
repiten (se reconstruye al cambiar el script, la red, o cada siete días). Tiene que salir con 0: lo que no es
imprescindible lleva `|| true`.

```bash
#!/bin/bash
# ai-protocol: preparación del entorno de nube (Ubuntu 24.04, como root).
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq || true

# PostGIS para el PostgreSQL 16 que trae la imagen, y la base de datos de los tests con los datos de la semilla
# .env.testing del stack de Laravel (testing, usuario y contraseña postgres). Queda en el disco, que sí se guarda.
apt-get install -y -qq postgresql-16-postgis-3 > /dev/null || true
{ service postgresql start > /dev/null \
  && su postgres -c "psql -qc \"ALTER USER postgres PASSWORD 'postgres'\"" \
  && { su postgres -c 'createdb testing' 2> /dev/null || true; }; } || true

# gitleaks, para el gate «secretos» de bin/verify.sh. Con go install, porque las releases de GitHub de un repo que
# no está en la sesión responden 403; GOTOOLCHAIN=auto baja el Go que pide gitleaks si el de la imagen es anterior.
GOTOOLCHAIN=auto GOBIN=/usr/local/bin go install github.com/zricethezav/gitleaks/v8@v8.30.1 || true

# PHP 8.4, si el proyecto lo pide (la imagen trae 8.3). Necesita ppa.launchpadcontent.net y api.launchpad.net en
# los dominios permitidos del entorno: acceso «Custom», con la lista por defecto incluida.
if ! php -v 2>/dev/null | grep -q '^PHP 8\.4'; then
    { add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1 \
      && apt-get update -qq \
      && apt-get install -y -qq php8.4-cli php8.4-mbstring php8.4-xml php8.4-curl php8.4-zip php8.4-intl \
           php8.4-bcmath php8.4-pgsql php8.4-sqlite3 > /dev/null \
      && update-alternatives --set php /usr/bin/php8.4; } \
    || echo 'aviso: no se instaló PHP 8.4; usa la Docker Compose del proyecto o permite el PPA' >&2
fi
exit 0
```

**Lo que no guarda la caché:** los servicios en marcha y las dependencias del proyecto. Al empezar cada sesión
hacen falta `service postgresql start` y `composer install` o `npm ci`: pídelo en el mensaje que lanza la fase
(«/phase; antes, arranca PostgreSQL e instala dependencias»). También vale un hook `SessionStart` que sólo actúe
si `CLAUDE_CODE_REMOTE` es `true`, pero vive en `.claude/settings.json`, que es del kit: añadirlo es un commit
`chore(protocol): …` que `install.sh --upgrade` enseñará después como conflicto.

**Lanzar una fase:** abre una sesión sobre el repo, en la rama base (`main` o `epic/<NN-slug>`), y escribe
`/phase`. La skill crea o retoma `phase/<NN-slug>/<FF>` en su Paso 0, se para en el Paso A a esperar tu visto bueno
y, al cerrar, empuja la rama y abre el PR.

## Local

La sesión corre en tu máquina, con tus herramientas: `git`, `gh` con `gh auth login`, gitleaks y lo del stack (PHP
con Composer o Node). Termina igual que en la nube: push de la rama de la fase y PR.

- **Con Docker Compose.** Pon el servicio de PHP en `VERIFY_SERVICE`, en `.ai/project/verify.conf`: desde el host,
  `bin/verify.sh` se relanza dentro del contenedor. Ese contenedor ve el repo entero, `.git` incluido, y necesita
  `git` y `gitleaks`; en una imagen Alpine, por ejemplo, `apk add git` y
  `COPY --from=zricethezav/gitleaks:v8.30.1 /usr/bin/gitleaks /usr/local/bin/gitleaks`. La base de datos de los
  tests (PostgreSQL con PostGIS) va como otro servicio de la misma Compose.
- **Con Remote Control.** Una sesión local que se sigue y se dirige desde el móvil o desde claude.ai:
  `claude --remote-control`, o `/remote-control` dentro de una sesión abierta. Sirve para dar el visto bueno del
  Paso A o responder un STOP & ASK lejos del ordenador. La sesión sigue en tu máquina: si la apagas, se para.

## Qué elegir

| | Nube | Local con Docker Compose | Remote Control |
|---|---|---|---|
| Dónde corre | VM de Anthropic, nueva en cada sesión | Tu máquina y tus contenedores | Tu máquina |
| Sigue si apagas el ordenador | Sí | No | No |
| Entorno | Imagen común + script de preparación | El del proyecto, idéntico al de producción | El de tu máquina |
| Credenciales de GitHub | El proxy; nunca entran en la VM | Las tuyas (`gh auth login`) | Las tuyas |
| Final | Rama `phase/…`, PR, CI | Igual | Igual |

La nube es el modo por defecto: no depende de una máquina encendida y el entorno es el mismo para todos. El local
conviene cuando el entorno del proyecto no cabe en la imagen común (servicios propios, versiones que el script no
instala) o cuando hace falta depurar a mano con el agente al lado.
