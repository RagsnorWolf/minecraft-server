#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
echo "=== RAGSNOR PAPER 1.21.10 ==="
if screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
  echo "Paper: ENCENDIDO"
else
  echo "Paper: APAGADO"
fi
if screen -ls 2>/dev/null | grep -qE '[.]playit[[:space:]]'; then
  echo "Playit: AGENTE EN EJECUCIÓN"
else
  echo "Playit: AGENTE NO EJECUTÁNDOSE"
fi
echo ""
echo "Dirección pública: verla en https://playit.gg/account/tunnels"
echo "Últimas líneas Paper:"
tail -n 25 server/logs/latest.log 2>/dev/null || true
