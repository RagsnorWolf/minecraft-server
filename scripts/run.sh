#!/usr/bin/env bash
# Arranca el servidor + tunel publico y publica la direccion.
#
# Orden de preferencia del tunel:
#   1) playit.gg  (si existe PLAYIT_SECRET)  -> da TCP (Java) y UDP (Bedrock)
#   2) bore.pub   (sin cuenta, solo TCP/Java) -> funciona siempre
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRV="$ROOT/server"
DURATION="${DURATION:-0}"      # 0 = sin limite
HEAP="${HEAP:-6G}"
REPO="${GITHUB_REPOSITORY:-RagsnorWolf/minecraft-server}"
ADDR_FILE="$SRV/ADDRESS.txt"

cd "$SRV" || exit 1

log() { echo "[$(date +%H:%M:%S)] $*"; }

# ------------------------------------------------------------ utilidades ---
publish() {
  # Guarda la direccion y la publica en un issue del repo (para leerla remoto)
  local java_addr="$1" bedrock_addr="$2"
  {
    echo "JAVA=$java_addr"
    echo "BEDROCK=$bedrock_addr"
    echo "FECHA=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "CODESPACE=${CODESPACE_NAME:-github-actions}"
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
    '{title:$title, body:("Servidor encendido.\n\n| Edicion | Direccion |\n|---|---|\n| Java | `" + $java + "` |\n| Bedrock | `" + $bedrock + "` |\n\nHost: `" + $host + "`\nHora UTC: `" + $ts + "`")}')

  curl -s -o /dev/null -X POST \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$REPO/issues" \
    -d "$payload" || true
}

wait_for_server() {
  log "Esperando a que Paper termine de arrancar ..."
  for _ in $(seq 1 180); do
    if grep -qE 'Done \([0-9.]+s\)!' logs/latest.log 2>/dev/null; then
      log "Servidor listo."
      return 0
    fi
    if ! screen -ls 2>/dev/null | grep -q '\.mc'; then
      log "ERROR: el proceso del servidor murio."
      tail -n 60 logs/latest.log 2>/dev/null
      return 1
    fi
    sleep 2
  done
  log "ERROR: timeout esperando 'Done'."
  return 1
}

# ------------------------------------------------------------- tuneles -----
start_playit() {
  command -v docker >/dev/null 2>&1 || { log "docker no disponible"; return 1; }
  log "Levantando playit.gg (TCP 25565 + UDP 19132) ..."
  docker rm -f playit >/dev/null 2>&1
  docker run -d --name playit --network host \
    -e SECRET_KEY="$PLAYIT_SECRET" \
    ghcr.io/playit-cloud/playit-agent:latest >/dev/null 2>&1 || {
      log "no se pudo iniciar el contenedor de playit"; return 1; }

  local addr=""
  for _ in $(seq 1 45); do
    addr=$(docker logs playit 2>&1 \
      | grep -Eo '([a-zA-Z0-9-]+\.)+(playit\.gg|ply\.gg|joinmc\.link)(:[0-9]{1,5})?' \
      | head -n1)
    [ -n "$addr" ] && break
    sleep 2
  done
  [ -n "$addr" ] || { log "playit no devolvio direccion"; docker logs playit 2>&1 | tail -20; return 1; }
  PLAYIT_ADDR="$addr"
  return 0
}

start_bore() {
  log "Levantando tunel bore.pub (solo Java, sin cuenta) ..."
  local arch
  arch=$(uname -m)
  local file="bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz"
  [ "$arch" = "aarch64" ] && file="bore-v0.6.0-aarch64-unknown-linux-musl.tar.gz"

  if [ ! -x /tmp/bore ]; then
    curl -fsSL "https://github.com/ekzhang/bore/releases/download/v0.6.0/$file" -o /tmp/bore.tgz || return 1
    tar -xzf /tmp/bore.tgz -C /tmp || return 1
    mv /tmp/bore /tmp/bore-bin 2>/dev/null || true
    chmod +x /tmp/bore-bin
  fi

  pkill -f 'bore-bin local' >/dev/null 2>&1 || true
  nohup /tmp/bore-bin local 25565 --to bore.pub > /tmp/bore.log 2>&1 &
  local addr=""
  for _ in $(seq 1 30); do
    addr=$(grep -Eo 'bore\.pub:[0-9]{1,5}' /tmp/bore.log | head -n1)
    [ -n "$addr" ] && break
    sleep 1
  done
  [ -n "$addr" ] || { log "bore no devolvio direccion"; cat /tmp/bore.log; return 1; }
  BORE_ADDR="$addr"
  return 0
}

# ------------------------------------------------------------ principal ----
if screen -ls 2>/dev/null | grep -q '\.mc'; then
  log "El servidor ya esta corriendo."
  cat "$ADDR_FILE" 2>/dev/null
  exit 0
fi

[ -f server.jar ] || { log "Falta server.jar. Ejecuta scripts/install.sh"; exit 1; }

JAVA_FLAGS=(
  "-Xms${HEAP}" "-Xmx${HEAP}"
  -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200
  -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC
  -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M
  -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4
  -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90
  -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32
  -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1
  -jar server.jar nogui
)

log "Arrancando Paper con ${HEAP} de RAM ..."
screen -dmS mc java "${JAVA_FLAGS[@]}"
wait_for_server || exit 1

JAVA_ADDR="localhost:25565"
BEDROCK_ADDR="no disponible"

if [ -n "${PLAYIT_SECRET:-}" ] && start_playit; then
  JAVA_ADDR="$PLAYIT_ADDR"
  BEDROCK_ADDR="$PLAYIT_ADDR"
elif start_bore; then
  JAVA_ADDR="$BORE_ADDR"
  BEDROCK_ADDR="(requiere playit.gg: agrega PLAYIT_SECRET)"
fi

publish "$JAVA_ADDR" "$BEDROCK_ADDR"

# ------------------------------------------------------------- keepalive ---
if [ "$DURATION" -gt 0 ]; then
  log "El servidor se apagara en $DURATION minutos."
  sleep $((DURATION * 60))
  log "Apagando ..."
  screen -S mc -X stuff $'stop\n' || true
  sleep 15
  screen -S mc -X quit >/dev/null 2>&1 || true
  docker stop playit >/dev/null 2>&1 || true
  pkill -f 'bore-bin local' >/dev/null 2>&1 || true
else
  log "Servidor en primer plano logico. Ctrl+C para salir."
  while screen -ls 2>/dev/null | grep -q '\.mc'; do sleep 30; done
fi
