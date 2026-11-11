#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v playit >/dev/null 2>&1; then
  echo "Playit CLI todavía no está instalado."
  echo "Ejecutá bash .devcontainer/setup.sh y volvé a intentar."
  exit 1
fi

# Iniciar playitd en su propio socket, dentro del workspace persistente.
bash scripts/start-playitd.sh
SOCKET="$ROOT/.playit/playitd.sock"

echo ""
echo "Abriendo la vinculación oficial de Playit..."
echo "Se mostrará un enlace. Abrilo desde el navegador, iniciá sesión y autorizá el agente."
echo "No compartas el token o la clave privada."
playit --socket-path "$SOCKET" setup

echo ""
echo "Vinculación finalizada. Comprobando el agente..."
playit --socket-path "$SOCKET" status
echo ""
echo "El agente permanece ejecutándose en segundo plano."
echo "Iniciando/verificando Paper..."
bash scripts/start.sh
