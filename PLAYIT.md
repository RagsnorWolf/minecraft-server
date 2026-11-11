# Dirección pública Java + Bedrock con Playit

Playit es el túnel público. Se necesita una vez por Codespace; después se reinicia junto al servidor.

## 1. Vincular el agente Playit

1. Abrí el Codespace en el navegador.
2. En una terminal ejecutá:

```bash
bash scripts/connect-playit.sh
```

3. Seguí el enlace o código que muestre Playit para vincular el agente a tu cuenta. El script volverá a iniciar el agente al terminar.
4. Revisá el registro del agente:

```bash
tail -f server/logs/playit.log
```

No pegues claves privadas en el repositorio ni en chats.

Después de vincularlo, verificá que el agente siga activo:

```bash
bash scripts/status.sh
```

## 2. Crear el túnel Java

En https://playit.gg/account/tunnels:

1. Creá un túnel nuevo de tipo **Minecraft Java**.
2. Destino local: `127.0.0.1`.
3. Puerto local: `25565`.
4. Protocolo: TCP.
5. Guardá el túnel.

Copiá el hostname y puerto público que aparece en Playit. Esa es la dirección que se escribe en **Minecraft Java → Multiplayer → Add Server**. No supongas que el puerto público será 25565; usá el que muestra Playit.

## 3. Configurar Bedrock con Geyser + Floodgate

El servidor ya instala ambos plugins. Primero Paper tiene que arrancar una vez para generar:

`server/plugins/Geyser-Spigot/config.yml`

Luego:

1. En Playit creá un túnel nuevo de tipo **Minecraft Bedrock (NetherNet)**.
2. Abrí ese túnel y copiá el token NXS que proporciona Playit.
3. En el Explorer del Codespace abrí `server/plugins/Geyser-Spigot/config.yml`.
4. En la sección `bedrock:`, configurá el transporte NetherNet y el servicio de señalización NXS con el endpoint `https://nethernet.playit.gg` y el token de ese túnel. Desactivá STUN discovery. Seguí el bloque de configuración que Playit ofrece para tu túnel, respetando la indentación.
5. Confirmá que la sección `remote:` tenga `auth-type: floodgate` (el servidor lo ajusta automáticamente en el arranque).
6. Guardá el archivo y reiniciá Paper:

```bash
bash scripts/stop.sh
bash scripts/start.sh
```

7. En el log de Geyser verificá que NetherNet/NXS se haya iniciado correctamente y que no aparezcan errores de autenticación del túnel.
8. En Minecraft Bedrock agregá el hostname que da Playit y el puerto de conexión que el panel indica (Bedrock normalmente usa el puerto público 19132).

La versión actual de Playit documenta NetherNet con NXS, el endpoint `https://nethernet.playit.gg` y un token específico del túnel: https://github.com/playit-cloud/playit-agent/releases/tag/v1.2.0

**Privacidad:** el bloque de Configuration Help incluye un token privado. No lo subas a Git, no lo compartas y no lo pegues en conversaciones. El directorio `server/` ya está ignorado por Git.

## 4. Dónde consultar las direcciones

- Java: panel **Tunnels** de Playit → túnel Minecraft Java.
- Bedrock: panel **Tunnels** de Playit → túnel NetherNet (normalmente puerto 19132).
- El panel de GitHub Codespaces no reemplaza a Playit para la IP pública del juego.

Si el Codespace se detiene, el agente y el servidor se desconectan. Al reanudar el Codespace, el script inicia el daemon desde `.playit/playit.toml` y luego Paper. La clave no se sube al repositorio.
