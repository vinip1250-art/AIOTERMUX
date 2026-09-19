#!/data/data/com.termux/files/usr/bin/bash

set -e

# ============================================================
# AIOTERMUX - Uninstaller
# ============================================================
#
# Remove:
#   - Ubuntu proot-distro
#   - AIOStreams
#   - Node.js
#   - pnpm
#   - todos os arquivos dentro do Ubuntu
#
# NÃO remove:
#   - Termux
#   - pacotes do Termux
#   - armazenamento do Android
#
# ============================================================

DISTRO="ubuntu"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

clear

echo -e "${RED}${BOLD}"
echo "=========================================="
echo "       AIOStreams Uninstaller"
echo "=========================================="
echo -e "${RESET}"

echo
echo -e "${YELLOW}ATENÇÃO!${RESET}"
echo
echo "Este procedimento removerá completamente:"
echo
echo "  - Ubuntu do proot-distro"
echo "  - AIOStreams"
echo "  - Node.js"
echo "  - pnpm"
echo "  - todos os dados armazenados dentro do Ubuntu"
echo
echo "O Termux em si NÃO será removido."
echo

read -r -p "Digite REMOVE para continuar: " CONFIRM

if [ "$CONFIRM" != "REMOVE" ]; then
    echo
    echo "Operação cancelada."
    exit 0
fi

echo
echo -e "${CYAN}Removendo Ubuntu...${RESET}"
echo

if ! command -v proot-distro >/dev/null 2>&1; then
    echo "proot-distro não está instalado."
    exit 0
fi

if ! proot-distro list 2>/dev/null | grep -q "^ubuntu"; then
    echo "Ubuntu não está instalado."
    exit 0
fi

# ------------------------------------------------------------
# Tentar encerrar processos
# ------------------------------------------------------------

echo "[1/3] Encerrando processos do Ubuntu..."

proot-distro login "$DISTRO" -- bash -c '
    pkill -f "AIOStreams" 2>/dev/null || true
    pkill -f "node" 2>/dev/null || true
    pkill -f "pnpm" 2>/dev/null || true
' 2>/dev/null || true

echo "OK"

# ------------------------------------------------------------
# Remover Ubuntu
# ------------------------------------------------------------

echo
echo "[2/3] Removendo Ubuntu..."

proot-distro remove "$DISTRO"

echo "OK"

# ------------------------------------------------------------
# Remover arquivos do instalador
# ------------------------------------------------------------

echo
echo "[3/3] Limpando arquivos do instalador..."

rm -f "$HOME/aio_install.log"
rm -f "$HOME/aio_update.log"
rm -f "$HOME/.aio_install_state"

echo "OK"

# ------------------------------------------------------------
# Final
# ------------------------------------------------------------

echo
echo -e "${GREEN}${BOLD}"
echo "=========================================="
echo "       DESINSTALAÇÃO CONCLUÍDA"
echo "=========================================="
echo -e "${RESET}"

echo
echo "O Ubuntu e o AIOStreams foram removidos."
echo
echo "O Termux continua instalado normalmente."
echo
echo "Para instalar novamente:"
echo
echo "  ./install.sh"
echo
