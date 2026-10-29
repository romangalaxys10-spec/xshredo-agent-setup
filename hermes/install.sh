#!/bin/sh
# Hermes agent framework install (docker).
# HERMES_REPO_URL: the Hermes agent runtime repository (set by the xShredo
# team to the pinned release used for customer deliveries).
set -e
REPO_URL="${HERMES_REPO_URL:-}"
echo "→ Hermes: setting up runtime workspace at /root/xshredo-ai/hermes"
mkdir -p /root/xshredo-ai/hermes && cd /root/xshredo-ai/hermes

if [ -n "$REPO_URL" ]; then
  if [ ! -d runtime ]; then
    git clone --depth 1 "$REPO_URL" runtime
  fi
  cd runtime
  if [ -f docker-compose.yml ] || [ -f compose.yaml ]; then
    docker compose up -d 2>/dev/null || docker-compose up -d
    echo "→ Hermes stack started."
  else
    echo "→ NOTE: no compose file — start per the Hermes runtime README."
  fi
else
  echo "→ HERMES_REPO_URL not set — workspace created at /root/xshredo-ai/hermes."
  echo "  Place the Hermes runtime here (or set HERMES_REPO_URL and re-run)."
  echo "  The xShredo console manifest (software + bridges) applies to this workspace."
fi
