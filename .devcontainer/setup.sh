#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo ">> Instalando utilidades ..."
sudo apt-get update -qq
sudo apt-get install -y -qq screen jq curl python3-yaml >/dev/null
echo ">> Instalando Paper + Geyser + Floodgate + ViaVersion ..."
PAPER_VERSION="${PAPER_VERSION:-1.21.10}" bash scripts/install.sh
echo "Codespace listo. El servidor arranca con .devcontainer/start.sh"
echo "Para ver el log: tail -f .devcontainer/server.log"
