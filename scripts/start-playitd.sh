#!/usr/bin/env bash
# Run the official Playit daemon directly, without systemd.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAYIT_HOME="$ROOT/.playit"
SOCKET="$PLAYIT_HOME/playitd.sock"
SECRET="$PLAYIT_HOME/playit.toml"
LOG="$ROOT/server/logs/playit.log"

mkdir -p "$PLAYIT_HOME" "$ROOT/server/logs"
chmod 700 "$PLAYIT_HOME"

if ! command -v screen >/dev/null 2>&1; then
  echo "ERROR: falta screen. Ejecutá bash .devcontainer/setup.sh."
  exit 1
fi

PLAYITD="$(command -v playitd || true)"
if [ -z "$PLAYITD" ] && [ -x /opt/playit/playitd ]; then
  PLAYITD="/opt/playit/playitd"
fi
if [ -z "$PLAYITD" ] || [ ! -x "$PLAYITD" ]; then
  echo "ERROR: no encuentro playitd. Instalá el agente con bash .devcontainer/setup.sh."
  exit 1
fi

# Evitar la antigua CLI que intentaba usar el servicio inexistente de systemd.
screen -S playit -X quit >/dev/null 2>&1 || true

if [ -S "$SOCKET" ] && screen -ls 2>/dev/null | grep -qE '[.]playitd[[:space:]]'; then
  echo "El daemon Playit ya está ejecutándose."
else
  rm -f "$SOCKET"
  echo "Iniciando playitd directamente, sin systemd..."
  screen -dmS playitd bash -lc \
    'exec "$1" --secret-path "$2" --socket-path "$3" -l "$4"' \
    _ "$PLAYITD" "$SECRET" "$SOCKET" "$LOG"
fi

for i in $(seq 1 15); do
  if [ -S "$SOCKET" ]; then
    chmod 600 "$SECRET" 2>/dev/null || true
    echo "Playit daemon listo. Socket privado: $SOCKET"
    echo "Log: $LOG"
    exit 0
  fi
  sleep 1
done

echo "ERROR: playitd no creó su socket."
echo "Últimas líneas del log:"
tail -n 60 "$LOG" 2>/dev/null || true
echo "Consola de screen:"
screen -S playitd -X hardcopy "$PLAYIT_HOME/playitd-screen.txt" >/dev/null 2>&1 || true
tail -n 40 "$PLAYIT_HOME/playitd-screen.txt" 2>/dev/null || true
exit 1
