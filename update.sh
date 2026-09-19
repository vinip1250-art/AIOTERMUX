#!/data/data/com.termux/files/usr/bin/bash

set -e

# ============================================================
# AIOTERMUX - AIOStreams Nightly Updater
# ============================================================

DISTRO="ubuntu"
AIO_DIR="/root/AIOStreams"

AIO_REPO="https://github.com/Viren070/AIOStreams.git"

LOG_FILE="$HOME/aio_update.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info() {
    echo -e "${CYAN}[*]${RESET} $1"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

warning() {
    echo -e "${YELLOW}[!]${RESET} $1"
}

error() {
    echo -e "${RED}[ERRO]${RESET} $1"
}

die() {
    error "$1"
    echo
    echo "Log: $LOG_FILE"
    exit 1
}

# ------------------------------------------------------------
# Verificações
# ------------------------------------------------------------

if [ ! -d "/data/data/com.termux" ]; then
    die "Este script precisa ser executado dentro do Termux."
fi

if ! command -v proot-distro >/dev/null 2>&1; then
    die "proot-distro não está instalado."
fi

if ! proot-distro list 2>/dev/null | grep -q "^ubuntu"; then
    die "Ubuntu não está instalado."
fi

# ------------------------------------------------------------
# Wake lock
# ------------------------------------------------------------

if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    trap 'termux-wake-unlock >/dev/null 2>&1' EXIT
fi

# ------------------------------------------------------------
# Banner
# ------------------------------------------------------------

clear

echo -e "${CYAN}${BOLD}"
echo "=========================================="
echo "       AIOStreams Nightly Updater"
echo "=========================================="
echo -e "${RESET}"

echo
echo "Log:"
echo "  $LOG_FILE"
echo

# ------------------------------------------------------------
# Atualização
# ------------------------------------------------------------

info "Verificando AIOStreams..."

proot-distro login "$DISTRO" -- bash -c "
    set -e

    if [ ! -d '${AIO_DIR}/.git' ]; then
        echo 'AIOStreams não encontrado em ${AIO_DIR}.'
        exit 1
    fi

    cd '${AIO_DIR}'

    echo
    echo 'Versão atualmente instalada:'
    git describe --tags --always || true

    echo
    echo 'Atualizando referências Git...'

    git fetch origin --tags --prune

    echo
    echo 'Buscando última Nightly...'

    NIGHTLY_TAG=\$(git tag --list '*-nightly' --sort=-version:refname | head -n 1)

    if [ -z \"\$NIGHTLY_TAG\" ]; then
        echo 'Nenhuma tag Nightly encontrada.'
        exit 1
    fi

    CURRENT_TAG=\$(git describe --tags --exact-match 2>/dev/null || true)

    echo
    echo \"Nightly atual:   \${CURRENT_TAG:-desconhecida}\"
    echo \"Nightly mais nova: \$NIGHTLY_TAG\"
    echo

    if [ \"\$CURRENT_TAG\" = \"\$NIGHTLY_TAG\" ]; then
        echo 'A versão atual já é a Nightly mais recente.'
    else

        echo 'Atualizando para: \$NIGHTLY_TAG'

        git checkout --force \"\$NIGHTLY_TAG\"

        echo
        echo 'Instalando dependências...'

        pnpm install

        echo
        echo 'Compilando AIOStreams...'

        pnpm run build

        echo
        echo 'Gerando metadata Nightly...'

        pnpm run metadata --channel=nightly

        echo
        echo 'Atualização concluída.'
    fi

    echo
    echo '=========================================='
    echo ' Versão instalada'
    echo '=========================================='
    echo
    echo \"Tag:    \$(git describe --tags --always)\"
    echo \"Commit: \$(git rev-parse --short HEAD)\"
    echo
" > "$LOG_FILE" 2>&1

STATUS=$?

if [ $STATUS -ne 0 ]; then
    error "Falha durante a atualização."
    echo
    echo "Últimas linhas do log:"
    echo "------------------------------------------"
    tail -n 100 "$LOG_FILE"
    echo "------------------------------------------"
    exit 1
fi

success "AIOStreams atualizado."

echo
echo -e "${BOLD}Para iniciar:${RESET}"
echo
echo "  proot-distro login ubuntu"
echo "  cd /root/AIOStreams"
echo "  pnpm start"
echo

echo -e "${BOLD}Log:${RESET}"
echo
echo "  cat ~/aio_update.log"
echo
