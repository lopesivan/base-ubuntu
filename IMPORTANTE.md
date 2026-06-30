git-server
==========

Esse é exatamente um dos pontos fortes do `s6`: **cada
servidor vira um serviço independente**.

Hoje você tem:

```text
services.d/
└── xpto-server/
    └── run
```

Se amanhã quiser um servidor Git, basta adicionar outro serviço:

```text
system/
├── opt/
│   ├── xpto-server/
│   │   └── server.py
│   └── git-server/
│       ├── git-http.sh
│       └── git-daemon.sh
│
└── root/
    └── etc/
        └── services.d/
            ├── xpto-server/
            │   └── run
            │
            ├── git-http/
            │   └── run
            │
            └── git-daemon/
                └── run
```

O `run` do Git seria algo como:

```bash
#!/usr/bin/with-contenv bash
exec git daemon \
    --reuseaddr \
    --verbose \
    --export-all \
    --base-path=/srv/git \
    /srv/git
```

Enquanto o servidor HTTP continua independente.

O interessante é que o `s6` fica assim:

```
           /init
              │
    ┌─────────┴──────────┐
    │                    │
cont-init.d         services.d
                         │
        ┌────────────────┼───────────────┐
        │                │               │
 xpto-server        git-http        git-daemon
```

Se o `git-daemon` morrer, apenas ele será reiniciado.

O servidor HTTP continua funcionando.

---

## Se quiser adicionar N serviços

A estrutura continua crescendo naturalmente.

```text
services.d/
├── nginx/
├── ssh/
├── xpto-server/
├── git-http/
├── git-daemon/
├── cron/
├── redis/
└── worker/
```

Cada um possui seu próprio:

```text
run
finish
```

(opcionalmente `notification-fd`, `data`, etc.).

---

## Eu iria um passo além

Como você está construindo uma base reutilizável, eu separaria **aplicações** de **serviços**.

```text
system/

opt/
    xpto-server/
    git-server/
    nginx/
    ssh/

root/

    etc/

        cont-init.d/

        services.d/

            xpto-server/
                run

            git-daemon/
                run

            nginx/
                run

            ssh/
                run
```

Repare que:

* `/opt` contém **os programas**;
* `/etc/services.d` contém **como executá-los**.

Assim um mesmo programa pode ter mais de um serviço.

Por exemplo:

```text
opt/git-server/
    git-http-backend
    git-daemon
```

e

```text
services.d/

git-http/
    run

git-daemon/
    run
```

São dois serviços diferentes usando os mesmos binários.

---

## Eu também criaria um diretório `services`

Outra ideia que acho elegante é desacoplar completamente a lógica do serviço.

```text
system/

services/

    git-daemon/
        run

    nginx/
        run

    xpto-server/
        run
```

No `Dockerfile`:

```dockerfile
COPY system/services/ /etc/services.d/
```

Assim a estrutura fica muito clara:

```
opt/        -> aplicações
etc/        -> configuração
services/   -> supervisão do s6
```

Na minha opinião, essa organização escala muito bem. Você pode começar com um único servidor HTTP e, no futuro, adicionar Git, Nginx, SSH, Redis ou qualquer outro serviço sem alterar a arquitetura: basta criar um novo diretório em `services.d` com o respectivo `run`. É exatamente esse o modelo que o `s6-overlay` foi projetado para suportar.

