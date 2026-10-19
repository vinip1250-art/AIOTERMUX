# AIOTERMUX

Instalador do **AIOStreams Nightly** para Android usando **Termux + Ubuntu via `proot-distro`**. O projeto automatiza a preparação do ambiente, instalação do Node.js e pnpm, download do código-fonte do AIOStreams, compilação e geração dos metadados da versão Nightly.

> **Importante:** os scripts devem ser executados diretamente no Termux, não dentro do Ubuntu/PRoot. O AIOStreams é instalado em `/root/AIOStreams` dentro do Ubuntu.

## O que os scripts fazem

| Script | Função |
|---|---|
| `install.sh` | Prepara o Termux, instala o Ubuntu se necessário, instala dependências, configura Node.js 24 e pnpm 11.0.8, baixa a tag Nightly mais recente, instala dependências, compila o projeto e gera os metadados. Se já encontrar uma instalação, apresenta opções para atualizar, reinstalar ou cancelar. |
| `update.sh` | Atualiza uma instalação existente para a tag Nightly mais recente, instala dependências, recompila e gera os metadados. |
| `uninstall.sh` | Remove a distribuição Ubuntu do `proot-distro`, incluindo o AIOStreams e todos os dados guardados dentro desse Ubuntu. Exige confirmação digitando `REMOVE`. |

## Requisitos

