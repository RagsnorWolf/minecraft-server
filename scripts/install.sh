#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRV="$ROOT/server"
VERSION="${PAPER_VERSION:-1.21.10}"
mkdir -p "$SRV/plugins" "$SRV/logs"

if [ "$VERSION" != "1.21.10" ]; then
  echo "ERROR: este proyecto está fijado en Paper 1.21.10."
  exit 1
fi

if [ ! -s "$SRV/paper.jar" ]; then
  echo "Resolviendo la build estable de Paper $VERSION..."
  BUILDS="$(curl -fsSL --retry 5 --retry-delay 2 "https://fill.papermc.io/v3/projects/paper/versions/$VERSION/builds")"
  PAPER_URL="$(printf '%s' "$BUILDS" | jq -r '([.[] | select(.channel == "STABLE")] + .)[0].downloads["server:default"].url // empty')"
  if [ -z "$PAPER_URL" ] || [ "$PAPER_URL" = "null" ]; then
    echo "ERROR: PaperMC no devolvió una build estable para $VERSION."
    exit 1
  fi
  curl -fL --retry 5 --retry-delay 2 "$PAPER_URL" -o "$SRV/paper.jar"
fi

if [ ! -s "$SRV/plugins/Geyser-Spigot.jar" ]; then
  echo "Descargando Geyser-Spigot..."
  curl -fL --retry 5 --retry-delay 2 \
    "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot" \
    -o "$SRV/plugins/Geyser-Spigot.jar"
fi

if [ ! -s "$SRV/plugins/floodgate-spigot.jar" ]; then
  echo "Descargando Floodgate-Spigot..."
  curl -fL --retry 5 --retry-delay 2 \
    "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot" \
    -o "$SRV/plugins/floodgate-spigot.jar"
fi

if [ ! -s "$SRV/plugins/ViaVersion.jar" ]; then
  echo "Descargando ViaVersion estable compatible con Java 21 y clientes 26.3..."
  VV_JSON="$(curl -fsSL --retry 5 --retry-delay 2 \
    -H "User-Agent: RagsnorWolf-MinecraftServer/1.0 (https://github.com/RagsnorWolf/minecraft-server)" \
    "https://api.modrinth.com/v2/project/viaversion/version?loaders=%5B%22paper%22%5D&game_versions=%5B%2226.3%22%5D&version_type=release")"
  VV_URL="$(printf '%s' "$VV_JSON" | jq -r '.[0].files[] | select(.primary == true) | .url' | head -n1)"
  if [ -z "$VV_URL" ] || [ "$VV_URL" = "null" ]; then
    VV_URL="$(printf '%s' "$VV_JSON" | jq -r '.[0].files[0].url // empty')"
  fi
  [ -n "$VV_URL" ] || { echo "ERROR: Modrinth no devolvió ViaVersion release para Paper/26.3."; exit 1; }
  curl -fL --retry 5 --retry-delay 2 "$VV_URL" -o "$SRV/plugins/ViaVersion.jar"
fi

printf 'eula=true\n' > "$SRV/eula.txt"
if [ ! -s "$SRV/server.properties" ]; then
  cp "$ROOT/config/server.properties" "$SRV/server.properties"
fi

# Forzar ajustes de seguridad y puertos sin pisar el resto del archivo.
set_prop() {
  local key="$1" value="$2"
  if grep -q "^$key=" "$SRV/server.properties"; then
    sed -i "s#^$key=.*#$key=$value#" "$SRV/server.properties"
  else
    printf '%s=%s\n' "$key" "$value" >> "$SRV/server.properties"
  fi
}
set_prop server-port 25565
set_prop online-mode true
set_prop enforce-secure-profile false
set_prop max-players 10
set_prop view-distance 8
set_prop simulation-distance 6
set_prop spawn-protection 0
set_prop level-name world

printf '%s\n' "$VERSION" > "$SRV/PAPER_VERSION.txt"
echo "Instalación lista:"
ls -lh "$SRV/paper.jar" "$SRV/plugins/"*.jar
