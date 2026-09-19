AIOTERMUX

Instalador e atualizador do AIOStreams Nightly para Android usando Termux + proot-distro + Ubuntu, sem Docker.

Repositório:

git@github.com:vinip1250-art/AIOTERMUX.git

Arquitetura

Android
└── Termux
    └── proot-distro
        └── Ubuntu
            ├── Node.js 24
            ├── pnpm
            └── AIOStreams Nightly

O projeto possui três scripts principais:

AIOTERMUX/
├── README.md
├── install.sh
├── update.sh
└── uninstall.sh

- "install.sh" → instalação inicial ou reinstalação/atualização da instalação existente.
- "update.sh" → atualização rápida do AIOStreams Nightly.
- "uninstall.sh" → remove o Ubuntu/proot-distro utilizado pelo projeto.

---

1. Requisitos

Antes de começar:

- Android com Termux instalado.
- Conexão com a Internet.
- Conta no GitHub.
- Acesso ao repositório "vinip1250-art/AIOTERMUX".
- Espaço livre suficiente no armazenamento.

«Recomenda-se instalar o Termux por uma fonte oficial/confiável, como F-Droid ou GitHub Releases do projeto Termux.»

---

2. Primeira abertura do Termux

Abra o Termux e atualize os pacotes:

pkg update -y
pkg upgrade -y

Instale as ferramentas necessárias:

pkg install -y git openssh proot-distro

Confira:

git --version
ssh -V
proot-distro --version

---

3. Configurar acesso SSH ao GitHub

Como este projeto utiliza o repositório:

git@github.com:vinip1250-art/AIOTERMUX.git

é necessário configurar uma chave SSH.

3.1 Criar a chave

Execute:

ssh-keygen -t ed25519 -C "SEU_EMAIL_DO_GITHUB"

Substitua:

SEU_EMAIL_DO_GITHUB

pelo e-mail associado à sua conta GitHub.

Quando aparecer:

Enter file in which to save the key

pressione:

Enter

Quando pedir uma passphrase, você pode definir uma senha ou pressionar "Enter" para deixar sem passphrase.

---

4. Iniciar o SSH Agent

Execute:

eval "$(ssh-agent -s)"

Adicione sua chave:

ssh-add ~/.ssh/id_ed25519

Confira:

ssh-add -l

---

5. Copiar a chave pública

Execute:

cat ~/.ssh/id_ed25519.pub

Será exibida uma linha semelhante a:

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... seu-email

Copie a linha inteira.

---

6. Adicionar a chave ao GitHub

Abra o GitHub no navegador.

Acesse:

Settings
→ SSH and GPG keys
→ New SSH key

Crie uma chave com:

Title:
Termux Android

Cole o conteúdo copiado de:

cat ~/.ssh/id_ed25519.pub

no campo da chave.

Salve.

---

7. Testar o acesso ao GitHub

No Termux:

ssh -T git@github.com

Na primeira conexão poderá aparecer:

Are you sure you want to continue connecting
(yes/no/[fingerprint])?

Digite:

yes

Se estiver correto, o GitHub deverá responder com uma mensagem semelhante a:

Hi vinip1250-art! You've successfully authenticated,
but GitHub does not provide shell access.

Isso significa que o SSH está funcionando.

---

8. Clonar o AIOTERMUX

Volte para o diretório inicial:

cd ~

Clone o repositório:

git clone git@github.com:vinip1250-art/AIOTERMUX.git

Entre no projeto:

cd ~/AIOTERMUX

Confira os arquivos:

ls -la

Deverá existir algo semelhante a:

README.md
install.sh
update.sh
uninstall.sh

---

9. Dar permissão aos scripts

Execute:

chmod +x install.sh update.sh uninstall.sh

Confira:

ls -l *.sh

Os arquivos deverão possuir permissão de execução, por exemplo:

-rwxr-xr-x install.sh
-rwxr-xr-x update.sh
-rwxr-xr-x uninstall.sh

---

10. Instalação do AIOStreams Nightly

Agora execute:

./install.sh

O instalador fará automaticamente as etapas necessárias.

Em uma instalação nova, o fluxo será aproximadamente:

Termux
  ↓
Atualização dos pacotes
  ↓
proot-distro
  ↓
Ubuntu
  ↓
Dependências do Ubuntu
  ↓
Node.js 24
  ↓
pnpm
  ↓
Clone do AIOStreams
  ↓
