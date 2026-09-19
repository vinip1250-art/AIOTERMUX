#!/data/data/com.termux/files/usr/bin/bash

set -e

# ============================================================
# AIOTERMUX - AIOStreams Nightly Installer
# ============================================================
#
# Instala:
#   Termux
#     └── proot-distro
#           └── Ubuntu
#                 └── Node.js 24
#                       └── pnpm 11
#                             └── AIOStreams Nightly
#
# O instalador:
#   1. Prepara o Termux
#   2. Instala Ubuntu via proot-distro
#   3. Instala dependências do Ubuntu
#   4. Instala Node.js 24
#   5. Instala pnpm
#   6. Clona AIOStreams
#   7. Detecta automaticamente a última tag *-nightly
#   8. Compila o AIOStreams
#   9. Gera metadata Nightly
#
# ============================================================

set +e

# ------------------------------------------------------------
# Configuração
# ------------------------------------------------------------

DISTRO="ubuntu"

AIO_REPO="https://github.com/Viren070/AIOStreams.git"
AIO_DIR="/root/AIOStreams"

NODE_MAJOR="24"
PNPM_VERSION="11.0.8"

LOG_FILE="$HOME/aio_install.log"

# Porta padrão do AIOStreams
AIO_PORT="3000"

# ------------------------------------------------------------
# Cores
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
CLEAR_LINE='\033[K'

# ------------------------------------------------------------
# Funções
# ------------------------------------------------------------

banner() {
    clear

    echo -e "${CYAN}${BOLD}"
    echo "=========================================="
    echo "       AIOStreams Nightly Installer"
    echo "=========================================="
    echo -e "${RESET}"
    echo
    echo "  Termux → Ubuntu → Node.js ${NODE_MAJOR}"
    echo "  AIOStreams → Nightly"
    echo
}

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
        tail -n 40 "$LOG_FILE"
        echo "------------------------------------------"
        exit 1
    fi
}

# ------------------------------------------------------------
# Início
# ------------------------------------------------------------

banner

echo "Log:"
echo "  $LOG_FILE"
echo

# ------------------------------------------------------------
# Wake lock
# ------------------------------------------------------------

if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    trap 'termux-wake-unlock >/dev/null 2>&1' EXIT
fi

# ------------------------------------------------------------
# Verificar Termux
# ------------------------------------------------------------

if [ ! -d "/data/data/com.termux" ]; then
    die "Este script precisa ser executado dentro do Termux."
fi

# ------------------------------------------------------------
# Preparar Termux
# ------------------------------------------------------------

echo
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

# ------------------------------------------------------------
# Ubuntu
# ------------------------------------------------------------

echo
echo -e "${BOLD}2. Preparando Ubuntu${RESET}"

if proot-distro list 2>/dev/null | grep -q "^ubuntu"; then
    info "Ubuntu já está disponível no proot-distro."
else
    run "Instalando Ubuntu" \
        proot-distro install ubuntu
fi

# ------------------------------------------------------------
# Atualização do Ubuntu
# ------------------------------------------------------------

echo
echo -e "${BOLD}3. Preparando ambiente Ubuntu${RESET}"

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
    tail -n 50 "$LOG_FILE"
    exit 1
fi

success "Ubuntu preparado."

# ------------------------------------------------------------
# Node.js 24
# ------------------------------------------------------------

echo
echo -e "${BOLD}4. Instalando Node.js ${NODE_MAJOR}${RESET}"

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
    error "Falha ao instalar Node.js ${NODE_MAJOR}."
    tail -n 60 "$LOG_FILE"
    exit 1
fi

success "Node.js ${NODE_MAJOR} instalado."

# ------------------------------------------------------------
# pnpm
# ------------------------------------------------------------

echo
echo -e "${BOLD}5. Instalando pnpm ${PNPM_VERSION}${RESET}"

proot-distro login "$DISTRO" -- bash -c "
    npm install -g pnpm@${PNPM_VERSION}

    pnpm --version
" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    error "Falha ao instalar pnpm."
    tail -n 50 "$LOG_FILE"
    exit 1
fi

success "pnpm ${PNPM_VERSION} instalado."

# ------------------------------------------------------------
# Git / AIOStreams
# ------------------------------------------------------------

echo
echo -e "${BOLD}6. Instalando AIOStreams${RESET}"

