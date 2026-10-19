#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# AIOTERMUX - AIOStreams Nightly (imagem OCI oficial)
DISTRO="ubuntu"
IMAGE="docker://ghcr.io/viren070/aiostreams:nightly"
WORK_DIR="/root/aiostreams-update"
TARGET_DIR="/root/aiostreams-test"
CONFIG_DIR="/root/aiostreams"
DATA_DIR="/root/aiostreams-data"
LOG_FILE="$HOME/aio_install.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[*]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET} $*"; }
warning() { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[ERRO]${RESET} $*"; }
die()     { error "$*"; echo "Log: $LOG_FILE"; exit 1; }

run() {
    local description="$1"; shift
    info "$description"
    if "$@" >>"$LOG_FILE" 2>&1; then
        success "$description"
    else
        error "$description"
        tail -n 80 "$LOG_FILE" 2>/dev/null || true
        exit 1
    fi
}

[[ -d /data/data/com.termux ]] || die "Execute este script dentro do Termux."
command -v proot-distro >/dev/null 2>&1 || {
    pkg update -y
    pkg install -y proot-distro
}

if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    trap 'termux-wake-unlock >/dev/null 2>&1 || true' EXIT
fi

: > "$LOG_FILE"
clear || true
echo -e "${CYAN}${BOLD}AIOStreams Nightly — instalador por imagem OCI${RESET}"
echo "Imagem: ghcr.io/viren070/aiostreams:nightly"
echo "Log: $LOG_FILE"
echo

run "Atualizando pacotes do Termux" pkg update -y
run "Instalando dependências do Termux" pkg install -y proot-distro curl tar gzip

if ! proot-distro list 2>/dev/null | grep -q '^ubuntu'; then
    run "Instalando Ubuntu no proot-distro" proot-distro install ubuntu
else
    success "Ubuntu já está instalado."
fi

run "Preparando Ubuntu e instalando ferramentas OCI" \
    proot-distro login "$DISTRO" -- bash -lc '
        set -e
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y ca-certificates curl skopeo umoci openssl coreutils
    '

# Cria a configuração apenas se ainda não existir. Nunca sobrescreve .env,
# banco de dados ou chave secreta em uma reinstalação/atualização.
run "Preparando diretórios persistentes" \
    proot-distro login "$DISTRO" -- bash -lc "
        set -e
        mkdir -p '$CONFIG_DIR' '$DATA_DIR/cache'
        if [ ! -f '$CONFIG_DIR/.env' ]; then
            SECRET_KEY=\$(openssl rand -hex 32)
            cat > '$CONFIG_DIR/.env' <<EOF
BASE_URL=http://IP_LOCAL_DO_CELULAR:3000
SECRET_KEY=\$SECRET_KEY
DATABASE_URI=sqlite:////root/aiostreams-data/db.sqlite
DISK_CACHE_DIR=/root/aiostreams-data/cache
AIOSTREAMS_AUTH=admin:ALTERE_PARA_UMA_SENHA_FORTE
EOF
            chmod 600 '$CONFIG_DIR/.env'
            echo 'Arquivo .env criado; revise BASE_URL e AIOSTREAMS_AUTH antes de usar.'
        else
            echo 'Arquivo .env existente preservado.'
        fi

        if [ ! -f '$CONFIG_DIR/start.sh' ]; then
            cat > '$CONFIG_DIR/start.sh' <<'START_EOF'
#!/bin/bash
set -e
set -a
source /root/aiostreams/.env
set +a

NODE_BIN=/root/aiostreams-test/rootfs/nodejs/bin/node
APP_DIR=/root/aiostreams-test/rootfs/app

if [ ! -x \"\$NODE_BIN\" ]; then
    echo \"Node embutido não encontrado: \$NODE_BIN\"
    echo \"Verifique se a estrutura da imagem Nightly mudou.\"
    exit 1
fi
if [ ! -f \"\$APP_DIR/packages/server/dist/server.js\" ]; then
    echo \"Servidor não encontrado em \$APP_DIR/packages/server/dist/server.js\"
    echo \"Verifique se a estrutura da imagem Nightly mudou.\"
    exit 1
fi

cd \"\$APP_DIR\"
exec \"\$NODE_BIN\" packages/server/dist/server.js
START_EOF
            chmod +x '$CONFIG_DIR/start.sh'
        fi
    "

# Baixa a tag móvel :nightly. O novo bundle só substitui a versão anterior
# depois que o download e a extração terminarem com sucesso.
info "Baixando a imagem Nightly mais recente do GHCR..."
proot-distro login "$DISTRO" -- bash -lc "
    set -e
    rm -rf '$WORK_DIR'
    mkdir -p '$WORK_DIR'
    skopeo copy --retry-times 3 '$IMAGE' oci:'$WORK_DIR/oci:nightly'
    umoci unpack --image '$WORK_DIR/oci:nightly' '$WORK_DIR/bundle'

    if [ ! -x '$WORK_DIR/bundle/rootfs/nodejs/bin/node' ]; then
        echo 'ERRO: o binário Node esperado não existe na imagem extraída.'
        echo 'A estrutura da imagem pode ter mudado; a instalação anterior foi preservada.'
        exit 1
    fi
    if [ ! -f '$WORK_DIR/bundle/rootfs/app/packages/server/dist/server.js' ]; then
        echo 'ERRO: o arquivo do servidor esperado não existe na imagem extraída.'
        echo 'A estrutura da imagem pode ter mudado; a instalação anterior foi preservada.'
        exit 1
    fi

    rm -rf '${TARGET_DIR}.new'
    mv '$WORK_DIR/bundle' '${TARGET_DIR}.new'
    rm -rf '${TARGET_DIR}.previous'
    if [ -d '$TARGET_DIR' ]; then mv '$TARGET_DIR' '${TARGET_DIR}.previous'; fi
    mv '${TARGET_DIR}.new' '$TARGET_DIR'
    rm -rf '${TARGET_DIR}.previous' '$WORK_DIR'
    chmod +x '$TARGET_DIR/rootfs/nodejs/bin/node'
    echo 'Imagem instalada: ghcr.io/viren070/aiostreams:nightly'
" >>"$LOG_FILE" 2>&1 || {
    error "Falha ao baixar/extrair a imagem Nightly."
    tail -n 100 "$LOG_FILE"
    exit 1
}

success "Imagem Nightly baixada e extraída."

echo
echo -e "${YELLOW}${BOLD}Configuração necessária antes de iniciar${RESET}"
echo "Edite o arquivo .env no Ubuntu:"
echo "  proot-distro login ubuntu"
echo "  nano /root/aiostreams/.env"
echo
echo "Configure:"
echo "  BASE_URL=http://IP_LOCAL_DO_CELULAR:3000"
echo "  AIOSTREAMS_AUTH=admin:SUA_SENHA_FORTE"
echo
echo "A SECRET_KEY foi gerada automaticamente. Preserve-a após a primeira inicialização."
echo
echo "Para iniciar:"
echo "  proot-distro login ubuntu -- /root/aiostreams/start.sh"
echo
echo "Para ver o log da instalação:"
echo "  cat ~/aio_install.log"
echo
warning "Este instalador usa a imagem OCI :nightly; não clona nem compila o código-fonte."
