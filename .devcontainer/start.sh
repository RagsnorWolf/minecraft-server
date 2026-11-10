#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p "$ROOT/.devcontainer"
echo "== Reanudando Ragsnor Paper 1.21.10 =="
if [ ! -s server/paper.jar ]; then
  bash scripts/install.sh
fi
bash scripts/start.sh
