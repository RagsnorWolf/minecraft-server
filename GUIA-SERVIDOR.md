# Guía completa — Ragsnor Paper 1.21.10

## 1. Qué estás creando

- **Software:** Paper 1.21.10.
- **Java:** Java 21.
- **Java Edition:** puerto local TCP 25565.
- **Bedrock Edition:** Geyser + Floodgate, puerto local UDP 19132; para acceso público se configura Playit NetherNet.
- **Máquina Codespaces utilizada:** 2 CPU, 8 GB RAM y 32 GB almacenamiento (tu Codespace actual).
- **RAM de Paper:** el arranque detecta el límite real del contenedor y asigna aproximadamente el 75%; en tu Codespace de 8 GB, unos 6 GB para Java.

Paper recomienda Java 21 para las versiones 1.20 a 1.21.11: https://docs.papermc.io/paper/getting-started/

## 2. Crear el Codespace desde un navegador

1. Abrí tu Codespace existente: https://github.com/codespaces/obscure-chainsaw-6v47qqqqq55w2r6ww
2. Entrá a **Terminal → New Terminal**.
3. Ejecutá `bash scripts/update-and-start.sh` para sincronizarlo con la nueva configuración, instalar los componentes y arrancar Paper.
5. Esperá a que VS Code Web termine de preparar el entorno. La primera instalación descarga Paper y plugins.
6. El servidor se inicia automáticamente al terminar la preparación.

También podés administrar tus entornos desde https://github.com/codespaces. Abrí el Codespace y elegí **Start** o **Resume**. Cuando arranca, el script vuelve a encender Paper y el agente Playit.

**Costo:** tu máquina de 2 núcleos y 32 GB de almacenamiento usa cuota de Codespaces. Revisá el consumo en Billing. GitHub factura el uso de CPU por hora y el almacenamiento por GB-mes. Revisá el importe que GitHub muestra al crear el Codespace antes de confirmarlo. Podés elegir una máquina mayor si aparece disponible, pero será más cara.

## 3. Cómo encender, apagar y comprobarlo

Abrí **Terminal → New Terminal** dentro de VS Code Web.

Primera sincronización del Codespace existente (actualiza el proyecto, instala dependencias y enciende el servidor):

```bash
bash scripts/update-and-start.sh
```

Encender después:

```bash
bash scripts/start.sh
```

Ver estado:

```bash
bash scripts/status.sh
```

Consola de Minecraft:

```bash
bash scripts/console.sh
```

Apagar Paper de forma segura:

```bash
bash scripts/stop.sh
```

Al apagar Paper con `stop`, Minecraft guarda los chunks y cierra el servidor. Después podés detener el Codespace desde https://github.com/codespaces. No hace falta borrar nada. Al reanudar el Codespace, los archivos guardados bajo `/workspaces` permanecen y el servidor vuelve a arrancar.

## 4. Direcciones para entrar

La dirección pública no existe hasta que se vincule el agente Playit y se creen los túneles. Seguí **PLAYIT.md**.

- **Java PC:** hostname:puerto del túnel Minecraft Java.
- **Bedrock móvil/Windows:** hostname y puerto del túnel Minecraft Bedrock (NetherNet).

No uses `localhost` ni `127.0.0.1` desde el celular: esas direcciones apuntan al propio dispositivo, no al Codespace.

## 5. Ubicación de las carpetas y archivos

La raíz del proyecto es:

`/workspaces/minecraft-server/`

El Explorer de VS Code Web muestra las carpetas y archivos. La carpeta `server/` aparece después de ejecutar la instalación y se excluye de Git.

### Archivos del proyecto (se ven en GitHub)

