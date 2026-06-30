# git-server

Gitea + OpenSSH sobre o baseimage Ubuntu + s6-overlay + su-exec.

## Estrutura

```
git-server/
├── Dockerfile
├── Makefile
├── .version
├── home/                          ← volume: repos e home do usuário
├── data/gitea/                    ← volume: banco SQLite + dados do Gitea
├── config/gitea/                  ← volume: app.ini (gerado no primeiro boot)
└── system/
    ├── entrypoint.sh
    ├── su-exec/su-exec
    ├── root/
    │   ├── usr/bin/with-contenv
    │   └── etc/
    │       ├── cont-init.d/
    │       │   ├── 01-envfile          (secrets FILE__VAR)
    │       │   ├── 10-adduser          (cria usuário com PUID/PGID)
    │       │   ├── 20-sshd             (gera chaves host + sshd_config)
    │       │   ├── 30-gitea            (cria app.ini + dirs)
    │       │   ├── 90-custom-folders
    │       │   └── 99-custom-scripts
    │       └── services.d/
    │           ├── sshd/run            (s6: sshd -D)
    │           └── gitea/run           (s6: gitea web como USER)
```

## Primeiro uso

```bash
# 1. Copie su-exec e os scripts do baseimage para system/
#    (mesmos arquivos do xpto-server)

# 2. Build
make build

# 3. Cria os volumes locais e sobe
make up
```

Acesse o Gitea em: http://localhost:3000
(Na primeira visita ele mostra o wizard de instalação — clique em "Install".)

## Portas

| Porta local | Serviço       |
|-------------|---------------|
| 3000        | Gitea HTTP    |
| 2222        | SSH (git)     |

SSH exposto na 2222 para não colidir com o SSH da máquina host.

## Configurar chave SSH para push

```bash
# Na máquina host — adicione no ~/.ssh/config:
Host gitea-local
    HostName localhost
    Port 2222
    User SEU_USUARIO_GITEA
    IdentityFile ~/.ssh/id_ed25519

# Clone via SSH:
git clone ssh://gitea-local/usuario/repo.git

# ou com a URL curta após configurar o Host:
git clone gitea-local:usuario/repo.git
```

## Variáveis de ambiente

| Variável | Padrão | Descrição                        |
|----------|--------|----------------------------------|
| USER     | —      | Nome do usuário Linux no container |
| GROUP    | —      | Nome do grupo                    |
| PUID     | 1000   | UID                              |
| PGID     | 1000   | GID                              |

## Volumes

| Volume local      | Dentro do container | Conteúdo                  |
|-------------------|---------------------|---------------------------|
| ./home            | /home/$USER         | Home + repos git          |
| ./data/gitea      | /var/lib/gitea      | SQLite + uploads + sessões|
| ./config/gitea    | /etc/gitea          | app.ini                   |

## Comandos úteis

```bash
make log          # logs em tempo real
make exec         # shell como USER
make exec-root    # shell como root
make exec-git     # shell como usuário git
make restart      # reinicia o container
make clean        # stop + rm
```