Última tag Nightly
  ↓
pnpm install
  ↓
pnpm run build
  ↓
pnpm run metadata --channel=nightly

---

11. Instalação existente

Se o instalador encontrar uma instalação anterior em:

/root/AIOStreams

ele poderá apresentar opções para:

1. Atualizar a instalação existente para a Nightly
2. Remover somente o AIOStreams e reinstalar
3. Cancelar

Escolha conforme a necessidade.

Opção 1 — Atualizar

Mantém a instalação existente e muda o código para a Nightly mais recente.

Opção 2 — Reinstalar AIOStreams

Remove:

/root/AIOStreams

e instala novamente.

Opção 3 — Cancelar

Não altera a instalação.

---

12. Entrar no Ubuntu

Depois da instalação:

proot-distro login ubuntu

Você estará dentro do Ubuntu.

Confira:

cat /etc/os-release

---

13. Verificar o AIOStreams

Dentro do Ubuntu:

cd /root/AIOStreams

Confira o Git:

git status

Confira a versão/tag:

git describe --tags --always

Confira Node:

node --version

Deve ser uma versão da série:

v24.x.x

Confira pnpm:

pnpm --version

---

14. Iniciar o AIOStreams

Dentro do Ubuntu:

cd /root/AIOStreams
pnpm start

O AIOStreams será iniciado na porta configurada pelo projeto.

Para acessar a interface, utilize o endereço correspondente ao IP do dispositivo e à porta utilizada pelo AIOStreams.

---

15. Parar o AIOStreams

Se o AIOStreams estiver rodando diretamente no terminal, normalmente:

Ctrl + C

interrompe o processo.

---

16. Atualização rápida

Depois que o AIOStreams já estiver instalado, não é necessário executar novamente:

./install.sh

Para atualizar a Nightly, entre no Termux:

cd ~/AIOTERMUX

e execute:

./update.sh

Esse é o comando rápido de atualização.

O "update.sh" verifica:

1. Ubuntu.
2. A instalação do AIOStreams.
3. As tags Nightly disponíveis.
4. A Nightly atualmente instalada.
5. A Nightly mais recente.

Se já estiver na versão mais recente, não recompila desnecessariamente.

Se houver uma versão nova:

Git fetch
    ↓
Checkout da nova Nightly
    ↓
pnpm install
    ↓
pnpm run build
    ↓
pnpm run metadata --channel=nightly

---

17. Log da instalação

O instalador mantém um log:

cat ~/aio_install.log

Para visualizar somente as últimas linhas:

tail -n 100 ~/aio_install.log

---

18. Log da atualização

O atualizador mantém um log:

cat ~/aio_update.log

Últimas 100 linhas:

tail -n 100 ~/aio_update.log

---

19. Atualizar o próprio AIOTERMUX

O "update.sh" atualiza o AIOStreams.

Se você também quiser atualizar os scripts do próprio repositório GitHub:

cd ~/AIOTERMUX
git pull

Confira o status:

git status

Depois:

./update.sh

---

20. Verificar o repositório remoto

Dentro de:

cd ~/AIOTERMUX

execute:

git remote -v

O esperado é:

origin  git@github.com:vinip1250-art/AIOTERMUX.git (fetch)
origin  git@github.com:vinip1250-art/AIOTERMUX.git (push)

---

21. Verificar o Ubuntu instalado

No Termux:

proot-distro list

Deverá aparecer:

ubuntu

Para entrar:

proot-distro login ubuntu

Para sair:

exit

---

22. Reinstalar somente o AIOStreams

Se o "install.sh" apresentar a opção de remover somente o AIOStreams, essa opção remove:

/root/AIOStreams

mas mantém o ambiente Ubuntu.

Depois o instalador pode clonar e preparar novamente o AIOStreams.

Isso é diferente de remover todo o Ubuntu.

---

23. Desinstalar o ambiente inteiro

Se quiser remover completamente o Ubuntu criado pelo projeto, execute no Termux:

cd ~/AIOTERMUX
./uninstall.sh

«Atenção: o "uninstall.sh" remove o ambiente Ubuntu/proot-distro utilizado pelo projeto. Isso pode apagar o AIOStreams e outros dados existentes dentro desse Ubuntu.»

---

24. Reinstalação completa

Para começar novamente do zero:

cd ~/AIOTERMUX
./uninstall.sh

Depois:

./install.sh

---

25. Fluxo resumido — instalação inicial

