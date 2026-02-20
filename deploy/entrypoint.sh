#!/bin/sh
set -e

# ──────────────────────────────────────────────────────────────
# OpenClaw Fly.io Entrypoint
# Syncs tracked config files from the Docker image to the
# persistent /data volume, installs tools, then starts the gateway.
# ──────────────────────────────────────────────────────────────

DEPLOY_DIR="/app/deploy/data"
DATA_DIR="/data"

# --- Sync tracked config files ---
# Always overwrite these from the repo (source of truth).
# Runtime state (agents/, sessions/, config/gogcli/) is left untouched.

sync_file() {
  # Copy file, removing destination first if needed (handles root-owned files)
  src="$1" dst="$2"
  if [ -f "$dst" ] && [ ! -w "$dst" ]; then
    echo "[entrypoint] $dst not writable, skipping (fix with: fly ssh console --command 'chown node:node $dst')"
    return 0
  fi
  cp "$src" "$dst"
}

if [ -d "$DEPLOY_DIR" ]; then
  echo "[entrypoint] syncing tracked config to $DATA_DIR"

  # openclaw.json — main gateway config
  sync_file "$DEPLOY_DIR/openclaw.json" "$DATA_DIR/openclaw.json"

  # auth-profiles.json — provider auth (keys come from env vars)
  sync_file "$DEPLOY_DIR/auth-profiles.json" "$DATA_DIR/auth-profiles.json"

  # workspace — TOOLS.md, skills, etc.
  mkdir -p "$DATA_DIR/workspace/skills"
  cp -r "$DEPLOY_DIR/workspace/"* "$DATA_DIR/workspace/" 2>/dev/null || true

  echo "[entrypoint] config sync complete"
else
  echo "[entrypoint] WARNING: $DEPLOY_DIR not found, skipping config sync"
fi

# --- Install gog binary if missing ---
GOG_BIN="$DATA_DIR/bin/gog"
if [ ! -x "$GOG_BIN" ]; then
  echo "[entrypoint] installing gog binary"
  mkdir -p "$DATA_DIR/bin"
  GOG_VERSION="v0.11.0"
  GOG_URL="https://github.com/steipete/gogcli/releases/download/${GOG_VERSION}/gogcli_${GOG_VERSION#v}_linux_amd64.tar.gz"
  curl -sL "$GOG_URL" -o /tmp/gogcli.tar.gz
  tar xzf /tmp/gogcli.tar.gz -C /tmp
  mv /tmp/gog "$GOG_BIN"
  chmod +x "$GOG_BIN"
  rm -f /tmp/gogcli.tar.gz
  echo "[entrypoint] gog $(${GOG_BIN} --version) installed"
else
  echo "[entrypoint] gog already installed: $(${GOG_BIN} --version)"
fi

# --- Start the gateway ---
echo "[entrypoint] starting gateway"
exec "$@"
