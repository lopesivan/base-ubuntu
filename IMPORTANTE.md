Sim, e isso é uma das partes mais legais do `s6-overlay`: **eles foram usados**, mesmo que você não tenha percebido.

Veja a ordem que apareceu no log:

```text
fix-attrs
legacy-cont-init
legacy-services
```

O `legacy-cont-init` executa **todos os scripts em**:

```text
/etc/cont-init.d/
```

na ordem lexicográfica:

```text
01-envfile
10-adduser
90-custom-folders
99-custom-scripts
```

Só depois o `legacy-services` inicia:

```text
/etc/services.d/xpto-server/run
```

Ou seja, a sequência é exatamente esta:

```
+----------------------+
| /init                |
+----------+-----------+
           |
           v
+----------------------+
| 01-envfile           |
+----------+-----------+
           |
           v
+----------------------+
| 10-adduser           |
+----------+-----------+
           |
           v
+----------------------+
| 90-custom-folders    |
+----------+-----------+
           |
           v
+----------------------+
| 99-custom-scripts    |
+----------+-----------+
           |
           v
+----------------------+
| xpto-server/run      |
+----------+-----------+
           |
           v
+----------------------+
| server.py            |
+----------------------+
```

Então eles **não ficaram inúteis**.

---

## O papel de cada um

### 01-envfile

Converte

```
FILE__PASSWORD=/run/secrets/password
```

em

```
PASSWORD=minha_senha
```

É muito útil quando usar Docker Secrets.

---

### 10-adduser

Cria o usuário

```
ivan
```

com

```
UID
GID
```

passados pelo compose.

Assim o servidor pode rodar como usuário comum.

---

### 90-custom-folders

Prepara diretórios da aplicação.

Hoje você cria

```
/config
/defaults
/app
```

Amanhã pode criar

```
/var/xpto

/run/xpto

/cache/xpto
```

---

### 99-custom-scripts

É o mais interessante.

Ele permite que qualquer pessoa coloque um script em

```
/config/custom-cont-init.d/
```

sem reconstruir a imagem.

Exemplo:

```
config/
└── custom-cont-init.d
    ├── 10-download-model
    ├── 20-create-db
    ├── 30-generate-config
```

Seu container executará tudo automaticamente.

---

## O que eu mudaria

Na verdade eu faria apenas uma mudança.

Hoje você ainda tem:

```
entrypoint.sh
```

Mas agora quem controla tudo é o

```
/init
```

Então eu removeria completamente o `entrypoint.sh`.

Ficaria:

```
system/

root/
    etc/
        cont-init.d/
        services.d/

opt/
    xpto-server/

Dockerfile
```

O `10-adduser` já faz exatamente o trabalho que o `entrypoint.sh` fazia.

Você está criando o usuário duas vezes:

```
entrypoint.sh
```

e

```
10-adduser
```

Isso é redundante.

---

## Minha sugestão

Eu reorganizaria assim:

```
system/

opt/
    xpto-server/
        server.py

root/
    etc/
        cont-init.d/
            01-envfile
            10-adduser
            20-config
            30-directories
            40-permissions

        services.d/
            xpto-server/
                run
```

Observe que eu substituiria a numeração `90` e `99` por `20`, `30` e `40`. Como são scripts da própria imagem, faz sentido executá-los cedo, antes de qualquer script personalizado que o usuário possa adicionar no futuro.

No geral, sua estrutura está muito próxima do padrão usado por imagens maduras baseadas em `s6-overlay` (como as da LinuxServer.io). A única simplificação que eu faria é eliminar o `entrypoint.sh` e deixar que todo o ciclo de inicialização seja controlado exclusivamente pelo `s6` através dos scripts em `cont-init.d` e dos serviços em `services.d`.

