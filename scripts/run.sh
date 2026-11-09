#!/usr/bin/env bash
# Arranca playit.gg (tunel) + Paper, espera, publica la direccion y apaga solo.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRV="$ROOT/server"
DURATION="${DURATION:-330}"
HEAP="${HEAP:-6G}"

cd "$SRV"

if [ -z "${PLAYIT_SECRET:-}" ]; then
  cat <<'EOF'
::error::Falta el secret PLAYIT_SECRET.
Crea una cuenta gratis en https://playit.gg, agrega un tunel
"Custom / Minecraft Java" -> local 25565 TCP y otro UDP 19132,
copia tu secret key y guardalo en:
  Settings -> Secrets and variables -> Actions -> New repository secret
  Nombre: PLAYIT_SECRET
EOF
  exit 1
fi

# ------------------------------------------------------------- Tunel -------
echo ">> Levantando agente playit.gg ..."
docker rm -f playit >/dev/null 2>&1 || true
docker run -d --name playit --network host \
  -e SECRET_KEY="$PLAYIT_SECRET" \
  ghcr.io/playit-cloud/playit-agent:latest >/dev/null

for i in $(seq 1 30); do
  if docker logs playit 2>&1 | grep -qiE 'tunnel|address|assigned'; then break; fi
  sleep 2
done
docker logs playit 2>&1 | tail -n 60 || true

# ----------------------------------------------------------- Servidor ------
JAVA_FLAGS=(
  "-Xms${HEAP}" "-Xmx${HEAP}"
  -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200
  -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch
  -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M
  -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4
  -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90
  -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32
  -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1
  -jar server.jar nogui
)

echo ">> Arrancando Paper con ${HEAP} de RAM ..."
screen -dmS mc java "${JAVA_FLAGS[@]}"

echo ">> Esperando 'Done' en la consola ..."
READY=0
for i in $(seq 1 150); do
  if grep -qE 'Done \([0-9.]+s\)!' logs/latest.log 2>/dev/null; then READY=1; break; fi
  if ! screen -ls 2>/dev/null | grep -q '\.mc'; then break; fi
  sleep 2
done

if [ "$READY" != "1" ]; then
  echo "::error::El servidor no llego a 'Done'. Ultimas lineas:"
  tail -n 80 logs/latest.log 2>/dev/null || true
  docker logs playit 2>&1 | tail -n 40 || true
  docker stop playit >/dev/null 2>&1 || true
  exit 1
fi

# ------------------------------------------------------- Direccion ---------
ADDR="$(docker logs playit 2>&1 \
  | grep -Eo '([a-zA-Z0-9-]+\.)+(playit\.gg|ply\.gg)(:[0-9]{1,5})?' \
  | head -n 1 || true)"

{
  echo "## Servidor Minecraft ONLINE"
  echo ""
  echo "| Dato | Valor |"
  echo "|------|-------|"
  echo "| Direccion | \`${ADDR:-ver logs de playit}\` |"
  echo "| Paper | \`${PAPER_VERSION}\` |"
  echo "| RAM Java | \`${HEAP}\` |"
  echo "| Duracion | ${DURATION} min |"
  echo "| Java (PC) | puerto 25565 |"
  echo "| Bedrock (celular/consola) | puerto 19132 |"
  echo ""
  echo "> El servidor se apaga solo al terminar el tiempo o cuando el job llegue a 6 h."
} >> "$GITHUB_STEP_SUMMARY"

echo ">> Direccion publica: ${ADDR:-no detectada}"

# ------------------------------------------------------ Espera activa ------
START=$(date +%s)
while :; do
  NOW=$(date +%s)
  ELAPSED=$(( (NOW - START) / 60 ))
  if [ "$ELAPSED" -ge "$DURATION" ]; then
    echo ">> Tiempo cumplido (${DURATION} min). Apagando ..."
    break
  fi
  if ! screen -ls 2>/dev/null | grep -q '\.mc'; then
    echo ">> El proceso del servidor ya no existe. Saliendo."
    break
  fi
  if [ $(( ELAPSED % 30 )) -eq 0 ] && [ "$ELAPSED" -gt 0 ]; then
    echo ">> ${ELAPSED}/${DURATION} min online"
  fi
  sleep 60
done

# ------------------------------------------------------------- Apagado -----
if screen -ls 2>/dev/null | grep -q '\.mc'; then
  echo ">> Enviando 'stop' a la consola ..."
  screen -S mc -X stuff $'stop\n' || true
  for i in $(seq 1 40); do
    screen -ls 2>/dev/null | grep -q '\.mc' || break
    sleep 2
  done
  screen -S mc -X quit >/dev/null 2>&1 || true
fi

docker stop playit >/dev/null 2>&1 || true
echo ">> Servidor detenido. Mundo guardado en cache para el proximo arranque."
