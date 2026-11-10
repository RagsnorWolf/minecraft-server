#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRV="$ROOT/server"
VERSION="${PAPER_VERSION:-1.21.10}"
MODRINTH_UA="RagsnorWolf-minecraft-server/1.0 (https://github.com/RagsnorWolf/minecraft-server)"
mkdir -p "$SRV/plugins"

if [ ! -s "$SRV/server.jar" ]; then
  echo ">> Resolviendo build STABLE de Paper $VERSION ..."
  BUILDS="$(curl -fsSL --retry 5 --retry-delay 3 "https://fill.papermc.io/v3/projects/paper/versions/$VERSION/builds")"
  if command -v jq >/dev/null 2>&1; then
    URL="$(printf '%s' "$BUILDS" | jq -r '(map(select(.channel=="STABLE")) + .) | .[0].downloads["server:default"].url // empty')"
  else
    URL="$(printf '%s' "$BUILDS" | python3 -c 'import json,sys; d=json.load(sys.stdin); s=[b for b in d if b.get("channel")=="STABLE"]; a=s or d; print(a[0]["downloads"]["server:default"]["url"] if a else "")')"
  fi
  [ -n "$URL" ] || { echo "::error::No se encontro build estable de Paper $VERSION"; exit 1; }
  curl -fsSL --retry 5 --retry-delay 3 "$URL" -o "$SRV/server.jar"
else
  echo ">> Paper ya presente, se reutiliza"
fi

if [ ! -s "$SRV/plugins/Geyser-Spigot.jar" ]; then
  echo ">> Descargando GeyserMC ..."
  curl -fsSL --retry 5 --retry-delay 3 "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot" -o "$SRV/plugins/Geyser-Spigot.jar"
fi

if [ ! -s "$SRV/plugins/floodgate-spigot.jar" ]; then
  echo ">> Descargando Floodgate ..."
  curl -fsSL --retry 5 --retry-delay 3 "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot" -o "$SRV/plugins/floodgate-spigot.jar"
fi

# ViaVersion permite clientes Java actuales (26.3) en Paper 1.21.10.
if [ ! -s "$SRV/plugins/ViaVersion.jar" ]; then
  echo ">> Resolviendo ViaVersion estable para clientes 26.3 ..."
  VV_JSON="$(curl -fsSL --retry 4 -H "User-Agent: $MODRINTH_UA" "https://api.modrinth.com/v2/project/viaversion/version?loaders=%5B%22paper%22%5D&game_versions=%5B%2226.3%22%5D&version_type=release")"
  if command -v jq >/dev/null 2>&1; then
    VV_URL="$(printf '%s' "$VV_JSON" | jq -r '.[0].files[] | select(.primary == true) | .url' | head -n1)"
    if [ -z "$VV_URL" ] || [ "$VV_URL" = "null" ]; then
      VV_URL="$(printf '%s' "$VV_JSON" | jq -r '.[0].files[0].url // empty')"
    fi
  else
    VV_URL="$(printf '%s' "$VV_JSON" | python3 -c 'import json,sys; v=json.load(sys.stdin); f=v[0].get("files",[]) if v else []; p=next((x for x in f if x.get("primary")),None); x=p or (f[0] if f else None); print(x.get("url","") if x else "")')"
  fi
  [ -n "$VV_URL" ] || { echo "::error::No se encontro release estable de ViaVersion para Paper/26.3"; exit 1; }
  curl -fsSL --retry 4 -H "User-Agent: $MODRINTH_UA" "$VV_URL" -o "$SRV/plugins/ViaVersion.jar"
fi

echo "eula=true" > "$SRV/eula.txt"
if [ ! -s "$SRV/server.properties" ]; then
  cp "$ROOT/config/server.properties" "$SRV/server.properties"
fi

set_prop() {
  local key="$1" value="$2"
  if grep -q "^${key}=" "$SRV/server.properties"; then
    sed -i "s#^${key}=.*#${key}=${value}#" "$SRV/server.properties"
  else
    printf '%s=%s\n' "$key" "$value" >> "$SRV/server.properties"
  fi
}

set_prop online-mode true
set_prop enforce-secure-profile false
set_prop max-players 4
set_prop view-distance 10
set_prop simulation-distance 8
set_prop spawn-protection 0
set_prop motd "Ragsnor | Java + Bedrock"
set_prop enable-status true
set_prop max-tick-time -1

echo ">> Instalacion lista:"
ls -lh "$SRV/server.jar" "$SRV/plugins/"*.jar
