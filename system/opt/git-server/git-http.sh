#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="${GIT_ROOT:-/srv/git}"
PORT="${GIT_HTTP_PORT:-8080}"

export GIT_PROJECT_ROOT="$ROOT"
export GIT_HTTP_EXPORT_ALL=1

mkdir -p "$ROOT"

echo "[git-http] porta $PORT"

exec python3 -m http.server \
    --cgi \
    "$PORT"
