#!/usr/bin/env bash
# Se ejecuta cada vez que el Codespace arranca (postStartCommand).
# Arranca el servidor en segundo plano para que puedas apagar el Codespace
# desde el celular y todo se detenga.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if screen -ls 2>/dev/null | grep -q '\.mc'; then
  echo ">> El servidor ya estaba corriendo."
  exit 0
fi

if [ ! -f server/server.jar ]; then
  echo ">> Servidor no instalado, instalando ..."
  bash scripts/install.sh
fi

mkdir -p .devcontainer
nohup bash scripts/run.sh > .devcontainer/server.log 2>&1 &
echo ">> Servidor lanzado en segundo plano. Log: .devcontainer/server.log"
echo ">> Espera ~1 minuto y busca la direccion de playit en ese log."