| Ruta | Función |
|---|---|
| `.devcontainer/devcontainer.json` | Tipo de máquina, Java y arranque automático |
| `.devcontainer/setup.sh` | Instala utilidades, Paper, Geyser, Floodgate y Playit |
| `.devcontainer/start.sh` | Arranque automático al abrir el Codespace |
| `config/server.properties` | Plantilla de propiedades iniciales |
| `scripts/install.sh` | Descarga Paper 1.21.10 y plugins |
| `scripts/start.sh` | Enciende Paper y Playit |
| `scripts/stop.sh` | Apaga Paper guardando el mundo |
| `scripts/status.sh` | Comprueba servidor y agente |
| `scripts/console.sh` | Abre la consola del servidor |
| `scripts/backup.sh` | Crea una copia comprimida del mundo |
| `PLAYIT.md` | Configuración de IP pública Java y Bedrock |

### Archivos generados (dentro de server/)

| Ruta | Qué contiene |
|---|---|
| `server/paper.jar` | Ejecutable Paper 1.21.10 |
| `server/eula.txt` | Aceptación de la EULA |
| `server/server.properties` | Puerto, jugadores, dificultad, distancias y mundo |
| `server/world/` | Mundo principal: construcciones, chunks y datos de jugadores |
| `server/world/region/` | Archivos de regiones/chunks del mundo |
| `server/world/playerdata/` | Inventarios y datos de jugadores |
| `server/world_nether/` | Dimensión Nether |
| `server/world_the_end/` | Dimensión End |
| `server/plugins/` | Archivos .jar de plugins |
| `server/plugins/Geyser-Spigot/config.yml` | Configuración de conexión Bedrock |
| `server/plugins/floodgate/` | Configuración y clave privada de Floodgate |
| `server/config/` | Configuración global y por mundo de Paper |
| `server/logs/latest.log` | Registro de la última ejecución |
| `server/logs/playit.log` | Registro del agente Playit |
| `server/logs/console.log` | Salida de la consola de Paper |

No todos los archivos aparecen antes del primer arranque. Paper y los plugins los generan.

## 6. Cambiar configuraciones

Para ajustes principales editá:

`server/server.properties`

Valores actuales importantes:
- `max-players=10`: máximo de jugadores.
- `view-distance=8`: distancia de visión.
- `simulation-distance=6`: distancia de simulación.
- `difficulty=normal`: dificultad.
- `gamemode=survival`: modo de juego.
- `online-mode=true`: autenticación Java oficial.
- `enforce-secure-profile=false`: compatibilidad de chat con Geyser.
- `server-port=25565`: puerto Java local.

Después de editar, reiniciá Paper con stop y start. Los ajustes avanzados de Paper aparecen en `server/config/` después del primer arranque. La configuración de cada plugin queda en su subcarpeta de `server/plugins/`.

## 7. Agregar plugins

1. Detené el servidor.
2. En Explorer abrí `server/plugins/`.
3. Subí el archivo `.jar` del plugin, compatible con Paper 1.21.10.
4. Volvé a encender Paper.
5. Comprobá con `/plugins` desde la consola.

No pongas mods Fabric o Forge en esta carpeta: Paper usa plugins Bukkit/Spigot/Paper.

## 8. Cambiar o restaurar el mundo

El mundo principal está en `server/world/`.

Antes de reemplazarlo:
1. ejecutá `bash scripts/stop.sh`;
2. ejecutá `bash scripts/backup.sh`;
3. subí el mapa Java al Codespace;
4. reemplazá el contenido de `server/world/` por el contenido del nuevo mundo (la carpeta debe contener directamente `level.dat`);
5. ejecutá `bash scripts/start.sh`.

Un mapa Bedrock no se puede copiar directamente a Paper: necesitás convertirlo a formato Java. No borres `world_nether` o `world_the_end` salvo que quieras reiniciar esas dimensiones.

## 9. Persistencia y copias

El mundo se guarda en el almacenamiento del Codespace, bajo `/workspaces/minecraft-server/server/`. Detener o reanudar el Codespace conserva esos datos; eliminar el Codespace sí puede borrarlos. Hacé backups y descargalos fuera de GitHub periódicamente.

El repositorio ignora `server/` y `backups/`: así no se suben mundos, plugins .jar ni credenciales privadas a Git.
