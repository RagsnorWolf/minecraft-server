#!/usr/bin/env bash
set -Eeuo pipefail
if ! screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
  echo "Paper está apagado. Ejecutá bash scripts/start.sh."
  exit 1
fi
screen -r mc
