#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p "$ROOT/.devcontainer"
exec >> "$ROOT/.devcontainer/startup.log" 2>&1
echo ""
echo "===== RAGSNOR PAPER 1.21.10 | $(date -Is) ====="

if [ ! -s server/paper.jar ]; then
  bash .devcontainer/setup.sh
fi

# Primer arranque: Paper genera config.yml. Después se ajusta Floodgate
# automáticamente y se reinicia Paper para aplicar la autenticación.
bash scripts/start.sh
set +e
python3 scripts/configure-geyser.py
config_status=$?
set -e
if [ "$config_status" -eq 3 ]; then
  echo "Aplicando auth-type=floodgate. Reinicio seguro de Paper..."
  bash scripts/stop.sh
  bash scripts/start.sh
elif [ "$config_status" -ne 0 ]; then
  echo "AVISO: no se pudo ajustar Geyser automáticamente (código $config_status)."
fi

echo "Arranque automático finalizado."
