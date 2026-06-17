**Vantagens dessa abordagem**

Partir de `ubuntu:22.04` com instalação mínima e s6-overlay
como init system tem algumas vantagens reais:

*Superfície de ataque reduzida.* Menos pacotes = menos
CVEs. Uma imagem Ubuntu completa tem centenas de pacotes que
nunca são usados num container. Aqui tens só o essencial.

*Init system correto.* O s6-overlay resolve um problema real
do Docker: processos zumbi e sinais não propagados. Sem ele,
se teu processo principal faz `fork`, os filhos ficam órfãos
e o container não encerra limpo. O s6 faz reaping de zumbis
e propaga SIGTERM corretamente.

*Troca de usuário segura.* O `su-exec` (equivalente ao
`gosu`) troca de root para o usuário da aplicação sem
criar um processo intermediário — diferente do `sudo`
que mantém o processo pai rodando.

*Base reproduzível.* Qualquer imagem derivada desta herda
o mesmo padrão de init, criação de usuário e estrutura
de diretórios.

---

**O que roda bem nessa base**

Qualquer serviço que seja um único processo ou um conjunto
pequeno de processos supervisionados:

- Servidores web (nginx, caddy)
- Aplicações Python, Node, Go, Java
- Ferramentas de CLI e automação
- Agentes e workers de fila
- Compiladores e ambientes de build (como o teu SDK)
- Serviços de banco de dados leves

---

**O que foi removido e o que isso implica**

Não tens `systemd`, `cron` nativo, `syslog`, nem a maioria
das ferramentas de sistema. Se precisares de:

- **Tarefas agendadas** → usa `s6-cron` ou um processo dedicado com `sleep` loop
- **Logs centralizados** → redireciona stdout/stderr para o Docker log driver
- **Múltiplos serviços** → registra cada um em
`custom-services.d` que o `99-custom-scripts` já processa

---

**Como adicionar um serviço à base**

Crias uma imagem filha:

```dockerfile
FROM ivancarlos/xpto-server:amd64-1.2.5

RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

COPY services/nginx /config/custom-services.d/nginx
```

Onde `nginx` é um script `run` simples:

```bash
#!/bin/bash
exec nginx -g "daemon off;"
```

O s6 supervisiona, reinicia se cair, e o container encerra
limpo quando necessário.
