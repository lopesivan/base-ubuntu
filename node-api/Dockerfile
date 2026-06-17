FROM ivancarlos/xpto-server:amd64-1.2.5

ARG NODE_VERSION="20"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
    && \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y --no-install-recommends \
        nodejs \
    && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copia aplicação
COPY app/ /app/

# Instala dependências e compila TypeScript
RUN cd /app && \
    npm install && \
    npm run build && \
    npm prune --production

# Configuração padrão
COPY defaults/ /defaults/

# Script de init
COPY system/root/etc/cont-init.d/ /etc/cont-init.d/

# Serviço s6
COPY system/services.d/node-api/ /etc/services.d/node-api/

EXPOSE 3000

ENTRYPOINT ["/init"]
