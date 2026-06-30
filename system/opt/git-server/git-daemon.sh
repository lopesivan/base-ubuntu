#!/usr/bin/env bash
set -Eeuo pipefail

GIT_ROOT="${GIT_ROOT:-/srv/git}"
PORT="${GIT_PORT:-9418}"

mkdir -p "$GIT_ROOT"

echo "[git-daemon] exportando repositórios em $GIT_ROOT"
echo "[git-daemon] porta $PORT"

exec git daemon \
    --verbose \
    --reuseaddr \
    --export-all \
    --base-path="$GIT_ROOT" \
    --port="$PORT" \
    "$GIT_ROOT"
