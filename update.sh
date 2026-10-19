#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# AIOTERMUX - Atualiza AIOStreams para a imagem OCI Nightly mais recente.
DISTRO="ubuntu"
IMAGE="docker://ghcr.io/viren070/aiostreams:nightly"
WORK_DIR="/root/aiostreams-update"
TARGET_DIR="/root/aiostreams-test"
CONFIG_DIR="/root/aiostreams"
LOG_FILE="$HOME/aio_update.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[*]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET} $*"; }
warning() { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[ERRO]${RESET} $*"; }
die()     { error "$*"; echo "Log: $LOG_FILE"; exit 1; }

[[ -d /data/data/com.termux ]] || die "Execute este script dentro do Termux."
command -v proot-distro >/dev/null 2>&1 || die "proot-distro não encontrado. Instale-o com: pkg install proot-distro"
proot-distro list 2>/dev/null | grep -q '^ubuntu' || die "Ubuntu não está instalado. Execute primeiro ./install.sh."

: > "$LOG_FILE"
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    trap 'termux-wake-unlock >/dev/null 2>&1 || true' EXIT
fi

echo -e "${CYAN}${BOLD}AIOStreams Nightly — atualização por imagem OCI${RESET}"
echo "Imagem: ghcr.io/viren070/aiostreams:nightly"
echo "Log: $LOG_FILE"
echo

info "Verificando configuração e dependências..."
proot-distro login "$DISTRO" -- bash -lc "
    set -e
    test -f '$CONFIG_DIR/.env' || {
        echo 'Arquivo $CONFIG_DIR/.env não encontrado. Execute ./install.sh primeiro.'
        exit 10
    }
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y ca-certificates skopeo umoci coreutils
" >>"$LOG_FILE" 2>&1 || {
    error "Não foi possível preparar as dependências ou validar a instalação."
    tail -n 80 "$LOG_FILE"
    exit 1
}

info "Baixando a tag Nightly atual e extraindo a imagem..."
proot-distro login "$DISTRO" -- bash -lc "
    set -euo pipefail
    rm -rf '$WORK_DIR'
    mkdir -p '$WORK_DIR'
    skopeo copy --retry-times 3 '$IMAGE' oci:'$WORK_DIR/oci:nightly'
    umoci unpack --image '$WORK_DIR/oci:nightly' '$WORK_DIR/bundle'

    # Valida a nova imagem antes de substituir a instalada.
    test -x '$WORK_DIR/bundle/rootfs/nodejs/bin/node' || {
        echo 'ERRO: binário Node esperado não encontrado na imagem.'
        echo 'A versão instalada foi preservada.'
        exit 20
    }
    test -f '$WORK_DIR/bundle/rootfs/app/packages/server/dist/server.js' || {
        echo 'ERRO: arquivo do servidor esperado não encontrado na imagem.'
        echo 'A versão instalada foi preservada.'
        exit 21
    }

    rm -rf '${TARGET_DIR}.new'
    mv '$WORK_DIR/bundle' '${TARGET_DIR}.new'
    rm -rf '${TARGET_DIR}.previous'
    if [ -d '$TARGET_DIR' ]; then
        mv '$TARGET_DIR' '${TARGET_DIR}.previous'
    fi

    if mv '${TARGET_DIR}.new' '$TARGET_DIR'; then
        chmod +x '$TARGET_DIR/rootfs/nodejs/bin/node'
        rm -rf '${TARGET_DIR}.previous' '$WORK_DIR'
        echo 'Atualização concluída: ghcr.io/viren070/aiostreams:nightly'
    else
        echo 'Falha ao ativar a nova imagem; tentando restaurar a versão anterior.'
        if [ -d '${TARGET_DIR}.previous' ]; then
            rm -rf '$TARGET_DIR'
            mv '${TARGET_DIR}.previous' '$TARGET_DIR'
        fi
        exit 22
    fi
" >>"$LOG_FILE" 2>&1 || {
    error "Falha na atualização. Consulte o log abaixo."
    tail -n 100 "$LOG_FILE"
    exit 1
}

success "AIOStreams foi atualizado para a imagem Nightly baixada."
echo
echo "O arquivo .env e os dados persistentes foram preservados."
echo "Para iniciar:"
echo "  proot-distro login ubuntu -- /root/aiostreams/start.sh"
echo
echo "Se o servidor já estava em execução, encerre-o e inicie-o novamente para usar a versão atualizada."
echo "Log completo: $LOG_FILE"
