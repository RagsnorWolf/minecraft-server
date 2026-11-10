#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRV="$ROOT/server"
cd "$ROOT"

if [ ! -s "$SRV/paper.jar" ]; then
  bash scripts/install.sh
fi
mkdir -p "$SRV/logs"

if ! screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
  echo "Iniciando agente Playit (si está instalado)..."
  if command -v playit >/dev/null 2>&1 && ! screen -ls 2>/dev/null | grep -qE '[.]playit[[:space:]]'; then
    screen -L -Logfile "$SRV/logs/playit.log" -dmS playit bash -lc 'exec playit'
    sleep 2
  fi

  echo "Arrancando Paper 1.21.10 con hasta 12 GB de RAM..."
  screen -L -Logfile "$SRV/logs/console.log" -dmS mc bash -lc \
    "cd '$SRV' && exec java -Xms6G -Xmx12G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -jar paper.jar --nogui"
else
  echo "Paper ya estaba ejecutándose."
fi

echo "Esperando a que Paper termine de iniciar..."
for i in $(seq 1 150); do
  if grep -qE 'Done \([0-9.]+s\)!' "$SRV/logs/latest.log" 2>/dev/null; then
    echo ""
    echo "SERVIDOR ENCENDIDO: Paper 1.21.10"
    echo "Java: puerto local TCP 25565"
    echo "Bedrock: Geyser local UDP 19132 (falta configurar el túnel NetherNet de Playit)"
    echo "Carpeta del mundo: $SRV/world"
    echo "Ver estado: bash scripts/status.sh"
    exit 0
  fi
  if ! screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
    echo "ERROR: Paper se cerró durante el arranque. Últimas líneas:"
    tail -n 100 "$SRV/logs/latest.log" 2>/dev/null || true
    exit 1
  fi
  sleep 2
done

echo "Paper sigue arrancando o tardó más de lo esperado. Revisá:"
echo "tail -f server/logs/latest.log"
