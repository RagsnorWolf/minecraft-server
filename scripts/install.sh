#!/usr/bin/env bash
# Instala Paper + GeyserMC + Floodgate en ./server
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRV="$ROOT/server"
VERSION="${PAPER_VERSION:-1.21.11}"

mkdir -p "$SRV/plugins"

# ---------------------------------------------------------------- Paper ----
if [ ! -s "$SRV/server.jar" ]; then
  echo ">> Resolviendo ultimo build STABLE de Paper $VERSION ..."
  BUILDS="$(curl -fsSL --retry 5 --retry-delay 3 \
    "https://fill.papermc.io/v3/projects/paper/versions/${VERSION}/builds")"

  if command -v jq >/dev/null 2>&1; then
    URL="$(printf '%s' "$BUILDS" | jq -r '
      (map(select(.channel=="STABLE")) + .)
      | .[0].downloads["server:default"].url // empty')"
  else
    URL="$(printf '%s' "$BUILDS" | python3 -c '
import json,sys
d=json.load(sys.stdin)
st=[b for b in d if b.get("channel")=="STABLE"] or d
print(st[0]["downloads"]["server:default"]["url"])')"
  fi

  [ -n "$URL" ] || { echo "::error::No se encontro build de Paper $VERSION"; exit 1; }
  echo ">> Descargando $URL"
  curl -fsSL --retry 5 --retry-delay 3 "$URL" -o "$SRV/server.jar"
else
  echo ">> Paper ya presente, se reutiliza"
fi

# --------------------------------------------------- Geyser + Floodgate ----
if [ ! -s "$SRV/plugins/Geyser-Spigot.jar" ]; then
  echo ">> Descargando GeyserMC ..."
  curl -fsSL --retry 5 --retry-delay 3 \
    "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot" \
    -o "$SRV/plugins/Geyser-Spigot.jar"
fi

if [ ! -s "$SRV/plugins/floodgate-spigot.jar" ]; then
  echo ">> Descargando Floodgate ..."
  curl -fsSL --retry 5 --retry-delay 3 \
    "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot" \
    -o "$SRV/plugins/floodgate-spigot.jar"
fi

# ---------------------------------------------------------------- EULA -----
echo "eula=true" > "$SRV/eula.txt"

# ------------------------------------------------------ server.properties --
if [ ! -s "$SRV/server.properties" ]; then
  cp "$ROOT/config/server.properties" "$SRV/server.properties"
  echo ">> server.properties creado desde config/"
fi

# Fuerza los valores pedidos en cada arranque (idempotente).
PROPS="$SRV/server.properties"
set_prop() {
  local k="$1" v="$2"
  if grep -q "^${k}=" "$PROPS" 2>/dev/null; then
    sed -i "s#^${k}=.*#${k}=${v}#" "$PROPS"
  else
    printf '%s=%s\n' "$k" "$v" >> "$PROPS"
  fi
}
set_prop online-mode false
set_prop max-players 4
set_prop view-distance 32
set_prop simulation-distance 32
set_prop spawn-protection 0
set_prop motd "Ragsnor | Java + Bedrock"
set_prop enable-status true
set_prop max-tick-time -1
echo ">> server.properties ajustado: online-mode=false, 4 jugadores, view 32, sim 32"

# Geyser se configura por variables de entorno (GEYSER_*) definidas en el
# workflow, asi no depende del formato interno de config.yml de cada version.
#   GEYSER_JAVA_AUTH_TYPE=floodgate  -> permite entrar a jugadores de Bedrock
#   GEYSER_BEDROCK_PORT=19132        -> puerto del tunel UDP

echo ">> Instalacion lista:"
ls -lh "$SRV/server.jar" "$SRV/plugins/"*.jar
