#!/usr/bin/env bash
# Arranca Paper, configura Geyser/Floodgate y levanta Playit.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRV="$ROOT/server"
DURATION="${DURATION:-0}"
HEAP="${HEAP:-6G}"
REPO="${GITHUB_REPOSITORY:-RagsnorWolf/minecraft-server}"
ADDR_FILE="$SRV/ADDRESS.txt"
JAVA_ADDR=""
BEDROCK_ADDR=""
PLAYIT_ADDR=""
cd "$SRV"
mkdir -p logs
log() { echo "[$(date +%H:%M:%S)] $*"; }

if ! [[ "$DURATION" =~ ^[0-9]+$ ]]; then
  log "ERROR: DURATION debe ser un entero en minutos."
  exit 1
fi
if (( DURATION > 350 )); then
  log "ERROR: DURATION no puede superar 350 minutos."
  exit 1
fi
if ! [[ "$HEAP" =~ ^[1-9][0-9]*G$ ]]; then
  log "ERROR: HEAP debe tener formato como 4G o 6G."
  exit 1
fi

publish() {
  local java_addr="$1" bedrock_addr="$2"
  {
    echo "JAVA=$java_addr"
    echo "BEDROCK=$bedrock_addr"
    echo "FECHA=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "HOST=${CODESPACE_NAME:-github-actions}"
  } > "$ADDR_FILE"
  echo ""
  echo "================================================================"
  echo "  JAVA     ->  $java_addr"
  echo "  BEDROCK  ->  $bedrock_addr"
  echo "================================================================"
  echo ""
  [ -n "${GITHUB_TOKEN:-}" ] || return 0
  local payload
  payload=$(jq -n \
    --arg title "Servidor ON - $java_addr" \
    --arg java "$java_addr" \
    --arg bedrock "$bedrock_addr" \
    --arg host "${CODESPACE_NAME:-github-actions}" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{title:$title, body:("Servidor encendido.\n\n| Edicion | Direccion |\n|---|---|\n| Java | **" + $java + "** |\n| Bedrock | **" + $bedrock + "** |\n\nHost: **" + $host + "**\nHora UTC: **" + $ts + "**")}')
  curl -fsS -o /dev/null -X POST \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$REPO/issues" \
    -d "$payload" || log "Aviso: no se pudo publicar el issue de estado."
}

wait_for_server() {
  log "Esperando a que Paper termine de arrancar ..."
  for _ in $(seq 1 180); do
    if grep -qE 'Done \([0-9.]+s\)!' logs/latest.log 2>/dev/null; then
      log "Servidor listo."
      return 0
    fi
    if ! screen -ls 2>/dev/null | grep -q '\.mc'; then
      log "ERROR: el proceso del servidor terminó inesperadamente."
      tail -n 80 logs/latest.log 2>/dev/null || true
      return 1
    fi
    sleep 2
  done
  log "ERROR: tiempo agotado esperando que Paper arranque."
  tail -n 80 logs/latest.log 2>/dev/null || true
  return 1
}

start_server() {
  log "Arrancando Paper con $HEAP de RAM ..."
  # Evita que el chequeo de "Done" detecte una línea de una sesión anterior.
  : > logs/latest.log
  screen -dmS mc java \
    "-Xms$HEAP" "-Xmx$HEAP" \
    -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC \
    -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M \
    -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 \
    -jar server.jar nogui
  wait_for_server
}

stop_server() {
  if screen -ls 2>/dev/null | grep -q '\.mc'; then
    log "Apagando Paper de forma segura ..."
    screen -S mc -X stuff $'stop\n' || true
    for _ in $(seq 1 60); do
      if ! screen -ls 2>/dev/null | grep -q '\.mc'; then break; fi
      sleep 1
    done
    screen -wipe >/dev/null 2>&1 || true
  fi
}

start_playit() {
  command -v docker >/dev/null 2>&1 || {
    log "Docker no está disponible; no se puede iniciar el agente Playit."
    return 1
  }
  log "Iniciando agente Playit ..."
  docker rm -f playit >/dev/null 2>&1 || true
  docker run -d --name playit --network host \
    -e SECRET_KEY="$PLAYIT_SECRET" \
    ghcr.io/playit-cloud/playit-agent:latest >/dev/null || {
      log "ERROR: no se pudo iniciar el contenedor Playit."
      return 1
    }
  for _ in $(seq 1 45); do
    PLAYIT_ADDR="$(docker logs playit 2>&1 \
      | grep -Eo '([a-zA-Z0-9-]+\.)+(playit\.gg|ply\.gg|joinmc\.link)(:[0-9]{1,5})?' \
      | head -n1 || true)"
    [ -n "$PLAYIT_ADDR" ] && break
    sleep 2
  done
  if [ -n "$PLAYIT_ADDR" ]; then
    log "Agente Playit listo. Se detectó el endpoint Java."
    return 0
  fi
  log "El agente Playit arrancó, pero no anunció un endpoint Java. Se probará Bore para Java."
  return 1
}

start_bore() {
  log "Iniciando túnel Bore de respaldo (solo Java) ..."
  local arch file
  arch="$(uname -m)"
  file="bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz"
  [ "$arch" = "aarch64" ] && file="bore-v0.6.0-aarch64-unknown-linux-musl.tar.gz"
  if [ ! -x /tmp/bore-bin ]; then
    curl -fsSL "https://github.com/ekzhang/bore/releases/download/v0.6.0/$file" -o /tmp/bore.tgz
    tar -xzf /tmp/bore.tgz -C /tmp
    mv /tmp/bore /tmp/bore-bin 2>/dev/null || true
    chmod +x /tmp/bore-bin
  fi
  pkill -f 'bore-bin local' >/dev/null 2>&1 || true
  nohup /tmp/bore-bin local 25565 --to bore.pub > /tmp/bore.log 2>&1 &
  local addr=""
  for _ in $(seq 1 30); do
    addr="$(grep -Eo 'bore\.pub:[0-9]{1,5}' /tmp/bore.log | head -n1 || true)"
    [ -n "$addr" ] && break
    sleep 1
  done
  [ -n "$addr" ] || {
    log "ERROR: Bore no devolvió una dirección."
    cat /tmp/bore.log || true
    return 1
  }
  JAVA_ADDR="$addr"
}

if screen -ls 2>/dev/null | grep -q '\.mc'; then
  log "El servidor ya está corriendo."
  cat "$ADDR_FILE" 2>/dev/null || true
  exit 0
fi
[ -s server.jar ] || {
  log "Falta server.jar. Ejecutá bash scripts/install.sh."
  exit 1
}

# Geyser crea su configuración en el primer arranque. Se hace una sola
# inicialización, se detiene Paper y se aplica Floodgate antes del arranque real.
GEYSER_CONFIG="$SRV/plugins/Geyser-Spigot/config.yml"
if [ ! -s "$GEYSER_CONFIG" ]; then
  log "Primer arranque: generando la configuración inicial de Geyser ..."
  start_server
  stop_server
fi
if [ ! -s "$GEYSER_CONFIG" ]; then
  log "ERROR: Geyser no generó plugins/Geyser-Spigot/config.yml."
  exit 1
fi

python3 "$ROOT/scripts/configure-geyser.py" "$SRV"

# En las pruebas automatizadas se omiten servicios públicos y credenciales.
# En uso normal, el agente debe estar activo antes de que Geyser cargue NetherNet.
if [ "${SKIP_PUBLIC_TUNNELS:-false}" = "true" ]; then
  log "Modo de prueba: túneles públicos omitidos."
elif [ -n "${PLAYIT_SECRET:-}" ]; then
  start_playit || true
else
  log "PLAYIT_SECRET no está configurado. Java usará Bore si está disponible."
fi

start_server

if [ "${SKIP_PUBLIC_TUNNELS:-false}" = "true" ]; then
  JAVA_ADDR="localhost:25565"
  BEDROCK_ADDR="Solo local: túneles públicos omitidos en la prueba"
else
  BEDROCK_FILE="$SRV/GEYSER_BEDROCK_ADDRESS.txt"
  if [ -s "$BEDROCK_FILE" ]; then
    BEDROCK_ADDR="$(cat "$BEDROCK_FILE")"
  elif [ -n "${PLAYIT_GEYSER_CONFIG:-}" ]; then
    BEDROCK_ADDR="NetherNet aplicado; falta PLAYIT_BEDROCK_ADDRESS"
  else
    BEDROCK_ADDR="No configurado: falta PLAYIT_GEYSER_CONFIG"
  fi

  if [ -n "$PLAYIT_ADDR" ]; then
    JAVA_ADDR="$PLAYIT_ADDR"
  else
    start_bore || {
      stop_server
      docker stop playit >/dev/null 2>&1 || true
      exit 1
    }
  fi
fi

publish "$JAVA_ADDR" "$BEDROCK_ADDR"
if [ "$DURATION" -gt 0 ]; then
  log "El servidor se apagará en $DURATION minutos."
  sleep "$((DURATION * 60))"
  stop_server
  docker stop playit >/dev/null 2>&1 || true
  pkill -f 'bore-bin local' >/dev/null 2>&1 || true
else
  log "Servidor en ejecución sin límite. Detené el Codespace para apagarlo."
  while screen -ls 2>/dev/null | grep -q '\.mc'; do sleep 30; done
  docker stop playit >/dev/null 2>&1 || true
  pkill -f 'bore-bin local' >/dev/null 2>&1 || true
fi
