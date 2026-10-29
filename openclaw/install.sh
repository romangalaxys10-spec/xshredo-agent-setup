#!/bin/sh
# OpenClaw runtime install (docker). REPO_URL can pin a fork/release.
set -e
REPO_URL="${OPENCLAW_REPO_URL:-https://github.com/openclaw/openclaw}"
BRANCH="${OPENCLAW_BRANCH:-main}"
echo "→ OpenClaw: fetching runtime from $REPO_URL ($BRANCH)"
mkdir -p /root/xshredo-ai && cd /root/xshredo-ai
if [ ! -d openclaw ]; then
  git clone --depth 1 -b "$BRANCH" "$REPO_URL" openclaw
fi
cd openclaw
# OpenClaw ships a compose file for the gateway + workspace
if [ -f docker-compose.yml ] || [ -f compose.yaml ]; then
  docker compose up -d 2>/dev/null || docker-compose up -d
  echo "→ OpenClaw stack started."
else
  echo "→ NOTE: no compose file in this release — start the runtime per upstream README."
fi
echo "→ OpenClaw installed at /root/xshredo-ai/openclaw"
