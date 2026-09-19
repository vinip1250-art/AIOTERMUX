#!/data/data/com.termux/files/usr/bin/bash

set -e

# ============================================================
# AIOTERMUX - AIOStreams Nightly Installer
# ============================================================

DISTRO="ubuntu"

AIO_REPO="https://github.com/Viren070/AIOStreams.git"
AIO_DIR="/root/AIOStreams"

NODE_MAJOR="24"
PNPM_VERSION="11.0.8"

AIO_PORT="3000"

LOG_FILE="$HOME/aio_install.log"

# ============================================================
# CORES
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ============================================================
# FUNÇÕES
# ============================================================

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

run() {
    local description="$1"
    shift

    echo
    info "$description"

    if "$@" >> "$LOG_FILE" 2>&1; then
        success "$description"
    else
        error "$description"
        echo
        echo "Últimas linhas do log:"
        echo "------------------------------------------"
        tail -n 50 "$LOG_FILE"
        echo "------------------------------------------"
        exit 1
    fi
}

# ============================================================
# BANNER
# ============================================================

clear

echo -e "${CYAN}${BOLD}"
echo "=========================================="
echo "       AIOStreams Nightly Installer"
echo "=========================================="
echo -e "${RESET}"

echo
echo "AIOStreams:"
echo "  $AIO_REPO"
echo
echo "Ambiente:"
echo "  Ubuntu / proot-distro"
echo "  Node.js ${NODE_MAJOR}"
echo "  pnpm ${PNPM_VERSION}"
echo

# ============================================================
# VERIFICA TERMUX
# ============================================================

if [ ! -d "/data/data/com.termux" ]; then
    die "Este script precisa ser executado dentro do Termux."
fi

# ============================================================
# WAKE LOCK
# ============================================================

if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    trap 'termux-wake-unlock >/dev/null 2>&1' EXIT
fi

# ============================================================
# PREPARAR TERMUX
# ============================================================

echo -e "${BOLD}1. Preparando Termux${RESET}"

run "Atualizando pacotes do Termux" \
    pkg update -y

run "Atualizando pacotes instalados" \
    pkg upgrade -y

run "Instalando dependências do Termux" \
    pkg install -y \
        proot-distro \
        curl \
        git \
        wget \
        tar \
        gzip

# ============================================================
# UBUNTU
# ============================================================

echo
echo -e "${BOLD}2. Verificando Ubuntu${RESET}"

if proot-distro list 2>/dev/null | grep -q "^ubuntu"; then

    success "Ubuntu já está instalado."

else

    run "Instalando Ubuntu" \
        proot-distro install ubuntu

fi

# ============================================================
# VERIFICAR AIOSTREAMS EXISTENTE
# ============================================================

echo
echo -e "${BOLD}3. Verificando instalação existente${RESET}"

AIO_EXISTS=0

if proot-distro login "$DISTRO" -- bash -c \
    "test -d '$AIO_DIR'"; then

    AIO_EXISTS=1

fi

