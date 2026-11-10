# Ragsnor Minecraft Server — Paper 1.21.10

Servidor Paper 1.21.10 para Minecraft Java, con Geyser + Floodgate preparados para habilitar Bedrock. Se ejecuta en GitHub Codespaces y conserva el mundo dentro del almacenamiento persistente del Codespace.

## Crear y encender

1. Abrí **Code → Codespaces → Create codespace on main**.
2. Elegí una máquina de al menos **4 CPU / 16 GB RAM / 64 GB de almacenamiento** si está disponible.
3. Codespaces instala Java 21, Paper, Geyser, Floodgate y Playit.
4. Al abrir o reanudar el Codespace, Paper se inicia automáticamente.

Para iniciarlo manualmente:

```bash
bash scripts/start.sh
```

## Comandos

```bash
bash scripts/status.sh   # estado y últimas líneas
bash scripts/stop.sh     # apagado seguro y guardado del mundo
bash scripts/start.sh    # volver a encender
bash scripts/console.sh  # abrir la consola de Paper
bash scripts/backup.sh   # backup comprimido del mundo (con Paper apagado)
```

## Direcciones públicas

La dirección pública se obtiene después de vincular el agente Playit y crear los túneles:
- Java: túnel **Minecraft Java**, destino local `127.0.0.1:25565`.
- Bedrock: túnel **Minecraft Bedrock (NetherNet)** y bloque de configuración **Geyser** aplicado a `server/plugins/Geyser-Spigot/config.yml`.

Seguí **[PLAYIT.md](PLAYIT.md)**. No hay una IP pública fija incorporada al repositorio: Playit asigna la dirección al agente activo.

## Carpetas

- `server/world/`: mundo principal.
- `server/plugins/`: plugins .jar y sus configuraciones.
- `server/server.properties`: ajustes del juego.
- `server/config/`: configuración avanzada de Paper.
- `server/logs/latest.log`: log de Paper.
- `server/logs/playit.log`: log del túnel.
- `backups/`: copias manuales del mundo.

Los datos de `server/` y `backups/` se excluyen de Git para evitar subir mundos, archivos .jar o claves privadas.
