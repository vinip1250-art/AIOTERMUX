Guia de Instalação, Persistência e Operação do AIOStreams no Android (Termux + PRoot)
Este guia documenta o procedimento completo para configurar o AIOStreams (versão Nightly) em qualquer dispositivo Android utilizando Termux e PRoot Ubuntu, garantindo que os perfis, metadados e bancos de dados persistam permanentemente após reinicializações e atualizações.
1. Pré-requisitos no Android
 * Instale o Termux e o Termux:Widget (preferencialmente via F-Droid ou GitHub Releases oficial).
 * Desative a otimização de bateria para o Termux:
   * Configurações > Aplicativos > Termux > Bateria: Selecione Sem restrições.
 * Permita permissão de execução em segundo plano para o Termux:Widget nas configurações do sistema.
2. Preparação do Termux e Instalação do PRoot Ubuntu
Abra o Termux e execute os comandos abaixo para atualizar os pacotes base e instalar a distribuição Ubuntu:
# Atualiza os repositórios do Termux
pkg update -y && pkg upgrade -y

# Instala ferramentas essenciais e o gerenciador proot-distro
pkg install proot-distro -y

# Instala o Ubuntu dentro do proot
proot-distro install ubuntu

3. Configuração Interna do Ubuntu
Acesse o ambiente Ubuntu:
proot-distro login ubuntu

Instale as ferramentas necessárias para download de imagens OCI e manipulação criptográfica:
# Atualiza pacotes internos
apt update && apt upgrade -y

# Instala skopeo (download de imagens OCI), umoci (extração de rootfs), openssl e utilitários
apt install skopeo umoci openssl curl procps -y

4. Estrutura de Diretórios e Persistência de Dados
Para viabilizar atualizações da versão Nightly sem perda de configurações, a arquitetura isola o código da aplicação dos dados persistentes:
 * /root/aiostreams-test/ → Efêmero: Contém o executável e o código extraído da imagem Docker (pode ser sobrescrito nos updates).
 * /root/aiostreams-data/ → Persistente: Armazena o banco SQLite (db.sqlite), mapeamentos e cache.
 * /root/aiostreams/.env → Persistente: Contém chaves criptográficas e credenciais fixas.
4.1. Criar pastas persistentes e gerar a chave estática
Dentro do Ubuntu, execute:
mkdir -p /root/aiostreams
mkdir -p /root/aiostreams-data/cache

# Gera a SECRET_KEY de 64 caracteres hexadecimais
KEY=$(openssl rand -hex 32)

# Cria o arquivo .env (Ajuste o IP e a senha conforme sua rede)
cat <<EOF > /root/aiostreams/.env
BASE_URL=http://192.168.1.50:3000
SECRET_KEY=$KEY
AIOSTREAMS_AUTH=admin:sua_senha_aqui
DATABASE_URI=sqlite:///root/aiostreams-data/db.sqlite
DISK_CACHE_DIR=/root/aiostreams-data/cache
EOF

> Atenção: Guarde um backup da linha SECRET_KEY. Todos os perfis gerados são criptografados com essa chave. Se ela for alterada, os perfis existentes se tornam ilegíveis.
> 
5. Download e Extração Inicial da Imagem Nightly
Ainda dentro do Ubuntu, faça o primeiro download e descompactação do rootfs:
WORK_DIR="/root/aiostreams-update"
TARGET_DIR="/root/aiostreams-test"

rm -rf "$WORK_DIR" "$TARGET_DIR"
mkdir -p "$WORK_DIR/oci"

# Baixa a imagem OCI do repositório oficial
skopeo copy docker://ghcr.io/viren070/aiostreams:nightly oci:"$WORK_DIR/oci:latest"

# Descompacta o rootfs da imagem
umoci unpack --image "$WORK_DIR/oci:latest" "$WORK_DIR/bundle"

# Move o rootfs descompactado para a pasta de execução
mv "$WORK_DIR/bundle" "$TARGET_DIR"
rm -rf "$WORK_DIR"

# Garante permissão de execução no binário Node embutido
chmod +x "$TARGET_DIR/rootfs/nodejs/bin/node" 2>/dev/null || true

6. Criação do Script de Inicialização Interno
Crie o arquivo /root/aiostreams/start.sh dentro do Ubuntu para exportar as variáveis e disparar o runtime:
cat <<'EOF' > /root/aiostreams/start.sh
#!/bin/bash
set -a
[ -f /root/aiostreams/.env ] && source /root/aiostreams/.env
set +a

# Prioriza o binário Node do container; se indisponível, usa o do sistema
if [ -x /root/aiostreams-test/rootfs/nodejs/bin/node ]; then
    NODE_BIN="/root/aiostreams-test/rootfs/nodejs/bin/node"
else
    NODE_BIN="node"
fi

cd /root/aiostreams-test/rootfs/app
exec "$NODE_BIN" packages/server/dist/server.js
EOF

chmod +x /root/aiostreams/start.sh

Saia do Ubuntu para configurar os atalhos no Termux:
exit

7. Comandos de Gerenciamento do Termux ($PREFIX/bin)
Como o PRoot é gerenciado por rastreamento de chamadas (ptrace), o controle de execução em segundo plano deve ser gerido diretamente pelo Termux.
No terminal padrão do Termux (~ $), execute os blocos a seguir:
7.1. Iniciar (aio-start)
cat <<'EOF' > $PREFIX/bin/aio-start
#!/data/data/com.termux/files/usr/bin/bash
if pgrep -f "packages/server/dist/server.js" >/dev/null 2>&1; then
    echo "=> AIOStreams já está em execução."
    exit 0
