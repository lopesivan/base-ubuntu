#!/bin/bash
# entrypoint.sh — cria grupo/usuário e troca para ele via su-exec
set -euo pipefail

log() { echo "[entrypoint] $*"; }
die() { log "ERROR: $*"; exit 1; }

# Variáveis obrigatórias para rodar como não-root
USER="${USER:-}"
GROUP="${GROUP:-}"
UID="${UID:-}"
GID="${GID:-}"

log "USER=${USER} GROUP=${GROUP} UID=${UID} GID=${GID}"

if [[ -z "$GID" || -z "$UID" || -z "$USER" || -z "$GROUP" ]]; then
  log "Rodando como root (variáveis de usuário não definidas)"
  exec "$@"
fi

# --- Grupo ------------------------------------------------------------------
if getent group "$GID" >/dev/null 2>&1; then
  log "GID $GID já existe"
elif getent group "$GROUP" >/dev/null 2>&1; then
  log "Grupo $GROUP já existe com GID diferente"
else
  log "Criando grupo $GROUP com GID $GID"
  groupadd -g "$GID" "$GROUP"
fi

# --- Usuário ----------------------------------------------------------------
if getent passwd "$UID" >/dev/null 2>&1; then
  log "UID $UID já existe"
elif getent passwd "$USER" >/dev/null 2>&1; then
  log "Usuário $USER já existe com UID diferente"
else
  log "Criando usuário $USER (UID=$UID GID=$GID)"
  useradd -u "$UID" -g "$GID" -M -s /bin/bash "$USER"
fi

# --- HOME -------------------------------------------------------------------
export HOME="/home/$USER"
mkdir -p "$HOME"
chown "$USER:$GROUP" "$HOME"

log "Executando como $USER: $*"
exec /usr/local/bin/su-exec "$USER" "$@"
