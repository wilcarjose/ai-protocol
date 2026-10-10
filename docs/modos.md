# Modos de ejecución

> Para quien prepara un proyecto que usa el kit: dónde puede correr la sesión que ejecuta una fase y qué hace falta
> en cada sitio. Por defecto, en un VPS propio que se maneja desde el teléfono; la nube queda de respaldo y el local,
> como opción. Lo que no cambia nunca es cómo termina la fase.

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

## VPS

El modo por defecto. Un servidor propio con Claude Code en modo servidor de Remote Control (`claude remote-control --spawn worktree`).
Desde la app de Claude abres una sesión en el VPS: corre allí, en su propio worktree de git, y sigue trabajando
aunque cierres la app. El visto bueno del Paso A, los STOP & ASK y la pregunta del cierre llegan como avisos al
teléfono. Las órdenes son de Ubuntu 24.04; en otra distribución cambian los paquetes, no los pasos.

### Preparación

Una vez por VPS. Cuando haya que dar una orden como root, va con `sudo`; el resto, como el usuario de los agentes
(`sudo -iu agentes`).

1. **Un usuario propio para los agentes**, sin `sudo`: `sudo adduser agentes`.
2. **Las herramientas, sin Docker:** git, tmux, gh, PHP 8.4 con Composer, Node 22, PostgreSQL 17 con PostGIS y
   gitleaks. PostgreSQL 17 es la versión de la CI del stack de Laravel (`postgis/postgis:17-3.5`); Ubuntu 24.04 trae
   la 16, así que se instala desde el repositorio oficial de PostgreSQL.

   ```bash
   sudo apt-get update && sudo apt-get install -y git tmux gh unzip postgresql-common software-properties-common
   sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && sudo apt-get install -y postgresql-17-postgis-3
   sudo add-apt-repository -y ppa:ondrej/php
   sudo apt-get install -y php8.4-cli php8.4-mbstring php8.4-xml php8.4-curl php8.4-zip php8.4-intl php8.4-bcmath \
       php8.4-pgsql php8.4-sqlite3
   curl -fsSL https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
   curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash - && sudo apt-get install -y nodejs
   curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz \
       | sudo tar xz -C /usr/local/bin gitleaks
   ```

3. **La base de datos de los tests**, con un rol que no es superusuario y que sólo es dueño de ella
   (§Aislamiento con staging). PostGIS se crea una vez como `postgres`, porque el rol no puede crearlo; después, la
   migración que lo pide (`CREATE EXTENSION IF NOT EXISTS postgis`) lo encuentra y sigue.

   ```bash
   sudo -u postgres psql -c "CREATE ROLE agentes LOGIN PASSWORD 'agentes'"
   sudo -u postgres createdb -O agentes testing
   sudo -u postgres psql -d testing -c 'CREATE EXTENSION postgis'
   ```

   `.env.testing` dice `postgres`; la unidad de systemd pone `DB_USERNAME` y `DB_PASSWORD`, que ganan a ese archivo.
   Con más de un proyecto Laravel en el VPS, una base por proyecto y su `DB_DATABASE` en la unidad.
4. **Las sesiones**, como `agentes`:
   - `curl -fsSL https://claude.ai/install.sh | bash` y `claude auth login` con la cuenta de claude.ai. Remote
     Control no acepta API keys: nada de `ANTHROPIC_API_KEY` en el entorno.
   - `gh auth login`, con una cuenta que pueda empujar ramas y abrir PRs en el repo.
   - La identidad de git: `git config --global user.name "…"` y `git config --global user.email "…"`.
   - El repo, en su home: `git clone <url> ~/mi-proyecto`.
5. **Comprueba**, como `agentes`, con una copia de este kit: `sh ai-protocol/docs/vps/doctor.sh`, y con
   `--env <ruta>` si hay staging. Repite hasta que no falte nada.

### Arranque

La primera vez, a mano, para aceptar la confianza en el directorio y la confirmación de Remote Control:

```bash
cd ~/mi-proyecto && claude remote-control --spawn worktree    # «y» a las dos preguntas; después, Ctrl+C
```

Después, como servicio de systemd: [`docs/vps/remote-control@.service`](vps/remote-control@.service) lo lanza dentro
de tmux, porque el servidor necesita un terminal, y lo reinicia si se cierra. Las órdenes están en su cabecera. Sin
systemd, vale `tmux new -s mi-proyecto 'claude remote-control --spawn worktree'`, pero tendrás que relanzarlo tú si
el VPS se reinicia.

**Los avisos push:** en el teléfono, la app de Claude con la misma cuenta, con permiso para notificar. En el VPS,
`claude`, `/config` y activa **Push when actions required** (permisos y preguntas, como el visto bueno del Paso A) y
**Push when Claude decides**.

### El día a día desde el teléfono