- Android com [Termux](https://github.com/termux/termux-app) instalado. Recomenda-se uma versão oficial do F-Droid ou GitHub.
- Conexão com a internet.
- Espaço livre suficiente para o Ubuntu, as dependências e a compilação.
- Para manter o serviço em segundo plano, recomenda-se desativar as restrições de bateria do Termux.

O instalador utiliza `proot-distro`, `curl`, `git`, `wget`, `tar` e `gzip` no Termux. Dentro do Ubuntu, prepara as ferramentas de compilação e instala **Node.js 24** e **pnpm 11.0.8**.

## Instalação

Abra o Termux e execute:

```bash
pkg update -y && pkg upgrade -y
pkg install -y git
git clone https://github.com/vinip1250-art/AIOTERMUX.git
cd AIOTERMUX
chmod +x install.sh update.sh uninstall.sh
./install.sh
```

O instalador conduz o processo e grava o log em:

```text
~/aio_install.log
```

## Configurar o arquivo `.env`

Depois da instalação, configure as variáveis de ambiente do AIOStreams antes de iniciar o servidor pela primeira vez. O arquivo deve ficar em:

```text
/root/AIOStreams/.env
```

Entre no Ubuntu e crie/edite o arquivo:

```bash
proot-distro login ubuntu
cd /root/AIOStreams
nano .env
```

Inclua as variáveis abaixo, preenchendo os valores indicados:

```dotenv
# URL usada pelo AIOStreams para gerar links de instalação
# Para acesso na rede local, substitua pelo IP local do celular.
BASE_URL=http://IP_LOCAL_DO_CELULAR:3000

# Chave de criptografia: gere uma chave antes de iniciar pela primeira vez.
SECRET_KEY=COLE_AQUI_UMA_CHAVE_HEX_DE_64_CARACTERES

# Banco de dados SQLite local
DATABASE_URI=sqlite://./data/db.sqlite

# Credenciais para acessar o dashboard
# Formato: usuario:senha
AIOSTREAMS_AUTH=admin:COLOQUE_UMA_SENHA_FORTE
```

Gere a chave `SECRET_KEY` no Ubuntu com:

```bash
openssl rand -hex 32
```

Copie o resultado e substitua o valor de exemplo em `SECRET_KEY`. Não deixe o texto de exemplo no arquivo. **Guarde essa chave com segurança e não a altere depois da primeira inicialização**, pois as configurações criptografadas existentes poderão deixar de ser legíveis.

Em `BASE_URL`, substitua `IP_LOCAL_DO_CELULAR` pelo endereço IP atual do aparelho na sua rede Wi-Fi. Por exemplo, se o IP for `192.168.1.50`, use `BASE_URL=http://192.168.1.50:3000`. O endereço pode mudar conforme a rede.

Em `AIOSTREAMS_AUTH`, defina um nome de usuário e uma senha forte no formato `usuario:senha`. Essa credencial é usada para autenticar o acesso ao dashboard. Não compartilhe o arquivo `.env`, pois ele contém segredos.

Salve o arquivo no Nano com `Ctrl+O`, pressione `Enter` e saia com `Ctrl+X`. Depois, inicie o AIOStreams conforme as instruções abaixo.

> `BASE_URL`, `SECRET_KEY` e `DATABASE_URI` são variáveis essenciais para a inicialização. `AIOSTREAMS_AUTH` define as credenciais de operador/dashboard. Consulte a [documentação oficial das variáveis de ambiente](https://docs.aiostreams.viren070.me/configuration/environment-variables) para detalhes adicionais.

Se ocorrer algum erro durante a instalação, consulte o log:

```bash
tail -n 100 ~/aio_install.log
```

### Se o AIOStreams já estiver instalado

Ao detectar `/root/AIOStreams`, o instalador apresenta três opções:

1. **Atualizar para a Nightly:** busca a tag Nightly mais recente, instala dependências, compila e gera os metadados.
2. **Remover e instalar novamente:** encerra processos relacionados e remove `/root/AIOStreams` antes de continuar. O Ubuntu, Node.js e pnpm são mantidos.
3. **Cancelar:** encerra o procedimento.

A opção de reinstalação remove o diretório do projeto. Faça backup de configurações e dados importantes antes de utilizá-la.

## Iniciar o AIOStreams

Após a instalação, entre no Ubuntu:

```bash
proot-distro login ubuntu
```

Inicie o servidor:

```bash
cd /root/AIOStreams
pnpm start
```

Mantenha a sessão do Termux ativa enquanto utiliza o serviço. Para encerrar o processo, normalmente pressione `Ctrl+C` na sessão em que ele está rodando.

### Acesso pela rede local

Para acessar o AIOStreams a partir de outro dispositivo conectado à mesma rede Wi-Fi:

1. Identifique o endereço IP local do celular.
2. Configure a URL base do AIOStreams com esse IP e a porta `3000`, conforme as opções de configuração do aplicativo.
3. Utilize o endereço correspondente no outro dispositivo.

O IP depende da sua rede e pode mudar. Não utilize um endereço de exemplo sem substituí-lo pelo IP atual do aparelho.

## Atualizar

No Termux, entre na pasta em que clonou este repositório:

```bash
cd ~/AIOTERMUX
./update.sh
```

O script verifica se o `proot-distro` e o Ubuntu estão disponíveis e confirma que existe um repositório Git do AIOStreams em `/root/AIOStreams`.

Em seguida, busca as tags disponíveis, seleciona a Nightly mais recente e, quando necessário, executa:

- Atualização das referências Git.
- Instalação das dependências com `pnpm install`.
- Compilação com `pnpm run build`.
- Geração dos metadados com `pnpm run metadata --channel=nightly`.

O log da atualização fica em:

```bash
cat ~/aio_update.log
```

Se o repositório foi clonado em outro diretório, utilize o caminho real em vez de `~/AIOTERMUX`.

## Desinstalar

> **Atenção: operação destrutiva.** O script remove a distribuição Ubuntu inteira do `proot-distro`, não apenas o AIOStreams. Todos os arquivos, configurações e dados armazenados dentro desse Ubuntu serão apagados.

No Termux, execute:

```bash
cd ~/AIOTERMUX
./uninstall.sh
```

Digite exatamente `REMOVE` quando solicitado para confirmar. Caso contrário, a operação será cancelada.

A desinstalação:

- Encerra processos relacionados ao Ubuntu, Node.js e pnpm.
- Remove a distribuição Ubuntu.
- Apaga os logs `~/aio_install.log` e `~/aio_update.log`, além do arquivo `~/.aio_install_state`, quando existirem.

**O que não é removido:** o aplicativo Termux, os pacotes instalados no próprio Termux e os arquivos do armazenamento compartilhado do Android.

Entretanto, todos os dados armazenados dentro da distribuição Ubuntu removida serão perdidos. Faça backup antes de continuar.

Para instalar novamente, clone o repositório e execute `./install.sh`.

## Diagnóstico

Consulte os logs diretamente no Termux:

```bash
# Log de instalação
tail -n 100 ~/aio_install.log

# Log de atualização
tail -n 100 ~/aio_update.log
```

Se o comando `pnpm start` falhar, confirme que está dentro do Ubuntu e no diretório correto:

```bash
proot-distro login ubuntu
cd /root/AIOStreams
node --version
pnpm --version
```

## Repositórios

- **AIOTERMUX:** https://github.com/vinip1250-art/AIOTERMUX
- **AIOStreams:** https://github.com/Viren070/AIOStreams

O projeto instala a versão **Nightly** do AIOStreams, que pode conter alterações recentes e instabilidade. Os comandos e requisitos podem mudar conforme o projeto upstream evolui.
