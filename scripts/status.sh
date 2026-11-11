#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SOCKET="$ROOT/.playit/playitd.sock"
echo "=== RAGSNOR PAPER 1.21.10 ==="
if screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
  echo "Paper: ENCENDIDO"
else
  echo "Paper: APAGADO"
fi
if [ -S "$SOCKET" ] && screen -ls 2>/dev/null | grep -qE '[.]playitd[[:space:]]'; then
  echo "Playit daemon: ENCENDIDO"
  if command -v playit >/dev/null 2>&1; then
    playit --socket-path "$SOCKET" status 2>&1 || true
  fi
else
  echo "Playit daemon: APAGADO o SIN SOCKET"
fi
echo ""
echo "Direcciones públicas: https://playit.gg/account/tunnels"
echo "Últimas líneas Paper:"
tail -n 20 server/logs/latest.log 2>/dev/null || true
echo ""
echo "Últimas líneas Playit:"
tail -n 20 server/logs/playit.log 2>/dev/null || true
