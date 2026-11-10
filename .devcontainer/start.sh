#!/usr/bin/env bash
# Se ejecuta cada vez que arranca el Codespace.
# Instala (si hace falta) y levanta el servidor + tunel en segundo plano.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

LOG="/workspaces/minecraft-server/.devcontainer/server.log"

if screen -ls 2>/dev/null | grep -q '\.mc'; then
  echo ">> El servidor ya estaba corriendo."
  cat server/ADDRESS.txt 2>/dev/null
  exit 0
fi

if [ ! -f server/server.jar ]; then
  echo ">> Instalando servidor ..."
  bash scripts/install.sh >> "$LOG" 2>&1 || exit 1
fi

echo ">> Arrancando servidor + tunel ..."
nohup bash scripts/run.sh >> "$LOG" 2>&1 &

echo ""
echo "======================================================================"
echo " Servidor lanzado. Segui el log con:"
echo "   tail -f .devcontainer/server.log"
echo " La direccion publica aparece ahi y tambien en server/ADDRESS.txt"
echo "======================================================================"
echo ""
