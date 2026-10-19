# AIOTERMUX — AIOStreams Nightly

Instalador do **AIOStreams Nightly** no Android usando **Termux + Ubuntu via `proot-distro`**. O `install.sh` utiliza a imagem OCI publicada no GitHub Container Registry (GHCR), em vez de clonar e compilar o código-fonte.

> **Importante:** execute os scripts a partir do Termux, não dentro da sessão Ubuntu/PRoot.

## Como funciona

O instalador baixa a tag móvel `ghcr.io/viren070/aiostreams:nightly`, extrai a imagem com `skopeo` e `umoci` e valida se os arquivos esperados existem antes de substituir a versão extraída anteriormente.

| Caminho no Ubuntu | Finalidade |
|---|---|
| `/root/aiostreams/.env` | Configuração e credenciais |
| `/root/aiostreams/start.sh` | Script de inicialização |
| `/root/aiostreams-test/` | Arquivos da imagem Nightly extraída |
| `/root/aiostreams-data/` | Dados persistentes e cache |
| `~/aio_install.log` no Termux | Log da instalação |

A primeira instalação também prepara a distribuição Ubuntu, instala as ferramentas necessárias e cria um `.env` inicial. Um `.env` existente é preservado.

## Requisitos

- Android com [Termux](https://github.com/termux/termux-app).
- Conexão com a internet.
- Espaço livre para a distribuição Ubuntu, a imagem e os dados.
- Para manter o serviço ativo em segundo plano, ajuste as restrições de bateria do Android para o Termux.

## Instalar

No Termux, execute:

```bash
pkg update -y && pkg upgrade -y
pkg install -y git
git clone https://github.com/vinip1250-art/AIOTERMUX.git
cd AIOTERMUX
chmod +x install.sh update.sh uninstall.sh
./install.sh
```

O instalador baixa a imagem `nightly` do GHCR. O processo pode levar alguns minutos, dependendo da conexão e do desempenho do aparelho.

## Configurar o `.env`

Antes de iniciar o servidor pela primeira vez, edite o arquivo de configuração dentro do Ubuntu:

```bash
proot-distro login ubuntu
nano /root/aiostreams/.env
```

O instalador cria um arquivo inicial semelhante a este:

```dotenv
BASE_URL=http://IP_LOCAL_DO_CELULAR:3000
SECRET_KEY=CHAVE_GERADA_AUTOMATICAMENTE
DATABASE_URI=sqlite:////root/aiostreams-data/db.sqlite
DISK_CACHE_DIR=/root/aiostreams-data/cache
AIOSTREAMS_AUTH=admin:ALTERE_PARA_UMA_SENHA_FORTE
```

Configure estes valores:

- **`BASE_URL`**: troque `IP_LOCAL_DO_CELULAR` pelo IP do celular na rede Wi-Fi, por exemplo `http://192.168.1.50:3000`. O IP pode mudar quando você troca de rede.
- **`SECRET_KEY`**: é gerada automaticamente pelo instalador. Preserve o valor depois da primeira inicialização; alterá-lo pode impedir o acesso a configurações que foram criptografadas com a chave anterior.
- **`AIOSTREAMS_AUTH`**: defina as credenciais no formato `usuario:senha`, usando uma senha forte.

Não compartilhe o `.env`, pois ele contém segredos. Se o arquivo já existia, o instalador não o sobrescreve.

Consulte também a [documentação oficial das variáveis de ambiente do AIOStreams](https://docs.aiostreams.viren070.me/configuration/environment-variables).

## Iniciar

Depois de configurar o `.env`, execute no Termux:

```bash
proot-distro login ubuntu -- /root/aiostreams/start.sh
```

Mantenha o Termux ativo enquanto utiliza o serviço. Para encerrar, use `Ctrl+C` na sessão em que o servidor está rodando.

## Acessar pela rede local

1. Conecte o celular e o outro dispositivo à mesma rede Wi-Fi.
2. Confira o IP local do celular nas configurações de Wi-Fi do Android.
3. Configure `BASE_URL` com esse IP e a porta `3000`.
4. No outro dispositivo, acesse o endereço correspondente, por exemplo `http://192.168.1.50:3000`.

O endereço acima é apenas um exemplo; substitua-o pelo IP real do aparelho. O acesso pela rede local depende também de a rede permitir comunicação entre dispositivos.

## Atualizar

A imagem oficial utiliza a tag móvel `nightly`, que aponta para a versão Nightly publicada mais recentemente. O fluxo de atualização deve baixar novamente essa imagem e preservar `/root/aiostreams/.env` e `/root/aiostreams-data/`.

**Atenção:** o `install.sh` descrito neste README já utiliza a imagem OCI. Confirme que o `update.sh` do seu clone também foi adaptado para baixar e extrair `ghcr.io/viren070/aiostreams:nightly` antes de executá-lo. Se ele ainda tentar atualizar tags Git, instalar dependências com pnpm ou compilar o código-fonte, ele segue o fluxo antigo e não corresponde ao novo instalador por imagem.

Quando o `update.sh` compatível estiver disponível, execute-o a partir da pasta do repositório no Termux:

```bash
cd ~/AIOTERMUX
./update.sh
```

## Desinstalar

Antes de executar `uninstall.sh`, leia o próprio script e confirme o que ele remove.

Se o script usar `proot-distro remove ubuntu`, ele removerá **a distribuição Ubuntu inteira**, não apenas o AIOStreams. Isso apaga também outros programas, configurações e arquivos que estejam dentro desse Ubuntu. Faça backup dos dados antes de confirmar a operação.

## Diagnóstico

Veja as últimas linhas do log de instalação:

```bash
tail -n 100 ~/aio_install.log
```

Se o servidor não iniciar, confira se a estrutura esperada da imagem ainda existe:

```bash
proot-distro login ubuntu -- bash -lc '
  ls -l /root/aiostreams-test/rootfs/nodejs/bin/node
  ls -l /root/aiostreams-test/rootfs/app/packages/server/dist/server.js
  cat /root/aiostreams/.env
'
```

Não publique o conteúdo completo do `.env` ao pedir ajuda, pois ele pode conter credenciais e chaves secretas. Se um desses caminhos não existir, a estrutura da imagem Nightly pode ter mudado; consulte o log e evite apagar manualmente a versão anterior sem backup.

## Repositórios

- **AIOTERMUX:** https://github.com/vinip1250-art/AIOTERMUX
- **AIOStreams:** https://github.com/Viren070/AIOStreams

A versão Nightly pode incluir mudanças recentes e instabilidade. A disponibilidade da tag e a estrutura interna da imagem dependem do projeto upstream.
