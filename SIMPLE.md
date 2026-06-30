Perfeito — stack mínima:

- **SSH** → push/pull autenticado com o `USER` do host
- **git-daemon** → `git://` anônimo read-only

Gerando tudo agora.Mesma lógica do Gitea: o tar tem só os **arquivos novos** — você copia em cima de um projeto que já tem `entrypoint.sh`, `su-exec`, `with-contenv` e os `cont-init.d` do baseimage.

---

## O que foi gerado

**`cont-init.d/20-sshd`** — gera as 3 chaves do host (`rsa`, `ecdsa`, `ed25519`) e escreve um `sshd_config` enxuto: sem senha, só pubkey, `AllowUsers` restrito ao `$USER` do host.

**`cont-init.d/30-git`** — cria `~/repos`, ajusta `.ssh/authorized_keys` com permissões corretas, e faz `/srv/git → ~/repos` via symlink (assim o git-daemon serve o mesmo volume sem duplicar montagem).

**`services.d/sshd/run`** — `sshd -D -e` supervisionado pelo s6.

**`services.d/git-daemon/run`** — `git daemon --export-all --base-path=/srv/git` supervisionado pelo s6.

---

## Fluxo do dia a dia

```bash
# 1. Build
make build

# 2. Sobe
make up

# 3. Adiciona sua chave pública
make add-key KEY="$(cat ~/.ssh/id_ed25519.pub)"

# 4. Cria um repo
make new-repo REPO=meu-projeto

# 5. Clona via SSH
git clone ssh://ivan@localhost:2222/~/repos/meu-projeto.git

# 6. Clona via git:// (read-only, anônimo)
git clone git://localhost/meu-projeto.git
```

**Observação sobre `--export-all`**: o `git-daemon` está com `--export-all`, então serve todos os repos sem precisar do `git-daemon-export-ok`. Se quiser opt-in por repo, remove essa flag do `services.d/git-daemon/run` e toca o arquivo manualmente em cada bare repo.

