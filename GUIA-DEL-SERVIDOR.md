# Guía completa del servidor Ragsnor

Esta guía explica dónde están los archivos, cómo manejar el servidor, añadir plugins y mundos, editar configuraciones y conectar Java/Bedrock mediante Playit.gg.

## 1. Elegí dónde ejecutar el servidor

El proyecto admite dos entornos, pero no son el mismo servidor:

| Entorno | Para qué sirve | Persistencia |
|---|---|---|
| GitHub Codespaces | Administrar archivos desde un explorador tipo VS Code, subir mapas, cambiar archivos y probar | Los archivos de /workspaces/minecraft-server permanecen al detener y volver a iniciar el Codespace |
| GitHub Actions | Encender un servidor temporal desde Run workflow | La máquina es temporal. El mundo y la configuración importante se recuperan mediante GitHub Actions Cache |

**Recomendación:** usá Codespaces cuando quieras subir mapas o gestionar archivos manualmente. Usá Actions cuando quieras lanzar una sesión temporal desde GitHub. Un archivo que arrastrás a Codespaces no aparece automáticamente dentro de una ejecución de Actions.

## 2. Abrir las carpetas del servidor

1. Entrá al repositorio: https://github.com/RagsnorWolf/minecraft-server
2. Hacé clic en **Code → Codespaces**.
3. Creá un Codespace con la rama **main**, o abrí el que ya tengas.
4. Esperá a que termine la preparación del contenedor.
5. Abrí el panel **Explorer** de la izquierda en VS Code Web.

La ruta completa es:

    /workspaces/minecraft-server/

