# ── Stage 1: build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /build

COPY app/package*.json ./
RUN npm install

COPY app/src/ ./src/
COPY app/tsconfig.json ./
RUN npm run build

# Remove devDependencies
RUN npm prune --omit=dev

# ── Stage 2: runtime ─────────────────────────────────────────────────────────
# Stage 2
FROM ivancarlos/xpto-server:amd64-1.2.5

# Copia node/npm do builder alpine — sem apt, sem nodesource
COPY --from=builder /usr/local/bin/node  /usr/local/bin/node
COPY --from=builder /usr/local/bin/npm   /usr/local/bin/npm

COPY --from=builder /build/dist/        /app/dist/
COPY --from=builder /build/node_modules /app/node_modules/
COPY --from=builder /build/package.json /app/package.json

COPY defaults/                          /defaults/
COPY system/root/etc/cont-init.d/       /etc/cont-init.d/
COPY system/services.d/node-api/        /etc/services.d/node-api/

EXPOSE 3000

ENTRYPOINT ["/init"]