if [ "$AIO_EXISTS" = "1" ]; then

    echo
    echo -e "${YELLOW}${BOLD}"
    echo "=========================================="
    echo " AIOStreams já está instalado"
    echo "=========================================="
    echo -e "${RESET}"

    echo
    echo "Diretório encontrado:"
    echo "  $AIO_DIR"
    echo

    EXISTING_VERSION=$(
        proot-distro login "$DISTRO" -- bash -c "
            cd '$AIO_DIR' 2>/dev/null &&
            git describe --tags --always 2>/dev/null || echo desconhecida
        " 2>/dev/null
    )

    echo "Versão encontrada:"
    echo "  $EXISTING_VERSION"
    echo

    echo "Escolha uma opção:"
    echo
    echo "  [1] Atualizar a instalação existente para a Nightly"
    echo "  [2] Remover AIOStreams e instalar novamente"
    echo "  [3] Cancelar"
    echo

    read -r -p "Opção [1-3]: " OPTION

    case "$OPTION" in

        1)

            echo
            echo -e "${CYAN}Atualizando instalação existente...${RESET}"
            echo

            proot-distro login "$DISTRO" -- bash -c "
                set -e

                cd '$AIO_DIR'

                git fetch origin --tags --prune

                NIGHTLY_TAG=\$(git tag --list '*-nightly' --sort=-version:refname | head -n 1)

                if [ -z \"\$NIGHTLY_TAG\" ]; then
                    echo 'Nenhuma tag Nightly encontrada.'
                    exit 1
                fi

                echo
                echo \"Nightly selecionada: \$NIGHTLY_TAG\"

                git checkout --force \"\$NIGHTLY_TAG\"

                echo
                echo 'Instalando dependências...'

                pnpm install

                echo
                echo 'Compilando...'

                pnpm run build

                echo
                echo 'Gerando metadata...'

                pnpm run metadata --channel=nightly

                echo
                echo '=========================================='
                echo ' Atualização concluída'
                echo '=========================================='
                echo
                echo \"Tag:    \$(git describe --tags --always)\"
                echo \"Commit: \$(git rev-parse --short HEAD)\"
                echo
            " 2>&1 | tee "$LOG_FILE"

            echo
            success "AIOStreams atualizado para Nightly."

            echo
            echo "Para iniciar:"
            echo
            echo "  proot-distro login ubuntu"
            echo "  cd /root/AIOStreams"
            echo "  pnpm start"
            echo

            exit 0
            ;;

        2)

            echo
            echo -e "${RED}${BOLD}"
            echo "ATENÇÃO!"
            echo -e "${RESET}"
            echo "Somente o AIOStreams será removido."
            echo
            echo "O Ubuntu, Node.js e pnpm serão mantidos."
            echo

            read -r -p "Digite REMOVE para confirmar: " CONFIRM

            if [ "$CONFIRM" != "REMOVE" ]; then
                echo
                warning "Operação cancelada."
                exit 0
            fi

            echo
            info "Parando processos do AIOStreams..."

            proot-distro login "$DISTRO" -- bash -c '
                pkill -f "AIOStreams" 2>/dev/null || true
                pkill -f "node.*AIOStreams" 2>/dev/null || true
                pkill -f "pnpm.*AIOStreams" 2>/dev/null || true
            ' 2>/dev/null || true

            success "Processos encerrados."

            echo
            info "Removendo instalação antiga..."

            proot-distro login "$DISTRO" -- bash -c "
                rm -rf '$AIO_DIR'
            "

            success "AIOStreams antigo removido."

            ;;

        3)

            echo
            warning "Instalação cancelada."
            exit 0
            ;;

        *)

            echo
            error "Opção inválida."
            exit 1
            ;;

    esac

fi

# ============================================================
# PREPARAR UBUNTU
# ============================================================

echo
echo -e "${BOLD}4. Preparando Ubuntu${RESET}"

proot-distro login "$DISTRO" -- bash -c '
    export DEBIAN_FRONTEND=noninteractive

    apt-get update

    apt-get install -y \
        ca-certificates \
        curl \
        wget \
        git \
        build-essential \
        python3 \
        make \
        g++ \
        pkg-config
' >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    error "Falha ao preparar Ubuntu."
    tail -n 60 "$LOG_FILE"
    exit 1
fi

success "Ubuntu preparado."

# ============================================================
# NODE.JS
# ============================================================

echo
echo -e "${BOLD}5. Verificando Node.js ${NODE_MAJOR}${RESET}"

NODE_OK=$(
    proot-distro login "$DISTRO" -- bash -c '
        node --version 2>/dev/null || true
    ' 2>/dev/null
)

if echo "$NODE_OK" | grep -q "^v${NODE_MAJOR}\."; then

    success "Node.js $NODE_OK já está instalado."

else

    info "Instalando Node.js ${NODE_MAJOR}..."

    proot-distro login "$DISTRO" -- bash -c "
        export DEBIAN_FRONTEND=noninteractive

        apt-get update

        apt-get install -y ca-certificates curl gnupg

        curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -

        apt-get install -y nodejs

        node --version
        npm --version
    " >> "$LOG_FILE" 2>&1

    if [ $? -ne 0 ]; then
        error "Falha ao instalar Node.js."
        tail -n 80 "$LOG_FILE"
        exit 1
    fi

    success "Node.js instalado."

fi

# ============================================================
# PNPM
# ============================================================

echo
echo -e "${BOLD}6. Verificando pnpm${RESET}"

PNPM_OK=$(
    proot-distro login "$DISTRO" -- bash -c '
        pnpm --version 2>/dev/null || true
    ' 2>/dev/null
)