La carpeta **server/** se crea al instalar Paper. **No aparece en el listado normal de GitHub** porque .gitignore la excluye deliberadamente: contiene el mundo, los .jar, las configuraciones privadas y los registros.

Si el Codespace ya existía antes de las últimas modificaciones del repositorio, abrí una terminal y actualizá el código:

    cd /workspaces/minecraft-server
    git pull

Después podés instalar el servidor si todavía no existe:

    bash scripts/install.sh

## 3. Qué hay dentro de cada carpeta

### Raíz del repositorio

| Archivo/carpeta | Para qué sirve |
|---|---|
| .devcontainer/ | Configuración del entorno Codespaces y arranque automático |
| .github/workflows/ | Flujos de GitHub Actions para iniciar y validar el servidor |
| config/server.properties | Plantilla inicial de propiedades de Minecraft |
| config/plugins.txt | Lista de enlaces de plugins adicionales que se instalan automáticamente |
| scripts/install.sh | Descarga Paper, Geyser, Floodgate, ViaVersion y plugins de la lista |
| scripts/run.sh | Arranca Paper, configura Geyser y gestiona los túneles |
| scripts/configure-geyser.py | Aplica en tiempo de ejecución la configuración privada de Geyser/Playit |
| docker-compose.yml | Alternativa para ejecutar el servidor en una VPS con Docker |
| README.md | Resumen del proyecto |

### Carpeta generada server/

Después de instalar y arrancar Paper, esta es la carpeta que vas a usar más:

    server/
    ├── server.jar
    ├── eula.txt
    ├── server.properties
    ├── bukkit.yml
    ├── spigot.yml
    ├── commands.yml
    ├── config/
    │   ├── paper-global.yml
    │   └── paper-world-defaults.yml
    ├── plugins/
    │   ├── Geyser-Spigot.jar
    │   ├── floodgate-spigot.jar
    │   ├── ViaVersion.jar
    │   ├── Geyser-Spigot/
    │   │   └── config.yml
    │   ├── floodgate/
    │   │   └── key.pem
    │   └── carpetas-de-otros-plugins/
    ├── world/
    │   ├── level.dat
    │   ├── region/
    │   ├── playerdata/
    │   ├── datapacks/
    │   └── dimensions/
    ├── logs/
    │   └── latest.log
    ├── ADDRESS.txt
    └── GEYSER_BEDROCK_ADDRESS.txt

La lista es orientativa: Paper y cada plugin crean archivos adicionales durante el primer arranque. Algunas carpetas no existen hasta que el plugin o el mundo se generan.

**Qué significa cada cosa:**

- **server.jar:** el programa de Paper que ejecuta el servidor.
- **eula.txt:** aceptación de la licencia de Minecraft. El instalador lo establece en eula=true.
- **server.properties:** puerto, dificultad, jugadores máximos, distancia de visión, autenticación y nombre del mundo.
- **bukkit.yml y spigot.yml:** ajustes de Bukkit/Spigot.
- **config/paper-global.yml:** configuración global avanzada de Paper.
- **config/paper-world-defaults.yml:** valores avanzados predeterminados para los mundos.
- **plugins/:** los .jar de los plugins y sus carpetas de datos/configuración.
- **plugins/Geyser-Spigot/config.yml:** configuración de conexión de Bedrock con Geyser.
- **plugins/floodgate/key.pem:** clave privada de Floodgate. **No la publiques ni la compartas.**
- **world/:** mundo principal, construcciones, chunks, datos de jugadores y dimensiones.
- **logs/latest.log:** registro de la ejecución más reciente.
- **ADDRESS.txt:** direcciones que el script publicó durante la sesión.
- **GEYSER_BEDROCK_ADDRESS.txt:** dirección Bedrock si se pudo detectar.

Paper guarda sus archivos de configuración y datos relacionados con el directorio del servidor, es decir, server/.

## 4. Encender el servidor desde Codespaces

El contenedor tiene un arranque automático configurado, pero también podés hacerlo a mano.

Abrí **Terminal → New Terminal** y ejecutá:

    cd /workspaces/minecraft-server
    bash .devcontainer/start.sh

Ese script comprueba si el servidor ya está encendido. Si falta server/server.jar, ejecuta el instalador. Después inicia scripts/run.sh en segundo plano.

### Ver si está encendido

    screen -ls

Si aparece una sesión llamada **mc**, Paper está ejecutándose.

### Ver los registros

    tail -f .devcontainer/server.log

Para ver el último registro de Paper:

    tail -f server/logs/latest.log

Para ver las direcciones de la sesión:

    cat server/ADDRESS.txt

Cuando el arranque termina, Paper muestra **Done (...)!**. Para Bedrock mediante NetherNet, Geyser también debe mostrar **Registered with the external signaling service**.

### Apagar correctamente

No borres la carpeta world ni cierres un proceso a la fuerza mientras guarda. En la terminal ejecutá:

    screen -S mc -X stuff $'stop\n'

Esperá a que termine de apagar y verificá:

    screen -ls

El apagado correcto guarda los chunks y datos del mundo.

### Volver a encender

    bash .devcontainer/start.sh

Detener el Codespace también detiene los procesos que están ejecutándose. Los archivos guardados bajo /workspaces permanecen cuando volvés a iniciarlo.

## 5. Encender desde GitHub Actions

Actions sirve para una sesión temporal. No abre un escritorio ni un explorador de carpetas como Codespaces.

1. Abrí https://github.com/RagsnorWolf/minecraft-server/actions/workflows/minecraft.yml
2. Seleccioná **Run workflow**.
3. Usá estos valores iniciales:

| Campo | Valor |
|---|---|
| Paper version | 1.21.10 |
| Duration | 330 |
| Heap | 6G |

4. Confirmá **Run workflow**.
5. Entrá en el job para ver los registros.

La sesión se apaga al terminar los minutos seleccionados; el máximo configurado por el script es 350 minutos. Para apagar antes, cancelá la ejecución en GitHub Actions.

La máquina de Actions es temporal. Este proyecto restaura y guarda el mundo y los archivos de configuración seleccionados usando cache. No es un hosting 24/7. Tampoco es lo mismo que el disco del Codespace.

## 6. Agregar plugins

Este servidor utiliza **Paper**, así que instalá plugins compatibles con Paper/Spigot/Bukkit. No uses mods Fabric o Forge en plugins/.

Descargá plugins solamente de sus autores o repositorios confiables. Un plugin tiene el mismo nivel de acceso que el servidor y puede ejecutar código en la máquina que lo hospeda.

### Método recomendado: config/plugins.txt

Este método sirve tanto para Codespaces como para Actions.

1. Buscá una versión del plugin que sea compatible con Paper 1.21.10.
2. Copiá su enlace de descarga directa al .jar (no el enlace a una página de proyecto).
3. Abrí config/plugins.txt desde el Explorer.
4. Agregá una URL HTTPS por línea.

Ejemplo ilustrativo:

    # Plugins adicionales
    https://servidor-del-autor.example/mi-plugin.jar

La URL del ejemplo es ficticia; reemplazala por la descarga real del autor.

5. Guardá el archivo.
6. En Codespaces, ejecutá:

    cd /workspaces/minecraft-server
    bash scripts/install.sh

7. Si Paper está encendido, apagalo correctamente y volvé a iniciarlo:

    screen -S mc -X stuff $'stop\n'

Esperá a que termine y ejecutá:

    bash .devcontainer/start.sh

Cuando ejecutes GitHub Actions, el instalador leerá el mismo config/plugins.txt y descargará los plugins declarados.

### Método manual: arrastrar un .jar a Codespaces

1. Apagá el servidor.
2. Abrí /workspaces/minecraft-server/server/plugins/ en Explorer.
3. Arrastrá el archivo .jar directamente a esa carpeta, no dentro de la carpeta de otro plugin.
4. Reiniciá Paper.
5. En consola o dentro del juego ejecutá /plugins.

Este método manual queda en ese Codespace, pero **no se incorpora a una ejecución de GitHub Actions**. Para compartir el plugin entre ambos entornos, usá config/plugins.txt.

### Actualizar o quitar un plugin

- Para actualizarlo, reemplazá su URL en config/plugins.txt y eliminá el .jar viejo de server/plugins/ en Codespaces antes de reinstalar.
- Para quitarlo, sacá su línea de config/plugins.txt, eliminá el .jar correspondiente de server/plugins/ y reiniciá.
- Revisá también la carpeta de datos del plugin. No borres sus configuraciones si querés conservarlas.

## 7. Agregar un mapa o mundo

Esta sección es para mundos de **Minecraft Java** compatibles con Paper. Un mapa Bedrock exportado no se puede copiar directamente a Paper: antes necesita conversión a formato Java.

### Preparar el mapa

1. Descargá el mapa en formato .zip.
2. Comprobá que sea para Minecraft 1.21.10 o una versión compatible.
3. En el ZIP buscá level.dat. Ese archivo debe quedar en la raíz de la carpeta del mundo, junto a carpetas como region, playerdata, datapacks o dimensions.

### Subirlo a Codespaces

1. Abrí el Codespace.
2. Apagá Paper con el comando de apagado seguro.
3. Arrastrá el ZIP al Explorer, por ejemplo a la raíz /workspaces/minecraft-server/.
4. Extraé el ZIP en una carpeta temporal.
5. Identificá cuál es la carpeta que contiene directamente level.dat.
6. Hacé una copia de seguridad del mundo anterior.
7. Copiá el contenido del mundo descargado a server/world/.

Ejemplo de comandos (reemplazá MI_MAPA.zip por el nombre real del archivo):

    cd /workspaces/minecraft-server
    mkdir -p /tmp/mapa-importado
    unzip -q "MI_MAPA.zip" -d /tmp/mapa-importado
    find /tmp/mapa-importado -name level.dat -print

El comando muestra la ubicación de level.dat. Usá la carpeta que lo contiene, no la carpeta superior que solo contiene otra carpeta.

Una vez identificada, hacé una copia del mundo existente:

    cd /workspaces/minecraft-server/server
    mv world "world-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir world

Copiá todos los archivos y carpetas del mundo nuevo dentro de server/world/, de modo que server/world/level.dat exista. No copies solamente region: también hacen falta los demás datos del mundo.

Antes de arrancar, verificá:

    test -f /workspaces/minecraft-server/server/world/level.dat \
      && echo "Mundo listo" \
      || echo "ERROR: no se encuentra level.dat"

El server.properties de este proyecto usa level-name=world, así que la carpeta debe llamarse world. Si el mapa tiene otro nombre, podés cambiar level-name para que coincida, pero no dejes dos mundos con nombres distintos pensando que Paper va a elegir el correcto automáticamente.

Cuando esté listo:

    cd /workspaces/minecraft-server
    bash .devcontainer/start.sh

### Importante sobre Actions

Subir un ZIP a Codespaces no lo copia a la máquina temporal de Actions. Si querés que un mundo importado también se use desde Actions, hay que incorporarlo al flujo de importación (por ejemplo, descargar un ZIP desde un enlace privado o una publicación de GitHub) o ejecutar el servidor desde Codespaces. No subas un mundo grande a Git normal sin revisar sus dimensiones: GitHub recomienda mantener los repositorios livianos y tiene límites de tamaño para archivos.

## 8. Configuración avanzada

Los archivos más importantes son:

| Archivo | Qué controla |
|---|---|
| server/server.properties | Configuración principal del juego |
| server/config/paper-global.yml | Rendimiento y comportamiento global de Paper |
| server/config/paper-world-defaults.yml | Ajustes predeterminados de cada mundo |
| server/bukkit.yml | Ajustes de Bukkit |
| server/spigot.yml | Ajustes de Spigot |
| server/commands.yml | Alias y comandos |
| server/plugins/NOMBRE/config.yml | Configuración individual de cada plugin |
| server/plugins/Geyser-Spigot/config.yml | Geyser y conexión Bedrock |

### Propiedades comunes

En server/server.properties:

- max-players=4: máximo de jugadores.
- view-distance=10: distancia de chunks que ve el jugador.
- simulation-distance=8: distancia de chunks que simulan entidades y actividad.
- difficulty=normal: dificultad.
- gamemode=survival: modo de juego predeterminado.
- pvp=true: permite PvP.
- online-mode=true: autentica las cuentas Java.
- spawn-protection=0: desactiva la protección de spawn.
- server-port=25565: puerto Java local.
- level-name=world: carpeta del mundo principal.
- enforce-secure-profile=false: compatibilidad de chat necesaria para este caso de Geyser/Floodgate.

### Qué archivo editar según el entorno

**Codespaces:** editá los archivos dentro de server/ desde Explorer. Esos cambios quedan en el almacenamiento del Codespace.

**GitHub Actions:** el flujo guarda en cache el mundo, server.properties, server/config/, archivos Bukkit/Spigot y datos de plugins. Los valores básicos de online-mode, max-players, view-distance, simulation-distance, spawn-protection, motd y max-tick-time también se establecen desde scripts/install.sh. Si cambiás alguno de esos valores para Actions, modificá la llamada set_prop correspondiente en scripts/install.sh para que el instalador no lo vuelva a poner en su valor anterior.

**Plantilla:** config/server.properties se copia solo si todavía no existe server/server.properties. Cambiar la plantilla no sobreescribe automáticamente una configuración que ya existe en Codespaces.

### Seguridad

- No compartas plugins/floodgate/key.pem.
- No pegues la configuración NetherNet ni la clave privada de Playit en archivos públicos.
- No subas el contenido de server/ al repositorio.
- No cambies online-mode=false como atajo para resolver problemas de autenticación. Esta configuración ahora utiliza autenticación oficial de Java y Floodgate para Bedrock.
- Hacé backups antes de tocar el mundo, UUIDs, autenticación o configuraciones avanzadas.

## 9. Configurar Playit.gg para Java y Bedrock

Playit publica el servidor sin abrir puertos del router. Necesitás dos túneles distintos porque Java y Bedrock utilizan protocolos diferentes.

### A. Crear el agente

1. Entrá en https://playit.gg/ y abrí tu cuenta.
2. Creá un agente desde la sección de instalación/configuración de Playit.
3. Obtené la Secret Key del agente.
4. Guardala en un lugar privado. No la subas a GitHub ni la pegues en el chat.

El script de este repositorio inicia el agente oficial de Playit mediante Docker cuando existe PLAYIT_SECRET.

### B. Crear el túnel Java

En Playit, creá un túnel nuevo de tipo **Minecraft Java**.

- Protocolo: TCP.
- Destino local: 127.0.0.1.
- Puerto local: 25565.

Guardá el hostname y puerto públicos que Playit te asigna. Esa es la dirección para jugadores Java.

### C. Crear el túnel Bedrock (NetherNet)

1. Creá otro túnel.
2. Elegí exactamente **Minecraft Bedrock (NetherNet)**, no el túnel antiguo llamado simplemente Minecraft Bedrock.
3. Confirmá que aceptás que NetherNet es experimental.
4. Abrí el túnel recién creado.
5. Entrá en **Configuration Help**.
6. Elegí la pestaña **Geyser**.
7. Copiá el bloque de configuración completo.

Ese bloque incluye un token privado que permite conectar un servidor a tu túnel. No lo compartas ni lo publiques.

### D. Guardar los secretos para GitHub Actions

Abrí:

https://github.com/RagsnorWolf/minecraft-server/settings/secrets/actions

Creá estos tres secretos con sus nombres exactos:

| Nombre | Valor |
|---|---|
| PLAYIT_SECRET | Secret Key del agente |
| PLAYIT_GEYSER_CONFIG | Bloque YAML copiado en Configuration Help → Geyser |
| PLAYIT_BEDROCK_ADDRESS | Host público del túnel Bedrock |

No agregues comillas alrededor del contenido YAML. Pegá el bloque respetando sus saltos de línea e indentación. Si el hostname incluye un puerto, conservá el valor tal como aparece en Playit.

### E. Guardar los secretos para Codespaces

Los secretos de Actions no se comparten automáticamente con Codespaces.

Abrí:

https://github.com/settings/codespaces

Creá los mismos tres secretos y asignales acceso al repositorio RagsnorWolf/minecraft-server. Si el Codespace ya estaba abierto, detenelo y volvé a iniciarlo para que reciba los nuevos secretos.

### F. Iniciar y comprobar

Arrancá el servidor desde Codespaces o Actions. En los registros buscá:

- Geyser
- Registered with the external signaling service
- Servidor listo

Si Geyser informa que se registró con el servicio externo de señalización, NetherNet está enlazado a Playit.

Las direcciones de la sesión se guardan en:

    server/ADDRESS.txt
    server/GEYSER_BEDROCK_ADDRESS.txt

**Para conectarse:**

| Cliente | Dirección |
|---|---|
| Java | Host y puerto públicos del túnel Minecraft Java |
| Bedrock | Host del túnel NetherNet y puerto configurado por Geyser (normalmente 19132) |

No uses la dirección Java para Bedrock. El túnel NetherNet es exclusivo para Bedrock; para Java creaste otro túnel.

## 10. Solución de problemas

### No aparece server/

Abrí Codespaces y ejecutá:

    cd /workspaces/minecraft-server
    bash scripts/install.sh

Después actualizá Explorer.

### El servidor no arranca

Revisá:

    tail -n 100 .devcontainer/server.log
    tail -n 100 server/logs/latest.log

### Paper arranca, pero no carga un plugin

- Confirmá que el .jar está directamente en server/plugins/.
- Confirmá que sea un plugin Paper/Spigot, no un mod Fabric/Forge.
- Comprobá la compatibilidad con Paper 1.21.10.
- Revisá server/logs/latest.log.
- Ejecutá /plugins en la consola.

### Java conecta, pero Bedrock no

- Confirmá que el segundo túnel es **Minecraft Bedrock (NetherNet)**.
- Confirmá que PLAYIT_GEYSER_CONFIG contiene el bloque copiado desde Configuration Help → Geyser.
- Comprobá que PLAYIT_SECRET está configurado en el entorno desde el que se inicia el servidor.
- Buscá **Registered with the external signaling service** en server/logs/latest.log.
- Verificá el host y puerto Bedrock.

### El agente Playit no inicia

El script necesita Docker para iniciar el contenedor oficial de Playit. En Codespaces comprobá:

    docker version

Si el cliente Docker no puede comunicarse con el daemon, Playit no se inicia desde ese entorno. La sesión puede recurrir a Bore como alternativa temporal para Java, pero Bore no sustituye el túnel Bedrock NetherNet.

### No encuentro la dirección pública

    cat /workspaces/minecraft-server/server/ADDRESS.txt

O mirá:

    tail -n 100 /workspaces/minecraft-server/.devcontainer/server.log

Las direcciones de túneles temporales pueden cambiar en otra sesión.

## 11. Documentación oficial

- Paper — archivos de configuración: https://docs.papermc.io/paper/reference/configuration/
- Paper — agregar plugins: https://docs.papermc.io/paper/adding-plugins/
- Paper — server.properties: https://docs.papermc.io/paper/reference/server-properties/
- Playit — Geyser y Paper: https://playit.gg/support/use-geyser-on-paper/
- GitHub — persistencia en Codespaces: https://docs.github.com/en/codespaces/developing-in-a-codespace/persisting-environment-variables-and-temporary-files
- GitHub — ciclo de vida de Codespaces: https://docs.github.com/en/codespaces/about-codespaces/understanding-the-codespace-lifecycle
