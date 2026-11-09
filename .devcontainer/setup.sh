#!/usr/bin/env bash
# Se ejecuta UNA vez al crear el Codespace.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo ">> Instalando utilidades ..."
sudo apt-get update -qq
sudo apt-get install -y -qq screen jq curl >/dev/null

echo ">> Instalando Paper + Geyser + Floodgate ..."
PAPER_VERSION="${PAPER_VERSION:-1.21.11}" bash scripts/install.sh

echo ""
echo "================================================"
echo " Codespace listo."
echo " El servidor arranca solo con: bash scripts/run.sh"
echo " o usando .devcontainer/start.sh (lo hace automatico)."
echo "================================================"
