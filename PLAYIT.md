# Dirección pública Java + Bedrock con Playit

Playit es el túnel público. Se necesita una vez por Codespace; después se reinicia junto al servidor.

## 1. Vincular el agente Playit

1. Abrí el Codespace en el navegador.
2. Esperá a que termine Paper. El script también intenta iniciar el agente Playit.
3. En la terminal ejecutá:

```bash
tail -f server/logs/playit.log
```

4. Si Playit muestra un enlace de activación/claim, abrilo en el navegador del celular o PC e iniciá sesión en Playit.
5. Si no aparece ningún enlace, ejecutá `playit setup` en una terminal y seguí lo que indique. No pegues claves privadas en el repositorio ni en chats.

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

1. En Playit creá otro túnel y elegí **Minecraft Bedrock (NetherNet)**. No elijas el túnel Bedrock antiguo.
2. Abrí **Configuration Help → Geyser** y copiá el bloque YAML completo.
3. En el Explorer del Codespace abrí `server/plugins/Geyser-Spigot/config.yml`.
4. Dentro de la sección `bedrock:`, reemplazá las opciones indicadas por Playit, respetando exactamente la indentación.
5. Dentro de `java:`, confirmá `auth-type: floodgate`.
6. Guardá el archivo y reiniciá Paper:

```bash
bash scripts/stop.sh
bash scripts/start.sh
```

7. En el log de Geyser buscá **Registered with the external signaling service**. Ese mensaje confirma que NetherNet quedó registrado.
8. En Minecraft Bedrock agregá el hostname que da Playit y el puerto indicado (normalmente 19132).

La guía oficial de Playit detalla estos mismos pasos: https://playit.gg/support/use-geyser-on-paper/

**Privacidad:** el bloque de Configuration Help incluye un token privado. No lo subas a Git, no lo compartas y no lo pegues en conversaciones. El directorio `server/` ya está ignorado por Git.

## 4. Dónde consultar las direcciones

- Java: panel **Tunnels** de Playit → túnel Minecraft Java.
- Bedrock: panel **Tunnels** de Playit → túnel NetherNet (normalmente puerto 19132).
- El panel de GitHub Codespaces no reemplaza a Playit para la IP pública del juego.

Si el Codespace se detiene, el agente y el servidor se desconectan. Al reanudar el Codespace, el script vuelve a iniciar ambos procesos.
