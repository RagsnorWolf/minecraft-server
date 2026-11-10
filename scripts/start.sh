#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRV="$ROOT/server"
cd "$ROOT"

if [ ! -s "$SRV/paper.jar" ]; then
  bash scripts/install.sh
fi
mkdir -p "$SRV/logs"

# Detectar el límite real del contenedor (cgroup), no la RAM física del host.
MEM_BYTES=""
for memfile in /sys/fs/cgroup/memory.max /sys/fs/cgroup/memory/memory.limit_in_bytes; do
  if [ -r "$memfile" ]; then
    value="$(cat "$memfile")"
    if [[ "$value" =~ ^[0-9]+$ ]] && (( value > 0 && value < 1152921504606846976 )); then
      MEM_BYTES="$value"
      break
    fi
  fi
done
if [ -z "$MEM_BYTES" ]; then
  MEM_BYTES="$(awk '/MemTotal/ {printf "%.0f", $2*1024}' /proc/meminfo)"
fi
TOTAL_GB=$(( MEM_BYTES / 1073741824 ))
[ "$TOTAL_GB" -ge 3 ] || TOTAL_GB=3
DEFAULT_HEAP_GB=$(( TOTAL_GB * 3 / 4 ))
[ "$DEFAULT_HEAP_GB" -ge 2 ] || DEFAULT_HEAP_GB=2
DEFAULT_XMS_GB=$(( DEFAULT_HEAP_GB / 3 ))
[ "$DEFAULT_XMS_GB" -ge 1 ] || DEFAULT_XMS_GB=1
HEAP="${HEAP:-${DEFAULT_HEAP_GB}G}"
XMS="${XMS:-${DEFAULT_XMS_GB}G}"
SKIP_PLAYIT="${SKIP_PLAYIT:-false}"

if ! [[ "$HEAP" =~ ^[1-9][0-9]*G$ && "$XMS" =~ ^[1-9][0-9]*G$ ]]; then
  echo "ERROR: HEAP y XMS deben tener formato como 6G y 2G."
  exit 1
fi
HEAP_N="${HEAP%G}"
XMS_N="${XMS%G}"
if (( XMS_N > HEAP_N )); then
  echo "ERROR: XMS no puede ser mayor que HEAP."
  exit 1
fi

# Playit se ejecuta separado de Paper y permanece activo en segundo plano.
if [ "$SKIP_PLAYIT" != "true" ] && command -v playit >/dev/null 2>&1; then
  if ! screen -ls 2>/dev/null | grep -qE '[.]playit[[:space:]]'; then
    echo "Iniciando agente Playit. Si todavía no fue vinculado, ejecutá: playit setup"
    screen -L -Logfile "$SRV/logs/playit.log" -dmS playit bash -lc 'exec playit'
    sleep 2
  fi
else
  echo "Playit omitido o no instalado."
fi

if screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
  echo "Paper ya estaba ejecutándose."
  echo "Estado: bash scripts/status.sh"
  exit 0
fi

echo "Arrancando Paper 1.21.10 con Xms=$XMS y Xmx=$HEAP (RAM detectada: ${TOTAL_GB}G)..."
: > "$SRV/logs/latest.log"
screen -L -Logfile "$SRV/logs/console.log" -dmS mc bash -lc \
  "cd '$SRV' && exec java -Xms$XMS -Xmx$HEAP -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -jar paper.jar --nogui"

# screen puede tardar un instante en publicar la sesión; no confundir esa
# carrera de arranque con un cierre real de Paper.
session_ready=false
for j in $(seq 1 10); do
  if screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
    session_ready=true
    break
  fi
  sleep 1
done
if [ "$session_ready" != "true" ]; then
  echo "ERROR: no se pudo crear la sesión de Paper."
  tail -n 120 "$SRV/logs/console.log" 2>/dev/null || true
  exit 1
fi

echo "Esperando a que Paper termine de iniciar..."
for i in $(seq 1 180); do
  if grep -qE 'Done \([0-9.]+s\)!' "$SRV/logs/latest.log" 2>/dev/null; then
    echo ""
    echo "SERVIDOR ENCENDIDO: Paper 1.21.10"
    echo "RAM asignada a Java: Xmx=$HEAP; Xms=$XMS (aprox. 75% de la RAM del Codespace)"
    echo "Java: puerto local TCP 25565"
    echo "Bedrock: Geyser local 19132 (necesita túnel NetherNet para acceso externo)"
    echo "Mundo: $SRV/world"
    echo "Ver estado: bash scripts/status.sh"
    exit 0
  fi
  if ! screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
    echo "ERROR: Paper se cerró durante el arranque. Últimas líneas:"
    tail -n 120 "$SRV/logs/latest.log" 2>/dev/null || true
    exit 1
  fi
  sleep 2
done

echo "Paper sigue arrancando o tardó más de lo esperado. Revisá:"
echo "tail -f server/logs/latest.log"
exit 1
