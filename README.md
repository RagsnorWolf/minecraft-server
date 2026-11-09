# Ragsnor — Servidor Minecraft en GitHub

Servidor **Paper 1.21.11** + **GeyserMC** + **Floodgate** corriendo en **GitHub Actions**,
con túnel **playit.gg** para que entren jugadores de **Java y Bedrock (celular/consola)**
desde cualquier lugar, sin abrir puertos y sin pagar nada.

Se prende y se apaga desde el celular entrando a `github.com` → **Actions** → **Run workflow**.

---

## Lo que tienes que saber antes (importante)

| Cosa | Realidad |
|------|----------|
| **Duración por sesión** | Máximo **6 horas** por arranque. Después GitHub mata el job y el servidor se apaga solo. Volvés a darle *Run workflow* y arranca de nuevo con el mundo intacto. |
| **Uptime** | **No es 24/7.** Es un servidor "por sesiones". Sirve para jugar con amigos un rato, no para tenerlo siempre prendido. |
| **Ping desde Mendoza** | Los runners de GitHub están en Azure (EE. UU. / Europa). Esperá **140–200 ms**. Para ping bajo real (30–60 ms) necesitás un servidor en São Paulo. |
| **RAM** | 16 GB en el runner; al server le damos **6 GB** de heap Java (configurable hasta 8G). |
| **Costo** | **$0.** Repo público = minutos de Actions gratis. Sin tarjeta, sin tokens, sin créditos. |
| **Datos** | El mundo se guarda automáticamente en la caché de Actions y se restaura en el próximo arranque. |

> ⚠️ GitHub Actions está pensado para CI/CD. Usarlo como servidor de juegos 24/7 va contra
> sus políticas de uso aceptable. Este repo está diseñado para **sesiones manuales y cortas**,
> que es el uso de menor riesgo.

---

## Instalación (5 minutos, una sola vez)

### 1. Crear el repositorio

**Opción A — desde la web (más fácil):**

1. Entrá a https://github.com/new
2. Nombre: `minecraft-server`
3. Visibilidad: **Public** (para tener minutos ilimitados de Actions)
4. **No** marques "Add a README"
5. Crear repositorio

**Opción B — por terminal:**

```bash
gh repo create minecraft-server --public --source=. --push
```

### 2. Subir estos archivos

```bash
git init
git add .
git commit -m "Servidor Minecraft Paper + Geyser"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/minecraft-server.git
git push -u origin main
```

### 3. Crear cuenta en playit.gg (gratis, sin tarjeta)

playit.gg es el túnel que hace que el servidor sea accesible desde internet.

1. Entrá a https://playit.gg y creá una cuenta (email nomás).
2. En el panel, **Add tunnel** → **Custom / Minecraft Java**:
   - Local address: `127.0.0.1`
   - Local port: `25565`
   - Protocol: **TCP**
3. **Add tunnel** otra vez → **Custom / Minecraft Bedrock**:
   - Local address: `127.0.0.1`
   - Local port: `19132`
   - Protocol: **UDP**
4. Copiá tu **Secret Key** (está en la sección *Agents* / *Setup*).

### 4. Guardar el secret en GitHub

1. En tu repo: **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret**
3. Nombre: `PLAYIT_SECRET`
4. Valor: tu secret key de playit.gg
5. **Add secret**

### 5. Arrancar el servidor

1. En tu repo: pestaña **Actions**
2. En la izquierda, click en **Minecraft Server**
3. Botón **Run workflow** (derecha)
4. Dejá los valores por defecto y dale **Run workflow**
5. Entrá al run → job **Paper + Geyser + Floodgate** → vas a ver el log en vivo
6. Cuando aparezca **Servidor Minecraft ONLINE**, arriba del log está la tabla con la **dirección** de playit

Eso es todo. El servidor queda online hasta 5 h 30 min (o hasta que se cumpla el tiempo que pusiste).

---

## Cómo conectarse

| Plataforma | Dirección |
|------------|-----------|
| **Java (PC)** | La dirección de playit, ej: `algo-at.playit.gg:25565` |
| **Bedrock (celular, consola, Win10)** | La dirección de playit del túnel UDP, ej: `algo-at.playit.gg:19132` |

La dirección de playit es **fija**: no cambia entre arranques. Guardala en favoritos.

### Primer ingreso como admin

1. Entrá al servidor desde Java con tu nick.
2. En el log de Actions no podés escribir comandos, así que el op se agrega desde el archivo `ops.json`.
3. Opción rápida: creá el archivo `server/ops.json` localmente... o mejor, usá **RCON** (ver abajo).

**Alternativa más simple:** agregá tu nick a `whitelist.json` y `ops.json` desde el repo:

```json
[
  {
    "uuid": "00000000-0000-0000-0000-000000000000",
    "name": "TuNick",
    "level": 4,
    "bypassesPlayerLimit": true
  }
]
```