1. En la app de Claude, *Code*: el servidor del VPS sale con un icono de ordenador y un punto verde. Abre una sesión
   nueva en él. Tendrá su worktree en `.claude/worktrees/<nombre>`, en una rama `worktree-<nombre>` que sale de
   `origin/main`.
2. Escribe `/phase; antes, composer install` (o `npm ci`): el worktree es un checkout nuevo, sin dependencias. Si el
   proyecto necesita su `.env` de desarrollo, un `.worktreeinclude` con `.env` en la raíz lo copia a cada worktree.
3. Responde el Paso A y los STOP & ASK cuando llegue el aviso.
4. Al cierre, la fase te pregunta qué mejorarías del protocolo, empuja su rama y abre el PR. Revísalo y fusiónalo
   desde GitHub.
5. La fase siguiente, en otra sesión nueva: una sesión por fase.

Tres reglas:

- **Las fases, sólo en las sesiones que abres.** El servidor crea además una sesión en la carpeta del repo: ésa no
  ejecuta fases, porque su `main` local se queda atrás y tiene dentro los worktrees de las demás.
- **Una fase a la vez por proyecto:** todas comparten la base `testing`.
- **`.claude/worktrees/` en el `.gitignore` del proyecto**, para que la carpeta del repo no los vea como archivos
  nuevos. Un worktree ya fusionado se borra con `git worktree remove .claude/worktrees/<nombre>`.

### Aislamiento con staging

Si el mismo VPS sirve staging (sin Docker, como producción), los agentes no deben poder tocarlo:

- **Usuarios distintos.** Staging corre con su propio usuario; `agentes` no está en su grupo ni tiene `sudo`.
- **El `.env` de staging, ilegible para los agentes:** del usuario de staging y con `chmod 600`.
  `doctor.sh --env <ruta>` lo comprueba. Las reglas `deny` de `.claude/settings.json` frenan al agente, pero la
  barrera de verdad son los permisos del sistema.
- **La base de datos de staging, con su propio rol.** El de los agentes no es superusuario y sólo es dueño de
  `testing`; si lo fuera, llegaría a la de staging (`doctor.sh` lo avisa).
- **Ningún secreto de producción en el VPS**: ni sus claves, ni sus copias de seguridad, ni su `.env`. Staging usa
  datos ficticios y las credenciales de prueba de cada servicio externo.

## Nube

El respaldo. Claude Code en la nube: [claude.ai/code](https://claude.ai/code), la pestaña *Code* de la app de Claude o
`claude --cloud "…"` desde la terminal. Cada sesión es una VM nueva de Ubuntu 24.04 con el repo clonado, que sigue
trabajando aunque cierres el portátil; el visto bueno del Paso A se da desde cualquier dispositivo. Sirve cuando el
VPS no está disponible o todavía no se ha preparado.

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
con Composer o Node). Termina igual que en el VPS: push de la rama de la fase y PR.

- **Con Docker Compose.** Pon el servicio de PHP en `VERIFY_SERVICE`, en `.ai/project/verify.conf`: desde el host,
  `bin/verify.sh` se relanza dentro del contenedor. Ese contenedor ve el repo entero, `.git` incluido, y necesita
  `git` y `gitleaks`; en una imagen Alpine, por ejemplo, `apk add git` y
  `COPY --from=zricethezav/gitleaks:v8.30.1 /usr/bin/gitleaks /usr/local/bin/gitleaks`. La base de datos de los
  tests (PostgreSQL con PostGIS) va como otro servicio de la misma Compose. En el VPS, `VERIFY_SERVICE` se queda
  vacío.
- **Con Remote Control.** Una sesión local que se sigue y se dirige desde el móvil o desde claude.ai:
  `claude --remote-control`, o `/remote-control` dentro de una sesión abierta. Sirve para dar el visto bueno del
  Paso A o responder un STOP & ASK lejos del ordenador. La sesión sigue en tu máquina: si la apagas, se para.

## Qué elegir

| | VPS | Nube | Local con Docker Compose | Local con Remote Control |
|---|---|---|---|---|
| Dónde corre | Tu servidor, cada sesión en su worktree | VM de Anthropic, nueva en cada sesión | Tu máquina y tus contenedores | Tu máquina |
| Sigue si apagas el ordenador | Sí | Sí | No | No |
| Entorno | El del VPS, sin Docker, como staging | Imagen común + script de preparación | El de la Compose del proyecto | El de tu máquina |
| Credenciales de GitHub | Las de `agentes` en el VPS (`gh auth login`) | El proxy; nunca entran en la VM | Las tuyas | Las tuyas |
| Se maneja desde | La app de Claude | La app o claude.ai | El ordenador | El ordenador, la app o claude.ai |
| Final | Rama `phase/…`, PR, CI | Igual | Igual | Igual |

El VPS es el modo por defecto: está siempre encendido, su entorno es el mismo para todas las fases y se parece al de
staging, y lo manejas desde el teléfono. La nube es el respaldo cuando el VPS no está disponible. El local conviene
para depurar a mano con el agente al lado.