proot-distro login "$DISTRO" -- bash -c "
    set -e

    if [ -d '${AIO_DIR}/.git' ]; then
        echo 'AIOStreams já existe. Atualizando repositório...'

        cd '${AIO_DIR}'

        git fetch --all --tags --prune

    else
        echo 'Clonando AIOStreams...'

        rm -rf '${AIO_DIR}'

        git clone --filter=blob:none --no-checkout '${AIO_REPO}' '${AIO_DIR}'

        cd '${AIO_DIR}'

        git fetch --tags
    fi

    cd '${AIO_DIR}'

    echo
    echo 'Buscando última tag Nightly...'

    NIGHTLY_TAG=\$(git tag --list '*-nightly' --sort=-version:refname | head -n 1)

    if [ -z \"\$NIGHTLY_TAG\" ]; then
        echo 'ERRO: nenhuma tag Nightly encontrada.'
        exit 1
    fi

    echo
    echo \"Nightly selecionada: \$NIGHTLY_TAG\"

    git checkout --force \"\$NIGHTLY_TAG\"

    echo
    echo 'Commit:'
    git rev-parse --short HEAD

    echo
    echo 'Tag:'
    git describe --tags --always
" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    error "Falha ao baixar/selecionar AIOStreams Nightly."
    tail -n 80 "$LOG_FILE"
    exit 1
fi

success "AIOStreams Nightly selecionado."

# ------------------------------------------------------------
# Dependências
# ------------------------------------------------------------

echo
echo -e "${BOLD}7. Instalando dependências do AIOStreams${RESET}"

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

# ------------------------------------------------------------
# Build
# ------------------------------------------------------------

echo
echo -e "${BOLD}8. Compilando AIOStreams${RESET}"

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

# ------------------------------------------------------------
# Metadata Nightly
# ------------------------------------------------------------

echo
echo -e "${BOLD}9. Gerando metadata Nightly${RESET}"

proot-distro login "$DISTRO" -- bash -c "
    set -e

    cd '${AIO_DIR}'

    pnpm run metadata --channel=nightly
" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    error "Falha ao gerar metadata Nightly."
    tail -n 80 "$LOG_FILE"
    exit 1
fi

success "Metadata Nightly gerado."

# ------------------------------------------------------------
# Informações da instalação
# ------------------------------------------------------------

echo
echo -e "${BOLD}10. Verificando instalação${RESET}"

proot-distro login "$DISTRO" -- bash -c "
    cd '${AIO_DIR}'

    echo
    echo '=========================================='
    echo ' AIOStreams instalado'
    echo '=========================================='
    echo
    echo \"Node: \$(node --version)\"
    echo \"pnpm: \$(pnpm --version)\"
    echo \"Tag:  \$(git describe --tags --always)\"
    echo \"Commit: \$(git rev-parse --short HEAD)\"
    echo
    echo 'Diretório: ${AIO_DIR}'
    echo 'Porta: ${AIO_PORT}'
    echo
"

# ------------------------------------------------------------
# Final
# ------------------------------------------------------------

echo
echo -e "${GREEN}${BOLD}"
echo "=========================================="
echo "       INSTALAÇÃO CONCLUÍDA"
echo "=========================================="
echo -e "${RESET}"

echo
echo -e "${BOLD}Para entrar no Ubuntu:${RESET}"
echo
echo "  proot-distro login ubuntu"
echo

echo -e "${BOLD}Para iniciar o AIOStreams:${RESET}"
echo
echo "  cd /root/AIOStreams"
echo "  pnpm start"
echo

echo -e "${BOLD}Acesso local:${RESET}"
echo
echo "  http://127.0.0.1:${AIO_PORT}/stremio/configure"
echo

echo -e "${BOLD}Para verificar a versão instalada:${RESET}"
echo
echo "  cd /root/AIOStreams"
echo "  git describe --tags --always"
echo

echo -e "${BOLD}Para ver o log da instalação:${RESET}"
echo
echo "  cat ~/aio_install.log"
echo

O que mudou em relação ao AIOTERMUX original

O seu script antigo fazia:

GitHub Release
     ↓
aiostreams-ubuntu-v2.tar.gz
     ↓
proot-distro restore
     ↓
AIOStreams já pré-instalado

O novo faz:

GitHub
  ↓
proot-distro Ubuntu
  ↓
Node.js 24
  ↓
pnpm 11
  ↓
git clone AIOStreams
  ↓
última tag *-nightly
  ↓
pnpm install
  ↓
pnpm build
  ↓
pnpm run metadata --channel=nightly
  ↓
pnpm start

A documentação oficial confirma que a instalação "from source" usa exatamente a sequência de instalação/build/metadata/start acima.

Além disso, as Nightlies são realmente publicadas como tags datadas, por exemplo "2026.09.18.2336-nightly", e a release aponta para um commit específico ("a766f36"). O script não fixa esse número: ele procura automaticamente a maior tag "*-nightly", então seu repositório não ficará preso à Nightly de hoje.

Estrutura que eu usaria no seu GitHub

AIOTERMUX/
├── README.md
├── install.sh
├── update.sh
└── uninstall.sh

Eu faria o "install.sh" acima como instalação inicial e criaria um "update.sh" separado para atualizar somente o AIOStreams para a próxima Nightly, sem reinstalar Ubuntu, Node ou todas as dependências. Isso é particularmente útil porque a Nightly é atualizada a cada commit.

Também vale observar que a imagem Docker oficial atualmente é multi-arquitetura ("linux/amd64" e "linux/arm64"), mas no seu caso não precisamos dela: o script compila diretamente dentro do Ubuntu do Termux.
