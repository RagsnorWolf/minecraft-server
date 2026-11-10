#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
  echo "Por seguridad, apagá Paper antes de hacer el backup:"
  echo "bash scripts/stop.sh"
  exit 1
fi
mkdir -p backups
STAMP="$(date +%Y%m%d-%H%M%S)"
tar -czf "backups/world-$STAMP.tar.gz" -C server world world_nether world_the_end 2>/dev/null || {
  echo "No se pudo completar el backup. Revisá si existe server/world."
  rm -f "backups/world-$STAMP.tar.gz"
  exit 1
}
echo "Backup guardado en backups/world-$STAMP.tar.gz"
