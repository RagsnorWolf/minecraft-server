#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== RAGSNOR PAPER 1.21.10: PREPARANDO CODESPACE =="
sudo apt-get update -qq
sudo apt-get install -y -qq screen curl jq unzip ca-certificates >/dev/null

if ! java -version 2>&1 | grep -q '21\.'; then
  echo "ERROR: este entorno necesita Java 21."
  java -version
  exit 1
fi

# Playit es el túnel público para Java y Bedrock. Si el instalador externo
# falla, Paper igual queda instalado y se puede reintentar Playit después.
if ! command -v playit >/dev/null 2>&1; then
  echo "Instalando el agente oficial de Playit..."
  if curl -fsSL https://packages.playit.gg/install.sh | sudo bash -s -- -y; then
    echo "Agente Playit instalado."
  else
    echo "AVISO: Playit no se pudo instalar automáticamente. Paper seguirá funcionando."
  fi
fi

echo "Descargando Paper 1.21.10, Geyser y Floodgate..."
bash scripts/install.sh

echo ""
echo "Preparación terminada. El servidor se inicia al abrir/reanudar el Codespace."
