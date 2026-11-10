#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== SINCRONIZANDO EL CODESPACE CON main =="
git pull --ff-only origin main
echo ""
echo "== INSTALANDO PAPER 1.21.10, GEYSER, FLOODGATE Y PLAYIT =="
bash .devcontainer/setup.sh
echo ""
echo "== ENCENDIENDO PAPER =="
bash .devcontainer/start.sh
echo ""
bash scripts/status.sh