fi

termux-wake-lock
echo "=> Iniciando AIOStreams..."
nohup proot-distro login ubuntu -- /root/aiostreams/start.sh > $HOME/aio.log 2>&1 &
sleep 3

if pgrep -f "packages/server/dist/server.js" >/dev/null 2>&1; then
    echo "=> AIOStreams iniciado com sucesso em segundo plano!"
    echo "=> Logs em tempo real: aio-logs"
    echo "=> Acesso: http://192.168.1.50:3000"
else
    echo "=> Erro ao iniciar. Verifique com: cat ~/aio.log"
fi
EOF
chmod +x $PREFIX/bin/aio-start

7.2. Parar (aio-stop)
cat <<'EOF' > $PREFIX/bin/aio-stop
#!/data/data/com.termux/files/usr/bin/bash
echo "=> Parando AIOStreams..."
pkill -f "packages/server/dist/server.js"
sleep 1
termux-wake-unlock
echo "=> Parado."
EOF
chmod +x $PREFIX/bin/aio-stop

7.3. Status (aio-status)
cat <<'EOF' > $PREFIX/bin/aio-status
#!/data/data/com.termux/files/usr/bin/bash
if pgrep -f "packages/server/dist/server.js" >/dev/null 2>&1; then
    echo "=> AIOStreams está RODANDO (PID: $(pgrep -f "packages/server/dist/server.js"))."
else
    echo "=> AIOStreams está PARADO."
fi
EOF
chmod +x $PREFIX/bin/aio-status

7.4. Logs em Tempo Real (aio-logs)
cat <<'EOF' > $PREFIX/bin/aio-logs
#!/data/data/com.termux/files/usr/bin/bash
tail -f $HOME/aio.log
EOF
chmod +x $PREFIX/bin/aio-logs

7.5. Atualização Automática sem Perda de Dados (aio-update)
cat <<'EOF' > $PREFIX/bin/aio-update
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
aio-stop

echo "==> Baixando imagem Nightly mais recente..."
proot-distro login ubuntu -- bash -c '
set -e
WORK_DIR="/root/aiostreams-update"
TARGET_DIR="/root/aiostreams-test"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/oci"

skopeo copy docker://ghcr.io/viren070/aiostreams:nightly oci:"$WORK_DIR/oci:latest"
echo "==> Descompactando nova versão via umoci..."
umoci unpack --image "$WORK_DIR/oci:latest" "$WORK_DIR/bundle"

rm -rf "$TARGET_DIR"
mv "$WORK_DIR/bundle" "$TARGET_DIR"
rm -rf "$WORK_DIR"
chmod +x "$TARGET_DIR/rootfs/nodejs/bin/node" 2>/dev/null || true
'

echo "==> Atualização concluída. Reiniciando servidor..."
aio-start
EOF
chmod +x $PREFIX/bin/aio-update

8. Integração com Termux:Widget (Atalhos na Tela Inicial)
No terminal do Termux, crie os executáveis do widget:
mkdir -p ~/.shortcuts/tasks

# Botão Iniciar silencioso em background
cat <<'EOF' > ~/.shortcuts/tasks/"AIOStreams Iniciar"
#!/data/data/com.termux/files/usr/bin/bash
aio-start
EOF
chmod +x ~/.shortcuts/tasks/"AIOStreams Iniciar"

# Botão Parar silencioso
cat <<'EOF' > ~/.shortcuts/tasks/"AIOStreams Parar"
#!/data/data/com.termux/files/usr/bin/bash
aio-stop
EOF
chmod +x ~/.shortcuts/tasks/"AIOStreams Parar"

# Botão Atualizar (Abre terminal para acompanhar download e extração)
cat <<'EOF' > ~/.shortcuts/"AIOStreams Atualizar"
#!/data/data/com.termux/files/usr/bin/bash
aio-update
echo ""
echo "Pressione ENTER para fechar a tela."
read
EOF
chmod +x ~/.shortcuts/"AIOStreams Atualizar"

Para adicionar à tela inicial do Android:
 * Pressione e segure na área de trabalho do smartphone > Widgets.
 * Localize Termux:Widget.
 * Adicione o atalho individual (Termux Shortcut) ou a lista suspensa (Termux Widget).
9. Procedimento de Backup e Restauração
Para migrar para outro smartphone ou restaurar após formatação:
Criar backup das configurações e banco de dados:
No Termux, execute:
proot-distro login ubuntu -- tar -czvf /sdcard/Download/aiostreams_backup.tar.gz /root/aiostreams/.env /root/aiostreams-data/

Isso gera um arquivo aiostreams_backup.tar.gz diretamente na pasta Downloads do celular.
Restaurar o backup em um novo dispositivo:
Após instalar o PRoot e o Ubuntu (seções 2 e 3):
 * Coloque o arquivo aiostreams_backup.tar.gz na pasta Downloads do novo celular.
 * Restaure os dados com:
proot-distro login ubuntu -- tar -xzvf /sdcard/Download/aiostreams_backup.tar.gz -C /

 * Prossiga a partir do Passo 5 (Download da imagem) e Passo 6 (Criação dos atalhos). Todos os perfis e configurações anteriores voltarão imediatamente.
 * 
