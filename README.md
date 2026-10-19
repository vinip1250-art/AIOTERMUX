AIOTERMUX


Instalador do AIOStreams Nightly para Android usando Termux + Ubuntu via proot-distro. O projeto automatiza a preparação do ambiente, instalação do Node.js e pnpm, download do código-fonte do AIOStreams, compilação e geração dos metadados da versão Nightly.




Importante: os scripts devem ser executados diretamente no Termux, não dentro do Ubuntu/PRoot. O AIOStreams é instalado em /root/AIOStreams dentro do Ubuntu.




O que os scripts fazem




Script
Função




install.sh
Prepara o Termux, instala o Ubuntu se necessário, instala dependências, configura Node.js 24 e pnpm 11.0.8, baixa a tag Nightly mais recente, instala dependências, compila o projeto e gera os metadados. Se já encontrar uma instalação, apresenta opções para atualizar, reinstalar ou cancelar.


update.sh
Atualiza uma instalação existente para a tag Nightly mais recente, instala dependências, recompila e gera os metadados.


uninstall.sh
Remove a distribuição Ubuntu do proot-distro, incluindo o AIOStreams e todos os dados guardados dentro desse Ubuntu. Exige confirmação digitando REMOVE.




Requisitos




Android com Termux instalado. Recomenda-se uma versão oficial do F-Droid ou GitHub.


Conexão com a internet.


Espaço livre suficiente para o Ubuntu, as dependências e a compilação.


Para manter o serviço em segundo plano, recomenda-se desativar as restrições de bateria do Termux.




O instalador utiliza proot-distro, curl, git, wget, tar e gzip no Termux. Dentro do Ubuntu, prepara as ferramentas de compilação e instala Node.js 24 e pnpm 11.0.8.


Instalação


Abra o Termux e execute:


pkg update -y && pkg upgrade -y
pkg install -y git
git clone https://github.com/vinip1250-art/AIOTERMUX.git
cd AIOTERMUX
chmod +x install.sh update.sh uninstall.sh
./install.sh



O instalador conduz o processo e grava o log em:


~/aio_install.log



Se ocorrer algum erro, consulte o log:


tail -n 100 ~/aio_install.log



Se o AIOStreams já estiver instalado


Ao detectar /root/AIOStreams, o instalador apresenta três opções:




Atualizar para a Nightly: busca a tag Nightly mais recente, instala dependências, compila e gera os metadados.


Remover e instalar novamente: encerra processos relacionados e remove /root/AIOStreams antes de continuar. O Ubuntu, Node.js e pnpm são mantidos.


Cancelar: encerra o procedimento.




A opção de reinstalação remove o diretório do projeto. Faça backup de configurações e dados importantes antes de utilizá-la.


Iniciar o AIOStreams


Após a instalação, entre no Ubuntu:


proot-distro login ubuntu



Inicie o servidor:


cd /root/AIOStreams
pnpm start



Mantenha a sessão do Termux ativa enquanto utiliza o serviço. Para encerrar o processo, normalmente pressione Ctrl+C na sessão em que ele está rodando.


Acesso pela rede local


Para acessar o AIOStreams a partir de outro dispositivo conectado à mesma rede Wi-Fi:




Identifique o endereço IP local do celular.


Configure a URL base do AIOStreams com esse IP e a porta 3000, conforme as opções de configuração do aplicativo.


Utilize o endereço correspondente no outro dispositivo.




O IP depende da sua rede e pode mudar. Não utilize um endereço de exemplo sem substituí-lo pelo IP atual do aparelho.


Atualizar


No Termux, entre na pasta em que clonou este repositório:


cd ~/AIOTERMUX
./update.sh



O script verifica se o proot-distro e o Ubuntu estão disponíveis e confirma que existe um repositório Git do AIOStreams em /root/AIOStreams.


Em seguida, busca as tags disponíveis, seleciona a Nightly mais recente e, quando necessário, executa:




Atualização das referências Git.


Instalação das dependências com pnpm install.


Compilação com pnpm run build.


Geração dos metadados com pnpm run metadata --channel=nightly.




O log da atualização fica em:


cat ~/aio_update.log



Se o repositório foi clonado em outro diretório, utilize o caminho real em vez de ~/AIOTERMUX.


Desinstalar




Atenção: operação destrutiva. O script remove a distribuição Ubuntu inteira do proot-distro, não apenas o AIOStreams. Todos os arquivos, configurações e dados armazenados dentro desse Ubuntu serão apagados.




No Termux, execute:


cd ~/AIOTERMUX
./uninstall.sh



Digite exatamente REMOVE quando solicitado para confirmar. Caso contrário, a operação será cancelada.


A desinstalação:




Encerra processos relacionados ao Ubuntu, Node.js e pnpm.


Remove a distribuição Ubuntu.


Apaga os logs ~/aio_install.log e ~/aio_update.log, além do arquivo ~/.aio_install_state, quando existirem.




O que não é removido: o aplicativo Termux, os pacotes instalados no próprio Termux e os arquivos do armazenamento compartilhado do Android.


Entretanto, todos os dados armazenados dentro da distribuição Ubuntu removida serão perdidos. Faça backup antes de continuar.


Para instalar novamente, clone o repositório e execute ./install.sh.


Diagnóstico


Consulte os logs diretamente no Termux:


# Log de instalação
tail -n 100 ~/aio_install.log

# Log de atualização
tail -n 100 ~/aio_update.log



Se o comando pnpm start falhar, confirme que está dentro do Ubuntu e no diretório correto:


proot-distro login ubuntu
cd /root/AIOStreams
node --version
pnpm --version



Repositórios




AIOTERMUX: https://github.com/vinip1250-art/AIOTERMUX


AIOStreams: https://github.com/Viren070/AIOStreams




O projeto instala a versão Nightly do AIOStreams, que pode conter alterações recentes e instabilidade. Os comandos e requisitos podem mudar conforme o projeto upstream evolui.


