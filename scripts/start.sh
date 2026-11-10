#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRV="$ROOT/server"
cd "$ROOT"

if [ ! -s "$SRV/paper.jar" ]; then
  bash scripts/install.sh
fi
mkdir -p "$SRV/logs"

# Asignar aproximadamente el 75% de la RAM disponible al heap de Java,
# dejando memoria para Linux, Geyser, Playit y otros procesos.
TOTAL_GB="$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)"
DEFAULT_HEAP_GB=$(( TOTAL_GB * 3 / 4 ))
[ "$DEFAULT_HEAP_GB" -ge 2 ] || DEFAULT_HEAP_GB=2
DEFAULT_XMS_GB=$(( DEFAULT_HEAP_GB / 2 ))
[ "$DEFAULT_XMS_GB" -ge 1 ] || DEFAULT_XMS_GB=1
HEAP="${HEAP:-${DEFAULT_HEAP_GB}G}"
XMS="${XMS:-${DEFAULT_XMS_GB}G}"
SKIP_PLAYIT="${SKIP_PLAYIT:-false}"

if ! [[ "$HEAP" =~ ^[1-9][0-9]*G$ && "$XMS" =~ ^[1-9][0-9]*G$ ]]; then
  echo "ERROR: HEAP y XMS deben tener formato como 12G y 6G."
  exit 1
fi
HEAP_N="${HEAP%G}"
XMS_N="${XMS%G}"
if (( XMS_N > HEAP_N )); then
  echo "ERROR: XMS no puede ser mayor que HEAP."
  exit 1
fi

if ! screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
  echo "Iniciando agente Playit (si está instalado)..."
  if [ "$SKIP_PLAYIT" != "true" ] && command -v playit >/dev/null 2>&1 \
     && ! screen -ls 2>/dev/null | grep -qE '[.]playit[[:space:]]'; then
    screen -L -Logfile "$SRV/logs/playit.log" -dmS playit bash -lc 'exec playit'
    sleep 2
  fi

  echo "Arrancando Paper 1.21.10 con Xms=$XMS y Xmx=$HEAP..."
  # Limpiar el log previo para no confundir el "Done" de una sesión anterior.
  : > "$SRV/logs/latest.log"
  screen -L -Logfile "$SRV/logs/console.log" -dmS mc bash -lc \
    "cd '$SRV' && exec java -Xms$XMS -Xmx$HEAP -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -jar paper.jar --nogui"
else
  echo "Paper ya estaba ejecutándose."
fi

echo "Esperando a que Paper termine de iniciar..."
for i in $(seq 1 150); do
  if grep -qE 'Done \([0-9.]+s\)!' "$SRV/logs/latest.log" 2>/dev/null; then
    echo ""
    echo "SERVIDOR ENCENDIDO: Paper 1.21.10"
    echo "RAM asignada a Java: $HEAP (aprox. 75% de la RAM detectada)"
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
