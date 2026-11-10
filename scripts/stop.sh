#!/usr/bin/env bash
set -Eeuo pipefail
if screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
  echo "Enviando stop a Paper para guardar el mundo..."
  screen -S mc -X stuff $'stop\n'
  for i in $(seq 1 90); do
    if ! screen -ls 2>/dev/null | grep -qE '[.]mc[[:space:]]'; then
      echo "Paper apagado correctamente."
      exit 0
    fi
    sleep 1
  done
  echo "Paper sigue cerrándose. Mirá server/logs/latest.log."
else
  echo "Paper ya estaba apagado."
fi
