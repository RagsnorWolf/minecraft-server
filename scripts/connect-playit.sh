#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v playit >/dev/null 2>&1; then
  echo "Playit todavía no está instalado. Ejecutá primero:"
  echo "bash .devcontainer/setup.sh"
  exit 1
fi

# Cerrar el agente no vinculado que pudo haberse iniciado automáticamente.
screen -S playit -X quit >/dev/null 2>&1 || true

echo "Se abrirá el proceso de vinculación oficial de Playit."
echo "Seguí el enlace o código que aparezca en esta terminal."
playit setup

echo ""
echo "Vinculación finalizada. Reiniciando el servidor y el agente..."
bash scripts/start.sh
