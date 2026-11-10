# Ragsnor — Servidor Minecraft Java + Bedrock

Servidor Paper 1.21.10 con GeyserMC, Floodgate y ViaVersion. Se puede ejecutar por sesiones desde GitHub Actions o GitHub Codespaces y publicar Java y Bedrock mediante Playit.gg.

## Estado y límites

- Paper 1.21.10 usa Java 21. Se conserva esta versión para evitar convertir el mundo guardado a una versión nueva sin una copia verificada.
- ViaVersion se instala automáticamente para admitir clientes Java actuales, incluida la línea 26.3.
- Geyser + Floodgate permiten el acceso Bedrock sin que cada jugador tenga una cuenta Java.
- GitHub Actions funciona por sesiones y apaga el servidor al terminar el tiempo configurado (por defecto 330 minutos). No es un hosting 24/7.
- Codespaces también puede ejecutar el servidor, pero las horas gratuitas dependen de la cuota de la cuenta y el entorno debe permanecer activo.
- El mundo de Actions se conserva mediante GitHub Actions Cache. No es un sistema de copias de seguridad permanente: descargá copias periódicamente.

## Archivos y carpetas

La carpeta **server/** no se sube al repositorio. Está excluida por .gitignore y se genera al instalar el servidor.

Después de ejecutar la instalación, contiene:
- **server.jar**: Paper.
- **plugins/**: Geyser, Floodgate y ViaVersion.
- **plugins/Geyser-Spigot/config.yml**: configuración de Geyser y conexión Bedrock.
- **world/** y dimensiones: mundo.
- **logs/latest.log**: registro del servidor.
- **ADDRESS.txt**: direcciones publicadas durante la sesión.
- **GEYSER_BEDROCK_ADDRESS.txt**: dirección pública Bedrock, si fue configurada.

## Configurar Playit.gg (una sola vez)

Necesitás una cuenta en https://playit.gg y dos túneles diferentes.

### 1. Túnel Java

En Playit, creá un túnel de tipo Minecraft Java:
- Destino local: 127.0.0.1
- Puerto local: 25565
- Protocolo: TCP

En Agents / Setup copiá la Secret Key del agente. No la publiques ni la pegues en archivos del repositorio.

### 2. Túnel Bedrock

Para Geyser actual, creá un túnel de tipo **Minecraft Bedrock (NetherNet)**, no el túnel Bedrock antiguo. Confirmá el aviso experimental si Playit lo solicita.

Abrí ese túnel, entrá en **Configuration Help**, seleccioná **Geyser** y copiá el bloque de configuración que proporciona Playit. Ese bloque contiene credenciales privadas: tratálo como una contraseña.

### 3. Crear secretos de GitHub Actions

Abrí:
https://github.com/RagsnorWolf/minecraft-server/settings/secrets/actions

Creá estos secretos exactamente con estos nombres:

| Nombre | Contenido |
|---|---|
| PLAYIT_SECRET | Secret Key del agente Playit |
| PLAYIT_GEYSER_CONFIG | Bloque YAML copiado desde Configuration Help → Geyser |
| PLAYIT_BEDROCK_ADDRESS | Host público que muestra el túnel Bedrock |

Guardá el hostname tal como lo muestra Playit. Si ya incluye un puerto, dejalo incluido. Si no lo incluye, el script agrega el puerto Geyser configurado (19132).

### 4. Secretos para Codespaces

Si vas a ejecutar desde Codespaces, también creá esos mismos secretos en:
https://github.com/settings/codespaces

Asigná cada secreto al repositorio RagsnorWolf/minecraft-server. Actions y Codespaces mantienen sus secretos por separado.

No compartas en chats, issues, capturas ni commits el valor de los secretos. Si una clave se publica accidentalmente, revocala y generá otra en Playit.

## Arrancar desde GitHub Actions

1. Abrí la pestaña Actions del repositorio.
2. Seleccioná **Minecraft Server**.
3. Presioná **Run workflow**.
4. Usá Paper 1.21.10, duración 330 minutos y heap 6G como valores iniciales.
5. Abrí el job y revisá el registro. Cuando aparezca “Servidor listo”, el log y el issue de estado muestran las direcciones disponibles.

Para apagar antes de tiempo, cancelá la ejecución activa desde Actions.

Si Playit no está configurado, el script intenta ofrecer una dirección Bore temporal para Java. Bore **no sirve para Bedrock**.

## Arrancar desde Codespaces

1. En el repositorio, presioná Code → Codespaces → Create codespace on main.
2. Esperá a que termine .devcontainer/setup.sh.
3. .devcontainer/start.sh inicia el servidor cuando arranca el Codespace.
4. Seguí los registros con el comando: **tail -f .devcontainer/server.log**
5. La dirección también queda en **server/ADDRESS.txt**.
6. Para apagar, detené el Codespace.

La ruta del servidor dentro del Codespace es:
**/workspaces/minecraft-server/server/**

Los puertos reenviados de Codespaces sirven para pruebas locales, pero no reemplazan Playit para conexiones públicas Bedrock.

## Cómo entrar

| Edición | Dirección | Puerto |
|---|---|---|
| Java | Host publicado como JAVA en el log | el puerto que muestra Playit |
| Bedrock | Host configurado como BEDROCK | 19132, salvo que el bloque de Playit indique otro |

Java y Bedrock son túneles diferentes. No uses la dirección Java para Bedrock.

## Autenticación y seguridad

- online-mode=true mantiene la autenticación oficial de Java.
- Geyser usa auth-type: floodgate para permitir el ingreso Bedrock mediante Floodgate.
- No pongas online-mode=false como solución a problemas de Floodgate.
- PLAYIT_GEYSER_CONFIG y la clave de Floodgate son credenciales privadas. Nunca deben subirse al repositorio.
- El servidor está limitado inicialmente a 4 jugadores. Cambiá max-players solo si la memoria y la sesión lo permiten.

## Primer ingreso como administrador

Para dar permisos de operador, agregá tu UUID Java real a server/ops.json durante una sesión y preservá ese archivo entre sesiones. No uses UUIDs falsos ni el UUID de ceros en un servidor con autenticación oficial.

RCON no está habilitado por defecto. Para usarlo habría que configurarlo con una contraseña privada y restringirlo a localhost.

## Diagnóstico rápido

- Falta PLAYIT_SECRET: revisar Settings → Secrets and variables → Actions.
- Java no muestra dirección Playit: revisar que el agente esté enlazado y que exista el túnel Java TCP hacia 127.0.0.1:25565.
- Bedrock no conecta: revisar PLAYIT_GEYSER_CONFIG, PLAYIT_BEDROCK_ADDRESS, el tipo NetherNet y el mensaje de Geyser sobre el registro con el servicio de señalización.
- Geyser no acepta Bedrock: confirmar auth-type: floodgate y que Floodgate esté en server/plugins/.
- Servidor lento: reducir view-distance, simulation-distance o HEAP.

## Referencias oficiales

- Paper: https://papermc.io
- ViaVersion: https://viaversion.com
- Geyser + Playit: https://playit.gg/support/use-geyser-on-paper/
- Geyser Setup: https://geysermc.org/wiki/geyser/setup/
- Floodgate Setup: https://geysermc.org/wiki/floodgate/setup/
- Playit: https://playit.gg
