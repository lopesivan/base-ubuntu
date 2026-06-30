Perfeito. Vou gerar tudo seguindo exatamente o padrão que você já usa.

A arquitetura fica assim:
- Gitea instalado no build via `Dockerfile`
- SSH server (`openssh-server`) também no build
- `cont-init.d` cuida da inicialização (chaves SSH, config do Gitea)
- `s6-overlay` gerencia os dois processos: `sshd` + `gitea`
- Repos em `./home/${USER}` já montado

Vou gerar os arquivos:Agora tenho tudo que preciso. Vou gerar a estrutura completa.O tar contém só os arquivos **novos** — você joga dentro de um projeto que já tem `system/entrypoint.sh`, `system/su-exec/`, `system/root/usr/bin/with-contenv` e os `cont-init.d` do baseimage.

---

## O que foi gerado

**Novos arquivos em `system/`:**

| Arquivo | O que faz |
|---|---|
| `cont-init.d/20-sshd` | Gera chaves do host SSH + escreve `sshd_config` (só permite o `$USER`, sem senha, só pubkey) |
| `cont-init.d/30-gitea` | Cria dirs de dados, gera `app.ini` com SQLite + secret keys aleatórias (só no primeiro boot) |
| `services.d/sshd/run` | `sshd -D -e` supervisionado pelo s6 |
| `services.d/gitea/run` | `gitea web` rodando como `$USER` via `su-exec` |

**Dockerfile** — sobre o baseimage existente, acrescenta:
- `openssh-server` + `git` via apt
- `gitea` binary baixado direto do dl.gitea.com

**Makefile** — padrão idêntico ao do `xpto-server`, sem `docker-compose`, com `run`, `run-as-root`, `exec-git` e `init-dirs`.

---

## Fluxo de primeiro boot

```
/init (s6)
  → 01-envfile       (secrets)
  → 10-adduser       (cria USER com PUID/PGID)
  → 20-sshd          (chaves host + sshd_config)
  → 30-gitea         (app.ini + dirs)
  → 90-custom-folders
  → 99-custom-scripts
  ↓
services.d/sshd/run   ← sshd escutando na 22 (mapeada pra 2222)
services.d/gitea/run  ← gitea web na 3000
```

Acessa `http://localhost:3000`, clica em **Install** no wizard (já vem pré-preenchido pelo `app.ini`), cria o admin e pronto.