Paper acepta el UUID en ceros y lo resuelve por nombre al arrancar (offline). Si el server
está en `online-mode=true`, lo mejor es entrar una vez, y desde la consola del log buscar tu UUID real.

---

## Prender / apagar desde el celular

### Desde el navegador del celular (recomendado)

1. Abrí `github.com/TU_USUARIO/minecraft-server/actions/workflows/minecraft.yml`
2. **Run workflow** → **Run workflow**
3. Para apagar: entrá al run en curso → **Cancel workflow**

Anda perfecto en Chrome/Safari de Android/iOS. Podés agregar el link a la pantalla de inicio.

### Con la app de GitHub

La app oficial permite ver Actions y cancelar runs. Para *disparar* un workflow hace falta
el navegador (o la API).

### Por API con `curl` (para un atajo en Termius / iOS Shortcuts)

```bash
curl -X POST \
  -H "Authorization: Bearer TU_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/TU_USUARIO/minecraft-server/actions/workflows/minecraft.yml/dispatches \
  -d '{"ref":"main","inputs":{"version":"1.21.11","duration":"330","heap":"6G"}}'
```

Para cancelar:

```bash
curl -X POST \
  -H "Authorization: Bearer TU_GITHUB_TOKEN" \
  https://api.github.com/repos/TU_USUARIO/minecraft-server/actions/runs/ID_DEL_RUN/cancel
```

---

## Alternativa: GitHub Codespaces (sin límite de 6 h)

Si querés sesiones más largas o una terminal cómoda, usá el Codespace que ya viene configurado
en `.devcontainer/`.

1. En el repo: botón verde **Code** → pestaña **Codespaces** → **Create codespace on main**
2. Esperá a que termine el `postCreateCommand` (instala Paper + Geyser + Floodgate)
3. El servidor arranca solo (`postStartCommand`)
4. En la terminal del Codespace: `tail -f .devcontainer/server.log` para ver la dirección de playit
5. Para apagar: **Codespaces** → `...` → **Stop codespace**

**Límite gratuito:** 120 core-hours/mes. Con la máquina de 2 núcleos = **60 horas/mes**.
La máquina de 4 núcleos/16 GB = 30 horas/mes (más RAM, menos horas).

También necesitás cargar `PLAYIT_SECRET` en https://github.com/settings/codespaces
(Secrets → New secret → asignarlo a este repo).

---

## Estructura del repo

```
.
├── .github/workflows/minecraft.yml   # arranque manual, 6 h máx, guarda el mundo
├── .devcontainer/                    # alternativa Codespaces
│   ├── devcontainer.json
│   ├── setup.sh
│   └── start.sh
├── config/
│   ├── server.properties             # config del server
│   └── geyser-config.yml             # Geyser en modo floodgate
├── scripts/
│   ├── install.sh                    # descarga Paper + Geyser + Floodgate
│   └── run.sh                        # arranca túnel + server, espera, apaga
├── docker-compose.yml                # opcional para VPS propia
└── README.md
```

---

## Problemas comunes

| Síntoma | Causa / solución |
|---------|------------------|
| `Falta el secret PLAYIT_SECRET` | No cargaste el secret en Settings → Secrets → Actions. |
| El server arranca pero nadie puede entrar | El túnel de playit está en estado *offline*. Revisá que el secret sea el correcto y que los túneles estén creados en playit.gg. |
| `Unsupported class file major version` | El workflow usa Java 21. Si cambiás a Paper 26.x, subí a Java 25. |
| Bedrock entra pero lo patea | Falta `auth-type: floodgate` en `plugins/Geyser-Spigot/config.yml`. Este repo ya lo trae en `config/geyser-config.yml`. |
| Se perdió el mundo | La caché de Actions se borra tras 7 días sin uso. Entrá una vez por semana o descargá el mundo desde el artifact de logs. |
| Error `out of memory` | Bajá `heap` a `4G` en los inputs del workflow. |
| Quiero cambiar de versión | En *Run workflow* poné `version: 26.3` (última) o la que quieras. El script resuelve el build solo. |

---

## Cambiar la versión de Minecraft

El input `version` acepta cualquier versión publicada en Paper:

- `1.21.11` → última de la línea 1.21 (la que pediste)
- `26.3` → la más nueva (noviembre 2026), requiere Java 25

Para cambiar Java, editá `.github/workflows/minecraft.yml`:

```yaml
      - name: Java 21
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "25"
```

---

## Créditos / fuentes

- PaperMC: https://papermc.io — API v3: https://fill.papermc.io/v3/projects/paper
- GeyserMC: https://geysermc.org
- Floodgate: https://github.com/GeyserMC/Floodgate
- playit.gg: https://playit.gg
- Lista de hostings gratis: https://github.com/Myuui/Free-Minecraft-Hosts