Em um Termux novo:

pkg update -y
pkg upgrade -y
pkg install -y git openssh proot-distro

Configurar SSH:

ssh-keygen -t ed25519 -C "SEU_EMAIL_DO_GITHUB"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub

Adicionar a chave ao GitHub.

Testar:

ssh -T git@github.com

Clonar:

cd ~
git clone git@github.com:vinip1250-art/AIOTERMUX.git
cd AIOTERMUX

Dar permissão:

chmod +x install.sh update.sh uninstall.sh

Instalar:

./install.sh

Depois:

proot-distro login ubuntu
cd /root/AIOStreams
pnpm start

---

26. Fluxo resumido — atualização

No Termux:

cd ~/AIOTERMUX
git pull
./update.sh

Depois iniciar:

proot-distro login ubuntu
cd /root/AIOStreams
pnpm start

---

27. Fluxo resumido — uso diário

Depois que tudo estiver instalado:

Atualizar

cd ~/AIOTERMUX
./update.sh

Iniciar

proot-distro login ubuntu
cd /root/AIOStreams
pnpm start

Sair do Ubuntu

exit

---

28. Estrutura final

No Termux:

/data/data/com.termux/files/home/
│
└── AIOTERMUX/
    ├── README.md
    ├── install.sh
    ├── update.sh
    └── uninstall.sh

Dentro do Ubuntu:

/root/
└── AIOStreams/
    ├── package.json
    ├── src/
    ├── ...
    └── .git/

---

29. Comandos principais

Objetivo| Comando
Entrar no projeto| "cd ~/AIOTERMUX"
Instalação| "./install.sh"
Atualização rápida| "./update.sh"
Desinstalação| "./uninstall.sh"
Entrar no Ubuntu| "proot-distro login ubuntu"
Sair do Ubuntu| "exit"
Iniciar AIOStreams| "cd /root/AIOStreams && pnpm start"
Atualizar AIOTERMUX| "cd ~/AIOTERMUX && git pull"
Ver log da instalação| "cat ~/aio_install.log"
Ver log da atualização| "cat ~/aio_update.log"
Listar distros| "proot-distro list"
Ver versão Node| "node --version"
Ver versão pnpm| "pnpm --version"
Ver versão AIOStreams| "git describe --tags --always"

---

30. Solução de problemas

GitHub pede senha

Se:

git clone git@github.com:vinip1250-art/AIOTERMUX.git

pedir senha, verifique:

ssh -T git@github.com

Se necessário:

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

---

Verificar se a chave existe

ls -la ~/.ssh

Deve existir:

id_ed25519
id_ed25519.pub

---

Ubuntu não encontrado

Verifique:

proot-distro list

Se o Ubuntu não estiver instalado, execute:

./install.sh

---

AIOStreams não encontrado

Dentro do Ubuntu:

ls -la /root/AIOStreams

Se não existir, saia:

exit

e execute:

cd ~/AIOTERMUX
./install.sh

---

Verificar o Git do AIOStreams

Dentro do Ubuntu:

cd /root/AIOStreams
git remote -v

O repositório deve apontar para:

https://github.com/Viren070/AIOStreams.git

---

Verificar a Nightly instalada

Dentro do Ubuntu:

cd /root/AIOStreams
git describe --tags --always

Também é possível consultar:

git status

e:

git log -1 --oneline

---

31. Comandos para diagnóstico

Se alguma coisa der errado, estes comandos ajudam a identificar o problema:

echo "=== TERMUX ==="
uname -a

echo
echo "=== PROOT ==="
proot-distro list

echo
echo "=== GIT ==="
git --version

echo
echo "=== SSH ==="
ssh -V

echo
echo "=== UBUNTU ==="
proot-distro login ubuntu -- bash -c '
echo "Node:"
node --version
echo
echo "pnpm:"
pnpm --version
echo
echo "AIOStreams:"
cd /root/AIOStreams 2>/dev/null && git describe --tags --always || echo "AIOStreams não encontrado"
'

---

32. Projeto

Repositório:

git@github.com:vinip1250-art/AIOTERMUX.git

AIOStreams:

https://github.com/Viren070/AIOStreams

---

33. Comando essencial

Depois da configuração inicial, o comando principal para manter o AIOStreams Nightly atualizado é:

cd ~/AIOTERMUX && ./update.sh

E para iniciar:

proot-distro login ubuntu
cd /root/AIOStreams
pnpm start