if [ "$PNPM_OK" = "$PNPM_VERSION" ]; then

    success "pnpm ${PNPM_VERSION} já está instalado."

else

    info "Instalando pnpm ${PNPM_VERSION}..."

    proot-distro login "$DISTRO" -- bash -c "
        npm install -g pnpm@${PNPM_VERSION}
        pnpm --version
    " >> "$LOG_FILE" 2>&1

    if [ $? -ne 0 ]; then
        error "Falha ao instalar pnpm."
        tail -n 60 "$LOG_FILE"
        exit 1
    fi

    success "pnpm instalado."

fi

# ============================================================
# CLONAR AIOSTREAMS
# ============================================================

echo
echo -e "${BOLD}7. Baixando AIOStreams Nightly${RESET}"

proot-distro login "$DISTRO" -- bash -c "
    set -e

    rm -rf '$AIO_DIR'

    git clone --filter=blob:none '${AIO_REPO}' '${AIO_DIR}'

    cd '${AIO_DIR}'

    git fetch --tags

    NIGHTLY_TAG=\$(git tag --list '*-nightly' --sort=-version:refname | head -n 1)

    if [ -z \"\$NIGHTLY_TAG\" ]; then
        echo 'ERRO: nenhuma tag Nightly encontrada.'
        exit 1
    fi

    echo
    echo \"Nightly selecionada: \$NIGHTLY_TAG\"

    git checkout --force \"\$NIGHTLY_TAG\"

    echo
    echo \"Commit: \$(git rev-parse --short HEAD)\"
    echo \"Tag:    \$(git describe --tags --always)\"
" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    error "Falha ao baixar AIOStreams."
    tail -n 100 "$LOG_FILE"
    exit 1
fi

success "AIOStreams Nightly baixado."

# ============================================================
# DEPENDÊNCIAS
# ============================================================

echo
echo -e "${BOLD}8. Instalando dependências${RESET}"

proot-distro login "$DISTRO" -- bash -c "
    set -e

    cd '${AIO_DIR}'

    pnpm install
" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    error "Falha no pnpm install."
    tail -n 100 "$LOG_FILE"
    exit 1
fi

success "Dependências instaladas."

# ============================================================
# BUILD
# ============================================================

echo
echo -e "${BOLD}9. Compilando AIOStreams${RESET}"

proot-distro login "$DISTRO" -- bash -c "
    set -e

    cd '${AIO_DIR}'

    pnpm run build
" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    error "Falha no build."
    tail -n 120 "$LOG_FILE"
    exit 1
fi

success "Build concluído."

# ============================================================
# METADATA
# ============================================================

echo
echo -e "${BOLD}10. Gerando metadata Nightly${RESET}"

proot-distro login "$DISTRO" -- bash -c "
    set -e

    cd '${AIO_DIR}'

    pnpm run metadata --channel=nightly
" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    error "Falha ao gerar metadata."
    tail -n 80 "$LOG_FILE"
    exit 1
fi

success "Metadata gerado."

# ============================================================
# VERIFICAÇÃO
# ============================================================

echo
echo -e "${BOLD}11. Verificando instalação${RESET}"

proot-distro login "$DISTRO" -- bash -c "
    cd '${AIO_DIR}'

    echo
    echo '=========================================='
    echo ' AIOStreams'
    echo '=========================================='
    echo
    echo \"Node:   \$(node --version)\"
    echo \"pnpm:   \$(pnpm --version)\"
    echo \"Tag:    \$(git describe --tags --always)\"
    echo \"Commit: \$(git rev-parse --short HEAD)\"
    echo
"

# ============================================================
# FINAL
# ============================================================

echo
echo -e "${GREEN}${BOLD}"
echo "=========================================="
echo "       INSTALAÇÃO CONCLUÍDA"
echo "=========================================="
echo -e "${RESET}"

echo
echo "Para entrar no Ubuntu:"
echo
echo "  proot-distro login ubuntu"
echo

echo "Para iniciar:"
echo
echo "  cd /root/AIOStreams"
echo "  pnpm start"
echo

echo "Para atualizar posteriormente:"
echo
echo "  ./update.sh"
echo

echo "Log:"
echo
echo "  cat ~/aio_install.log"
echo
