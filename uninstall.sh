#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Remove somente os arquivos do AIOStreams. Não remove a distribuição Ubuntu.
DISTRO="ubuntu"
TARGET_DIR="/root/aiostreams-test"
WORK_DIR="/root/aiostreams-update"
CONFIG_DIR="/root/aiostreams"
DATA_DIR="/root/aiostreams-data"
LOG_FILE="$HOME/aio_uninstall.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[*]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET} $*"; }
warning() { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[ERRO]${RESET} $*"; }

[[ -d /data/data/com.termux ]] || { error "Execute este script dentro do Termux."; exit 1; }
command -v proot-distro >/dev/null 2>&1 || { error "proot-distro não encontrado."; exit 1; }
proot-distro list 2>/dev/null | grep -q '^ubuntu' || {
    warning "A distribuição Ubuntu não está instalada; não há nada a remover dentro dela."
    exit 0
}

echo -e "${YELLOW}${BOLD}Desinstalação do AIOStreams${RESET}"
echo
echo "Este script removerá somente:"
echo "  - $TARGET_DIR (imagem Nightly extraída)"
echo "  - $WORK_DIR (arquivos temporários da imagem)"
echo "  - $CONFIG_DIR (inclui .env e start.sh)"
echo
echo "A distribuição Ubuntu e os outros programas instalados nela serão preservados."
echo "Os dados persistentes em $DATA_DIR também serão preservados por padrão."
echo
read -r -p "Digite REMOVER para continuar: " confirmation
[[ "$confirmation" == "REMOVER" ]] || { info "Operação cancelada."; exit 0; }

echo
read -r -p "Deseja apagar também o banco de dados e o cache em $DATA_DIR? (s/N): " remove_data
remove_data="${remove_data,,}"
if [[ "$remove_data" == "s" || "$remove_data" == "sim" ]]; then
    echo -e "${RED}Atenção: isso apagará os dados persistentes do AIOStreams.${RESET}"
    read -r -p "Digite APAGAR-DADOS para confirmar: " data_confirmation
    if [[ "$data_confirmation" == "APAGAR-DADOS" ]]; then
        REMOVE_DATA="yes"
    else
        warning "Confirmação não recebida; os dados serão preservados."
        REMOVE_DATA="no"
    fi
else
    REMOVE_DATA="no"
fi

: > "$LOG_FILE"
info "Removendo os arquivos do AIOStreams..."
proot-distro login "$DISTRO" -- bash -lc "
    set -e
    rm -rf '$TARGET_DIR' '${TARGET_DIR}.new' '${TARGET_DIR}.previous' '$WORK_DIR' '$CONFIG_DIR'
    if [ '$REMOVE_DATA' = yes ]; then
        rm -rf '$DATA_DIR'
        echo 'Dados persistentes removidos.'
    else
        echo 'Dados persistentes preservados em $DATA_DIR.'
    fi
    echo 'Arquivos do AIOStreams removidos. A distribuição Ubuntu foi mantida.'
" >>"$LOG_FILE" 2>&1 || {
    error "A desinstalação falhou. Log:"
    tail -n 80 "$LOG_FILE"
    exit 1
}

success "AIOStreams removido."
echo "Ubuntu e os demais programas da distribuição foram preservados."
echo "Log: $LOG_FILE"
