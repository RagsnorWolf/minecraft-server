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
WORLDS=()
for world in world world_nether world_the_end; do
  [ -d "server/$world" ] && WORLDS+=("$world")
done
if [ "${#WORLDS[@]}" -eq 0 ]; then
  echo "No hay carpetas de mundo en server/ para respaldar."
  exit 1
fi
tar -czf "backups/world-$STAMP.tar.gz" -C server "${WORLDS[@]}"
echo "Backup guardado en backups/world-$STAMP.tar.gz"
